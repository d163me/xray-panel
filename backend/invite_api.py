from flask import request, jsonify
from app_combined_server import app
from models import db, Invite
from datetime import datetime, timedelta
import secrets

@app.route("/api/invite/create", methods=["POST"])
def create_invite():
    data = request.get_json()
    code = secrets.token_urlsafe(8)
    max_uses = int(data.get("max_uses", 3))
    days_valid = int(data.get("days_valid", 7))
    role = data.get("role", "user")

    invite = Invite(
        code=code,
        role=role,
        max_uses=max_uses,
        uses=0,
        expires_at=datetime.utcnow() + timedelta(days=days_valid)
    )

    db.session.add(invite)
    db.session.commit()

    return jsonify({"code": code, "role": role})
