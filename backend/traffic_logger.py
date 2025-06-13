from app_combined_server import db
from flask import request
from models import User
from datetime import datetime

class TrafficLog(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    uuid = db.Column(db.String, db.ForeignKey("user.uuid"))
    rx = db.Column(db.BigInteger, default=0)
    tx = db.Column(db.BigInteger, default=0)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

def log_traffic(uuid, rx, tx):
    user = User.query.filter_by(uuid=uuid).first()
    if not user:
        return
    entry = TrafficLog(uuid=uuid, rx=rx, tx=tx)
    db.session.add(entry)
    db.session.commit()
