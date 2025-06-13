import { useEffect, useState } from "react";

export default function InviteList() {
  const [invites, setInvites] = useState([]);

  useEffect(() => {
    fetch("/api/invite/list")
      .then((res) => res.json())
      .then(setInvites);
  }, []);

  return (
    <div className="mt-4">
      <h3 className="text-lg font-semibold">Список инвайтов</h3>
      <ul className="text-sm mt-2">
        {invites.map((i) => (
          <li key={i.code} className="mb-1">
            <code>{i.code}</code> — использовано {i.uses}/{i.max_uses}
            {i.expires_at && ` — до ${new Date(i.expires_at).toLocaleString()}`}
          </li>
        ))}
      </ul>
    </div>
  );
}
