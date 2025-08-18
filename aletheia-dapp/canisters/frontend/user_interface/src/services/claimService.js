import { api } from '../api/client';
import { ENDPOINTS } from '../api/endpoints';

export const claimService = {
  list: (params) => api.get(ENDPOINTS.CLAIMS, { params }),
  create: (claimData) => api.post(ENDPOINTS.CLAIMS, claimData),
  get: (claimId) => api.get(ENDPOINTS.CLAIM(claimId))
};
