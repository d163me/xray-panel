import { useEffect, useState } from "react";

export default function ServerSelector({ selected, onChange }) {
  const [servers, setServers] = useState([]);

  useEffect(() => {
    fetch("/api/servers")
      .then((res) => res.json())
      .then((d) => setServers(d));
  }, []);

  return (
    <select
      className="w-full mt-2 p-2 border rounded"
      value={selected}
      onChange={(e) => onChange(Number(e.target.value))}
    >
      {servers.map((s) => (
        <option key={s.id} value={s.id}>
          {s.name} ({s.ip})
        </option>
      ))}
    </select>
  );
}
