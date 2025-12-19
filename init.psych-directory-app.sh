#!/usr/bin/env bash
# init.psych-directory-app.sh
# One-shot scaffold for psych-directory-app. Run from inside the repo root directory.
# Creates a Next.js + Tailwind frontend and a Fastify backend with Mongo + Redis + (placeholder) Postgres, plus Docker Compose.
# Overwrites files if they exist. Requires: bash, sed, cat.

set -euo pipefail

APP_ROOT="."  # current dir

################################
# Root: workspace + dotfiles   #
################################
cat > package.json <<'EOF'
{
  "name": "psych-directory-app",
  "private": true,
  "workspaces": ["frontend", "backend"],
  "scripts": {
    "dev": "npm run -w backend dev & npm run -w frontend dev",
    "build": "npm -w backend run build && npm -w frontend run build",
    "start": "npm -w backend start & npm -w frontend start",
    "lint": "npm -w backend run lint && npm -w frontend run lint",
    "format": "prettier -w ."
  },
  "devDependencies": {
    "prettier": "^3.3.3"
  }
}
EOF

cat > .gitignore <<'EOF'
# Node
node_modules
npm-debug.log*
yarn-*.log*
pnpm-lock.yaml
package-lock.json

# Env
.env
backend/.env
frontend/.env.local

# Next.js
.next
out

# Logs
logs
*.log
*.gz

# OS
.DS_Store

# Docker
docker-data/
EOF

cat > .prettierrc <<'EOF'
{
  "singleQuote": true,
  "semi": true,
  "printWidth": 100,
  "trailingComma": "none"
}
EOF

cat > README.md <<'EOF'
# Psych Directory App

Monorepo: Next.js frontend + Fastify backend. Local DBs via Docker Compose.

## Quick Start
```sh
npm i
cp backend/.env.sample backend/.env
docker compose up -d
npm run dev
```

- Frontend: http://localhost:3000
- Backend:  http://localhost:4000 (OpenAPI UI: /documentation)
EOF

#########################################
# Docker Compose (local infra optional) #
#########################################
mkdir -p docker-data/postgres docker-data/mongo
cat > docker-compose.yml <<'EOF'
version: "3.9"
services:
  postgres:
    image: postgres:16
    container_name: psych_pg
    environment:
      POSTGRES_USER: psych
      POSTGRES_PASSWORD: psychpass
      POSTGRES_DB: psychdb
    ports: ["5432:5432"]
    volumes:
      - ./docker-data/postgres:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U psych"]
      interval: 5s
      timeout: 3s
      retries: 20

  mongo:
    image: mongo:7
    container_name: psych_mongo
    ports: ["27017:27017"]
    volumes:
      - ./docker-data/mongo:/data/db
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
      interval: 5s
      timeout: 5s
      retries: 20

  redis:
    image: redis:7
    container_name: psych_redis
    ports: ["6379:6379"]
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 20
EOF

#################
# Frontend app  #
#################
mkdir -p frontend/pages frontend/components frontend/styles frontend/public frontend/utils
cat > frontend/package.json <<'EOF'
{
  "name": "frontend",
  "private": true,
  "scripts": {
    "dev": "next dev -p 3000",
    "build": "next build",
    "start": "next start -p 3000",
    "lint": "next lint",
    "postinstall": "tailwindcss -v >/dev/null 2>&1 || true"
  },
  "dependencies": {
    "next": "14.2.5",
    "react": "18.3.1",
    "react-dom": "18.3.1"
  },
  "devDependencies": {
    "autoprefixer": "^10.4.20",
    "eslint": "^8.57.0",
    "eslint-config-next": "14.2.5",
    "postcss": "^8.4.41",
    "tailwindcss": "^3.4.10"
  }
}
EOF

cat > frontend/jsconfig.json <<'EOF'
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["*"]
    }
  }
}
EOF

cat > frontend/next.config.js <<'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = { reactStrictMode: true };
module.exports = nextConfig;
EOF

cat > frontend/postcss.config.js <<'EOF'
module.exports = { plugins: { tailwindcss: {}, autoprefixer: {} } };
EOF

