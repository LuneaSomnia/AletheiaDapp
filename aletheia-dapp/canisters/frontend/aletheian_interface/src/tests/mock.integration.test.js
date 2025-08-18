import { describe, expect, it, beforeAll, afterAll } from 'vitest';
import { server } from '../mocks/server';
import { authService } from '../../services/authService';
import { aletheianService } from '../../services/aletheianService';

beforeAll(() => server.listen());
afterAll(() => server.close());

describe('Aletheian Interface Mocks', () => {
  it('should fetch verification queue', async () => {
    const tasks = await aletheianService.getQueue();
    expect(tasks).toHaveLength(2);
  });

  it('should get ledger entry', async () => {
    const entry = await aletheianService.getLedgerEntry('b4a3e203-1b48-437f-88d5-8a6e2a8d9e01');
    expect(entry.verifications).toBe(3);
  });
});
