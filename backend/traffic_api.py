from flask import jsonify
from app_combined_server import app
from traffic_logger import TrafficLog
from models import User

@app.route("/api/traffic/<uuid>", methods=["GET"])
def get_user_traffic(uuid):
    logs = TrafficLog.query.filter_by(uuid=uuid).order_by(TrafficLog.timestamp.desc()).limit(30).all()
    return jsonify([
        {
            "timestamp": log.timestamp.isoformat(),
            "rx": log.rx,
            "tx": log.tx
        } for log in logs[::-1]
    ])
