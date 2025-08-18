import { api } from '../api/client';
import { ENDPOINTS } from '../api/endpoints';

export const notificationService = {
  list: () => api.get(ENDPOINTS.NOTIFICATIONS),
  markRead: (notificationIds) => 
    api.post(ENDPOINTS.NOTIFICATIONS_MARK_READ, { ids: notificationIds })
};
