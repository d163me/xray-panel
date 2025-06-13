from models import InviteCode
from datetime import datetime, timedelta
import uuid

def create_invite(max_uses=1, days_valid=7):
    code = str(uuid.uuid4())[:8]
    invite = InviteCode(
        code=code,
        max_uses=max_uses,
        expires_at=datetime.utcnow() + timedelta(days=days_valid)
    )
    return invite

def validate_invite(code):
    invite = InviteCode.query.filter_by(code=code).first()
    if not invite:
        return False
    if invite.expires_at and invite.expires_at < datetime.utcnow():
        return False
    if invite.max_uses and invite.uses >= invite.max_uses:
        return False
    return invite
