import { providersRoutes } from './providers.js';

export async function registerRoutes(app) {
  app.get('/healthz', async () => ({ ok: true }));
  app.register(providersRoutes, { prefix: '/v1/providers' });
}
