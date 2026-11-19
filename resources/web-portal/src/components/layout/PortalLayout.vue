<template>
  <div class="min-h-screen bg-slate-50 dark:bg-[#0B0F19] flex transition-colors duration-250 font-sans text-slate-800 dark:text-slate-100">
    <!-- Sidebar Overlay (Mobile) -->
    <div
      v-if="sidebarOpen"
      @click="sidebarOpen = false"
      class="fixed inset-0 bg-slate-950/60 backdrop-blur-xs z-40 lg:hidden"
    ></div>

    <!-- Sidebar with Collapsible Accordion Slider Menus -->
    <aside
      :class="[
        'w-64 border-r border-slate-200/80 dark:border-slate-800/80 bg-white dark:bg-[#111827] flex-shrink-0 flex flex-col transition-all duration-300 z-30',
        sidebarOpen ? 'translate-x-0 fixed inset-y-0 left-0' : '-translate-x-full fixed inset-y-0 left-0 lg:static lg:translate-x-0',
      ]"
    >
      <!-- Brand Header -->
      <div class="h-16 flex items-center px-6 border-b border-slate-200/80 dark:border-slate-800/80 gap-3">
        <div class="w-9 h-9 rounded-xl bg-indigo-600 flex items-center justify-center text-white text-lg font-black shadow-md shadow-indigo-500/20">
          <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
          </svg>
        </div>
        <div>
          <h1 class="text-sm font-bold text-slate-900 dark:text-white tracking-wide leading-none">MyRepairHub</h1>
          <span class="text-[10px] text-indigo-600 dark:text-indigo-400 font-extrabold tracking-widest uppercase">Web Portal</span>
        </div>
      </div>

      <!-- Shop Profile Card -->
      <div class="p-4 border-b border-slate-200/70 dark:border-slate-800/70 bg-slate-50/50 dark:bg-slate-900/40">
        <div class="flex items-center gap-3">
          <div class="w-10 h-10 rounded-full bg-indigo-100 dark:bg-slate-800 border border-indigo-200 dark:border-slate-700 flex items-center justify-center text-indigo-700 dark:text-indigo-400 font-bold overflow-hidden">
            <img v-if="authStore.shop?.logo_url" :src="authStore.shop.logo_url" class="object-cover w-full h-full" />
            <span v-else>{{ (authStore.shopName || 'MR').substring(0, 2).toUpperCase() }}</span>
          </div>
          <div class="overflow-hidden min-w-0 flex-1">
            <div class="flex items-center gap-1.5">
              <h4 class="text-xs font-bold text-slate-800 dark:text-slate-200 truncate">{{ authStore.shopName }}</h4>
              <span class="px-1.5 py-0.5 rounded text-[9px] font-extrabold bg-indigo-100 text-indigo-700 dark:bg-indigo-900/50 dark:text-indigo-400 border border-indigo-200 dark:border-indigo-800" title="Shop ID">
                #{{ authStore.shop?.id || '1' }}
              </span>
            </div>
            <p class="text-[10px] text-slate-500 dark:text-slate-400 truncate">{{ authStore.user?.mobile || authStore.user?.email || 'Shop Owner' }}</p>
          </div>
        </div>
      </div>

      <!-- Navigation: Option 2 Ultra Compact Main Menu & Submenus -->
      <nav class="flex-1 px-3 py-3 space-y-1.5 overflow-y-auto custom-scrollbar">
        <!-- 1. Dashboard (Direct Link) -->
        <router-link
          to="/"
          @click="sidebarOpen = false"
          class="flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-xs font-semibold transition-all group"
          :class="[isRouteActive('/') ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/20 font-bold' : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800/60 hover:text-slate-900 dark:hover:text-slate-200']"
        >
          <svg class="w-4 h-4 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2H6a2 2 0 01-2-2v-4zM14 16a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2h-2a2 2 0 01-2-2v-4z" />
          </svg>
          <span class="flex-1">Dashboard</span>
        </router-link>

        <!-- 2. Counter Operations (Accordion: Repairs, Sales, Used Mobiles) -->
        <div class="rounded-xl overflow-hidden transition-all">
          <button
            type="button"
            @click="toggleGroup('operations')"
            class="w-full flex items-center justify-between px-3 py-2.5 text-xs font-bold rounded-xl transition-all select-none cursor-pointer"
            :class="isGroupActive(['/repairs', '/sales', '/used-mobiles']) ? 'text-indigo-600 dark:text-indigo-400 bg-indigo-50/80 dark:bg-indigo-950/40 shadow-xs' : 'text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800/50'"
          >
            <div class="flex items-center gap-2.5 min-w-0">
              <svg class="w-4 h-4 flex-shrink-0 text-indigo-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
              </svg>
              <span class="truncate">Counter Operations</span>
            </div>
            <svg
              class="w-3.5 h-3.5 text-slate-400 transition-transform duration-200 flex-shrink-0"
              :class="{ 'rotate-180': openGroups.operations }"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
            </svg>
          </button>
          <div v-show="openGroups.operations" class="border-l-2 border-indigo-200 dark:border-indigo-900/60 ml-4 pl-3 py-1 space-y-1 transition-all my-1">
            <router-link
              to="/repairs"
              @click="sidebarOpen = false"
              class="flex items-center justify-between px-2.5 py-1.5 rounded-lg text-xs font-medium transition-all"
              :class="isRouteActive('/repairs') && !isRouteActive('/repairs/new') ? 'bg-indigo-600 text-white font-semibold' : 'text-slate-600 dark:text-slate-400 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-slate-100 dark:hover:bg-slate-800/40'"
            >
              <span>Repair Orders</span>
              <span class="text-[10px] opacity-70">Jobs</span>
            </router-link>
            <router-link
              to="/repairs/new"
              @click="sidebarOpen = false"
              class="flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg text-xs font-medium transition-all text-emerald-600 dark:text-emerald-400 hover:bg-emerald-50 dark:hover:bg-emerald-950/30"
              :class="isRouteActive('/repairs/new') ? 'bg-emerald-600 !text-white font-semibold' : ''"
            >
              <span class="font-bold">+</span>
              <span>New Repair Ticket</span>
            </router-link>
            <router-link
              to="/sales"
              @click="sidebarOpen = false"
              class="flex items-center justify-between px-2.5 py-1.5 rounded-lg text-xs font-medium transition-all"
              :class="isRouteActive('/sales') && !isRouteActive('/sales/new') ? 'bg-indigo-600 text-white font-semibold' : 'text-slate-600 dark:text-slate-400 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-slate-100 dark:hover:bg-slate-800/40'"
            >
              <span>Sales & Invoices</span>
              <span class="text-[10px] opacity-70">Bills</span>
            </router-link>
            <router-link
              to="/sales/new"
              @click="sidebarOpen = false"
              class="flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg text-xs font-medium transition-all text-emerald-600 dark:text-emerald-400 hover:bg-emerald-50 dark:hover:bg-emerald-950/30"
              :class="isRouteActive('/sales/new') ? 'bg-emerald-600 !text-white font-semibold' : ''"
            >
              <span class="font-bold">+</span>
              <span>New Sale / POS Counter</span>
            </router-link>
            <router-link
              to="/used-mobiles"
              @click="sidebarOpen = false"
              class="block px-2.5 py-1.5 rounded-lg text-xs font-medium transition-all"
              :class="isRouteActive('/used-mobiles') && !route.query.action ? 'bg-indigo-600 text-white font-semibold' : 'text-slate-600 dark:text-slate-400 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-slate-100 dark:hover:bg-slate-800/40'"
            >
              Used Mobiles Inventory
            </router-link>
            <router-link
              to="/used-mobiles?action=buy"
              @click="sidebarOpen = false"
              class="block px-2.5 py-1.5 rounded-lg text-xs font-medium transition-all text-amber-600 dark:text-amber-400 hover:bg-amber-50 dark:hover:bg-amber-950/30"
              :class="route.query.action === 'buy' ? 'bg-amber-600 !text-white font-semibold' : ''"
            >
              + Buy Used Mobile
            </router-link>
            <router-link
              to="/used-mobiles?action=sell"
              @click="sidebarOpen = false"
              class="block px-2.5 py-1.5 rounded-lg text-xs font-medium transition-all text-indigo-600 dark:text-indigo-400 hover:bg-indigo-50 dark:hover:bg-indigo-950/30"
              :class="route.query.action === 'sell' ? 'bg-indigo-600 !text-white font-semibold' : ''"
            >
              Sell Used Mobile
            </router-link>
          </div>
        </div>

        <!-- 3. Stock & Procurement (Accordion: Inventory, Purchases) -->
        <div class="rounded-xl overflow-hidden transition-all">
          <button
            type="button"
            @click="toggleGroup('stock')"
            class="w-full flex items-center justify-between px-3 py-2.5 text-xs font-bold rounded-xl transition-all select-none cursor-pointer"
            :class="isGroupActive(['/inventory', '/purchases']) ? 'text-indigo-600 dark:text-indigo-400 bg-indigo-50/80 dark:bg-indigo-950/40 shadow-xs' : 'text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800/50'"
          >
            <div class="flex items-center gap-2.5 min-w-0">
              <svg class="w-4 h-4 flex-shrink-0 text-indigo-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
              </svg>
              <span class="truncate">Stock & Purchasing</span>
            </div>
            <svg
              class="w-3.5 h-3.5 text-slate-400 transition-transform duration-200 flex-shrink-0"
              :class="{ 'rotate-180': openGroups.stock }"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
            </svg>
          </button>
          <div v-show="openGroups.stock" class="border-l-2 border-indigo-200 dark:border-indigo-900/60 ml-4 pl-3 py-1 space-y-1 transition-all my-1">
            <router-link
              to="/inventory"
              @click="sidebarOpen = false"
              class="block px-2.5 py-1.5 rounded-lg text-xs font-medium transition-all"
              :class="isRouteActive('/inventory') ? 'bg-indigo-600 text-white font-semibold' : 'text-slate-600 dark:text-slate-400 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-slate-100 dark:hover:bg-slate-800/40'"
            >
              Shop Inventory Stock
            </router-link>
            <router-link
              to="/purchases"
              @click="sidebarOpen = false"
              class="block px-2.5 py-1.5 rounded-lg text-xs font-medium transition-all"
              :class="isRouteActive('/purchases') ? 'bg-indigo-600 text-white font-semibold' : 'text-slate-600 dark:text-slate-400 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-slate-100 dark:hover:bg-slate-800/40'"
            >
              Purchases & Vendors
            </router-link>
          </div>
        </div>

        <!-- 4. Customers & Warranties (Accordion: Customers, Warranties) -->
        <div class="rounded-xl overflow-hidden transition-all">
          <button
            type="button"
            @click="toggleGroup('customers')"
            class="w-full flex items-center justify-between px-3 py-2.5 text-xs font-bold rounded-xl transition-all select-none cursor-pointer"
            :class="isGroupActive(['/customers', '/warranties']) ? 'text-indigo-600 dark:text-indigo-400 bg-indigo-50/80 dark:bg-indigo-950/40 shadow-xs' : 'text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800/50'"
          >
            <div class="flex items-center gap-2.5 min-w-0">
              <svg class="w-4 h-4 flex-shrink-0 text-indigo-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
              <span class="truncate">Customers & After-Sales</span>
            </div>
            <svg
              class="w-3.5 h-3.5 text-slate-400 transition-transform duration-200 flex-shrink-0"
              :class="{ 'rotate-180': openGroups.customers }"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
            </svg>
          </button>
          <div v-show="openGroups.customers" class="border-l-2 border-indigo-200 dark:border-indigo-900/60 ml-4 pl-3 py-1 space-y-1 transition-all my-1">
            <router-link
              to="/customers"
              @click="sidebarOpen = false"
              class="block px-2.5 py-1.5 rounded-lg text-xs font-medium transition-all"
              :class="isRouteActive('/customers') ? 'bg-indigo-600 text-white font-semibold' : 'text-slate-600 dark:text-slate-400 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-slate-100 dark:hover:bg-slate-800/40'"
            >
              Customer Accounts & Khata
            </router-link>
            <router-link
              to="/warranties"
              @click="sidebarOpen = false"
              class="block px-2.5 py-1.5 rounded-lg text-xs font-medium transition-all"
              :class="isRouteActive('/warranties') ? 'bg-indigo-600 text-white font-semibold' : 'text-slate-600 dark:text-slate-400 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-slate-100 dark:hover:bg-slate-800/40'"
            >
              Warranties & Guarantees
            </router-link>
          </div>
        </div>

        <!-- 5. Team Management (Accordion: Staff, Technicians) -->
        <div class="rounded-xl overflow-hidden transition-all">
          <button
            type="button"
            @click="toggleGroup('team')"
            class="w-full flex items-center justify-between px-3 py-2.5 text-xs font-bold rounded-xl transition-all select-none cursor-pointer"
            :class="isGroupActive(['/staff', '/technicians']) ? 'text-indigo-600 dark:text-indigo-400 bg-indigo-50/80 dark:bg-indigo-950/40 shadow-xs' : 'text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800/50'"
          >
            <div class="flex items-center gap-2.5 min-w-0">
              <svg class="w-4 h-4 flex-shrink-0 text-indigo-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V8a2 2 0 00-2-2h-5m-4 0V5a2 2 0 114 0v1m-4 0a2 2 0 104 0m-5 8a2 2 0 100-4 2 2 0 000 4zm0 0c1.306 0 2.417.835 2.83 2M9 14a3.001 3.001 0 00-2.83 2M15 11h3m-3 4h2" />
              </svg>
              <span class="truncate">Team & Staff</span>
            </div>
            <svg
              class="w-3.5 h-3.5 text-slate-400 transition-transform duration-200 flex-shrink-0"
              :class="{ 'rotate-180': openGroups.team }"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
            </svg>
          </button>
          <div v-show="openGroups.team" class="border-l-2 border-indigo-200 dark:border-indigo-900/60 ml-4 pl-3 py-1 space-y-1 transition-all my-1">
            <router-link
              to="/staff"
              @click="sidebarOpen = false"
              class="block px-2.5 py-1.5 rounded-lg text-xs font-medium transition-all"
              :class="isRouteActive('/staff') ? 'bg-indigo-600 text-white font-semibold' : 'text-slate-600 dark:text-slate-400 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-slate-100 dark:hover:bg-slate-800/40'"
            >
              Staff Members (App Logins)
            </router-link>
            <router-link
              to="/technicians"
              @click="sidebarOpen = false"
              class="block px-2.5 py-1.5 rounded-lg text-xs font-medium transition-all"
              :class="isRouteActive('/technicians') ? 'bg-indigo-600 text-white font-semibold' : 'text-slate-600 dark:text-slate-400 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-slate-100 dark:hover:bg-slate-800/40'"
            >
              Repair Technicians
            </router-link>
          </div>
        </div>

        <!-- 6. Accounts & Administration (Accordion: Expenses, Reports, Subscription, Settings) -->
        <div class="rounded-xl overflow-hidden transition-all">
          <button
            type="button"
            @click="toggleGroup('admin')"
            class="w-full flex items-center justify-between px-3 py-2.5 text-xs font-bold rounded-xl transition-all select-none cursor-pointer"
            :class="isGroupActive(['/expenses', '/reports', '/subscription', '/settings']) ? 'text-indigo-600 dark:text-indigo-400 bg-indigo-50/80 dark:bg-indigo-950/40 shadow-xs' : 'text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800/50'"
          >
            <div class="flex items-center gap-2.5 min-w-0">
              <svg class="w-4 h-4 flex-shrink-0 text-indigo-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
              <span class="truncate">Accounts & Settings</span>
            </div>
            <svg
              class="w-3.5 h-3.5 text-slate-400 transition-transform duration-200 flex-shrink-0"
              :class="{ 'rotate-180': openGroups.admin }"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
            </svg>
          </button>
          <div v-show="openGroups.admin" class="border-l-2 border-indigo-200 dark:border-indigo-900/60 ml-4 pl-3 py-1 space-y-1 transition-all my-1">
            <router-link
              to="/expenses"
              @click="sidebarOpen = false"
              class="block px-2.5 py-1.5 rounded-lg text-xs font-medium transition-all"
              :class="isRouteActive('/expenses') ? 'bg-indigo-600 text-white font-semibold' : 'text-slate-600 dark:text-slate-400 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-slate-100 dark:hover:bg-slate-800/40'"
            >
              Shop Expenses (Kharcha)
            </router-link>
            <router-link
              to="/reports"
              @click="sidebarOpen = false"
              class="block px-2.5 py-1.5 rounded-lg text-xs font-medium transition-all"
              :class="isRouteActive('/reports') ? 'bg-indigo-600 text-white font-semibold' : 'text-slate-600 dark:text-slate-400 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-slate-100 dark:hover:bg-slate-800/40'"
            >
              Reports & Profit Hub
            </router-link>
            <router-link
              to="/subscription"
              @click="sidebarOpen = false"
              class="block px-2.5 py-1.5 rounded-lg text-xs font-medium transition-all"
              :class="isRouteActive('/subscription') ? 'bg-indigo-600 text-white font-semibold' : 'text-slate-600 dark:text-slate-400 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-slate-100 dark:hover:bg-slate-800/40'"
            >
              Subscription & Billing
            </router-link>
            <router-link
              to="/settings"
              @click="sidebarOpen = false"
              class="block px-2.5 py-1.5 rounded-lg text-xs font-medium transition-all"
              :class="isRouteActive('/settings') ? 'bg-indigo-600 text-white font-semibold' : 'text-slate-600 dark:text-slate-400 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-slate-100 dark:hover:bg-slate-800/40'"
            >
              Shop Profile & Settings
            </router-link>
          </div>
        </div>
      </nav>

      <!-- Bottom User Profile Footer -->
      <div class="p-3.5 border-t border-slate-200/80 dark:border-slate-800/80 bg-white dark:bg-[#111827]">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2.5 overflow-hidden">
            <div class="w-8 h-8 rounded-xl bg-indigo-100 dark:bg-indigo-950/60 border border-indigo-200 dark:border-indigo-800 flex items-center justify-center text-indigo-700 dark:text-indigo-400 font-bold text-xs flex-shrink-0">
              {{ (authStore.user?.name || 'O').substring(0, 1).toUpperCase() }}
            </div>
            <div class="overflow-hidden min-w-0">
              <h4 class="text-xs font-bold text-slate-800 dark:text-white truncate">{{ authStore.user?.name || 'Owner' }}</h4>
              <span class="inline-flex items-center px-1.5 py-0.2 rounded text-[9px] font-bold bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 border border-indigo-500/20 uppercase">
                Owner
              </span>
            </div>
          </div>
          <button
            @click="handleLogout"
            class="p-1.5 text-slate-400 hover:text-rose-600 dark:hover:text-rose-400 hover:bg-rose-50 dark:hover:bg-rose-950/40 rounded-lg transition-colors cursor-pointer"
            title="Sign Out"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
            </svg>
          </button>
        </div>
      </div>
    </aside>

    <!-- Main Content Area -->
    <div class="flex-1 flex flex-col min-w-0 overflow-hidden">
      <!-- Top Header Bar -->
      <header class="h-16 border-b border-slate-200/80 dark:border-slate-800/80 bg-white/80 dark:bg-[#111827]/80 backdrop-blur-md px-4 sm:px-6 flex items-center justify-between z-20 transition-colors">
        <div class="flex items-center gap-3">
          <!-- Mobile Menu Trigger -->
          <button @click="sidebarOpen = true" class="p-2 -ml-2 rounded-xl text-slate-500 dark:text-slate-400 hover:text-slate-800 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-slate-800 lg:hidden cursor-pointer">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </button>
          <h2 class="text-base sm:text-lg font-bold text-slate-900 dark:text-white tracking-tight">{{ pageTitle }}</h2>
        </div>

        <div class="flex items-center gap-2.5 sm:gap-3">
          <!-- Light / Dark Mode Toggle (Sun/Moon) -->
          <button
            @click="toggleTheme"
            type="button"
            class="p-2 text-slate-500 dark:text-slate-400 hover:text-indigo-600 dark:hover:text-amber-400 rounded-xl hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors cursor-pointer"
            title="Toggle Light/Dark Theme"
          >
            <!-- Sun Icon (if dark mode active) -->
            <svg v-if="isDark" class="w-5 h-5 text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 9H3m15.364-6.364l-.707.707M6.343 17.657l-.707.707m0-12.728l.707.707m12.728 12.728l.707-.707M12 8a4 4 0 100 8 4 4 0 000-8z" />
            </svg>
            <!-- Moon Icon (if light mode active) -->
            <svg v-else class="w-5 h-5 text-indigo-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
            </svg>
          </button>

          <!-- Live Status Indicator -->
          <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20 select-none">
            <span class="w-1.5 h-1.5 rounded-full bg-emerald-500 dark:bg-emerald-400 animate-ping"></span>
            <span class="hidden md:inline">Live Web Engine</span>
            <span class="md:hidden">Live</span>
          </span>

          <!-- Google Play App Shortcut -->
          <a
            href="https://play.google.com/store/apps/details?id=com.repairehub"
            target="_blank"
            class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-xl text-xs font-bold text-slate-600 dark:text-slate-300 hover:text-emerald-600 bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700/60 transition-colors"
          >
            <svg class="w-3.5 h-3.5 text-emerald-500" viewBox="0 0 24 24" fill="currentColor">
              <path d="M3.609 1.814L13.792 12 3.61 22.186a1.94 1.94 0 01-.61-1.396V3.21c0-.528.216-1.03.609-1.396zm11.233 11.234l2.253 2.253-11.45 6.471 9.197-8.724zm0-2.096L5.645 2.228l11.45 6.47-2.253 2.254zm1.096 1.048l3.197 1.808c.883.499.883 1.314 0 1.813l-3.197 1.808-1.936-1.936 1.936-1.893z" />
            </svg>
            <span>App</span>
          </a>

          <!-- User Menu -->
          <div class="relative">
            <button
              @click="userMenuOpen = !userMenuOpen"
              class="w-9 h-9 rounded-xl bg-slate-100 dark:bg-slate-800 flex items-center justify-center font-bold text-xs text-slate-700 dark:text-slate-200 hover:ring-2 hover:ring-indigo-500/20 transition-all cursor-pointer"
            >
              {{ (authStore.user?.name || 'U').substring(0, 1).toUpperCase() }}
            </button>
            <div
              v-if="userMenuOpen"
              @click="userMenuOpen = false"
              class="fixed inset-0 z-30"
            ></div>
            <div
              v-if="userMenuOpen"
              class="absolute right-0 mt-2 w-52 bg-white dark:bg-[#111827] rounded-2xl shadow-xl border border-slate-200/80 dark:border-slate-800/80 py-2 z-40 text-xs font-semibold"
            >
              <div class="px-4 py-2 border-b border-slate-100 dark:border-slate-800/80">
                <p class="font-bold text-slate-900 dark:text-white truncate">{{ authStore.user?.name }}</p>
                <p class="text-[11px] text-slate-400 truncate">{{ authStore.user?.mobile || authStore.user?.phone }}</p>
              </div>
              <router-link to="/settings" class="flex items-center gap-2 px-4 py-2.5 text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800/60 transition">
                Shop Settings
              </router-link>
              <router-link to="/subscription" class="flex items-center gap-2 px-4 py-2.5 text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800/60 transition">
                Subscription & Plan
              </router-link>
              <button
                @click="handleLogout"
                class="w-full text-left flex items-center gap-2 px-4 py-2.5 text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/30 transition border-t border-slate-100 dark:border-slate-800/80 mt-1 cursor-pointer"
              >
                Sign Out
              </button>
            </div>
          </div>
        </div>
      </header>

      <!-- Main Scrollable Content Body -->
      <main
        ref="mainContentRef"
        class="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8 bg-slate-50/70 dark:bg-[#0B0F19]"
      >
        <router-view />
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useAuthStore } from '@/stores/auth';

