const API_BASE = process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000";
export async function fetchProviders({ q = "", page = 1, limit = 10 } = {}) {
  const params = new URLSearchParams({ q, page: String(page), limit: String(limit) });
  const res = await fetch(`${API_BASE}/v1/providers?` + params.toString(), { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to fetch providers");
  return res.json();
}
