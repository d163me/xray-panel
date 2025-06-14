import os
from flask import Flask
from flask_cors import CORS
from db import db   # ваш единственный экземпляр SQLAlchemy

app = Flask(__name__)

# Абсолютный путь к папке backend
BASEDIR = os.path.abspath(os.path.dirname(__file__))
INSTANCE_DIR = os.path.join(BASEDIR, "instance")
DB_PATH = os.path.join(INSTANCE_DIR, "db.sqlite")

# Убедимся, что папка instance существует
os.makedirs(INSTANCE_DIR, exist_ok=True)

app.config["SQLALCHEMY_DATABASE_URI"] = f"sqlite:///{DB_PATH}"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

CORS(app)
db.init_app(app)

# импортируем модели и роуты после init_app
from models import *   # InviteCode, User, Server
from admin_api_routes import *
from invite_api import *
from traffic_api import *
from proxy_config_generator import *
from telegram_auth import *
from multi_server_model import *

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
