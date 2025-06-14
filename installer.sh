#!/usr/bin/env bash

# Установка панели Xray + продакшн сборка фронтенда в одном скрипте
INSTALL_DIR=/opt/xray-proxy-panel

# 1. Удаляем старую версию
if [ -d "$INSTALL_DIR" ]; then
  echo "🔄 Удаляю старую версию..."
  pkill -f backend.py || true
  rm -rf "$INSTALL_DIR"
fi

# 2. Устанавливаем системные пакеты
echo "📦 Устанавливаю зависимости..."
apt update && apt install -y python3 python3-venv git curl nodejs npm

# 3. Создаём структуру
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# 4. Настраиваем backend (Flask)
echo "⚙️ Настраиваю backend..."
python3 -m venv venv
source venv/bin/activate
pip install --no-cache-dir flask flask-cors

# Создаём backend.py
cat > backend.py << 'EOF'
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS

app = Flask(__name__, static_folder='static', static_url_path='')
CORS(app)

@app.route('/api/create_proxy', methods=['POST'])
def create_proxy():
    name = request.json.get('name') or 'default'
    # Здесь можно добавить логику реального конфига Xray
    proxy_link = f"vmess://{name}@example.com:443"
    return jsonify({'proxy': proxy_link})

@app.route('/')
def index():
    return send_from_directory(app.static_folder, 'index.html')

@app.errorhandler(404)
def not_found(e):
    return send_from_directory(app.static_folder, 'index.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
EOF

# 5. Сборка и настройка frontend (Vite + React)
echo "⚛️ Настраиваю frontend..."
npm create vite@latest frontend -- --template react --force
cd frontend
npm install axios

# Формируем App.jsx
cat > src/App.jsx << 'EOF'
import { useState } from 'react'
import axios from 'axios'

function App() {
  const [name, setName] = useState('')
  const [proxy, setProxy] = useState('')

  const createProxy = async () => {
    try {
      const res = await axios.post('/api/create_proxy', { name })
      setProxy(res.data.proxy)
    } catch (e) {
      console.error(e)
      alert('Ошибка при создании прокси')
    }
  }

  return (
    <div style={{ padding: '2rem', fontFamily: 'sans-serif' }}>
      <h1>Создать прокси</h1>
      <input
        type="text"
        placeholder="Имя прокси"
        value={name}
        onChange={(e) => setName(e.target.value)}
        style={{ marginRight: '0.5rem', padding: '0.5rem' }}
      />
      <button onClick={createProxy} style={{ padding: '0.5rem 1rem' }}>
        Создать
      </button>
      {proxy && (
        <p style={{ marginTop: '1rem' }}>
          Прокси: <a href={proxy}>{proxy}</a>
        </p>
      )}
    </div>
  )
}

export default App
EOF

# Vite config остаётся базовым
cat > vite.config.js << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  build: { outDir: 'dist' }
})
EOF

# Строим фронтенд
echo "📦 Сборка фронтенда..."
npm run build

# Копируем в статику backend
echo "📂 Копирую сборку во backend/static..."
mkdir -p ../static
cp -r dist/* ../static/

# 6. Запуск backend с раздачей статичных файлов
echo "🐍 Запускаю Flask на порту 80..."
cd ..
nohup bash -c "source venv/bin/activate && python3 backend.py" &> backend.log &

# 7. Установка Xray
echo "🚀 Устанавливаю Xray..."
bash -c "$(curl -fsSL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)"

clear
echo "✅ Установка завершена!"
echo "Перейдите в браузере на: http://$(curl -s ifconfig.me)"
