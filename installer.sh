#!/bin/bash

set -e

echo -e "\n📦 [1/8] Удаление старой версии и остановка процессов..."

sudo systemctl stop marzban-backend.service || true
pkill -f app_combined_server.py || true
pkill -f "npm run dev" || true
rm -rf /opt/marzban-fork

echo -e "\n⬇️ [2/8] Клонирование репозитория..."
git clone https://github.com/d163me/xray-panel.git /opt/marzban-fork

echo -e "\n🐍 [3/8] Настройка Python-бэкенда..."
cd /opt/marzban-fork/backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

echo -e "\n🧪 [4/8] Обновление vite.config.js..."
cat > /opt/marzban-fork/frontend/vite.config.js <<EOF
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    host: true,
    port: 5173,
    allowedHosts: ['hydrich.online']
  }
})
EOF

echo -e "\n🌐 [5/8] Установка конфигурации nginx..."
cat > /etc/nginx/sites-available/hydrich.online <<EOF
server {
    listen 80;
    server_name hydrich.online;

    location / {
        proxy_pass http://127.0.0.1:5173;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

ln -sf /etc/nginx/sites-available/hydrich.online /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

echo -e "\n🧬 [6/8] Инициализация базы и создание администратора..."
cd /opt/marzban-fork/backend
source venv/bin/activate
python <<EOF
from app_combined_server import db, app
from models import User

with app.app_context():
    db.create_all()
    if not User.query.filter_by(username="admin").first():
        user = User(username="admin", password="123456")
        db.session.add(user)
        db.session.commit()
        print("✅ Пользователь admin создан.")
    else:
        print("ℹ️ Пользователь 'admin' уже существует.")
EOF

echo -e "\n🧱 [7/8] Установка frontend-зависимостей..."
cd /opt/marzban-fork/frontend
npm install

echo -e "\n🚀 [8/8] Автозапуск backend и frontend..."
cd /opt/marzban-fork/backend
source venv/bin/activate
nohup python app_combined_server.py > backend.log 2>&1 &

cd /opt/marzban-fork/frontend
nohup npm run dev > frontend.log 2>&1 &

echo -e "\n✅ Установка завершена и всё запущено!"
echo -e "🌐 Панель доступна по адресу: http://hydrich.online"
echo -e "🔐 Логин: admin | Пароль: 123456"
