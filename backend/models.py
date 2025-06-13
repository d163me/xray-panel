from flask_sqlalchemy import SQLAlchemy
db = SQLAlchemy()

class Invite(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    code = db.Column(db.String, unique=True, nullable=False)
    role = db.Column(db.String, default='user')  # 👈 добавлено
    max_uses = db.Column(db.Integer, nullable=False)
    uses = db.Column(db.Integer, default=0)
    expires_at = db.Column(db.DateTime)
    created_at = db.Column(db.DateTime, default=db.func.now())
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    telegram_id = db.Column(db.BigInteger, unique=True, nullable=False)
    first_name = db.Column(db.String)
    username = db.Column(db.String)
    uuid = db.Column(db.String, unique=True)
    role = db.Column(db.String, default='user')  # 'user', 'vip', 'admin'
    created_at = db.Column(db.DateTime, default=db.func.now())
class Server(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String, nullable=False)
    ip = db.Column(db.String, nullable=False)
    created_at = db.Column(db.DateTime, default=db.func.now())
class TrafficLog(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_uuid = db.Column(db.String, nullable=False)
    timestamp = db.Column(db.DateTime, default=db.func.now())
    rx = db.Column(db.BigInteger, default=0)  # входящий
    tx = db.Column(db.BigInteger, default=0)  # исходящий

