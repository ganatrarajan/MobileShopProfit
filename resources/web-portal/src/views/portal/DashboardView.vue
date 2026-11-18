<template>
  <div class="space-y-6 pb-12 transition-colors duration-200">
    <!-- 1. HERO / CONTROL PANEL -->
    <div class="relative z-10 bg-white/70 dark:bg-slate-900/70 backdrop-blur-md border border-slate-200/60 dark:border-slate-800/60 rounded-2xl p-6 shadow-sm flex flex-col lg:flex-row justify-between items-start lg:items-center gap-6 transition-all">
      <div class="space-y-1">
        <span class="text-[10px] text-indigo-600 dark:text-indigo-400 font-extrabold tracking-widest uppercase mb-1 block">
          {{ authStore.shopName || dashboardData.shop_name || 'MY MOBILE SHOP' }}
        </span>
        <h1 class="text-2xl font-black tracking-tight flex items-center gap-2.5 text-slate-900 dark:text-white">
          Good {{ greeting }}, {{ ownerName }}!
          <span class="animate-bounce origin-[70%_70%] inline-block">👋</span>
        </h1>
        <div class="flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-slate-500 dark:text-slate-400 font-medium">
          <span class="inline-flex items-center gap-1.5 font-bold text-indigo-600 dark:text-indigo-400">
            <span class="w-1.5 h-1.5 rounded-full bg-indigo-500"></span>
            Shop ID: #{{ authStore.shop?.id || '1' }}
          </span>
          <span class="inline-flex items-center gap-1.5">
            Role: <span class="font-bold text-slate-700 dark:text-slate-300">Shop Owner</span>
          </span>
          <span class="inline-flex items-center gap-1.5 font-semibold text-emerald-600 dark:text-emerald-400">
            <span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
            Web Portal Active
          </span>
        </div>
      </div>

      <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 w-full lg:w-auto">
        <!-- Quick Jump Search -->
        <div class="relative flex-1 sm:w-64">
          <span class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
          </span>
          <input
            v-model="quickSearch"
            @keyup.enter="handleQuickSearch"
            type="text"
            placeholder="Search repairs or customers..."
            class="w-full pl-9 pr-4 py-2 text-xs font-semibold bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 dark:focus:border-indigo-400 transition-all placeholder-slate-400 dark:placeholder-slate-500 text-slate-800 dark:text-slate-100"
          />
        </div>

        <!-- Live Ticking Date & Time Card -->
        <div class="bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 px-4 py-2 rounded-xl flex items-center gap-3 shrink-0 shadow-xs">
          <svg class="w-4 h-4 text-indigo-500 dark:text-indigo-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
          <div class="text-[11px] leading-tight font-extrabold text-slate-600 dark:text-slate-300">
            <div>{{ formattedTodayDate }}</div>
            <div class="text-indigo-600 dark:text-indigo-400 tabular-nums font-black">{{ currentClockTime }}</div>
          </div>
        </div>
      </div>
    </div>

    <!-- 2. QUICK ACTION SHORTCUTS (Matching Mobile App Dashboard Fast Creation Grid) -->
    <div class="space-y-2">
      <div class="flex items-center justify-between">
        <h2 class="text-xs font-extrabold uppercase tracking-wider text-slate-500 dark:text-slate-400 flex items-center gap-1.5">
          <svg class="w-3.5 h-3.5 text-indigo-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M13 10V3L4 14h7v7l9-11h-7z"/></svg>
          Quick Actions
        </h2>
        <span class="text-[11px] text-slate-400">Fast access to daily shop operations</span>
      </div>

      <div class="flex items-center gap-2.5 overflow-x-auto pb-1 scrollbar-none">
        <router-link
          to="/repairs/new"
          class="inline-flex items-center gap-2 px-3.5 py-2.5 rounded-xl text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-500 shadow-md shadow-indigo-600/20 transition-all shrink-0 active:scale-95 cursor-pointer"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 4v16m8-8H4"></path></svg>
          + New Repair Job
        </router-link>

        <router-link
          to="/sales/new"
          class="inline-flex items-center gap-2 px-3.5 py-2.5 rounded-xl text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-500 shadow-md shadow-emerald-600/20 transition-all shrink-0 active:scale-95 cursor-pointer"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"></path></svg>
          + New Sale / POS
        </router-link>

        <router-link
          to="/purchases"
          class="inline-flex items-center gap-2 px-3.5 py-2.5 rounded-xl text-xs font-bold text-slate-700 dark:text-slate-200 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 hover:border-purple-500 shadow-xs transition-all shrink-0 active:scale-95 cursor-pointer"
        >
          <svg class="w-4 h-4 text-purple-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
          Purchases (Stock-in)
        </router-link>

        <router-link
          to="/expenses"
          class="inline-flex items-center gap-2 px-3.5 py-2.5 rounded-xl text-xs font-bold text-slate-700 dark:text-slate-200 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 hover:border-rose-500 shadow-xs transition-all shrink-0 active:scale-95 cursor-pointer"
        >
          <svg class="w-4 h-4 text-rose-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 14l6-6m-5.5.5h.01m4.99 5h.01M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16l3.5-2 3.5 2 3.5-2 3.5 2z"></path></svg>
          Add Expense
        </router-link>

        <router-link
          to="/customers"
          class="inline-flex items-center gap-2 px-3.5 py-2.5 rounded-xl text-xs font-bold text-slate-700 dark:text-slate-200 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 hover:border-indigo-500 shadow-xs transition-all shrink-0 active:scale-95 cursor-pointer"
        >
          <svg class="w-4 h-4 text-sky-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z"></path></svg>
          Customers Directory
        </router-link>

        <router-link
          to="/technicians"
          class="inline-flex items-center gap-2 px-3.5 py-2.5 rounded-xl text-xs font-bold text-slate-700 dark:text-slate-200 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 hover:border-sky-500 shadow-xs transition-all shrink-0 active:scale-95 cursor-pointer"
        >
          <svg class="w-4 h-4 text-sky-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
          Technicians
        </router-link>

        <router-link
          to="/used-mobiles"
          class="inline-flex items-center gap-2 px-3.5 py-2.5 rounded-xl text-xs font-bold text-slate-700 dark:text-slate-200 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 hover:border-amber-500 shadow-xs transition-all shrink-0 active:scale-95 cursor-pointer"
        >
          <svg class="w-4 h-4 text-amber-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"/></svg>
          Used Mobiles (Buy/Sell)
        </router-link>

        <router-link
          to="/reports"
          class="inline-flex items-center gap-2 px-3.5 py-2.5 rounded-xl text-xs font-bold text-slate-700 dark:text-slate-200 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 hover:border-indigo-500 shadow-xs transition-all shrink-0 active:scale-95 cursor-pointer"
        >
          <svg class="w-4 h-4 text-purple-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path></svg>
          P&L Reports
        </router-link>
      </div>
    </div>

    <!-- 3. DASHBOARD ANALYTICS FILTERS (Common Shop-Wide Period Filter) -->
    <div class="relative z-30 bg-white/70 dark:bg-slate-900/70 backdrop-blur-md border border-slate-200/60 dark:border-slate-800/60 rounded-2xl p-4 shadow-sm flex flex-wrap items-center justify-between gap-4 transition-all">
      <div class="flex items-center gap-2 text-xs font-black uppercase tracking-wider text-slate-700 dark:text-slate-300">
        <svg class="w-4 h-4 text-indigo-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z"></path></svg>
        <span>Shop Analytics Period</span>
        <span class="text-[11px] font-normal text-slate-400 lowercase">(updates all metrics, sales & repairs)</span>
      </div>

      <div class="flex flex-wrap items-center gap-3">
        <!-- Unified Period Filter Preset (Persists across all portal views) -->
        <SearchableSelect
          v-model="filterStore.selectedPeriod"
          :options="filterStore.periodOptions"
          @change="onPeriodChange"
          placeholder="Select Period"
          searchPlaceholder="Search period..."
          minWidth="160px"
          alignRight
        />

        <!-- Reset Button -->
        <button
          v-if="filterStore.selectedPeriod !== 'this_month'"
          @click="resetFilters"
          type="button"
          class="px-3 py-1.5 bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-600 dark:text-slate-300 rounded-xl text-xs font-bold transition-all cursor-pointer"
        >
          Reset to This Month
        </button>
      </div>
    </div>

    <!-- 4. NEEDS ATTENTION STRIP (Matching Mobile App Warning Alerts) -->
    <div v-if="dashboardAttention.length > 0" class="p-4 bg-amber-500/10 border border-amber-500/20 rounded-2xl space-y-2">
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-2">
          <svg class="w-4 h-4 text-amber-600 dark:text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
          <h3 class="text-xs font-extrabold uppercase tracking-wider text-amber-900 dark:text-amber-200">Needs Attention</h3>
        </div>
        <span class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-200/60 dark:bg-amber-900/40 text-amber-900 dark:text-amber-200">
          {{ dashboardAttention.length }} items
        </span>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-2">
        <div
          v-for="(item, idx) in dashboardAttention"
          :key="idx"
          class="p-2.5 rounded-xl bg-white/80 dark:bg-slate-900/80 border border-amber-200/60 dark:border-amber-800/40 flex items-center justify-between text-xs"
        >
          <div class="flex items-center gap-2 truncate">
            <span class="w-2 h-2 rounded-full bg-amber-500 shrink-0"></span>
            <span class="font-bold text-slate-800 dark:text-slate-200 truncate">{{ item.title || item.message || item }}</span>
          </div>
          <router-link
            v-if="item.action_url || item.url"
            :to="item.action_url || item.url"
            class="text-[11px] font-bold text-amber-700 dark:text-amber-400 hover:underline shrink-0 ml-2"
          >
            Review →
          </router-link>
        </div>
      </div>
    </div>

    <!-- 5. 6 PERIOD-ADAPTIVE METRIC STAT CARDS -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
      <!-- Card 1: Collections / Cash Received -->
      <router-link
        to="/sales"
        class="bg-white/70 dark:bg-slate-900/70 backdrop-blur-md border border-slate-200/60 dark:border-slate-800/60 rounded-2xl p-6 shadow-sm hover:border-emerald-500/50 hover:shadow-md transition-all group cursor-pointer flex flex-col justify-between"
      >
        <div class="flex items-start justify-between">
          <div>
            <p class="text-[11px] font-extrabold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              {{ periodDisplayLabel }} Collections
            </p>
            <p class="text-2xl font-black text-slate-900 dark:text-white mt-1 tabular-nums">
              ₹{{ formatAmount(financialOverview.cash_collected || financialOverview.total_sales || 0) }}
            </p>
          </div>
          <div class="w-11 h-11 rounded-2xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20 flex items-center justify-center shadow-xs">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
          </div>
        </div>
        <p class="text-xs font-semibold text-slate-400 dark:text-slate-500 mt-4 group-hover:text-emerald-600 dark:group-hover:text-emerald-400 flex items-center justify-between transition-colors">
          <span>Cash & online payments collected</span>
          <span class="group-hover:translate-x-1 transition-transform">→</span>
        </p>
      </router-link>

      <!-- Card 2: Active Repairs -->
      <router-link
        to="/repairs"
        class="bg-white/70 dark:bg-slate-900/70 backdrop-blur-md border border-slate-200/60 dark:border-slate-800/60 rounded-2xl p-6 shadow-sm hover:border-sky-500/50 hover:shadow-md transition-all group cursor-pointer flex flex-col justify-between"
      >
        <div class="flex items-start justify-between">
          <div>
            <p class="text-[11px] font-extrabold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              {{ periodDisplayLabel }} Repairs
            </p>
            <p class="text-2xl font-black text-slate-900 dark:text-white mt-1 tabular-nums">
              {{ repairStats.active_repairs_count || 0 }}
            </p>
          </div>
          <div class="w-11 h-11 rounded-2xl bg-sky-500/10 text-sky-600 dark:text-sky-400 border border-sky-500/20 flex items-center justify-center shadow-xs">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path></svg>
          </div>
        </div>
        <p class="text-xs font-semibold text-slate-400 dark:text-slate-500 mt-4 group-hover:text-sky-600 dark:group-hover:text-sky-400 flex items-center justify-between transition-colors">
          <span>{{ repairStats.ready_count || 0 }} ready for pickup • {{ repairStats.total_repairs_count || 0 }} total</span>
          <span class="group-hover:translate-x-1 transition-transform">→</span>
        </p>
      </router-link>

      <!-- Card 3: Net Profit -->
      <router-link
        to="/reports"
        class="bg-white/70 dark:bg-slate-900/70 backdrop-blur-md border border-slate-200/60 dark:border-slate-800/60 rounded-2xl p-6 shadow-sm hover:border-indigo-500/50 hover:shadow-md transition-all group cursor-pointer flex flex-col justify-between"
      >
        <div class="flex items-start justify-between">
          <div>
            <p class="text-[11px] font-extrabold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              {{ periodDisplayLabel }} Net Profit
            </p>
            <p class="text-2xl font-black text-slate-900 dark:text-white mt-1 tabular-nums">
              ₹{{ formatAmount(financialOverview.net_profit || 0) }}
            </p>
          </div>
          <div class="w-11 h-11 rounded-2xl bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 border border-indigo-500/20 flex items-center justify-center shadow-xs">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"></path></svg>
          </div>
        </div>
        <p class="text-xs font-semibold text-slate-400 dark:text-slate-500 mt-4 group-hover:text-indigo-600 dark:group-hover:text-indigo-400 flex items-center justify-between transition-colors">
          <span>Profit margin: {{ salesStats.profit_margin || 0 }}%</span>
          <span class="group-hover:translate-x-1 transition-transform">→</span>
        </p>
      </router-link>

      <!-- Card 4: Total Customers -->
      <router-link
        to="/customers"
        class="bg-white/70 dark:bg-slate-900/70 backdrop-blur-md border border-slate-200/60 dark:border-slate-800/60 rounded-2xl p-6 shadow-sm hover:border-amber-500/50 hover:shadow-md transition-all group cursor-pointer flex flex-col justify-between"
      >
        <div class="flex items-start justify-between">
          <div>
            <p class="text-[11px] font-extrabold uppercase tracking-wider text-slate-500 dark:text-slate-400">Total Customers</p>
            <p class="text-2xl font-black text-slate-900 dark:text-white mt-1 tabular-nums">
              {{ totalCustomersCount || 0 }}
            </p>
          </div>
          <div class="w-11 h-11 rounded-2xl bg-amber-500/10 text-amber-600 dark:text-amber-400 border border-amber-500/20 flex items-center justify-center shadow-xs">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
          </div>
        </div>
        <p class="text-xs font-semibold text-slate-400 dark:text-slate-500 mt-4 group-hover:text-amber-600 dark:group-hover:text-amber-400 flex items-center justify-between transition-colors">
          <span>Registered customer profiles</span>
          <span class="group-hover:translate-x-1 transition-transform">→</span>
        </p>
      </router-link>

      <!-- Card 5: Inventory Stock Items -->
      <router-link
        to="/inventory"
        class="bg-white/70 dark:bg-slate-900/70 backdrop-blur-md border border-slate-200/60 dark:border-slate-800/60 rounded-2xl p-6 shadow-sm hover:border-purple-500/50 hover:shadow-md transition-all group cursor-pointer flex flex-col justify-between"
      >
        <div class="flex items-start justify-between">
          <div>
            <p class="text-[11px] font-extrabold uppercase tracking-wider text-slate-500 dark:text-slate-400">Inventory Stock</p>
            <p class="text-2xl font-black text-slate-900 dark:text-white mt-1 tabular-nums">
              {{ inventoryStats.total_items || 0 }} Items
            </p>
          </div>
          <div class="w-11 h-11 rounded-2xl bg-purple-500/10 text-purple-600 dark:text-purple-400 border border-purple-500/20 flex items-center justify-center shadow-xs">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"></path></svg>
          </div>
        </div>
        <p class="text-xs font-semibold text-slate-400 dark:text-slate-500 mt-4 group-hover:text-purple-600 dark:group-hover:text-purple-400 flex items-center justify-between transition-colors">
          <span>Stock value: ₹{{ formatAmount(inventoryStats.total_stock_value || 0) }}</span>
          <span class="group-hover:translate-x-1 transition-transform">→</span>
        </p>
      </router-link>

      <!-- Card 6: Period Total Sales -->
      <router-link
        to="/sales"
        class="bg-white/70 dark:bg-slate-900/70 backdrop-blur-md border border-slate-200/60 dark:border-slate-800/60 rounded-2xl p-6 shadow-sm hover:border-rose-500/50 hover:shadow-md transition-all group cursor-pointer flex flex-col justify-between"
      >
        <div class="flex items-start justify-between">
          <div>
            <p class="text-[11px] font-extrabold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              {{ periodDisplayLabel }} Total Sales
            </p>
            <p class="text-2xl font-black text-slate-900 dark:text-white mt-1 tabular-nums">
              ₹{{ formatAmount(financialOverview.total_sales || salesStats.total_sales || 0) }}
            </p>
          </div>
          <div class="w-11 h-11 rounded-2xl bg-rose-500/10 text-rose-600 dark:text-rose-400 border border-rose-500/20 flex items-center justify-center shadow-xs">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"></path></svg>
          </div>
        </div>
        <p class="text-xs font-semibold text-slate-400 dark:text-slate-500 mt-4 group-hover:text-rose-600 dark:group-hover:text-rose-400 flex items-center justify-between transition-colors">
          <span>{{ salesStats.total_count || 0 }} invoices billed</span>
          <span class="group-hover:translate-x-1 transition-transform">→</span>
        </p>
      </router-link>
    </div>

    <!-- 6. TWO-COLUMN LAYOUT: RECENT REPAIRS & RECENT SALES -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Recent Repairs Card -->
      <div class="bg-white/70 dark:bg-slate-900/70 backdrop-blur-md border border-slate-200/60 dark:border-slate-800/60 rounded-2xl overflow-hidden shadow-sm hover:shadow-md transition-all">
        <div class="p-5 border-b border-slate-200/60 dark:border-slate-800/60 flex items-center justify-between">
          <div class="flex items-center gap-2.5">
            <div class="w-8 h-8 rounded-xl bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 flex items-center justify-center">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path></svg>
            </div>
            <div>
              <h3 class="text-sm font-bold text-slate-900 dark:text-white">Recent Repair Jobs</h3>
              <p class="text-[11px] text-slate-400">Latest device intakes and service orders</p>
            </div>
          </div>
          <router-link to="/repairs" class="text-xs font-bold text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 flex items-center gap-1">
            <span>View All</span>
            <span>→</span>
          </router-link>
        </div>

        <div v-if="loading" class="p-8 text-center text-xs text-slate-400 font-semibold">
          Loading repairs...
        </div>
        <div v-else-if="recentRepairs.length === 0" class="p-8 text-center text-slate-400 text-xs">
          <p>No recent repair jobs matching criteria.</p>
          <router-link to="/repairs/new" class="text-indigo-600 font-bold text-xs mt-2 inline-block">Create first repair job →</router-link>
        </div>
        <div v-else class="divide-y divide-slate-100 dark:divide-slate-800/60">
          <router-link
            v-for="repair in recentRepairs"
            :key="repair.id"
            :to="`/repairs/${repair.id}`"
            class="flex items-center justify-between p-4 hover:bg-slate-50 dark:hover:bg-slate-800/40 transition-colors cursor-pointer group"
          >
            <div class="min-w-0 flex-1 pr-3">
              <div class="flex items-center gap-2">
                <span class="text-xs font-black text-slate-900 dark:text-white group-hover:text-indigo-600 dark:group-hover:text-indigo-400 transition-colors">
                  #{{ repair.job_number || repair.jobNumber || ('JOB-' + String(repair.id).padStart(6, '0')) }}
                </span>
                <span class="text-xs font-semibold text-slate-700 dark:text-slate-300 truncate">
                  {{ repair.customer?.name || repair.customer_name || 'Walk-in Customer' }}
                </span>
              </div>
              <p class="text-[11px] text-slate-400 mt-0.5 truncate">
                {{ repair.device?.model || repair.device?.brand || repair.device_model || 'Device Repair' }}
                <span v-if="repair.problem_description" class="text-slate-400"> • {{ repair.problem_description }}</span>
              </p>
            </div>

            <!-- Right Side: Amount & Visible Status Pill (Fixed empty pill bug) -->
            <div class="text-right flex flex-col items-end gap-1 shrink-0">
              <span class="text-xs font-black text-slate-900 dark:text-white tabular-nums">
                ₹{{ formatAmount(repair.final_cost || repair.estimated_cost || 0) }}
              </span>
              <span :class="getStatusBadgeClass(repair.repair_status || repair.status)">
                {{ getStatusLabel(repair.repair_status || repair.status) }}
              </span>
            </div>
          </router-link>
        </div>
      </div>

      <!-- Recent Sales Card -->
      <div class="bg-white/70 dark:bg-slate-900/70 backdrop-blur-md border border-slate-200/60 dark:border-slate-800/60 rounded-2xl overflow-hidden shadow-sm hover:shadow-md transition-all">
        <div class="p-5 border-b border-slate-200/60 dark:border-slate-800/60 flex items-center justify-between">
          <div class="flex items-center gap-2.5">
            <div class="w-8 h-8 rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"></path></svg>
            </div>
            <div>
              <h3 class="text-sm font-bold text-slate-900 dark:text-white">Recent Sales & Invoices</h3>
              <p class="text-[11px] text-slate-400">Latest customer bills and counter sales</p>
            </div>
          </div>
          <router-link to="/sales" class="text-xs font-bold text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 flex items-center gap-1">
            <span>View All</span>
            <span>→</span>
          </router-link>
        </div>

        <div v-if="loading" class="p-8 text-center text-xs text-slate-400 font-semibold">
          Loading sales...
        </div>
        <div v-else-if="recentSales.length === 0" class="p-8 text-center text-slate-400 text-xs">
          <p>No recent sales invoices.</p>
          <router-link to="/sales/new" class="text-indigo-600 font-bold text-xs mt-2 inline-block">Create first sale invoice →</router-link>
        </div>
        <div v-else class="divide-y divide-slate-100 dark:divide-slate-800/60">
          <router-link
            v-for="sale in recentSales"
            :key="sale.id"
            :to="`/sales/${sale.id}`"
            class="flex items-center justify-between p-4 hover:bg-slate-50 dark:hover:bg-slate-800/40 transition-colors cursor-pointer group"
          >
            <div class="min-w-0 flex-1 pr-3">
              <div class="flex items-center gap-2">
                <span class="text-xs font-black text-slate-900 dark:text-white group-hover:text-emerald-600 dark:group-hover:text-emerald-400 transition-colors">
                  #{{ sale.invoice_number || sale.invoiceNumber || ('INV-' + String(sale.id).padStart(6, '0')) }}
                </span>
                <span class="text-xs font-semibold text-slate-700 dark:text-slate-300 truncate">
                  {{ sale.customer?.name || sale.customer_name || 'Walk-in Customer' }}
                </span>
              </div>
              <p class="text-[11px] text-slate-400 mt-0.5">
                {{ sale.items_count || (sale.items?.length || 1) }} items • {{ formatDate(sale.sale_date || sale.created_at) }}
              </p>
            </div>

            <!-- Right Side: Amount & Payment Status -->
            <div class="text-right flex flex-col items-end gap-1 shrink-0">
              <span class="text-xs font-black text-slate-900 dark:text-white tabular-nums">
                ₹{{ formatAmount(sale.grand_total || sale.total_amount || 0) }}
              </span>
              <span
                v-if="Number(sale.amount_due) > 0"
                class="px-2 py-0.5 rounded text-[10px] font-extrabold uppercase bg-rose-500/10 text-rose-600 dark:text-rose-400 border border-rose-500/20"
              >
                Due: ₹{{ formatAmount(sale.amount_due) }}
              </span>
              <span
                v-else
                class="px-2 py-0.5 rounded text-[10px] font-extrabold uppercase bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20"
              >
                Paid Full
              </span>
            </div>
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '@/stores/auth';
import { useFilterStore } from '@/stores/filter';
import { dashboardApi, repairApi, saleApi, customerApi } from '@/api/endpoints';
import SearchableSelect from '@/components/common/SearchableSelect.vue';

