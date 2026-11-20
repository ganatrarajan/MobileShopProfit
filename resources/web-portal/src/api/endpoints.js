import api from './index';

// ── Auth ──
export const authApi = {
  login: (data) => api.post('/auth/login', data),
  me: () => api.get('/auth/me'),
  sessionCheck: () => api.get('/auth/session-check'),
  updateProfile: (data) => api.post('/auth/update-profile', data),
  changePassword: (data) => api.post('/auth/change-password', data),
  logout: () => api.post('/auth/logout'),
};

// ── Dashboard ──
export const dashboardApi = {
  get: (params) => api.get('/dashboard', { params }),
  profitLedger: (params) => api.get('/profit-ledger', { params }),
};

// ── Shop ──
export const shopApi = {
  get: () => api.get('/shop'),
  update: (data) => api.put('/shop', data),
  uploadLogo: (formData) => api.post('/shop/logo', formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
  }),
};

// ── Customers ──
export const customerApi = {
  list: (params) => api.get('/customers', { params }),
  get: (id) => api.get(`/customers/${id}`),
  create: (data) => api.post('/customers', data),
  update: (id, data) => api.put(`/customers/${id}`, data),
  delete: (id) => api.delete(`/customers/${id}`),
};

// ── Repairs ──
export const repairApi = {
  list: (params) => api.get('/repairs', { params }),
  get: (id) => api.get(`/repairs/${id}`),
  create: (data) => api.post('/repairs', data),
  update: (id, data) => api.put(`/repairs/${id}`, data),
  delete: (id) => api.delete(`/repairs/${id}`),
  updateStatus: (id, data) => api.post(`/repairs/${id}/status`, data),
  addPart: (id, data) => api.post(`/repairs/${id}/parts`, data),
  removePart: (repairId, partId) => api.delete(`/repairs/${repairId}/parts/${partId}`),
  addPayment: (id, data) => api.post(`/repairs/${id}/payments`, data),
};

// ── Sales ──
export const saleApi = {
  list: (params) => api.get('/sales', { params }),
  get: (id) => api.get(`/sales/${id}`),
  create: (data) => api.post('/sales', data),
  update: (id, data) => api.put(`/sales/${id}`, data),
  delete: (id) => api.delete(`/sales/${id}`),
  addPayment: (id, data) => api.post(`/sales/${id}/payments`, data),
};

// ── Inventory ──
export const inventoryApi = {
  list: (params) => api.get('/inventory', { params }),
  get: (id) => api.get(`/inventory/${id}`),
  create: (data) => api.post('/inventory', data),
  update: (id, data) => api.put(`/inventory/${id}`, data),
  delete: (id) => api.delete(`/inventory/${id}`),
  addStock: (id, data) => api.post(`/inventory/${id}/stock`, data),
  adjustStock: (id, data) => api.post(`/inventory/${id}/adjustment`, data),
  movements: (id) => api.get(`/inventory/${id}/movements`),
  checkImei: (params) => api.get('/inventory/check-imei', { params }),
};

// ── Vendors ──
export const vendorApi = {
  list: (params) => api.get('/vendors', { params }),
  get: (id) => api.get(`/vendors/${id}`),
  create: (data) => api.post('/vendors', data),
  update: (id, data) => api.put(`/vendors/${id}`, data),
  delete: (id) => api.delete(`/vendors/${id}`),
  addPayment: (id, data) => api.post(`/vendors/${id}/payments`, data),
};

// ── Purchases ──
export const purchaseApi = {
  list: (params) => api.get('/purchases', { params }),
  get: (id) => api.get(`/purchases/${id}`),
  create: (data) => api.post('/purchases', data),
  update: (id, data) => api.put(`/purchases/${id}`, data),
  delete: (id) => api.delete(`/purchases/${id}`),
  addStock: (id, data) => api.post(`/purchases/${id}/add-stock`, data),
  removeStock: (id, data) => api.post(`/purchases/${id}/remove-stock`, data),
  addPayment: (id, data) => api.post(`/purchases/${id}/payments`, data),
};

// ── Expenses ──
export const expenseApi = {
  list: (params) => api.get('/expenses', { params }),
  get: (id) => api.get(`/expenses/${id}`),
  create: (data) => api.post('/expenses', data),
  update: (id, data) => api.put(`/expenses/${id}`, data),
  delete: (id) => api.delete(`/expenses/${id}`),
};

export const expenseCategoryApi = {
  list: () => api.get('/expense-categories'),
  create: (data) => api.post('/expense-categories', data),
  update: (id, data) => api.put(`/expense-categories/${id}`, data),
  delete: (id) => api.delete(`/expense-categories/${id}`),
};