const router = useRouter();
const route = useRoute();
const authStore = useAuthStore();

const sidebarOpen = ref(false);
const userMenuOpen = ref(false);
const isDark = ref(false);
const mainContentRef = ref(null);
let modalObserver = null;

// Collapsible slider accordion open states (Single active accordion: opening one closes others)
const openGroups = reactive({
  operations: false,
  stock: false,
  customers: false,
  team: false,
  admin: false,
});

function toggleGroup(key) {
  const currentState = !!openGroups[key];
  // Close all groups
  Object.keys(openGroups).forEach((k) => {
    openGroups[k] = false;
  });
  // Toggle selected group
  openGroups[key] = !currentState;
}

function isGroupActive(paths) {
  return paths.some(p => route.path.startsWith(p));
}

// Auto expand accordion if current route belongs to an accordion group
function autoExpandGroup() {
  let target = null;
  if (isGroupActive(['/repairs', '/sales', '/used-mobiles'])) target = 'operations';
  else if (isGroupActive(['/inventory', '/purchases'])) target = 'stock';
  else if (isGroupActive(['/customers', '/warranties'])) target = 'customers';
  else if (isGroupActive(['/staff', '/technicians'])) target = 'team';
  else if (isGroupActive(['/expenses', '/reports', '/subscription', '/settings'])) target = 'admin';

  Object.keys(openGroups).forEach((k) => {
    openGroups[k] = (k === target);
  });
}

