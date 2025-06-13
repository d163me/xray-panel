import InviteGenerator from "./InviteGenerator";
import InviteList from "./InviteList";

export default function AdminDashboard() {
  return (
    <div className="p-4">
      <h2 className="text-xl font-bold mb-4">Админ-панель</h2>
      <InviteGenerator />
      <InviteList />
    </div>
  );
}
