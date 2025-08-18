import { rest } from 'msw';
import { fixtures } from './fixtures';

const simulateLatency = () => {
  const min = parseInt(import.meta.env.VITE_MOCK_LATENCY_MIN) || 150;
  const max = parseInt(import.meta.env.VITE_MOCK_LATENCY_MAX) || 600;
  return Math.random() * (max - min) + min;
};

export const handlers = [
  // Auth
  rest.post(ENDPOINTS.AUTH_LOGIN, async (req, res, ctx) => {
    const { username } = await req.json();
    const user = fixtures.users.find(u => u.username === username);
    
    if (!user) {
      return res(
        ctx.delay(simulateLatency()),
        ctx.status(401),
        ctx.json({ error: 'Invalid credentials' })
      );
    }
    
    return res(
      ctx.delay(simulateLatency()),
      ctx.json({
        token: 'mock_jwt_token',
        user
      })
    );
  }),

  rest.get(ENDPOINTS.AUTH_ME, (req, res, ctx) => {
    return res(
      ctx.delay(simulateLatency()),
      ctx.json(fixtures.users[0])
    );
  }),

  // Claims
  rest.get(ENDPOINTS.CLAIMS, (req, res, ctx) => {
    const page = parseInt(req.url.searchParams.get('page') || '1');
    const limit = parseInt(req.url.searchParams.get('limit') || '10');
    
    const start = (page - 1) * limit;
    const end = start + limit;
    const paginatedClaims = fixtures.claims.slice(start, end);
    
    return res(
      ctx.delay(simulateLatency()),
      ctx.json({
        data: paginatedClaims,
        meta: {
          total: fixtures.claims.length,
          page,
          limit,
          totalPages: Math.ceil(fixtures.claims.length / limit)
        }
      })
    );
  }),

  rest.post(ENDPOINTS.CLAIMS, async (req, res, ctx) => {
    const newClaim = await req.json();
    const isDuplicate = fixtures.claims.some(
      claim => claim.text === newClaim.text
    );

    if (isDuplicate) {
      return res(
        ctx.status(409),
        ctx.json({ error: 'DUPLICATE_CLAIM' })
      );
    }

    const createdClaim = {
      ...newClaim,
      id: crypto.randomUUID(),
      createdAt: new Date().toISOString(),
      status: 'pending'
    };
    fixtures.claims.unshift(createdClaim);

    return res(
      ctx.delay(simulateLatency()),
      ctx.status(201),
      ctx.json(createdClaim)
    );
  })
];
