#!/bin/bash

# Путь установки
INSTALL_DIR=/opt/xray-proxy-panel

# Удаление старой версии
if [ -d "$INSTALL_DIR" ]; then
    echo "Удаляю старую версию..."
    pkill -f flask
    pkill -f vite
    rm -rf "$INSTALL_DIR"
fi

# Установка зависимостей
apt update && apt install -y python3 python3-venv git curl nodejs npm

# Создание структуры
mkdir -p "$INSTALL_DIR"

# Backend setup
cd "$INSTALL_DIR"
python3 -m venv venv
source venv/bin/activate
pip install flask flask-cors

cat <<EOF > backend.py
from flask import Flask, request, jsonify
from flask_cors import CORS
app = Flask(__name__)
CORS(app)

@app.route('/create_proxy', methods=['POST'])
def create_proxy():
    proxy_name = request.json.get('name')
    # Здесь логика создания конфига Xray (упрощенно)
    proxy_link = f"vmess://{proxy_name}@example.com:443"
    return jsonify({"proxy": proxy_link})

app.run(host='0.0.0.0', port=5000)
EOF

nohup flask run &

# Frontend setup
npm create vite@latest frontend -- --template react
cd frontend
npm install axios

cat <<EOF > src/App.jsx
import { useState } from 'react'
import axios from 'axios'

function App() {
  const [name, setName] = useState('')
  const [proxy, setProxy] = useState('')

  const createProxy = async () => {
    const response = await axios.post('http://localhost:5000/create_proxy', { name })
    setProxy(response.data.proxy)
  }

  return (
    <div>
      <input type="text" value={name} onChange={(e) => setName(e.target.value)} />
      <button onClick={createProxy}>Создать прокси</button>
      {proxy && <p>Ваш прокси: {proxy}</p>}
    </div>
  )
}

export default App
EOF

nohup npm run dev -- --host &

# Установка Xray (упрощенно)
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)"

clear
echo "✅ Панель успешно установлена!"
