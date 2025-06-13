import { useEffect } from "react";

export default function LoginPage() {
  useEffect(() => {
    window.TelegramLoginWidget = {
      dataOnauth: async function (user) {
        const invite = prompt("Введите инвайт-код");
        const res = await fetch("/api/auth/telegram", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ ...user, invite }),
        });
        const result = await res.json();
        if (result.uuid) {
          localStorage.setItem("uuid", result.uuid);
          window.location.reload();
        } else {
          alert("Ошибка авторизации");
        }
      },
    };
    const script = document.createElement("script");
    script.src = "https://telegram.org/js/telegram-widget.js?7";
    script.setAttribute("data-telegram-login", "YOUR_BOT_USERNAME"); // замените на @your_bot
    script.setAttribute("data-size", "large");
    script.setAttribute("data-userpic", "false");
    script.setAttribute("data-request-access", "write");
    script.setAttribute("data-onauth", "TelegramLoginWidget.dataOnauth(user)");
    document.getElementById("telegram-login").appendChild(script);
  }, []);

  return (
    <div className="flex items-center justify-center min-h-screen">
      <div id="telegram-login" />
    </div>
  );
}
