import { api } from '../api/client';
import { ENDPOINTS } from '../api/endpoints';

export const authService = {
  login: async (credentials) => {
    return api.post(ENDPOINTS.AUTH_LOGIN, credentials);
  },
  getMe: async () => {
    return api.get(ENDPOINTS.AUTH_ME);
  },
  updateProfile: async (userId, updates) => {
    return api.put(ENDPOINTS.USERS(userId), updates);
  },
  logout: async () => {
    clearAuthToken();
  }
};
