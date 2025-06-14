import { useEffect } from "react";

// простая функция v4 UUID вместо crypto.randomUUID()
function uuidv4() {
  return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c =>
    (c ^ (crypto.getRandomValues(new Uint8Array(1))[0] & (15 >> (c/4)))).toString(16)
  );
}

export default function LoginPage() {
  useEffect(() => {
    window.TelegramLoginWidget = {
      dataOnauth: async function (user) {
        console.log("Telegram user:", user);
        const invite = prompt("Введите инвайт-код:");
        console.log("Invite code:", invite);

        const body = { ...user, invite, client_uuid: uuidv4() };
        const res = await fetch("/api/auth/telegram", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(body),
        });

        const result = await res.json();
        if (res.ok && result.uuid) {
          localStorage.setItem("uuid", result.uuid);
          window.location.reload();
        } else {
          alert("Ошибка авторизации: " + (result.error||"unknown"));
        }
      }
    };
  }, []);

  return (
    <div className="flex items-center justify-center min-h-screen">
      <script
        async
        src="https://telegram.org/js/telegram-widget.js?22"
        data-telegram-login="hydrich_bot"       {/* замените на своего бота без @ */}
        data-size="large"
        data-userpic="false"
        data-request-access="write"
        data-onauth="TelegramLoginWidget.dataOnauth(user)"
      />
    </div>
  );
}
