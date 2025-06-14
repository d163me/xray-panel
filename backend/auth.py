from flask import request, jsonify
from werkzeug.security import check_password_hash
from app_combined_server import app, db
from models import User

@app.route("/api/auth/login", methods=["POST"])
def login():
    data = request.get_json()
    if not data or not data.get("username") or not data.get("password"):
        return jsonify({"error": "Missing credentials"}), 400

    user = User.query.filter_by(username=data["username"]).first()
    if not user:
        return jsonify({"error": "User not found"}), 401

    if not check_password_hash(user.password_hash, data["password"]):
        return jsonify({"error": "Incorrect password"}), 401

    return jsonify({"uuid": user.uuid})
