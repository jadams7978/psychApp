import pkg from 'pg';
const { Pool } = pkg;

export async function postgresPlugin(fastify) {
  const pool = new Pool({
    host: process.env.PG_HOST || 'localhost',
    port: Number(process.env.PG_PORT || 5432),
    database: process.env.PG_DATABASE || 'psychdb',
    user: process.env.PG_USER || 'psych',
    password: process.env.PG_PASSWORD || 'psychpass',
    max: 10
  });

  fastify.decorate('pg', { pool });
  fastify.addHook('onClose', async () => { await pool.end(); });
}