const router = useRouter();
const authStore = useAuthStore();
const filterStore = useFilterStore();

const loading = ref(true);
const dashboardData = ref({});
const recentRepairs = ref([]);
const recentSales = ref([]);
const totalCustomersCount = ref(0);

const quickSearch = ref('');

// Live Clock implementation
const currentClockTime = ref('');
const formattedTodayDate = ref('');
let clockTimer = null;

function updateClock() {
  const now = new Date();
  const timeOptions = { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true };
  const dateOptions = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
  currentClockTime.value = now.toLocaleTimeString('en-US', timeOptions);
  formattedTodayDate.value = now.toLocaleDateString('en-US', dateOptions);
}

const ownerName = computed(() => {
  const name = authStore.user?.name || authStore.shop?.owner_name || dashboardData.value?.owner_name || 'Owner';
  return name.split(' ')[0];
});

const greeting = computed(() => {
  const hour = new Date().getHours();
  if (hour < 12) return 'Morning';
  if (hour < 17) return 'Afternoon';
  return 'Evening';
});

const periodDisplayLabel = computed(() => filterStore.periodDisplayLabel);

function onPeriodChange() {
  filterStore.setPeriod(filterStore.selectedPeriod);
  fetchDashboardData();
}

function resetFilters() {
  filterStore.setPeriod('this_month');
  fetchDashboardData();
}

