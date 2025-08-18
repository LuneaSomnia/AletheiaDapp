export const ENDPOINTS = {
  AUTH_LOGIN: '/api/auth/login',
  AUTH_ME: '/api/auth/me',
  CLAIMS: '/api/claims',
  CLAIM: (id) => `/api/claims/${id}`,
  ALETHEIAN_QUEUE: '/api/aletheian/queue',
  ALETHEIAN_SUBMIT: (id) => `/api/aletheian/claims/${id}/submit`,
  LEDGER: (id) => `/api/ledger/${id}`,
  NOTIFICATIONS: '/api/notifications',
  NOTIFICATIONS_MARK_READ: '/api/notifications/mark-read',
  UPLOAD_SIGN: '/api/uploads/sign',
  SEARCH: '/api/search',
  FINANCE: '/api/finance',
  FINANCE_WITHDRAWALS: '/api/finance/withdrawals',
  FINANCE_HISTORY: '/api/finance/history'
};
