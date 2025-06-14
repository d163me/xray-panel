import { useEffect } from "react";

// простая функция v4 UUID
function uuidv4() {
  return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c =>
    (c ^ (crypto.getRandomValues(new Uint8Array(1))[0] & (15 >> (c/4)))).toString(16)
  );
}

export default function LoginPage() {
  useEffect(() => {
    // глобальный хендлер
    window.TelegramLoginWidget = {
      dataOnauth: async function (user) {
        console.log("Telegram user:", user);
        const invite = prompt("Введите инвайт-код:");
        console.log("Invite code:", invite);

        const body = { ...user, invite, client_uuid: uuidv4() };

        try {
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
            alert("Ошибка авторизации: " + (result.error || "unknown"));
          }
        } catch (err) {
          console.error(err);
          alert("Ошибка сети или сервера.");
        }
      }
    };

    // вставка виджета Telegram
    const script = document.createElement("script");
    script.src = "https://telegram.org/js/telegram-widget.js?22";
    script.setAttribute("data-telegram-login", "hydrich_bot"); // без @
    script.setAttribute("data-size", "large");
    script.setAttribute("data-userpic", "false");
    script.setAttribute("data-request-access", "write");
    script.setAttribute("data-onauth", "TelegramLoginWidget.dataOnauth(user)");
    script.async = true;

    document.getElementById("telegram-login-container").appendChild(script);
  }, []);

  return (
    <div className="flex items-center justify-center min-h-screen">
      <div id="telegram-login-container"></div>
    </div>
  );
}
