#!/bin/bash

set -e

REPO_URL="https://github.com/d163me/xray-panel.git"
APP_DIR="/opt/marzban-fork"
BACKEND_DIR="$APP_DIR/backend"
INSTANCE_DIR="$BACKEND_DIR/instance"
DB_FILE="$INSTANCE_DIR/db.sqlite"
SERVICE_NAME="marzban-backend"
DOMAIN="hydrich.online"  # <- Задайте ваш домен

echo "[1/8] Обновление системы и установка зависимостей..."
apt update -y && apt upgrade -y
apt install -y git curl python3 python3-venv python3-pip nginx sqlite3

echo "[2/8] Установка Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

echo "[3/8] Клонирование или обновление репозитория..."
if [ -d "$APP_DIR" ]; then
  echo "    📂 $APP_DIR найден, обновляем..."
  cd "$APP_DIR"
  git pull origin main
else
  echo "    📂 Клонируем репозиторий в $APP_DIR..."
  git clone "$REPO_URL" "$APP_DIR"
fi

echo "[4/8] Настройка Python-бэкенда..."
cd "$BACKEND_DIR"
python3 -m venv venv
source venv/bin/activate
pip install --no-cache-dir -r requirements.txt

echo "[   ] Подготовка файла базы данных..."
mkdir -p "$INSTANCE_DIR"
touch "$DB_FILE"
chmod 755 "$INSTANCE_DIR"
chmod 664 "$DB_FILE"

echo "[   ] Инициализация схемы БД..."
python3 <<EOF
import os
from flask import Flask
from flask_cors import CORS
from db import db

# создаём приложение с абсолютным путём к БД
app = Flask(__name__)
basedir = os.path.abspath(os.path.dirname(__file__))
db_path = os.path.join(basedir, "instance", "db.sqlite")
app.config["SQLALCHEMY_DATABASE_URI"] = f"sqlite:///{db_path}"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

CORS(app)
db.init_app(app)
with app.app_context():
    db.create_all()
print("    ✅ Схема БД создана в", db_path)
EOF
deactivate

echo "[5/8] Настройка systemd-сервиса..."
cat > /etc/systemd/system/$SERVICE_NAME.service <<EOF
[Unit]
Description=Marzban Fork Backend
After=network.target

[Service]
User=root
WorkingDirectory=$BACKEND_DIR
ExecStart=$BACKEND_DIR/venv/bin/python $BACKEND_DIR/app_combined_server.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl restart $SERVICE_NAME

echo "[6/8] Сборка фронтенда..."
cd "$APP_DIR/frontend"
npm install --no-audit --no-fund
npm run build

echo "[7/8] Настройка nginx..."
cat > /etc/nginx/sites-available/marzban <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    root $APP_DIR/frontend/dist;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/marzban /etc/nginx/sites-enabled/marzban
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

echo "[8/8] Установка и настройка завершены!"
echo "Перейдите в браузере на http://$DOMAIN и проверьте работу панели."
