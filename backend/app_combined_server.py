from flask import Flask
from flask_cors import CORS
from db import db  # Импортируем один экземпляр SQLAlchemy

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///instance/db.sqlite"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

CORS(app)
db.init_app(app)  # Инициализируем SQLAlchemy с приложением

# Импортируем API-маршруты после создания app и db
from admin_api_routes import *
from invite_api import *
from traffic_api import *
from proxy_config_generator import *
from telegram_auth import *
from multi_server_model import *

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
