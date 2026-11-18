import axios from 'axios';

const api = axios.create({
  baseURL: '/api/v1',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
});

// Request interceptor — attach Bearer token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('auth_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor — handle 401 (expired session on protected routes only)
api.interceptors.response.use(
  (response) => response,
  (error) => {
    const isLoginEndpoint = error.config?.url?.includes('/login');
    const isLoginPage = typeof window !== 'undefined' && window.location.pathname.includes('/login');

    // ONLY redirect to login if this is NOT a login attempt itself
    // Prevents wiping out form fields and reloading page when entering wrong credentials
    if (error.response?.status === 401 && !isLoginEndpoint) {
      localStorage.removeItem('auth_token');
      localStorage.removeItem('user');
      localStorage.removeItem('shop');
      if (!isLoginPage) {
        window.location.href = '/portal/login';
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
