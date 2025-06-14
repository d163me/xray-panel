from flask import Flask
from flask_cors import CORS
from models import db
from admin_api_routes import admin_api
from user_api_routes import user_api

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///db.sqlite3"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db.init_app(app)
CORS(app)

app.register_blueprint(admin_api)
app.register_blueprint(user_api)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