// ── Warranties ──
export const warrantyApi = {
  list: (params) => api.get('/warranties', { params }),
  get: (id) => api.get(`/warranties/${id}`),
  create: (data) => api.post('/warranties', data),
  update: (id, data) => api.put(`/warranties/${id}`, data),
  delete: (id) => api.delete(`/warranties/${id}`),
  getClaims: (id) => api.get(`/warranties/${id}/claims`),
  addClaim: (id, data) => api.post(`/warranties/${id}/claims`, data),
  allClaims: (params) => api.get('/warranty-claims', { params }),
  updateClaim: (claimId, data) => api.put(`/warranty-claims/${claimId}`, data),
  deleteClaim: (claimId) => api.delete(`/warranty-claims/${claimId}`),
};

// ── Used Mobiles ──
export const usedMobileApi = {
  list: (params) => api.get('/used-mobiles', { params }),
  get: (id) => api.get(`/used-mobiles/${id}`),
  create: (data) => api.post('/used-mobiles', data),
  update: (id, data) => api.put(`/used-mobiles/${id}`, data),
  delete: (id) => api.delete(`/used-mobiles/${id}`),
  stats: () => api.get('/used-mobiles/stats'),
  addRepairExpense: (id, data) => api.post(`/used-mobiles/${id}/repair-expense`, data),
  sell: (id, data) => api.post(`/used-mobiles/${id}/sell`, data),
  addPayment: (id, data) => api.post(`/used-mobiles/${id}/payments`, data),
};

// ── Technicians ──
export const technicianApi = {
  list: (params) => api.get('/technicians', { params }),
  get: (id) => api.get(`/technicians/${id}`),
  create: (data) => api.post('/technicians', data),
  update: (id, data) => api.put(`/technicians/${id}`, data),
  delete: (id) => api.delete(`/technicians/${id}`),
  payments: (id) => api.get(`/technicians/${id}/payments`),
  addPayment: (id, data) => api.post(`/technicians/${id}/payments`, data),
  deletePayment: (id, paymentId) => api.delete(`/technicians/${id}/payments/${paymentId}`),
  myWorkSummary: () => api.get('/technician/my-work-summary'),
};

// ── Staff ──
export const staffApi = {
  list: (params) => api.get('/staff', { params }),
  get: (id) => api.get(`/staff/${id}`),
  create: (data) => api.post('/staff', data),
  update: (id, data) => api.put(`/staff/${id}`, data),
  delete: (id) => api.delete(`/staff/${id}`),
  toggleStatus: (id) => api.post(`/staff/${id}/toggle-status`),
};

// ── Reports ──
export const reportApi = {
  outstanding: (params) => api.get('/reports/outstanding', { params }),
  sales: (params) => api.get('/reports/sales', { params }),
  repairs: (params) => api.get('/reports/repairs', { params }),
  inventory: (params) => api.get('/reports/inventory', { params }),
  expenses: (params) => api.get('/reports/expenses', { params }),
  payments: (params) => api.get('/reports/payments', { params }),
  customers: (params) => api.get('/reports/customers', { params }),
  warranties: (params) => api.get('/reports/warranties', { params }),
  export: (params) => api.get('/reports/export', { params, responseType: 'blob' }),
};

// ── Subscription ──
export const subscriptionApi = {
  status: () => api.get('/subscription/status'),
  history: () => api.get('/subscription/history'),
  plans: () => api.get('/plans'),
};

// ── Devices ──
export const deviceApi = {
  list: (params) => api.get('/devices', { params }),
  listForCustomer: (customerId) => api.get(`/customers/${customerId}/devices`),
  createForCustomer: (customerId, data) => api.post(`/customers/${customerId}/devices`, data),
  update: (id, data) => api.put(`/devices/${id}`, data),
  delete: (id) => api.delete(`/devices/${id}`),
  search: (params) => api.get('/devices/search', { params }),
  brands: () => api.get('/device-brands'),
  models: (params) => api.get('/device-models', { params }),
};

// ── Referrals ──
export const referralApi = {
  summary: () => api.get('/referrals/summary'),
  getShopPayments: (shopId) => api.get(`/referrals/shops/${shopId}/payments`),
};

// ── Profit Intelligence ──
export const profitApi = {
  summary: () => api.get('/profit-intelligence/summary'),
  details: (category) => api.get(`/profit-intelligence/details/${category}`),
};

// ── Support ──
export const supportApi = {
  contactInfo: () => api.get('/support/contact-info'),
  submit: (data) => api.post('/support-requests', data),
};

// ── Notifications ──
export const notificationApi = {
  list: () => api.get('/notifications'),
  markAllRead: () => api.post('/notifications/read-all'),
  markRead: (id) => api.post(`/notifications/${id}/read`),
};
