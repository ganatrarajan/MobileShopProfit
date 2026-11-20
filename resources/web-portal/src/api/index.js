import axios from 'axios';

const api = axios.create({
  baseURL: '/api/v1',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Client-Type': 'web',
  },
});

// Request interceptor — attach Bearer token and record activity
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('auth_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    // Update activity timestamp in storage
    try {
      localStorage.setItem('mr_portal_last_active', Date.now().toString());
    } catch {
      // ignore
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor — handle 401 (expired session or concurrent login)
api.interceptors.response.use(
  (response) => response,
  (error) => {
    const isLoginEndpoint = error.config?.url?.includes('/login');
    const isLoginPage = typeof window !== 'undefined' && window.location.pathname.includes('/login');

    // ONLY redirect to login if this is NOT a login attempt itself
    // Prevents wiping out form fields and reloading page when entering wrong credentials
    if (error.response?.status === 401 && !isLoginEndpoint) {
      try {
        if (!sessionStorage.getItem('portal_auth_notice')) {
          sessionStorage.setItem(
            'portal_auth_notice',
            JSON.stringify({
              type: 'concurrent',
              message: 'Your session has ended because this account was logged into from another web browser. Only 1 active web session is allowed at a time.',
            })
          );
        }
      } catch {
        // ignore
      }

      localStorage.removeItem('auth_token');
      localStorage.removeItem('user');
      localStorage.removeItem('shop');
      localStorage.removeItem('mr_portal_last_active');

      if (!isLoginPage && typeof window !== 'undefined') {
        window.location.href = '/portal/login?reason=concurrent';
      }
    }
    // Enhance 422 validation errors with the first specific field error message
    if (error.response?.data?.errors && typeof error.response.data.errors === 'object') {
      const firstKey = Object.keys(error.response.data.errors)[0];
      const firstError = error.response.data.errors[firstKey];
      if (Array.isArray(firstError) && firstError[0]) {
        error.response.data.message = firstError[0];
      }
    }

    return Promise.reject(error);
  }
);

export default api;
