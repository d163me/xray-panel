import Dashboard from "./pages/Dashboard";
import LoginPage from "./pages/LoginPage";

function App() {
  const uuid = localStorage.getItem("uuid");

  return uuid ? <Dashboard /> : <LoginPage />;
}

export default App;
