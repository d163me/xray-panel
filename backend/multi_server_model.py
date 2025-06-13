from flask import request, jsonify
from app_combined_server import app, db
from models import Server

@app.route("/api/servers", methods=["GET"])
def list_servers():
    servers = Server.query.filter_by(active=True).all()
    return jsonify([{
        "id": s.id,
        "name": s.name,
        "ip": s.ip,
        "path": s.path,
        "note": s.note
    } for s in servers])

@app.route("/api/servers", methods=["POST"])
def add_server():
    data = request.json
    server = Server(
        name=data["name"],
        ip=data["ip"],
        path=data.get("path", "/"),
        note=data.get("note", "")
    )
    db.session.add(server)
    db.session.commit()
    return jsonify({"message": "added", "id": server.id})
