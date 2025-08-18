import { setupWorker } from 'msw';
import { createHandlers } from '../../../../shared-mocks/handlers';

export const worker = setupWorker(...createHandlers({ ui: 'aletheian' }));
