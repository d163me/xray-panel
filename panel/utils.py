import uuid
import json
import subprocess

CONFIG_PATH = '/opt/xray-core/config.json'

def generate_uuid():
    return str(uuid.uuid4())

def generate_vless_link(uuid_str, username):
    domain = "hydrich.online"
    return f"vless://{uuid_str}@{domain}:443?encryption=none&security=tls&type=ws&host={domain}&path=%2Fvless#{username}"

def add_client_to_config(uuid_str, email):
    with open(CONFIG_PATH, 'r') as f:
        config = json.load(f)

    if 'settings' not in config['inbounds'][0]:
        config['inbounds'][0]['settings'] = {}

    config['inbounds'][0]['settings'].setdefault('clients', [])
    config['inbounds'][0]['settings']['decryption'] = 'none'

    config['inbounds'][0]['settings']['clients'].append({
        "id": uuid_str,
        "email": email
    })

    with open(CONFIG_PATH, 'w') as f:
        json.dump(config, f, indent=2)

    subprocess.run(['systemctl', 'restart', 'xray'])
