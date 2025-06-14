#!/bin/bash

set -e

echo "🚀 Установка xray-panel..."

echo -e "\n🛑 [1/8] Остановка старых процессов..."
pkill -f "npm run dev" || true
pkill -f "app_combined_server.py" || true

echo -e "\n🧹 [2/8] Удаление старой версии..."
rm -rf /opt/marzban-fork

echo -e "\n📥 [3/8] Клонирование репозитория..."
git clone https://github.com/d163me/xray-panel.git /opt/marzban-fork

echo -e "\n🌐 [3.5/8] Конфигурация Vite (разрешаем все хосты)..."
sed -i "s/server.allowedHosts = \[\]/server.allowedHosts = \[\"hydrich.online\"\]/" /opt/marzban-fork/frontend/vite.config.js

echo -e "\n🔧 [4/8] Настройка Python-бэкенда..."
apt update
apt install -y python3-venv python3-pip git nginx curl

# Удаляем старые версии nodejs и npm
apt remove -y nodejs npm || true
apt autoremove -y || true

# Установка Node.js 18 и npm через NodeSource
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

cd /opt/marzban-fork/backend

python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo -e "\n🧬 [5/8] Инициализация базы и создание администратора..."
python3 <<EOF
from app_combined_server import db, app, User
with app.app_context():
    db.create_all()
    admin = User.query.filter_by(username='admin').first()
    if not admin:
        admin = User(username='admin', password='123456')
        db.session.add(admin)
        db.session.commit()
        print("✅ Пользователь admin создан.")
    else:
        print("ℹ️ Пользователь 'admin' уже существует.")
EOF

echo -e "\n📦 [6/8] Установка frontend-зависимостей..."
cd /opt/marzban-fork/frontend
npm install

echo -e "\n🚀 [7/8] Автозапуск backend..."
cd /opt/marzban-fork/backend
nohup ./venv/bin/python app_combined_server.py > backend.log 2>&1 &

echo -e "\n🚀 [8/8] Автозапуск frontend (Vite)..."
cd /opt/marzban-fork/frontend
nohup npm run dev > frontend.log 2>&1 &

echo -e "\n✅ Установка завершена и всё запущено!"
echo "🌐 Панель доступна по адресу: http://hydrich.online:5173"
echo "🔐 Логин: admin | Пароль: 123456"
