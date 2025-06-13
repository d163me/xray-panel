import { useEffect, useState } from "react";
import ServerSelector from "../components/ServerSelector";
import TrafficChart from "../components/TrafficChart";

export default function Dashboard() {
  const [uuid, setUuid] = useState(localStorage.getItem("uuid"));
  const [selectedServer, setSelectedServer] = useState(null);
  const [config, setConfig] = useState("");

  useEffect(() => {
    if (!uuid || !selectedServer) return;

    fetch("/api/proxy-config", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ uuid, server_id: selectedServer }),
    })
      .then((res) => res.json())
      .then((data) => setConfig(data.config));
  }, [uuid, selectedServer]);

  if (!uuid) return <div>Пожалуйста, войдите</div>;

  return (
    <div className="p-4">
      <h2 className="text-xl font-bold mb-2">Конфигурация прокси</h2>
      <ServerSelector selected={selectedServer} onChange={setSelectedServer} />
      {config && (
        <div className="mt-2">
          <p className="break-all text-sm">{config}</p>
          <button
            className="mt-2 bg-blue-500 text-white px-3 py-1 rounded"
            onClick={() => navigator.clipboard.writeText(config)}
          >
            Скопировать
          </button>
        </div>
      )}
      <TrafficChart uuid={uuid} />
    </div>
  );
}
