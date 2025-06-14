import os
import hashlib
import hmac
import uuid as uuidlib
from datetime import datetime
from flask import request, jsonify
from app_combined_server import app, db
from models import User, InviteCode
from dotenv import load_dotenv

# ⬇️ Явная загрузка .env по абсолютному пути
load_dotenv(dotenv_path="/opt/marzban-fork/backend/.env")

BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")

# ⬇️ Отладочный вывод
print("🔑 BOT_TOKEN =", BOT_TOKEN)

def check_telegram_auth(data):
    auth_data = data.copy()
    hash_check = auth_data.pop("hash", None)
    if not hash_check:
        return False
    auth_data_sorted = sorted([f"{k}={v}" for k, v in auth_data.items()])
    data_check_string = "\n".join(auth_data_sorted)
    secret_key = hashlib.sha256(BOT_TOKEN.encode()).digest()
    hmac_obj = hmac.new(secret_key, data_check_string.encode(), hashlib.sha256)
    return hmac_obj.hexdigest() == hash_check

@app.route("/api/auth/telegram", methods=["POST"])
def telegram_login():
    data = request.get_json()
    if not data:
        return jsonify({"error": "no data"}), 400

    if not check_telegram_auth(data):
        return jsonify({"error": "invalid auth"}), 403

    telegram_id = data.get("id")
    username = str(telegram_id) if telegram_id else None
    if not username:
        return jsonify({"error": "missing id"}), 400

    existing = User.query.filter_by(username=username).first()
    if existing:
        return jsonify({"uuid": existing.uuid})

    invite_code = data.get("invite")
    client_uuid = data.get("client_uuid")

    if not invite_code or not client_uuid:
        return jsonify({"error": "missing invite or uuid"}), 400

    invite = InviteCode.query.filter_by(code=invite_code).first()
    if not invite:
        return jsonify({"error": "invalid invite"}), 400
    if invite.expires_at and invite.expires_at < datetime.utcnow():
        return jsonify({"error": "invite expired"}), 400
    if invite.max_uses and invite.uses >= invite.max_uses:
        return jsonify({"error": "invite maxed out"}), 400

    new_user = User(
        uuid=client_uuid,
        role="user",
        username=username
    )

    invite.uses += 1
    if invite.used_by:
        invite.used_by += f",{client_uuid}"
    else:
        invite.used_by = client_uuid

    db.session.add(new_user)
    db.session.commit()

    return jsonify({"uuid": new_user.uuid})
