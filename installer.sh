#!/bin/bash

set -e

REPO_URL="https://github.com/d163me/xray-panel.git"
APP_DIR="/opt/marzban-fork"
BACKEND_DIR="$APP_DIR/backend"
FRONTEND_DIR="$APP_DIR/frontend"
INSTANCE_DIR="$BACKEND_DIR/instance"
DB_FILE="$INSTANCE_DIR/db.sqlite"

echo "[1/8] Установка зависимостей..."
apt update -y && apt upgrade -y
apt install -y git curl python3 python3-venv python3-pip nginx sqlite3

echo "[2/8] Установка Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

echo "[3/8] Клонирование или обновление проекта..."
if [ -d "$APP_DIR" ]; then
  echo "    📂 $APP_DIR найден, обновляем..."
  cd "$APP_DIR"
  git pull origin main
else
  git clone "$REPO_URL" "$APP_DIR"
fi

echo "[4/8] Установка Python-зависимостей..."
cd "$BACKEND_DIR"
python3 -m venv venv
source venv/bin/activate
pip install --no-cache-dir -r requirements.txt

echo "[5/8] Инициализация базы и создание администратора..."
mkdir -p "$INSTANCE_DIR"
touch "$DB_FILE"

cat <<EOF | python3
import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from werkzeug.security import generate_password_hash

basedir = os.path.abspath(os.path.dirname(__file__))
instance_path = os.path.join(basedir, "backend", "instance")
db_path = os.path.join(instance_path, "db.sqlite")
os.makedirs(instance_path, exist_ok=True)

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = f"sqlite:///{db_path}"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
CORS(app)
db = SQLAlchemy(app)

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)
    role = db.Column(db.String(20), nullable=False, default="user")

with app.app_context():
    db.create_all()
    if not User.query.filter_by(username="admin").first():
        admin = User(username="admin", password_hash=generate_password_hash("123456"), role="admin")
        db.session.add(admin)
        db.session.commit()
        print("✅ Пользователь 'admin' создан с паролем '123456'")
    else:
        print("ℹ️ Пользователь 'admin' уже существует.")
EOF

echo "[6/8] Установка frontend-зависимостей..."
cd "$FRONTEND_DIR"
npm install

echo "[7/8] Автозапуск backend..."
cd "$BACKEND_DIR"
source venv/bin/activate
nohup python app_combined_server.py > backend.log 2>&1 &

echo "[8/8] Автозапуск frontend (Vite)..."
cd "$FRONTEND_DIR"
nohup npm run dev > frontend.log 2>&1 &

echo ""
echo "✅ Установка завершена и всё запущено!"
echo "🌐 Панель доступна по адресу: http://<IP_или_домен>:5173"
echo "🔐 Логин: admin | Пароль: 123456"
