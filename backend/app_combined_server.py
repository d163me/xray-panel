from flask import Flask
from flask_cors import CORS
from models import db  # Импортируем db отсюда!

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///db.sqlite"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db.init_app(app)  # Вот это обязательно!
CORS(app)

with app.app_context():
    db.create_all()

from admin_api_routes import *
from invite_api import *
from traffic_api import *
from proxy_config_generator import *
from telegram_auth import *
from multi_server_model import *

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