cat > frontend/tailwind.config.js <<'EOF'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./pages/**/*.{js,jsx}", "./components/**/*.{js,jsx}"],
  theme: { extend: {} },
  plugins: []
};
EOF

cat > frontend/styles/globals.css <<'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

:root { color-scheme: light dark; }
body { @apply bg-white text-gray-900 dark:bg-gray-950 dark:text-gray-100; }
EOF

cat > frontend/public/manifest.json <<'EOF'
{
  "name": "Psych Directory",
  "short_name": "PsychDir",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#111827",
  "icons": [
    { "src": "/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icon-512.png", "sizes": "512x512", "type": "image/png" }
  ]
}
EOF

: > frontend/public/icon-192.png
: > frontend/public/icon-512.png

cat > frontend/components/Navbar.js <<'EOF'
import Link from "next/link";

export default function Navbar() {
  return (
    <header className="w-full border-b border-gray-200 dark:border-gray-800">
      <nav className="max-w-6xl mx-auto flex items-center justify-between p-4">
        <Link href="/" className="text-xl font-semibold">Psych Directory</Link>
        <div className="flex items-center gap-4">
          <Link href="/providers" className="hover:underline">Providers</Link>
          <Link href="/about" className="hover:underline">About</Link>
        </div>
      </nav>
    </header>
  );
}
EOF

