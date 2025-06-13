from app_combined_server import db
from datetime import datetime
from sqlalchemy.dialects.sqlite import JSON

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    uuid = db.Column(db.String, unique=True, nullable=False)
    role = db.Column(db.String, default="user")
    username = db.Column(db.String, nullable=True)

class InviteCode(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    code = db.Column(db.String, unique=True, nullable=False)
    used_by = db.Column(JSON, default=list)
    uses = db.Column(db.Integer, default=0)
    max_uses = db.Column(db.Integer, default=1)
    expires_at = db.Column(db.DateTime, nullable=True)

class Server(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String, unique=True)
    ip = db.Column(db.String)
    path = db.Column(db.String)
    note = db.Column(db.String)
    active = db.Column(db.Boolean, default=True)
