from flask import request, jsonify
from app_combined_server import app
from models import User, Server

@app.route("/api/config-by-server", methods=["POST"])
def config_by_server():
    data = request.json
    uuid = data.get("uuid")
    server_id = data.get("server_id")

    user = User.query.filter_by(uuid=uuid).first()
    server = Server.query.filter_by(id=server_id).first()

    if not user or not server:
        return {"error": "not found"}, 404

    url = f"vless://{user.uuid}@{server.ip}:443?encryption=none&security=tls&type=ws&path={server.path}#{server.name}"
    return jsonify({"config": url})
