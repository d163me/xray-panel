#!/bin/bash

set -e

echo "🚀 Установка xray-panel..."

# [1/8] Остановка старых процессов
echo -e "\n🛑 [1/8] Остановка старых процессов..."
pkill -f "app_combined_server.py" || true
pkill -f "npm run dev" || true

# [2/8] Удаление старой версии
echo -e "\n🧹 [2/8] Удаление старой версии..."
rm -rf /opt/marzban-fork

# [3/8] Клонирование или обновление репозитория
echo -e "\n📥 [3/8] Клонирование репозитория..."
git clone https://github.com/d163me/xray-panel /opt/marzban-fork

# [3.5/8] Автонастройка vite.config.js
echo -e "\n🌐 [3.5/8] Конфигурация Vite (разрешаем hydrich.online)..."
cat > /opt/marzban-fork/frontend/vite.config.js <<EOF
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    host: true,
    port: 5173,
    allowedHosts: ['hydrich.online'],
  }
})
EOF

# [4/8] Настройка Python-бэкенда
echo -e "\n🐍 [4/8] Настройка Python-бэкенда..."
cd /opt/marzban-fork/backend
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# [5/8] Установка frontend-зависимостей
echo -e "\n📦 [5/8] Установка frontend-зависимостей..."
cd /opt/marzban-fork/frontend
npm install

# [6/8] Инициализация базы и создание администратора
echo -e "\n🧬 [6/8] Инициализация базы и создание администратора..."
cd /opt/marzban-fork/backend
source venv/bin/activate
python <<EOF
from flask import Flask
from models import db, User

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///db.sqlite3"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
db.init_app(app)

with app.app_context():
    db.create_all()
    if not User.query.filter_by(username="admin").first():
        db.session.add(User(username="admin", password="123456"))
        db.session.commit()
        print("✅ Пользователь admin создан.")
    else:
        print("ℹ️ Пользователь 'admin' уже существует.")
EOF

# [7/8] Автозапуск backend
echo -e "\n⚙️ [7/8] Автозапуск backend..."
nohup /opt/marzban-fork/backend/venv/bin/python /opt/marzban-fork/backend/app_combined_server.py > /opt/backend.log 2>&1 &

# [8/8] Автозапуск frontend
echo -e "\n⚙️ [8/8] Автозапуск frontend (Vite)..."
cd /opt/marzban-fork/frontend
nohup npm run dev > /opt/frontend.log 2>&1 &

echo -e "\n✅ Установка завершена и всё запущено!"
echo "🌐 Панель доступна по адресу: http://hydrich.online:5173"
echo "🔐 Логин: admin | Пароль: 123456"
