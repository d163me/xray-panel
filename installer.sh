#!/bin/bash

set -e

REPO_URL="https://github.com/d163me/xray-panel.git"
APP_DIR="/opt/marzban-fork"
BACKEND_DIR="$APP_DIR/backend"
FRONTEND_DIR="$APP_DIR/frontend"
INSTANCE_DIR="$BACKEND_DIR/instance"
DB_FILE="$INSTANCE_DIR/db.sqlite"

echo "[1/7] Обновление системы и установка зависимостей..."
apt update -y && apt upgrade -y
apt install -y git curl python3 python3-venv python3-pip nginx sqlite3

echo "[2/7] Установка Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

echo "[3/7] Клонирование или обновление репозитория..."
if [ -d "$APP_DIR" ]; then
  echo "    📂 $APP_DIR найден, обновляем..."
  cd "$APP_DIR"
  git pull origin main
else
  echo "    📂 Клонируем репозиторий в $APP_DIR..."
  git clone "$REPO_URL" "$APP_DIR"
fi

echo "[4/7] Настройка Python-бэкенда..."
cd "$BACKEND_DIR"
python3 -m venv venv
source venv/bin/activate
pip install --no-cache-dir -r requirements.txt

echo "[5/7] Инициализация базы данных и создание администратора..."
mkdir -p "$INSTANCE_DIR"
touch "$DB_FILE"

cat <<EOF | python3
import os
from flask import Flask
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash
from models import User

# Абсолютный путь к базе данных
basedir = os.path.abspath(os.path.dirname(__file__))
instance_path = os.path.join(basedir, "backend", "instance")
db_path = os.path.join(instance_path, "db.sqlite")

# Создаём папку, если нужно
os.makedirs(instance_path, exist_ok=True)

# Flask app + DB
app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = f"sqlite:///{db_path}"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
CORS(app)
db = SQLAlchemy(app)

with app.app_context():
    db.create_all()
    if not User.query.filter_by(username="admin").first():
        user = User(username="admin", password_hash=generate_password_hash("123456"), role="admin")
        db.session.add(user)
        db.session.commit()
        print("✅ Пользователь 'admin' создан с паролем '123456'")
    else:
        print("ℹ️ Пользователь 'admin' уже существует.")
EOF

echo "[6/7] Установка зависимостей frontend..."
cd "$FRONTEND_DIR"
npm install

echo "[7/7] Установка завершена!"
echo "➡ Backend: cd $BACKEND_DIR && source venv/bin/activate && python app_combined_server.py"
echo "➡ Frontend: cd $FRONTEND_DIR && npm run dev"
echo "🔐 Логин: admin | Пароль: 123456"
