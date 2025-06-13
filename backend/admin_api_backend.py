from flask import request, jsonify
from app_combined_server import app, db
from models import InviteCode, User
import uuid as uuidlib
from datetime import datetime, timedelta

@app.route("/api/invite/generate", methods=["POST"])
def generate_invite():
    data = request.json or {}
    max_uses = data.get("max_uses", 1)
    days_valid = data.get("days_valid", 7)

    invite = InviteCode(
        code=str(uuidlib.uuid4())[:8],
        max_uses=max_uses,
        expires_at=datetime.utcnow() + timedelta(days=days_valid)
    )
    db.session.add(invite)
    db.session.commit()
    return jsonify({
        "code": invite.code,
        "max_uses": invite.max_uses,
        "expires_at": invite.expires_at.isoformat()
    })

@app.route("/api/users/manual", methods=["POST"])
def manual_create_user():
    data = request.json
    new_user = User(
        uuid=data.get("uuid") or str(uuidlib.uuid4()),
        role=data.get("role", "user"),
        username=data.get("username")
    )
    db.session.add(new_user)
    db.session.commit()
    return jsonify({"message": "user added", "uuid": new_user.uuid})
