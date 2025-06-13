from flask import jsonify, request
from app_combined_server import app, db
from models import InviteCode
from datetime import datetime, timedelta
import uuid

@app.route("/api/invite/list", methods=["GET"])
def get_invite_list():
    invites = InviteCode.query.all()
    return jsonify([{
        "code": i.code,
        "used_by": i.used_by,
        "max_uses": i.max_uses,
        "uses": i.uses,
        "expires_at": i.expires_at.isoformat() if i.expires_at else None
    } for i in invites])

@app.route("/api/invite/create", methods=["POST"])
def create_invite_api():
    data = request.json or {}
    max_uses = data.get("max_uses", 1)
    days_valid = data.get("days_valid", 7)

    invite = InviteCode(
        code=str(uuid.uuid4())[:8],
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
