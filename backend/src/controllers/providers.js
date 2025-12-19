// Postgres-backed providers controller
import { z } from 'zod';

const ProviderSchema = z.object({
  id: z.string(),
  name: z.string(),
  specialties: z.array(z.string()).optional(),
  city: z.string().optional(),
  state: z.string().optional()
});

export async function listProviders({ app, q, page, limit }) {
  // Temporarily skip Redis due to networking issue
  // const cacheKey = `providers:pg:q=${q}:p=${page}:l=${limit}`;
  // const cached = await app.redis.get(cacheKey);
  // if (cached) return JSON.parse(cached);

  const offset = (page - 1) * limit;
  const params = [];
  let where = '';
  if (q) {
    params.push(`%${q}%`, `%${q}%`);
    where = `WHERE name ILIKE $1 OR EXISTS (
      SELECT 1 FROM unnest(specialties) s WHERE s ILIKE $2
    )`;
  }

  const { rows: countRows } = await app.pg.pool.query(
    `SELECT COUNT(*)::int AS total FROM providers_index ${where}`, params
  );
  const total = countRows[0].total;

  const { rows } = await app.pg.pool.query(
    `SELECT id, name, city, state, specialties
     FROM providers_index
     ${where}
     ORDER BY name ASC
     LIMIT $${where ? params.length + 1 : 1}
     OFFSET $${where ? params.length + 2 : 2}`,
    where ? [...params, limit, offset] : [limit, offset]
  );

  const items = rows.map(r =>
    ProviderSchema.parse({
      ...r,
      specialties: Array.isArray(r.specialties) ? r.specialties : []
    })
  );
  const payload = { items, total, page, limit };
  // await app.redis.set(cacheKey, JSON.stringify(payload), 'EX', 30);
  return payload;
}

export async function getProviderById({ app, id }) {
  const { rows } = await app.pg.pool.query(
    `SELECT id, name, city, state, specialties
     FROM providers_index WHERE id = $1`,
    [id]
  );
  if (!rows[0]) return null;
  return ProviderSchema.parse({
    ...rows[0],
    specialties: Array.isArray(rows[0].specialties) ? rows[0].specialties : []
  });
}