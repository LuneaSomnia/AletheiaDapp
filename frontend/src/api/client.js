const BASE = import.meta.env.VITE_API_BASE || '/api';
let authToken = null;

export function setAuthToken(token) { authToken = token; }
export function clearAuthToken() { authToken = null; }

async function request(path, { method = 'GET', body = null, headers = {}, params } = {}) {
  const url = new URL((import.meta.env.VITE_USE_MOCKS === 'true' ? '' : BASE) + path, window.location.origin);
  
  if (params) {
    Object.entries(params).forEach(([key, value]) => {
      url.searchParams.set(key, value);
    });
  }

  const headersWithAuth = new Headers({
    'Content-Type': 'application/json',
    ...headers
  });
  
  if (authToken) {
    headersWithAuth.set('Authorization', `Bearer ${authToken}`);
  }

  const response = await fetch(url.toString(), {
    method,
    headers: headersWithAuth,
    body: body ? JSON.stringify(body) : null
  });

  if (!response.ok) {
    const error = new Error(`HTTP error! status: ${response.status}`);
    error.status = response.status;
    error.body = await response.json().catch(() => null);
    throw error;
  }

  return response.json();
}

export const api = {
  get: (path, opts) => request(path, { ...opts, method: 'GET' }),
  post: (path, body, opts) => request(path, { ...opts, method: 'POST', body }),
  put: (path, body, opts) => request(path, { ...opts, method: 'PUT', body }),
  del: (path, opts) => request(path, { ...opts, method: 'DELETE' })
};
