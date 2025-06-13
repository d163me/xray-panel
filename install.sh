#!/bin/bash

echo "[1/3] Обновляем код с GitHub..."
cd /opt/marzban-fork || exit
git pull || exit

echo "[2/3] Обновляем базу данных..."
cd backend || exit
source venv/bin/activate
python3 <<EOF
from app_combined_server import app
from models import db
with app.app_context():
    db.create_all()
EOF
deactivate

echo "[3/3] Перезапускаем backend..."
systemctl restart marzban-backend

echo "[✔] Установка завершена. Проверьте http://your.domain.com"
