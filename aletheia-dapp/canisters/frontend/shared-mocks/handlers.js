import { rest } from 'msw';

const getUiFromReq = (req) => {
  return req.headers.get('x-ui') || 'user'; // default to user UI
};

export const createHandlers = ({ ui = 'user' } = {}) => {
  const getFixtures = (req) => {
    const targetUI = getUiFromReq(req);
    try {
      return require(`../../${targetUI}/src/mocks/fixtures/claims.json`);
    } catch {
      return require('./fixtures/common.json'); 
    }
  };

  return [
    // Auth handlers
    rest.post('/api/auth/login', (req, res, ctx) => {
      const users = require('../../user_interface/src/mocks/fixtures/users.json');
      const { username } = req.body;
      const user = users.find(u => u.username === username);
      
      return user 
        ? res(ctx.json({ token: 'mock_jwt', user }))
        : res(ctx.status(401));
    }),

    // Claims endpoints
    rest.get('/api/claims', (req, res, ctx) => {
      const claims = getFixtures(req);
      return res(ctx.json({
        data: claims,
        meta: { total: claims.length }
      }));
    }),

    rest.post('/api/claims', async (req, res, ctx) => {
      const claims = getFixtures(req);
      const newClaim = await req.json();
      const isDuplicate = claims.some(c => c.text === newClaim.text);
      
      return isDuplicate
        ? res(ctx.status(409), ctx.json({ error: 'DUPLICATE_CLAIM' }))
        : res(ctx.status(201), ctx.json({ ...newClaim, id: crypto.randomUUID() }));
    }),

    // UI-specific endpoints
    rest.get('/api/aletheian/queue', (req, res, ctx) => {
      if (getUiFromReq(req) !== 'aletheian') return res(ctx.status(403));
      const tasks = require('../../aletheian_interface/src/mocks/fixtures/tasks.json');
      return res(ctx.json(tasks));
    })
  ];
};