function syncModalScrollLock() {
  // Check if any modal backdrop is active in the document
  const modalOverlays = document.querySelectorAll(
    '.fixed.inset-0.z-50, .fixed.inset-0.z-\\[999999\\], [data-modal-backdrop]'
  );
  const isAnyModalOpen = modalOverlays.length > 0;
  if (isAnyModalOpen) {
    document.body.classList.add('modal-open');
    if (mainContentRef.value) {
      mainContentRef.value.style.overflow = 'hidden';
    }
  } else {
    document.body.classList.remove('modal-open');
    if (mainContentRef.value) {
      mainContentRef.value.style.overflow = '';
    }
  }
}

watch(() => route.path, () => {
  autoExpandGroup();
  userMenuOpen.value = false;
  document.body.classList.remove('modal-open');
  if (mainContentRef.value) {
    mainContentRef.value.style.overflow = '';
  }
});

function isRouteActive(path) {
  if (path === '/') return route.path === '/';
  return route.path.startsWith(path);
}

const pageTitle = computed(() => {
  const p = route.path;
  if (p === '/') return 'Dashboard Overview';
  if (p.startsWith('/repairs')) return 'Repair Orders Directory';
  if (p.startsWith('/sales')) return 'Sales & Point of Sale';
  if (p.startsWith('/customers')) return 'Customers Directory';
  if (p.startsWith('/inventory')) return 'Inventory & Spare Parts';
  if (p.startsWith('/purchases')) return 'Stock Purchases';
  if (p.startsWith('/expenses')) return 'Shop Expenses';
  if (p.startsWith('/warranties')) return 'Warranties & Guarantees';
  if (p.startsWith('/used-mobiles')) return 'Used Mobiles (Buy & Sell)';
  if (p.startsWith('/technicians')) return 'Technicians Management';
  if (p.startsWith('/staff')) return 'Staff Accounts';
  if (p.startsWith('/reports')) return 'Reports & Analytics';
  if (p.startsWith('/subscription')) return 'Subscription & Billing';
  if (p.startsWith('/settings')) return 'Shop Settings';
  return 'MyRepairHub Portal';
});

function toggleTheme() {
  isDark.value = !isDark.value;
  if (isDark.value) {
    document.documentElement.classList.add('dark');
    localStorage.setItem('theme', 'dark');
  } else {
    document.documentElement.classList.remove('dark');
    localStorage.setItem('theme', 'light');
  }
}

async function handleLogout() {
  await authStore.logout();
  router.push('/login');
}

onMounted(() => {
  const savedTheme = localStorage.getItem('theme');
  if (savedTheme === 'dark' || (!savedTheme && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
    isDark.value = true;
    document.documentElement.classList.add('dark');
  } else {
    isDark.value = false;
    document.documentElement.classList.remove('dark');
  }
  autoExpandGroup();

  // Initialize observer to automatically lock background scrolling when any modal opens
  modalObserver = new MutationObserver(() => {
    syncModalScrollLock();
  });
  modalObserver.observe(document.body, { childList: true, subtree: true });
});

onUnmounted(() => {
  if (modalObserver) {
    modalObserver.disconnect();
  }
  document.body.classList.remove('modal-open');
  if (mainContentRef.value) {
    mainContentRef.value.style.overflow = '';
  }
});
</script>

<style>
body.modal-open {
  overflow: hidden !important;
}
</style>
