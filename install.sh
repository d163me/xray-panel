#!/bin/bash

set -e

echo "[1/3] Обновляем репозиторий..."
cd /opt/marzban-fork
git pull

echo "[2/3] Обновляем базу данных..."
source backend/venv/bin/activate
python3 -c "from models import db; from app_combined_server import app; with app.app_context(): db.create_all()"

echo "[3/3] Перезапускаем сервис..."
systemctl restart marzban-backend

echo "[✔] Установка и перезапуск завершены."
