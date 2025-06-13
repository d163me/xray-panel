import { useState } from "react";

export default function InviteGenerator() {
  const [invite, setInvite] = useState(null);
  const [role, setRole] = useState("user");

  const generate = () => {
    fetch("/api/invite/create", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        max_uses: 5,
        days_valid: 7,
        role,
      }),
    })
      .then((res) => res.json())
      .then(setInvite);
  };

  return (
    <div className="mt-4">
      <h3 className="text-lg font-semibold">Создать инвайт</h3>
      <div className="flex gap-2 mt-2">
        <select
          className="p-2 border rounded"
          value={role}
          onChange={(e) => setRole(e.target.value)}
        >
          <option value="user">User</option>
          <option value="vip">VIP</option>
          <option value="admin">Admin</option>
        </select>
        <button className="bg-blue-600 text-white px-4 py-2 rounded" onClick={generate}>
          Сгенерировать
        </button>
      </div>
      {invite && (
        <p className="mt-2 text-sm">
          <strong>{invite.role}</strong> инвайт: <code>{invite.code}</code>
        </p>
      )}
    </div>
  );
}
