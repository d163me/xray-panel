import { useState } from "react";

export default function LoginPage() {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");

  const login = async (e) => {
    e.preventDefault();

    const res = await fetch("/api/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username, password }),
    });

    const result = await res.json();

    if (res.ok && result.uuid) {
      localStorage.setItem("uuid", result.uuid);
      window.location.reload();
    } else {
      alert("Ошибка входа: " + (result.error || "unknown"));
    }
  };

  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-100">
      <form
        onSubmit={login}
        className="bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4 w-96"
      >
        <h2 className="text-2xl mb-4 font-bold text-center">Вход</h2>

        <label className="block text-gray-700 text-sm font-bold mb-2">
          Логин
        </label>
        <input
          className="shadow appearance-none border rounded w-full py-2 px-3 mb-4 text-gray-700"
          type="text"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
          required
        />

        <label className="block text-gray-700 text-sm font-bold mb-2">
          Пароль
        </label>
        <input
          className="shadow appearance-none border rounded w-full py-2 px-3 mb-6 text-gray-700"
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
        />

        <button
          type="submit"
          className="bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded w-full"
        >
          Войти
        </button>
      </form>
    </div>
  );
}
