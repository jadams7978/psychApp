import { useEffect, useState } from "react";
import Navbar from "@/components/Navbar";
import { fetchProviders } from "@/utils/api";

export default function Providers() {
  const [data, setData] = useState({ items: [], total: 0, page: 1, limit: 10 });
  const [q, setQ] = useState("");
  const [loading, setLoading] = useState(false);

  async function load(page = 1) {
    setLoading(true);
    try {
      const res = await fetchProviders({ q, page, limit: 10 });
      setData(res);
    } catch (e) {
      alert(e.message); // minimal surfacing for scaffold
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(1); }, []);

  return (
    <>
      <Navbar />
      <main className="max-w-6xl mx-auto p-6">
        <h1 className="text-2xl font-semibold mb-4">Providers</h1>

        <div className="flex gap-2 mb-4">
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Search by name or specialty…"
            className="flex-1 rounded-md border border-gray-300 dark:border-gray-700 bg-transparent px-3 py-2"
          />
          <button
            onClick={() => load(1)}
            className="rounded-md px-4 py-2 border border-gray-300 dark:border-gray-700"
            disabled={loading}
          >
            {loading ? "Searching…" : "Search"}
          </button>
        </div>

        <ul className="divide-y divide-gray-200 dark:divide-gray-800">
          {data.items.map((p) => (
            <li key={p.id} className="py-3">
              <div className="font-medium">{p.name}</div>
              <div className="text-sm text-gray-600 dark:text-gray-400">
                {p.specialties?.join(", ") || "General"}
              </div>
              <div className="text-sm text-gray-600 dark:text-gray-400">{p.city}, {p.state}</div>
            </li>
          ))}
        </ul>

        <div className="flex items-center gap-2 mt-4">
          <button
            onClick={() => load(Math.max(1, data.page - 1))}
            className="px-3 py-1 border rounded"
            disabled={data.page <= 1 || loading}
          >Prev</button>
          <span className="text-sm">Page {data.page}</span>
          <button
            onClick={() => load(data.page + 1)}
            className="px-3 py-1 border rounded"
            disabled={(data.page * data.limit) >= data.total || loading}
          >Next</button>
        </div>
      </main>
    </>
  );
}
