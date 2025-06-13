#!/bin/bash

echo "🚀 Установка Xray Panel"

# Ввод домена
read -p "Введите ваш домен (например: example.com): " domain

# Обновление системы
apt update && apt upgrade -y

# Установка зависимостей
apt install -y curl unzip nginx certbot python3-certbot-nginx git python3 python3-pip

# Установка Xray
mkdir -p /opt/xray-core
cd /opt/xray-core
curl -L -o xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o xray.zip
rm xray.zip
chmod +x xray

# Генерация UUID
uuid=$(cat /proc/sys/kernel/random/uuid)
echo "🔑 UUID: $uuid"

# Конфигурация Xray
cat > /opt/xray-core/config.json <<EOF
{
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$uuid",
            "level": 0,
            "email": "user@$domain"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/vless"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

# Установка сервиса Xray
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

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable xray
systemctl restart xray

# Установка Flask-панели
mkdir -p /opt/xray-panel/templates
cat > /opt/xray-panel/panel.py <<EOF
from flask import Flask, render_template
import json

app = Flask(__name__)

@app.route('/')
def index():
    with open('/opt/xray-core/config.json') as f:
        data = json.load(f)
    clients = data['inbounds'][0]['settings']['clients']
    return render_template('index.html', clients=clients)

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8880)
EOF

cat > /opt/xray-panel/templates/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Xray Panel</title>
</head>
<body>
    <h1>Подключения</h1>
    {% for client in clients %}
        <p><strong>UUID:</strong> {{ client.id }}</p>
        <p>VLESS-ссылка:</p>
        <code>vless://{{ client.id }}@{{ domain }}:443?encryption=none&security=tls&type=ws&host={{ domain }}&path=%2Fvless#Client</code>
    {% endfor %}
</body>
</html>
EOF

# Установка python-зависимостей
pip3 install flask

# Юнит-файл для панели
cat > /etc/systemd/system/xray-panel.service <<EOF
[Unit]
Description=Xray Panel
After=network.target

[Service]
WorkingDirectory=/opt/xray-panel
ExecStart=/usr/bin/python3 /opt/xray-panel/panel.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable xray-panel
systemctl start xray-panel

# Настройка nginx
cat > /etc/nginx/sites-available/xray <<EOF
server {
    listen 80;
    server_name $domain;

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}
EOF

ln -sf /etc/nginx/sites-available/xray /etc/nginx/sites-enabled/xray
nginx -t && systemctl reload nginx

# Получение SSL-сертификата
certbot --nginx --non-interactive --agree-tos --email you@example.com -d $domain

# Обновление конфигурации Xray на TLS
sed -i 's/"security": "none"/"security": "tls"/' /opt/xray-core/config.json
sed -i '/"security": "tls"/a \        "tlsSettings": {\n          "certificates": [\n            {\n              "certificateFile": "/etc/letsencrypt/live/'$domain'/fullchain.pem",\n              "keyFile": "/etc/letsencrypt/live/'$domain'/privkey.pem"\n            }\n          ]\n        },' /opt/xray-core/config.json

systemctl restart xray

echo ""
echo "✅ Установка завершена: https://$domain"
echo "📡 VLESS: vless://$uuid@$domain:443?encryption=none&security=tls&type=ws&host=$domain&path=%2Fvless#Client"
