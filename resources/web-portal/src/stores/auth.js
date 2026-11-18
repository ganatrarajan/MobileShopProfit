import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { authApi, shopApi } from '@/api/endpoints';

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null);
  const shop = ref(null);
  const token = ref(null);
  const loading = ref(false);

  const isAuthenticated = computed(() => !!token.value && !!user.value);
  const isOwner = computed(() => user.value?.role === 'owner');
  const shopName = computed(() => shop.value?.name || 'My Shop');

  function initAuth() {
    const savedToken = localStorage.getItem('auth_token');
    const savedUser = localStorage.getItem('user');
    const savedShop = localStorage.getItem('shop');

    if (savedToken) {
      token.value = savedToken;
      try {
        user.value = savedUser ? JSON.parse(savedUser) : null;
        shop.value = savedShop ? JSON.parse(savedShop) : null;
      } catch {
        user.value = null;
        shop.value = null;
      }
    }
  }

  async function login(mobile, password) {
    loading.value = true;
    try {
      const response = await authApi.login({
        login: mobile,
        password: password,
        login_source: 'web',
      });


      const data = response.data;
      if (!data.success) {
        throw new Error(data.message || 'Login failed');
      }

      // Enforce owner-only web login
      if (data.data.user.role !== 'owner') {
        throw new Error('Web portal access is available for shop owners only. Staff members please use the mobile app.');
      }

      token.value = data.data.token;
      user.value = data.data.user;
      shop.value = data.data.shop;

      localStorage.setItem('auth_token', data.data.token);
      localStorage.setItem('user', JSON.stringify(data.data.user));
      localStorage.setItem('shop', JSON.stringify(data.data.shop));

      return data;
    } finally {
      loading.value = false;
    }
  }

  async function fetchProfile() {
    try {
      const response = await authApi.me();
      if (response.data.success) {
        user.value = response.data.data.user;
        shop.value = response.data.data.shop;
        localStorage.setItem('user', JSON.stringify(user.value));
        localStorage.setItem('shop', JSON.stringify(shop.value));
      }
    } catch (error) {
      console.error('Failed to fetch profile:', error);
    }
  }

  async function fetchShop() {
    try {
      const response = await shopApi.get();
      if (response.data.success) {
        shop.value = response.data.data;
        localStorage.setItem('shop', JSON.stringify(shop.value));
      }
    } catch (error) {
      console.error('Failed to fetch shop:', error);
    }
  }

  async function logout() {
    try {
      await authApi.logout();
    } catch {
      // Ignore logout API error
    } finally {
      token.value = null;
      user.value = null;
      shop.value = null;
      localStorage.removeItem('auth_token');
      localStorage.removeItem('user');
      localStorage.removeItem('shop');
    }
  }

  return {
    user,
    shop,
    token,
    loading,
    isAuthenticated,
    isOwner,
    shopName,
    initAuth,
    login,
    fetchProfile,
    fetchShop,
    logout,
  };
});
