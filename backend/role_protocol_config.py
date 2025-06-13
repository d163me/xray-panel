from flask import jsonify
from app_combined_server import app

@app.route("/api/config-options", methods=["GET"])
def get_available_config_roles():
    return jsonify({
        "roles": ["admin", "user", "vip"],
        "protocols": ["vless", "vmess", "trojan"]
    })
