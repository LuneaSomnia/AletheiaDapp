import { setupServer } from 'msw/node';
import { createHandlers } from '../../shared-mocks/handlers';

export const server = setupServer(...createHandlers({ ui: 'user' }));
