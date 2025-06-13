from flask import request, jsonify
from app_combined_server import app, db
from models import User, InviteCode
import uuid
from datetime import datetime

@app.route("/api/invite/verify", methods=["POST"])
def verify_and_create_user():
    data = request.json
    invite_code = data.get("code")
    user_id = data.get("username")

    if not invite_code or not user_id:
        return {"error": "missing fields"}, 400

    invite = InviteCode.query.filter_by(code=invite_code).first()
    if not invite:
        return {"error": "invalid invite"}, 404
    if invite.expires_at and invite.expires_at < datetime.utcnow():
        return {"error": "expired"}, 400
    if invite.max_uses and invite.uses >= invite.max_uses:
        return {"error": "max uses reached"}, 400

    new_user = User(
        uuid=str(uuid.uuid4()),
        role="user",
        username=user_id
    )
    invite.uses += 1
    invite.used_by.append(new_user.uuid)

    db.session.add(new_user)
    db.session.commit()
    return jsonify({"uuid": new_user.uuid})
