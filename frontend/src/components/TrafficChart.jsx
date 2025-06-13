import { useEffect, useState } from "react";
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer } from "recharts";

export default function TrafficChart({ uuid }) {
  const [data, setData] = useState([]);

  useEffect(() => {
    fetch(`/api/traffic/${uuid}`)
      .then((res) => res.json())
      .then((d) => setData(d));
  }, [uuid]);

  return (
    <div className="mt-4">
      <h3 className="text-lg font-semibold">Трафик</h3>
      <ResponsiveContainer width="100%" height={300}>
        <LineChart data={data}>
          <XAxis dataKey="timestamp" hide />
          <YAxis />
          <Tooltip />
          <Line type="monotone" dataKey="rx" stroke="#8884d8" />
          <Line type="monotone" dataKey="tx" stroke="#82ca9d" />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}
