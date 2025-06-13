from flask import request, jsonify
from app_combined_server import app, db
from models import User, InviteCode

@app.route("/api/users", methods=["GET"])
def list_users():
    users = User.query.all()
    return jsonify([{
        "id": u.id,
        "uuid": u.uuid,
        "role": u.role,
        "username": u.username
    } for u in users])

@app.route("/api/users/<uuid>", methods=["DELETE"])
def delete_user(uuid):
    u = User.query.filter_by(uuid=uuid).first()
    if not u:
        return {"error": "Not found"}, 404
    db.session.delete(u)
    db.session.commit()
    return {"message": "deleted"}

@app.route("/api/invites", methods=["GET"])
def list_invites():
    invites = InviteCode.query.all()
    return jsonify([{
        "code": i.code,
        "used_by": i.used_by,
        "max_uses": i.max_uses,
        "uses": i.uses,
        "expires_at": i.expires_at.isoformat() if i.expires_at else None
    } for i in invites])

@app.route("/api/invites/<code>", methods=["DELETE"])
def delete_invite(code):
    i = InviteCode.query.filter_by(code=code).first()
    if not i:
        return {"error": "Not found"}, 404
    db.session.delete(i)
    db.session.commit()
    return {"message": "deleted"}
