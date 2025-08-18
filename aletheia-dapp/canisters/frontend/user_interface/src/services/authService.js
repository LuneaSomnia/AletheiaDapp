import { api } from '../api/client';
import { ENDPOINTS } from '../api/endpoints';

export const authService = {
  login: (credentials) => api.post(ENDPOINTS.AUTH_LOGIN, credentials),
  getMe: () => api.get(ENDPOINTS.AUTH_ME),
  logout: () => {
    localStorage.removeItem('authToken');
    window.location.reload();
  }
};