const financialOverview = computed(() => {
  return dashboardData.value?.data?.financial_overview || dashboardData.value?.financial_overview || {};
});

const salesStats = computed(() => {
  return dashboardData.value?.data?.sales || dashboardData.value?.sales || {};
});

const repairStats = computed(() => {
  return dashboardData.value?.data?.repairs || dashboardData.value?.repairs || {};
});

const inventoryStats = computed(() => {
  return dashboardData.value?.data?.inventory || dashboardData.value?.inventory || {};
});

const dashboardAttention = computed(() => {
  return dashboardData.value?.data?.attention || dashboardData.value?.attention || [];
});

function handleQuickSearch() {
  const q = quickSearch.value.trim();
  if (q) {
    router.push({ path: '/repairs', query: { search: q } });
  }
}

function formatAmount(amount) {
  const num = Number(amount) || 0;
  return num.toLocaleString('en-IN');
}

function formatDate(dateStr) {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  return d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short' });
}

function getStatusLabel(status) {
  const map = {
    received: 'Received',
    diagnosing: 'Diagnosing',
    waiting_customer: 'Waiting Customer',
    waiting_parts: 'Waiting Parts',
    repairing: 'Repairing',
    ready: 'Ready for Pickup',
    delivered: 'Delivered',
    cancelled: 'Cancelled',
    pending: 'Pending',
    in_progress: 'In Progress',
    completed: 'Completed',
  };
  return map[status] || status || 'Received';
}

