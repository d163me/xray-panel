import { useState } from "react";

export default function InviteGenerator() {
  const [invite, setInvite] = useState(null);

  const generate = () => {
    fetch("/api/invite/generate", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ max_uses: 3, days_valid: 7 }),
    })
      .then((res) => res.json())
      .then(setInvite);
  };

  return (
    <div className="mt-4">
      <h3 className="text-lg font-semibold">Создать инвайт</h3>
      <button className="mt-2 p-2 bg-blue-600 text-white rounded" onClick={generate}>
        Сгенерировать
      </button>
      {invite && (
        <p className="mt-2 text-sm">Инвайт: <code>{invite.code}</code></p>
      )}
    </div>
  );
}
