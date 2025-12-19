import 'dotenv/config';
import { randomUUID } from 'crypto';

import pkg from 'pg';


const { Pool } = pkg;
const pool = new Pool({
  host: process.env.PG_HOST || 'localhost',
  port: Number(process.env.PG_PORT || 5432),
  database: process.env.PG_DATABASE || 'psychdb',
  user: process.env.PG_USER || 'psych',
  password: process.env.PG_PASSWORD || 'psychpass'
});

const specialties = ['CBT','Anxiety','Depression','Trauma','Couples','ADHD'];
const cities = [
  { city: 'Austin', state: 'TX' },
  { city: 'Chicago', state: 'IL' },
  { city: 'New York', state: 'NY' },
  { city: 'Seattle', state: 'WA' }
];

function pick(n, arr){ return Array.from({length:n},()=>arr[Math.floor(Math.random()*arr.length)]); }

async function main() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query('CREATE EXTENSION IF NOT EXISTS pg_trgm;');
    await client.query(`
      CREATE TABLE IF NOT EXISTS providers_index (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        city TEXT,
        state TEXT,
        specialties TEXT[]
      );
    `);
    await client.query('TRUNCATE TABLE providers_index;');

    const values = [];
    for (let i = 0; i < 40; i++) {
      const { city, state } = cities[i % cities.length];
      const specs = Array.from(new Set(pick(2 + (i % 3), specialties)));
      values.push([randomUUID(), `Therapist ${i + 1}`, city, state, specs]);
    }

    await client.query(
      `INSERT INTO providers_index (id, name, city, state, specialties)
       SELECT * FROM UNNEST ($1::text[], $2::text[], $3::text[], $4::text[], $5::text[][])`,
      [
        values.map(v => v[0]),
        values.map(v => v[1]),
        values.map(v => v[2]),
        values.map(v => v[3]),
        values.map(v => v[4])
      ]
    );
    await client.query('COMMIT');
    console.log(`✅ Seeded ${values.length} providers into Postgres`);
  } catch (e) {
    await client.query('ROLLBACK');
    console.error(e);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

main();