function getStatusBadgeClass(status) {
  const s = String(status || '').toLowerCase();
  if (s.includes('delivered') || s.includes('completed')) {
    return 'px-2 py-0.5 rounded text-[10px] font-extrabold uppercase bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20';
  }
  if (s.includes('ready')) {
    return 'px-2 py-0.5 rounded text-[10px] font-extrabold uppercase bg-teal-500/10 text-teal-600 dark:text-teal-400 border border-teal-500/20';
  }
  if (s.includes('repairing') || s.includes('progress') || s.includes('diagnos')) {
    return 'px-2 py-0.5 rounded text-[10px] font-extrabold uppercase bg-sky-500/10 text-sky-600 dark:text-sky-400 border border-sky-500/20';
  }
  if (s.includes('waiting')) {
    return 'px-2 py-0.5 rounded text-[10px] font-extrabold uppercase bg-amber-500/10 text-amber-600 dark:text-amber-400 border border-amber-500/20';
  }
  if (s.includes('cancel')) {
    return 'px-2 py-0.5 rounded text-[10px] font-extrabold uppercase bg-rose-500/10 text-rose-600 dark:text-rose-400 border border-rose-500/20';
  }
  return 'px-2 py-0.5 rounded text-[10px] font-extrabold uppercase bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 border border-indigo-500/20';
}

