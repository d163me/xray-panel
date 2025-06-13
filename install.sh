#!/bin/bash

set -e

echo "📦 Установка зависимостей..."
apt update && apt install -y nginx certbot python3-pip unzip curl socat

echo "🐍 Установка Flask..."
pip3 install flask

echo "📁 Создание директорий..."
mkdir -p /opt/xray-core /opt/xray-panel/templates /var/www/html

echo "⬇️ Загрузка Xray..."
curl -L -o /tmp/Xray-linux-64.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o /tmp/Xray-linux-64.zip -d /opt/xray-core
chmod +x /opt/xray-core/xray

echo "🧾 Генерация UUID..."
UUID=$(cat /proc/sys/kernel/random/uuid)
echo "UUID: $UUID"

cat > /opt/xray-core/config.json <<EOF
{
  "inbounds": [{
    "port": 10000,
    "protocol": "vless",
    "settings": {
      "clients": [{
        "id": "$UUID"
      }],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "ws",
      "wsSettings": {
        "path": "/vless"
      }
    }
  }],
  "outbounds": [{
    "protocol": "freedom"
  }]
}
EOF

echo "📝 Создание systemd сервиса для Xray..."
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

echo "🌐 Настройка Nginx..."
cat > /etc/nginx/sites-available/xray <<EOF
server {
    listen 80;
    server_name hydrich.online;

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}
EOF

ln -sf /etc/nginx/sites-available/xray /etc/nginx/sites-enabled/xray
nginx -t && systemctl restart nginx

echo "🔐 Получение SSL сертификата..."
certbot certonly --webroot -w /var/www/html -d hydrich.online --agree-tos --email your@email.com --non-interactive

echo "🔁 Перенастройка Nginx на HTTPS..."
cat > /etc/nginx/sites-available/xray <<EOF
server {
    listen 80;
    server_name hydrich.online;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name hydrich.online;

    ssl_certificate /etc/letsencrypt/live/hydrich.online/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/hydrich.online/privkey.pem;

    location /vless {
        proxy_redirect off;
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

echo "🌐 Создание панели управления..."
cat > /opt/xray-panel/panel.py <<EOF
from flask import Flask, render_template
app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

app.run(host='0.0.0.0', port=8880)
EOF

cat > /opt/xray-panel/templates/index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>Xray Panel</title></head>
<body>
  <h1>Подключение через VLESS</h1>
  <p><code>vless://$UUID@hydrich.online:443?encryption=none&security=tls&type=ws&host=hydrich.online&path=%2Fvless#Xray</code></p>
</body>
</html>
EOF

echo "📝 Создание systemd сервиса для панели..."
cat > /etc/systemd/system/xray-panel.service <<EOF
[Unit]
Description=Xray Panel
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/xray-panel/panel.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "🚀 Запуск сервисов..."
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable xray xray-panel
systemctl restart xray xray-panel

echo "✅ Установка завершена: https://hydrich.online"
