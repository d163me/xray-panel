#!/bin/bash

set -e

echo "🔧 Введите ваш домен (example.com):"
read DOMAIN

echo "📦 Установка зависимостей..."
apt update
apt install -y nginx certbot python3-certbot-nginx git curl unzip python3-venv

echo "📁 Установка Xray..."
mkdir -p /opt/xray-core
cd /opt/xray-core
curl -L -o xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip xray.zip && rm xray.zip
chmod +x xray

echo "📦 Установка панели..."
mkdir -p /opt/xray-panel/templates
cat > /opt/xray-panel/templates/index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>Xray Panel</title></head>
<body>
  <h1>Панель работает!</h1>
  <p>vless://UUID@$DOMAIN:443?encryption=none&security=tls&type=ws&host=$DOMAIN&path=%2Fvless#Xray</p>
</body>
</html>
EOF

cat > /opt/xray-panel/panel.py <<EOF
from flask import Flask, render_template
app = Flask(__name__, template_folder="templates")
@app.route("/")
def index():
    return render_template("index.html")
if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8880)
EOF

echo "📦 Установка Python-зависимостей..."
python3 -m venv /opt/xray-panel/venv
/opt/xray-panel/venv/bin/pip install flask

echo "🧾 Генерация UUID..."
UUID=\$(cat /proc/sys/kernel/random/uuid)
echo "UUID: \$UUID"

cat > /opt/xray-core/config.json <<EOF
{
  "inbounds": [{
    "port": 10000,
    "protocol": "vless",
    "settings": {
      "clients": [{"id": "\$UUID"}],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "ws",
      "wsSettings": {"path": "/vless"}
    }
  }],
  "outbounds": [{"protocol": "freedom"}]
}
EOF

echo "⚙️ Настройка systemd для Xray..."
cat > /etc/systemd/system/xray.service <<EOF
[Unit]
Description=Xray Service
After=network.target

[Service]
ExecStart=/opt/xray-core/xray -config /opt/xray-core/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "⚙️ Настройка systemd для панели..."
cat > /etc/systemd/system/xray-panel.service <<EOF
[Unit]
Description=Xray Panel
After=network.target

[Service]
ExecStart=/opt/xray-panel/venv/bin/python /opt/xray-panel/panel.py
WorkingDirectory=/opt/xray-panel
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "⚙️ Настройка Nginx..."
cat > /etc/nginx/sites-available/xray <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}
EOF

ln -s /etc/nginx/sites-available/xray /etc/nginx/sites-enabled/xray
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

echo "🔒 Получение SSL сертификата..."
certbot --nginx --non-interactive --agree-tos --email admin@$DOMAIN -d $DOMAIN

echo "🔁 Настройка HTTPS в Nginx..."
cat > /etc/nginx/sites-available/xray <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location /vless {
        proxy_pass http://127.0.0.1:10000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }

    location / {
        proxy_pass http://127.0.0.1:8880;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

nginx -t && systemctl reload nginx

echo "🚀 Запуск служб..."
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now xray
systemctl enable --now xray-panel

echo "✅ Установка завершена: https://$DOMAIN"
echo "🔗 VLESS: vless://\$UUID@$DOMAIN:443?encryption=none&security=tls&type=ws&host=$DOMAIN&path=%2Fvless#Xray"
