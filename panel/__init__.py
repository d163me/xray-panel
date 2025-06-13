def create_app():
    from flask import Flask
    from panel.routes import bp

    app = Flask(__name__)
    app.secret_key = 'super-secret-key'
    app.register_blueprint(bp)

    return app
