import uuid

def generate_uuid():
    return str(uuid.uuid4())

def generate_vless_link(uuid_str, username):
    return f"vless://{uuid_str}@example.com:443?encryption=none&security=tls&type=ws&host=example.com&path=%2Fvless#{username}"
