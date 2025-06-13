from flask import Flask
from panel.routes import bp
import os

def create_app():
    base_dir = os.path.abspath(os.path.dirname(__file__))
    templates_dir = os.path.join(base_dir, '..', 'templates')

    app = Flask(__name__, template_folder=templates_dir)
    app.secret_key = 'super-secret-key'
    app.register_blueprint(bp)
    return app
