import { useEffect, useState } from "react";

const API_URL = import.meta.env.VITE_API_URL || "";

export default function App() {
  const [notices, setNotices] = useState([]);
  const [name, setName] = useState("");
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  const loadNotices = async () => {
    try {
      const res = await fetch(`${API_URL}/notices`);
      if (!res.ok) throw new Error(`Failed to load notices (${res.status})`);
      setNotices(await res.json());
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadNotices();
  }, []);

  const handleSubmit = async (event) => {
    event.preventDefault();
    setError("");
    try {
      const res = await fetch(`${API_URL}/notices`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name, message }),
      });
      if (!res.ok) throw new Error(`Failed to post notice (${res.status})`);
      setName("");
      setMessage("");
      await loadNotices();
    } catch (err) {
      setError(err.message);
    }
  };

  const handleDelete = async (id) => {
    setError("");
    try {
      const res = await fetch(`${API_URL}/notices/${id}`, { method: "DELETE" });
      if (!res.ok) throw new Error(`Failed to delete notice (${res.status})`);
      setNotices((prev) => prev.filter((n) => n.id !== id));
    } catch (err) {
      setError(err.message);
    }
  };

  return (
    <main className="page">
      <h1>Notice Board</h1>

      <form className="notice-form" onSubmit={handleSubmit}>
        <input
          placeholder="Your name"
          value={name}
          onChange={(e) => setName(e.target.value)}
          required
        />
        <textarea
          placeholder="Your message"
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          required
        />
        <button type="submit">Post Notice</button>
      </form>

      {error && <p className="error">{error}</p>}
      {loading && <p>Loading notices...</p>}

      <ul className="notice-list">
        {notices.map((notice) => (
          <li key={notice.id} className="notice-card">
            <div>
              <strong>{notice.name}</strong>
              <p>{notice.message}</p>
            </div>
            <button onClick={() => handleDelete(notice.id)}>Delete</button>
          </li>
        ))}
      </ul>
    </main>
  );
}
