import { useEffect } from "react";

declare global {
  interface Window {
    TelegramLoginWidget: any;
  }
}

export const TelegramLoginButton = () => {
  useEffect(() => {
    const script = document.createElement("script");
    script.src = "https://telegram.org/js/telegram-widget.js?7";
    script.setAttribute("data-telegram-login", "hydrich_bot"); // замените на @имя_бота без @
    script.setAttribute("data-size", "large");
    script.setAttribute("data-userpic", "false");
    script.setAttribute("data-onauth", "handleTelegramAuth(user)");
    script.setAttribute("data-request-access", "write");
    script.async = true;

    document.getElementById("telegram-button-container")?.appendChild(script);

    // Глобальная функция вызывается Telegram виджетом
    window.handleTelegramAuth = async (user: any) => {
      try {
        const invite = new URLSearchParams(window.location.search).get("invite");

        const res = await fetch("/api/auth/telegram", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ ...user, invite }),
        });

        const result = await res.json();
        if (res.ok) {
          localStorage.setItem("uuid", result.uuid);
          window.location.href = "/dashboard"; // перенаправление после входа
        } else {
          alert(result.error || "Ошибка авторизации");
        }
      } catch (err) {
        alert("Сервер недоступен");
        console.error(err);
      }
    };
  }, []);

  return <div id="telegram-button-container"></div>;
};
