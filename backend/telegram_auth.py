from flask import request, jsonify
from app_combined_server import app, db
from models import User, InviteCode
import hashlib, hmac, uuid
from datetime import datetime

BOT_TOKEN = "8190122776:AAG0A12leBj0Xb7IaWu0swq74v7WU_oLuBQ"

def check_telegram_auth(data):
    auth_data = data.copy()
    hash_check = auth_data.pop("hash")
    auth_data_sorted = sorted([f"{k}={v}" for k, v in auth_data.items()])
    data_check_string = "\n".join(auth_data_sorted)
    secret_key = hashlib.sha256(BOT_TOKEN.encode()).digest()
    hmac_obj = hmac.new(secret_key, data_check_string.encode(), hashlib.sha256)
    return hmac_obj.hexdigest() == hash_check

@app.route("/api/auth/telegram", methods=["POST"])
def telegram_login():
    data = request.json
    if not check_telegram_auth(data):
        return {"error": "invalid auth"}, 403

    user_id = str(data["id"])
    existing = User.query.filter_by(username=user_id).first()
    if existing:
        return jsonify({"uuid": existing.uuid})

    invite_code = data.get("invite")
    if not invite_code:
        return {"error": "no invite"}, 400

    invite = InviteCode.query.filter_by(code=invite_code).first()
    if not invite or (invite.expires_at and invite.expires_at < datetime.utcnow()) or (invite.max_uses and invite.uses >= invite.max_uses):
        return {"error": "invalid invite"}, 400

    new_user = User(uuid=str(uuid.uuid4()), username=user_id, role=invite.role)
    invite.uses += 1

    db.session.add(new_user)
    db.session.commit()
    return jsonify({"uuid": new_user.uuid})
