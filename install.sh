#!/bin/bash
set -e

read -p "Введите домен (например, proxy.example.com): " DOMAIN
read -p "Введите email для Let's Encrypt: " EMAIL
read -p "Введите порт панели (по умолчанию 8880): " PORT
PORT=${PORT:-8880}

apt update && apt install -y python3 python3-venv nginx curl git unzip certbot python3-certbot-nginx socat

# Установка Xray
mkdir -p /opt/xray-core && cd /opt/xray-core
curl -LO https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o Xray-linux-64.zip && chmod +x xray

cat > /etc/systemd/system/xray.service << EOF
[Unit]
Description=Xray Service
After=network.target
[Service]
ExecStart=/opt/xray-core/xray -config /opt/xray-core/config.json
Restart=on-failure
User=nobody
[Install]
WantedBy=multi-user.target
EOF

cat > /opt/xray-core/config.json << EOF
{
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
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

# Панель
cd /opt
rm -rf xray-panel
git clone https://github.com/d163me/xray-panel.git
cd xray-panel
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

cat > /etc/systemd/system/xray-panel.service << EOF
[Unit]
Description=Xray Web Panel
After=network.target
[Service]
ExecStart=/opt/xray-panel/venv/bin/python3 app.py
WorkingDirectory=/opt/xray-panel
Restart=always
User=root
[Install]
WantedBy=multi-user.target
EOF

# Nginx конфигурация
cat > /etc/nginx/sites-available/xray << EOF
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
        proxy_pass http://127.0.0.1:443;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

ln -sf /etc/nginx/sites-available/xray /etc/nginx/sites-enabled/xray
nginx -t && systemctl restart nginx

certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL || true

systemctl daemon-reexec
systemctl enable xray --now
systemctl enable xray-panel --now

echo ""
echo "✅ Установка завершена: https://$DOMAIN"