cat > frontend/utils/api.js <<'EOF'
const API_BASE = process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000";
export async function fetchProviders({ q = "", page = 1, limit = 10 } = {}) {
  const params = new URLSearchParams({ q, page: String(page), limit: String(limit) });
  const res = await fetch(`${API_BASE}/v1/providers?` + params.toString(), { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to fetch providers");
  return res.json();
}
EOF

cat > frontend/pages/_app.js <<'EOF'
import "@/styles/globals.css";
import Head from "next/head";

export default function App({ Component, pageProps }) {
  return (
    <>
      <Head>
        <meta name="theme-color" content="#111827" />
        <link rel="manifest" href="/manifest.json" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
      </Head>
      <Component {...pageProps} />
    </>
  );
}
EOF

cat > frontend/pages/index.js <<'EOF'
import Navbar from "@/components/Navbar";
import Link from "next/link";

export default function Home() {
  return (
    <>
      <Navbar />
      <main className="max-w-6xl mx-auto p-6">
        <h1 className="text-3xl font-bold mb-4">Find a Therapist</h1>
        <p className="mb-6 text-gray-600 dark:text-gray-300">
          Search licensed therapists by specialty, insurance, and availability.
        </p>
        <Link href="/providers" className="inline-block rounded-lg bg-gray-900 text-white dark:bg-white dark:text-gray-900 px-4 py-2">
          Browse Providers
        </Link>
      </main>
    </>
  );
}
EOF

cat > frontend/pages/about.js <<'EOF'
import Navbar from "@/components/Navbar";

export default function About() {
  return (
    <>
      <Navbar />
      <main className="max-w-6xl mx-auto p-6">
        <h1 className="text-2xl font-semibold mb-4">About</h1>
        <p className="text-gray-700 dark:text-gray-300">
          An open, modern directory connecting people with mental health professionals.
        </p>
      </main>
    </>
  );
}
EOF

cat > frontend/pages/providers.js <<'EOF'
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
EOF

################################
# Backend (Fastify API server) #
################################
mkdir -p backend/src/{routes,controllers,models,plugins,utils}
cat > backend/package.json <<'EOF'
{
  "name": "backend",
  "private": true,
  "type": "module",
  "main": "src/index.js",
  "scripts": {
    "dev": "NODE_ENV=development nodemon --watch src --ext js --exec node src/index.js",
    "start": "NODE_ENV=production node src/index.js",
    "lint": "echo \"(add eslint if needed)\"",
    "build": "echo \"No build step for pure Node.js\""
  },
  "dependencies": {
    "@fastify/cors": "^10.0.1",
    "@fastify/rate-limit": "^10.2.1",
    "@fastify/sensible": "^6.0.1",
    "@fastify/swagger": "^9.4.1",
    "@fastify/swagger-ui": "^3.0.0",
    "dotenv": "^16.4.5",
    "fastify": "^4.28.1",
    "ioredis": "^5.4.1",
    "mongodb": "^6.9.0",
    "pg": "^8.12.0",
    "pino": "^9.5.0",
    "pino-pretty": "^11.2.2",
    "zod": "^3.23.8"
  },
  "devDependencies": {
    "nodemon": "^3.1.4"
  }
}
EOF

cat > backend/.env.sample <<'EOF'
PORT=4000
LOG_LEVEL=info

PG_HOST=localhost
PG_PORT=5432
PG_DATABASE=psychdb
PG_USER=psych
PG_PASSWORD=psychpass

MONGO_URI=mongodb://localhost:27017/psych
REDIS_URL=redis://localhost:6379

CORS_ORIGIN=http://localhost:3000
EOF

cat > backend/src/index.js <<'EOF'
import 'dotenv/config';
import Fastify from 'fastify';
import sensible from '@fastify/sensible';
import cors from '@fastify/cors';
import rateLimit from '@fastify/rate-limit';
import swagger from '@fastify/swagger';
import swaggerUi from '@fastify/swagger-ui';

import { postgresPlugin } from './plugins/postgres.js';
import { mongoPlugin } from './plugins/mongo.js';
import { redisPlugin } from './plugins/redis.js';
import { registerRoutes } from './routes/index.js';

const app = Fastify({
  logger: { transport: { target: 'pino-pretty' }, level: process.env.LOG_LEVEL || 'info' }
});

// Plugins
await app.register(sensible);
await app.register(cors, { origin: process.env.CORS_ORIGIN?.split(',') || true });
await app.register(rateLimit, { max: 100, timeWindow: '1 minute' });
await app.register(swagger, { openapi: { info: { title: 'Psych API', version: '1.0.0' } } });
await app.register(swaggerUi, { routePrefix: '/documentation' });

await app.register(postgresPlugin);
await app.register(mongoPlugin);
await app.register(redisPlugin);

// Routes
await registerRoutes(app);

// Redirect for convenience
app.get('/docs', async (_req, reply) => reply.redirect('/documentation'));

// Start
const port = Number(process.env.PORT || 4000);
try {
  await app.listen({ port, host: '0.0.0.0' });
  app.log.info(`API listening on :${port}`);
} catch (err) {
  app.log.error(err);
  process.exit(1);
}
EOF

cat > backend/src/plugins/postgres.js <<'EOF'
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
EOF

cat > backend/src/plugins/mongo.js <<'EOF'
import { MongoClient } from 'mongodb';

export async function mongoPlugin(fastify) {
  const uri = process.env.MONGO_URI || 'mongodb://localhost:27017/psych';
  const client = new MongoClient(uri);
  await client.connect();
  const db = client.db();

  fastify.decorate('mongo', { client, db });
  fastify.addHook('onClose', async () => { await client.close(); });
}
EOF

cat > backend/src/plugins/redis.js <<'EOF'
import Redis from 'ioredis';

export async function redisPlugin(fastify) {
  const redis = new Redis(process.env.REDIS_URL || 'redis://localhost:6379');
  fastify.decorate('redis', redis);
  fastify.addHook('onClose', async () => { await redis.quit(); });
}
EOF

cat > backend/src/routes/index.js <<'EOF'
import { providersRoutes } from './providers.js';

export async function registerRoutes(app) {
  app.get('/healthz', async () => ({ ok: true }));
  app.register(providersRoutes, { prefix: '/v1/providers' });
}
EOF

cat > backend/src/routes/providers.js <<'EOF'
import { listProviders, getProviderById } from '../controllers/providers.js';

export async function providersRoutes(app) {
  app.get('/', async (req) => {
    const { q = '', page = '1', limit = '10' } = req.query;
    const p = Number(page) || 1;
    const l = Math.min(50, Number(limit) || 10);
    return listProviders({ app, q: String(q), page: p, limit: l });
  });

  app.get('/:id', async (req, reply) => {
    const { id } = req.params;
    const found = await getProviderById({ app, id });
    if (!found) return reply.notFound('Provider not found');
    return found;
  });
}
EOF

cat > backend/src/controllers/providers.js <<'EOF'
import { z } from 'zod';

const ProviderSchema = z.object({
  id: z.string(),
  name: z.string(),
  specialties: z.array(z.string()).optional(),
  city: z.string().optional(),
  state: z.string().optional()
});

export async function listProviders({ app, q, page, limit }) {
  const cacheKey = `providers:q=${q}:p=${page}:l=${limit}`;
  const cached = await app.redis.get(cacheKey);
  if (cached) return JSON.parse(cached);

  const filter = q
    ? { $or: [{ name: new RegExp(q, 'i') }, { specialties: { $in: [new RegExp(q, 'i')] } }] }
    : {};
  const col = app.mongo.db.collection('providers');

  const total = await col.countDocuments(filter);
  const items = await col
    .find(filter, { projection: { _id: 0 } })
    .skip((page - 1) * limit)
    .limit(limit)
    .toArray();

  const safeItems = items.map((x) => ProviderSchema.parse(x));
  const payload = { items: safeItems, total, page, limit };

  await app.redis.set(cacheKey, JSON.stringify(payload), 'EX', 30);
  return payload;
}

export async function getProviderById({ app, id }) {
  const col = app.mongo.db.collection('providers');
  const doc = await col.findOne({ id }, { projection: { _id: 0 } });
  return doc ? ProviderSchema.parse(doc) : null;
}
EOF

cat > backend/src/models/provider.sql <<'EOF'
-- Example SQL (for future reporting/joins)
CREATE TABLE IF NOT EXISTS providers_index (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  city TEXT,
  state TEXT,
  specialties TEXT[]
);
EOF

cat > backend/src/utils/seed.js <<'EOF'
/**
 * Quick local seed for Mongo providers collection.
 * Run: node src/utils/seed.js
 */
import 'dotenv/config';
import { MongoClient } from 'mongodb';
import { randomUUID } from 'crypto';

const uri = process.env.MONGO_URI || 'mongodb://localhost:27017/psych';
const client = new MongoClient(uri);

const specialties = ['CBT', 'Anxiety', 'Depression', 'Trauma', 'Couples', 'ADHD'];

function sample(n, arr) {
  return Array.from({ length: n }, () => arr[Math.floor(Math.random() * arr.length)]);
}

async function main() {
  await client.connect();
  const db = client.db();
  const col = db.collection('providers');

  const baseCities = [
    { city: 'Austin', state: 'TX' },
    { city: 'Chicago', state: 'IL' },
    { city: 'New York', state: 'NY' },
    { city: 'Seattle', state: 'WA' }
  ];

  const docs = Array.from({ length: 40 }).map((_, i) => {
    const loc = baseCities[i % baseCities.length];
    return {
      id: randomUUID(),
      name: `Therapist ${i + 1}`,
      specialties: [...new Set(sample(2 + (i % 3), specialties))],
      ...loc
    };
  });

  await col.deleteMany({});
  await col.insertMany(docs);
  console.log(`Seeded ${docs.length} providers`);
  await client.close();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
EOF

####################################
# Final notes + tree verification  #
####################################
echo
echo "✔ Scaffold created in $(pwd)"
echo
echo "Next steps:"
echo "  1) npm i"
echo "  2) cp backend/.env.sample backend/.env"
echo "  3) docker compose up -d"
echo "  4) npm run dev"
echo "     Frontend: http://localhost:3000  Backend: http://localhost:4000/documentation"
echo

echo "Optional:"
echo "  - Seed mock data: node backend/src/utils/seed.js"
echo

# Print tree or fallback to find
if command -v tree >/dev/null 2>&1; then
  tree -a -I 'node_modules|.next|docker-data'
else
  echo "(Install 'tree' for a nicer view) Fallback listing:"
  find . -maxdepth 3 -not -path '*/node_modules/*' -not -path '*/.next/*' -not -path '*/docker-data/*' -print | sed 's|^\./||'
fi
