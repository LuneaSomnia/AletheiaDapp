import { api } from '../api/client';
import { ENDPOINTS } from '../api/endpoints';

export const aletheianService = {
  getQueue: () => api.get(ENDPOINTS.ALETHEIAN_QUEUE),
  submitVerification: (id, data) => api.post(ENDPOINTS.ALETHEIAN_SUBMIT(id), data),
  getLedgerEntry: (claimId) => api.get(ENDPOINTS.LEDGER(claimId)),
  getProgress: () => api.get(ENDPOINTS.ALETHEIAN_PROGRESS)
};