async function fetchDashboardData() {
  loading.value = true;
  try {
    const periodVal = filterStore.selectedPeriod;
    const params = periodVal ? { period: periodVal } : {};
    const [dashRes, repairRes, saleRes, custRes] = await Promise.all([
      dashboardApi.get(params).catch(() => ({ data: { data: {} } })),
      repairApi.list({
        per_page: 6,
        period: periodVal !== 'all_time' ? periodVal : undefined,
      }).catch(() => ({ data: { data: { data: [] } } })),
      saleApi.list({
        per_page: 6,
        period: periodVal !== 'all_time' ? periodVal : undefined,
      }).catch(() => ({ data: { data: { data: [] } } })),
      customerApi.list({ per_page: 1 }).catch(() => ({ data: { meta: { total: 0 } } })),
    ]);

    dashboardData.value = dashRes.data || {};
    recentRepairs.value = repairRes.data?.data?.data || repairRes.data?.data || [];
    recentSales.value = saleRes.data?.data?.data || saleRes.data?.data || [];
    totalCustomersCount.value = custRes.data?.meta?.total || custRes.data?.total || 0;
  } catch (err) {
    console.error('Failed to load dashboard:', err);
  } finally {
    loading.value = false;
  }
}

onMounted(() => {
  updateClock();
  clockTimer = setInterval(updateClock, 1000);
  fetchDashboardData();
});

onBeforeUnmount(() => {
  if (clockTimer) clearInterval(clockTimer);
});
</script>
