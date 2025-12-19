import 'dotenv/config';
import cors from '@fastify/cors';
import rateLimit from '@fastify/rate-limit';
import sensible from '@fastify/sensible';
import swagger from '@fastify/swagger';
import swaggerUi from '@fastify/swagger-ui';
import Fastify from 'fastify';


import { postgresPlugin } from './plugins/postgres.js';
import { redisPlugin } from './plugins/redis.js';
import { registerRoutes } from './routes/index.js';

const usePretty = process.env.NODE_ENV !== 'production';
const app = Fastify({
  logger: usePretty ? { transport: { target: 'pino-pretty' }, level: process.env.LOG_LEVEL || 'info' }
                    : { level: process.env.LOG_LEVEL || 'info' }
});

// Plugins
await app.register(sensible);
await app.register(cors, { origin: process.env.CORS_ORIGIN?.split(',') || true });
await app.register(rateLimit, { max: 100, timeWindow: '1 minute' });
await app.register(swagger, { openapi: { info: { title: 'Psych API', version: '1.0.0' } } });
await app.register(swaggerUi, { routePrefix: '/documentation' });

await app.register(postgresPlugin);
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
