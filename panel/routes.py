from flask import Blueprint, render_template, request
from panel.utils import generate_uuid, generate_vless_link

bp = Blueprint('main', __name__)

clients = []

@bp.route('/', methods=['GET', 'POST'])
def index():
    link = None
    if request.method == 'POST':
        username = request.form['username']
        uuid = generate_uuid()
        link = generate_vless_link(uuid, username)
        clients.append({'uuid': uuid, 'username': username, 'link': link})
    return render_template('index.html', clients=clients)
