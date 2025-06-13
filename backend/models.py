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
