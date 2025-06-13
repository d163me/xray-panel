import { useEffect } from 'react';

const TelegramLogin = () => {
  useEffect(() => {
    // Проверяем, есть ли Telegram-скрипт
    const existingScript = document.getElementById('telegram-login-script');
    if (existingScript) return;

    const script = document.createElement('script');
    script.src = 'https://telegram.org/js/telegram-widget.js?22';
    script.setAttribute('data-telegram-login', 'hydrich_bot'); // 👉 замени на @username своего бота
    script.setAttribute('data-size', 'large');
    script.setAttribute('data-userpic', 'false');
    script.setAttribute('data-lang', 'ru');
    script.setAttribute('data-request-access', 'write');
    script.setAttribute('data-onauth', 'onTelegramAuth(user)');
    script.id = 'telegram-login-script';

    document.getElementById('telegram-button-container').appendChild(script);

    // Глобальная функция для получения данных Telegram
    window.onTelegramAuth = function (user) {
      fetch('/api/auth/telegram', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(user)
      })
        .then(res => {
          if (res.ok) {
            window.location.reload(); // авторизация успешна
          } else {
            alert('Ошибка авторизации через Telegram');
          }
        })
        .catch(err => {
          console.error('Ошибка запроса:', err);
        });
    };
  }, []);

  return (
    <div id="telegram-button-container" className="flex justify-center mt-6" />
  );
};

export default TelegramLogin;
