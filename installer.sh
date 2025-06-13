#!/bin/bash

# Marzban Fork Installer - One Command Setup
# Требования: Ubuntu 20.04+, Python 3.10+, Git, NodeJS (для фронта)

set -e

echo "[+] Обновление системы..."
apt update && apt upgrade -y

echo "[+] Установка зависимостей..."
apt install -y git curl python3 python3-venv python3-pip nginx sqlite3

echo "[+] Клонируем проект..."
git clone https://github.com/d163me/xray-panel.git /opt/marzban-fork
cd /opt/marzban-fork

echo "[+] Настройка Python backend..."
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

echo "[+] Запуск backend на systemd..."
cat > /etc/systemd/system/marzban-backend.service <<EOF
[Unit]
Description=Marzban Fork Backend
After=network.target

[Service]
User=root
WorkingDirectory=/opt/marzban-fork/backend
ExecStart=/opt/marzban-fork/backend/venv/bin/python app_combined_server.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl enable marzban-backend
systemctl start marzban-backend

cd ..
echo "[+] Настройка frontend..."
cd frontend
npm install
npm run build

echo "[+] Настройка nginx..."
cat > /etc/nginx/sites-enabled/marzban <<EOF
server {
    listen 80;
    server_name your.domain.com;

    location / {
        root /opt/marzban-fork/frontend/dist;
        index index.html index.htm;
        try_files \$uri \$uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://localhost:8000/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

systemctl restart nginx

echo "[✔] Установка завершена! Перейдите на http://your.domain.com"
