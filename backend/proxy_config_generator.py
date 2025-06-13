from flask import request, jsonify
from app_combined_server import app
from models import User, Server

@app.route("/api/proxy-config", methods=["POST"])
def generate_proxy_config():
    data = request.json
    uuid = data.get("uuid")
    server_id = data.get("server_id")
    proto = data.get("proto", "vless")

    user = User.query.filter_by(uuid=uuid).first()
    server = Server.query.filter_by(id=server_id).first()

    if not user or not server:
        return {"error": "user or server not found"}, 404

    config = ""
    if proto == "vless":
        config = f"vless://{user.uuid}@{server.ip}:443?encryption=none&security=tls&type=ws&path={server.path}#{user.username or user.uuid}"
    elif proto == "vmess":
        config = f"vmess://{user.uuid}@{server.ip}:443?type=ws&security=tls&path={server.path}#{user.username or user.uuid}"
    elif proto == "trojan":
        config = f"trojan://{user.uuid}@{server.ip}:443?security=tls&type=ws&path={server.path}#{user.username or user.uuid}"
    else:
        return {"error": "unknown proto"}, 400

    return jsonify({"config": config})
