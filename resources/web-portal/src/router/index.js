import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from '@/stores/auth';
import { isSessionExpiredDueToInactivity, terminateSession } from '@/services/sessionManager';

// ── Auth Views ──
import LoginView from '@/views/auth/LoginView.vue';

// ── Portal Views ──
import PortalLayout from '@/components/layout/PortalLayout.vue';
import DashboardView from '@/views/portal/DashboardView.vue';

const routes = [
  // ── Auth Routes ──
  {
    path: '/login',
    name: 'login',
    component: LoginView,
    meta: { guest: true },
  },

  // ── Portal Routes (Authenticated Owner) ──
  {
    path: '/',
    component: PortalLayout,
    meta: { requiresAuth: true },
    children: [
      {
        path: '',
        name: 'dashboard',
        component: DashboardView,
      },
      {
        path: 'repairs',
        name: 'repairs',
        component: () => import('@/views/portal/repairs/RepairListView.vue'),
      },
      {
        path: 'repairs/new',
        name: 'repair-create',
        component: () => import('@/views/portal/repairs/RepairFormView.vue'),
      },
      {
        path: 'repairs/:id',
        name: 'repair-detail',
        component: () => import('@/views/portal/repairs/RepairDetailView.vue'),
      },
      {
        path: 'repairs/:id/edit',
        name: 'repair-edit',
        component: () => import('@/views/portal/repairs/RepairFormView.vue'),
      },
      {
        path: 'sales',
        name: 'sales',
        component: () => import('@/views/portal/sales/SaleListView.vue'),
      },
      {
        path: 'sales/new',
        name: 'sale-create',
        component: () => import('@/views/portal/sales/SaleFormView.vue'),
      },
      {
        path: 'sales/:id',
        name: 'sale-detail',
        component: () => import('@/views/portal/sales/SaleDetailView.vue'),
      },
      {
        path: 'customers',
        name: 'customers',
        component: () => import('@/views/portal/customers/CustomerListView.vue'),
      },
      {
        path: 'customers/:id',
        name: 'customer-detail',
        component: () => import('@/views/portal/customers/CustomerDetailView.vue'),
      },
      {
        path: 'inventory',
        name: 'inventory',
        component: () => import('@/views/portal/inventory/InventoryListView.vue'),
      },
      {
        path: 'purchases',
        name: 'purchases',
        component: () => import('@/views/portal/purchases/PurchaseListView.vue'),
      },
      {
        path: 'expenses',
        name: 'expenses',
        component: () => import('@/views/portal/expenses/ExpenseListView.vue'),
      },
      {
        path: 'warranties',
        name: 'warranties',
        component: () => import('@/views/portal/warranties/WarrantyListView.vue'),
      },
      {
        path: 'used-mobiles',
        name: 'used-mobiles',
        component: () => import('@/views/portal/used-mobiles/UsedMobileListView.vue'),
      },
      {
        path: 'used-mobiles/:id',
        name: 'used-mobile-detail',
        component: () => import('@/views/portal/used-mobiles/UsedMobileDetailView.vue'),
      },
      {
        path: 'technicians',
        name: 'technicians',
        component: () => import('@/views/portal/technicians/TechnicianListView.vue'),
      },
      {
        path: 'technicians/:id',
        name: 'technician-detail',
        component: () => import('@/views/portal/technicians/TechnicianDetailView.vue'),
      },
      {
        path: 'staff',
        name: 'staff',
        component: () => import('@/views/portal/staff/StaffListView.vue'),
      },
      {
        path: 'staff/:id',
        name: 'staff-detail',
        component: () => import('@/views/portal/staff/StaffDetailView.vue'),
      },
      {
        path: 'reports',
        name: 'reports',
        component: () => import('@/views/portal/reports/ReportsView.vue'),
      },
      {
        path: 'settings',
        name: 'settings',
        component: () => import('@/views/portal/settings/SettingsView.vue'),
      },
      {
        path: 'subscription',
        name: 'subscription',
        component: () => import('@/views/portal/subscription/SubscriptionView.vue'),
      },
    ],
  },

  // ── Catch-all redirect ──
  {
    path: '/:pathMatch(.*)*',
    redirect: '/',
  },
];

const router = createRouter({
  history: createWebHistory('/portal/'),
  routes,
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) return savedPosition;
    return { top: 0 };
  },
});

// ── Navigation Guards ──
router.beforeEach((to, from, next) => {
  const authStore = useAuthStore();

  if (to.meta.requiresAuth) {
    if (!authStore.isAuthenticated) {
      return next({ name: 'login', query: { redirect: to.fullPath } });
    }
    // Check if 30 minutes of inactivity elapsed
    if (isSessionExpiredDueToInactivity()) {
      terminateSession(
        'inactivity',
        'You have been automatically logged out due to 30 minutes of inactivity. Please sign in again.'
      );
      return next({ name: 'login', query: { reason: 'inactivity' } });
    }
    next();
  } else if (to.meta.guest && authStore.isAuthenticated) {
    if (isSessionExpiredDueToInactivity()) {
      terminateSession('inactivity');
      return next();
    }
    next({ name: 'dashboard' });
  } else {
    next();
  }
});

// Dynamic chunk loading failure auto-recovery (handles background rebuilds gracefully)
router.onError((error, to) => {
  const isChunkError =
    error?.message?.includes('Failed to fetch dynamically imported module') ||
    error?.message?.includes('Importing a module script failed') ||
    error?.message?.includes('error loading dynamically imported module');

  if (isChunkError && to) {
    const targetUrl = window.location.origin + '/portal' + (to.fullPath.startsWith('/') ? to.fullPath : '/' + to.fullPath);
    window.location.href = targetUrl;
  }
});

export default router;
