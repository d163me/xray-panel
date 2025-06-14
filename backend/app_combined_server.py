import os
from flask import Flask
from flask_cors import CORS
from db import db

app = Flask(__name__)

BASEDIR = os.path.abspath(os.path.dirname(__file__))
INSTANCE_DIR = os.path.join(BASEDIR, "instance")
DB_PATH = os.path.join(INSTANCE_DIR, "db.sqlite")
os.makedirs(INSTANCE_DIR, exist_ok=True)

app.config["SQLALCHEMY_DATABASE_URI"] = f"sqlite:///{DB_PATH}"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

CORS(app)
db.init_app(app)

from models import *
from auth import *

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
