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
