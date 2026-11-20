<template>
  <div class="space-y-6 pb-12 transition-colors duration-200">
    <!-- 1. HERO / TOP CONTROL PANEL -->
    <div class="relative z-10 bg-white/70 dark:bg-slate-900/70 backdrop-blur-md border border-slate-200/60 dark:border-slate-800/60 rounded-2xl p-5 sm:p-6 shadow-sm flex flex-col lg:flex-row justify-between items-start lg:items-center gap-5 transition-all">
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
            Shop ID: #{{ authStore.shop?.id || dashboardData.shop_id || '1' }}
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

        <!-- Profit Privacy Toggle (Matching Mobile App Counter Mode) -->
        <button
          @click="showProfits = !showProfits"
          type="button"
          :title="showProfits ? 'Hide profits (Counter Mode)' : 'Show profits'"
          class="px-3 py-2 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 hover:bg-slate-100 dark:hover:bg-slate-900 rounded-xl text-xs font-bold text-slate-600 dark:text-slate-300 flex items-center gap-1.5 transition-all cursor-pointer shadow-xs shrink-0"
        >
          <svg v-if="showProfits" class="w-4 h-4 text-emerald-600 dark:text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
          <svg v-else class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l18 18"/></svg>
          <span>{{ showProfits ? 'Profit Visible' : 'Profits Hidden' }}</span>
        </button>

        <!-- Live Ticking Clock -->
        <div class="bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 px-3.5 py-2 rounded-xl flex items-center gap-2.5 shrink-0 shadow-xs">
          <svg class="w-4 h-4 text-indigo-500 dark:text-indigo-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
          <div class="text-[11px] leading-tight font-extrabold text-slate-600 dark:text-slate-300">
            <div>{{ formattedTodayDate }}</div>
            <div class="text-indigo-600 dark:text-indigo-400 tabular-nums font-black">{{ currentClockTime }}</div>
          </div>
        </div>
      </div>
    </div>

    <!-- 2. QUICK ACTION SHORTCUTS (Fast creation buttons matching mobile app) -->
    <div class="space-y-2">
      <div class="flex items-center justify-between">
        <h2 class="text-xs font-extrabold uppercase tracking-wider text-slate-500 dark:text-slate-400 flex items-center gap-1.5">
          <svg class="w-3.5 h-3.5 text-indigo-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M13 10V3L4 14h7v7l9-11h-7z"/></svg>
          Quick Actions
        </h2>
        <span class="text-[11px] text-slate-400">Tap to create or jump directly to daily operations</span>
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
          Add Expense (Kharcha)
        </router-link>

        <router-link
          to="/used-mobiles"
          class="inline-flex items-center gap-2 px-3.5 py-2.5 rounded-xl text-xs font-bold text-slate-700 dark:text-slate-200 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 hover:border-sky-500 shadow-xs transition-all shrink-0 active:scale-95 cursor-pointer"
        >
          <svg class="w-4 h-4 text-sky-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"/></svg>
          Used Mobiles (Buy/Sell)
        </router-link>

        <router-link
          to="/customers"
          class="inline-flex items-center gap-2 px-3.5 py-2.5 rounded-xl text-xs font-bold text-slate-700 dark:text-slate-200 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 hover:border-indigo-500 shadow-xs transition-all shrink-0 active:scale-95 cursor-pointer"
        >
          <svg class="w-4 h-4 text-indigo-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z"></path></svg>
          Customers & Khata
        </router-link>

        <router-link
          to="/reports"
          class="inline-flex items-center gap-2 px-3.5 py-2.5 rounded-xl text-xs font-bold text-slate-700 dark:text-slate-200 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 hover:border-emerald-500 shadow-xs transition-all shrink-0 active:scale-95 cursor-pointer"
        >
          <svg class="w-4 h-4 text-emerald-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path></svg>
          Reports & Profit Hub
        </router-link>
      </div>
    </div>

    <!-- 3. DASHBOARD ANALYTICS PERIOD FILTER -->
    <div class="relative z-30 bg-white/70 dark:bg-slate-900/70 backdrop-blur-md border border-slate-200/60 dark:border-slate-800/60 rounded-2xl p-4 shadow-sm flex flex-wrap items-center justify-between gap-4 transition-all">
      <div class="flex items-center gap-2 text-xs font-black uppercase tracking-wider text-slate-700 dark:text-slate-300">
        <svg class="w-4 h-4 text-indigo-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z"></path></svg>
        <span>Shop Analytics Period:</span>
        <span class="text-xs font-extrabold text-indigo-600 dark:text-indigo-400 capitalize">{{ periodDisplayLabel }}</span>
        <span class="text-[11px] font-normal text-slate-400 lowercase hidden sm:inline">(updates all sales, repairs & shop profit metrics)</span>
      </div>

      <div class="flex flex-wrap items-center gap-3">
        <SearchableSelect
          v-model="filterStore.selectedPeriod"
          :options="filterStore.periodOptions"
          @change="onPeriodChange"
          placeholder="Select Period"
          searchPlaceholder="Search period..."
          minWidth="160px"
          alignRight
        />

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

    <!-- 4. NEEDS ATTENTION ALERT STRIP (Matching Mobile App Warnings) -->
    <div v-if="dashboardAttention.length > 0" class="p-4 bg-amber-500/10 border border-amber-500/20 rounded-2xl space-y-2.5">
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-2">
          <svg class="w-4 h-4 text-amber-600 dark:text-amber-400 animate-pulse" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
          <h3 class="text-xs font-extrabold uppercase tracking-wider text-amber-900 dark:text-amber-200">Needs Attention</h3>
        </div>
        <span class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-200/60 dark:bg-amber-900/40 text-amber-900 dark:text-amber-200">
          {{ dashboardAttention.length }} items
        </span>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-2.5">
        <div
          v-for="(item, idx) in dashboardAttention"
          :key="idx"
          class="p-3 rounded-xl bg-white/80 dark:bg-slate-900/80 border border-amber-200/60 dark:border-amber-800/40 flex items-center justify-between text-xs"
        >
          <div class="flex items-center gap-2 truncate">
            <span class="w-2 h-2 rounded-full bg-amber-500 shrink-0"></span>
            <div class="truncate">
              <span class="font-bold text-slate-800 dark:text-slate-200 block truncate">{{ item.title || item.message || item }}</span>
              <span v-if="item.subtitle" class="text-[10px] text-slate-400 block truncate">{{ item.subtitle }}</span>
            </div>
          </div>
          <router-link
            v-if="resolveAttentionLink(item)"
            :to="resolveAttentionLink(item)"
            class="text-[11px] font-bold text-amber-700 dark:text-amber-400 hover:underline shrink-0 ml-2"
          >
            Review →
          </router-link>
        </div>
      </div>
    </div>

    <!-- 5. FINANCIAL OVERVIEW HERO CARD (Clean Web Portal Card Style) -->
    <div class="bg-white/80 dark:bg-slate-900/80 backdrop-blur-md border border-slate-200/80 dark:border-slate-800/80 rounded-2xl sm:rounded-3xl p-6 sm:p-7 shadow-xs space-y-6 transition-all">
      <!-- Top Row: Title, Profit Badge, Reports Link -->
      <div class="flex flex-wrap items-center justify-between gap-3">
        <div class="flex items-center gap-3">
          <div class="w-10 h-10 rounded-2xl bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 border border-indigo-500/20 flex items-center justify-center shadow-xs">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"/></svg>
          </div>
          <div>
            <h2 class="text-base font-black text-slate-900 dark:text-white tracking-tight">Net Profit & Financial Overview</h2>
            <p class="text-xs text-slate-400 mt-0.5">Showing consolidated financials for <span class="font-bold text-slate-700 dark:text-slate-300">{{ periodDisplayLabel }}</span></p>
          </div>
        </div>

        <div class="flex items-center gap-2.5">
          <span
            class="px-3 py-1 rounded-full text-xs font-black tracking-wide uppercase border flex items-center gap-1.5"
            :class="isNetProfitPositive
              ? 'bg-emerald-50 dark:bg-emerald-950/60 text-emerald-700 dark:text-emerald-300 border-emerald-200 dark:border-emerald-800/60'
              : 'bg-rose-50 dark:bg-rose-950/60 text-rose-700 dark:text-rose-300 border-rose-200 dark:border-rose-800/60'"
          >
            <span class="w-1.5 h-1.5 rounded-full" :class="isNetProfitPositive ? 'bg-emerald-500' : 'bg-rose-500'"></span>
            <span>{{ isNetProfitPositive ? 'Net Profitable' : 'Net Loss' }}</span>
          </span>

          <router-link
            to="/reports"
            class="inline-flex items-center gap-1.5 text-xs font-bold text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 px-3 py-1.5 rounded-xl bg-indigo-50 dark:bg-indigo-950/40 border border-indigo-100 dark:border-indigo-900/40 transition"
          >
            <span>Full P&L Reports</span>
            <span>→</span>
          </router-link>
        </div>
      </div>

      <!-- Main Net Profit Hero Number -->
      <div class="flex flex-col sm:flex-row sm:items-end justify-between gap-4 pt-1">
        <div>
          <span class="text-xs font-bold text-slate-400 uppercase tracking-wider block">Total Net Profit (Repairs + POS Sales + Used Mobiles)</span>
          <div class="flex items-baseline gap-3 mt-1">
            <span
              class="text-3xl sm:text-4xl font-black tabular-nums tracking-tight"
              :class="isNetProfitPositive ? 'text-emerald-600 dark:text-emerald-400' : 'text-rose-600 dark:text-rose-400'"
            >
              {{ showProfits ? `₹${formatAmount(financialOverview.net_profit || 0)}` : '••••••••' }}
            </span>
            <span v-if="salesStats.profit_margin" class="text-xs font-bold px-2 py-0.5 rounded-md bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 border border-emerald-200/60">
              {{ salesStats.profit_margin }}% margin
            </span>
          </div>
          <p class="text-xs text-slate-400 mt-1 font-medium">Realized net earnings after spare parts, technician payouts and shop overheads</p>
        </div>

        <div class="text-left sm:text-right p-3 sm:p-0 rounded-xl bg-slate-50 sm:bg-transparent dark:bg-slate-950/50 sm:dark:bg-transparent">
          <span class="text-xs font-bold text-slate-400 uppercase tracking-wider block">Net Cash Position</span>
          <p
            class="text-xl sm:text-2xl font-black tabular-nums mt-0.5"
            :class="Number(financialOverview.net_cash_remaining) >= 0 ? 'text-slate-900 dark:text-white' : 'text-rose-600 dark:text-rose-400'"
          >
            ₹{{ formatAmount(financialOverview.net_cash_remaining ?? (financialOverview.cash_collected - (financialOverview.total_expenses || 0))) }}
          </p>
          <span class="text-[11px] text-slate-400">Cash collected minus expenses</span>
        </div>
      </div>

      <!-- 3-Column Profit Source Sub-cards (Clean Web Portal Style) -->
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-3.5">
        <!-- Repair Profit Card -->
        <div class="bg-amber-50/40 dark:bg-amber-950/20 border border-amber-200/60 dark:border-amber-900/30 rounded-2xl p-4 flex items-center justify-between">
          <div>
            <span class="text-[11px] font-bold text-amber-700 dark:text-amber-400 flex items-center gap-1.5 uppercase tracking-wider">
              <span>🔧</span>
              <span>Repair Profit</span>
            </span>
            <p class="text-xl font-black text-slate-900 dark:text-white tabular-nums mt-1">
              {{ showProfits ? `₹${formatAmount(financialOverview.repair_earnings ?? financialOverview.repair_net_profit ?? 0)}` : '••••' }}
            </p>
            <span class="text-[10px] text-slate-400 mt-0.5 block">After parts & tech payouts</span>
          </div>
          <router-link to="/repairs" class="text-xs font-bold text-amber-600 dark:text-amber-400 hover:text-amber-700 shrink-0">
            View →
          </router-link>
        </div>

        <!-- Sales Profit Card -->
        <div class="bg-emerald-50/40 dark:bg-emerald-950/20 border border-emerald-200/60 dark:border-emerald-900/30 rounded-2xl p-4 flex items-center justify-between">
          <div>
            <span class="text-[11px] font-bold text-emerald-700 dark:text-emerald-400 flex items-center gap-1.5 uppercase tracking-wider">
              <span>💰</span>
              <span>Sales & POS Profit</span>
            </span>
            <p class="text-xl font-black text-slate-900 dark:text-white tabular-nums mt-1">
              {{ showProfits ? `₹${formatAmount(financialOverview.sales_profit || 0)}` : '••••' }}
            </p>
            <span class="text-[10px] text-slate-400 mt-0.5 block">Counter items & accessories</span>
          </div>
          <router-link to="/sales" class="text-xs font-bold text-emerald-600 dark:text-emerald-400 hover:text-emerald-700 shrink-0">
            View →
          </router-link>
        </div>

        <!-- Used Mobiles Profit Card -->
        <div class="bg-sky-50/40 dark:bg-sky-950/20 border border-sky-200/60 dark:border-sky-900/30 rounded-2xl p-4 flex items-center justify-between">
          <div>
            <span class="text-[11px] font-bold text-sky-700 dark:text-sky-400 flex items-center gap-1.5 uppercase tracking-wider">
              <span>📱</span>
              <span>Used Mob. Profit</span>
            </span>
            <p class="text-xl font-black text-slate-900 dark:text-white tabular-nums mt-1">
              {{ showProfits ? `₹${formatAmount(financialOverview.used_mobile_profit || 0)}` : '••••' }}
            </p>
            <span class="text-[10px] text-slate-400 mt-0.5 block">Second-hand phone margins</span>
          </div>
          <router-link to="/used-mobiles" class="text-xs font-bold text-sky-600 dark:text-sky-400 hover:text-sky-700 shrink-0">
            View →
          </router-link>
        </div>
      </div>

      <!-- 4-Column Cash Flow & Settlements Strip -->
      <div class="p-3.5 rounded-2xl bg-slate-50 dark:bg-slate-950/60 border border-slate-200/60 dark:border-slate-800/60 grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs">
        <div>
          <span class="text-[11px] text-slate-400 block font-medium">Total Sales Volume</span>
          <span class="font-extrabold text-slate-900 dark:text-white tabular-nums text-sm">
            ₹{{ formatAmount(financialOverview.total_sales || salesStats.total_sales || 0) }}
          </span>
        </div>
        <div>
          <span class="text-[11px] text-slate-400 block font-medium">Collected Cash / UPI</span>
          <span class="font-extrabold text-emerald-600 dark:text-emerald-400 tabular-nums text-sm">
            ₹{{ formatAmount(financialOverview.cash_collected || salesStats.total_collected || 0) }}
          </span>
        </div>
        <div>
          <span class="text-[11px] text-slate-400 block font-medium">Expenses & Purchases</span>
          <span class="font-extrabold text-rose-600 dark:text-rose-400 tabular-nums text-sm">
            ₹{{ formatAmount((financialOverview.total_expenses || expenseStats.total_expenses_sum || 0) + (financialOverview.total_purchases || purchaseStats.total_purchases || 0)) }}
          </span>
        </div>
        <div>
          <span class="text-[11px] text-slate-400 block font-medium">Net Cash Remaining</span>
          <span
            class="font-extrabold tabular-nums text-sm"
            :class="Number(financialOverview.net_cash_remaining) >= 0 ? 'text-slate-900 dark:text-white' : 'text-rose-600 dark:text-rose-400'"
          >
            ₹{{ formatAmount(financialOverview.net_cash_remaining ?? (financialOverview.cash_collected - (financialOverview.total_expenses || 0))) }}
          </span>
        </div>
      </div>
    </div>

    <!-- 6. SHOP PERFORMANCE SUMMARY SECTION (Matching Mobile App Dashboard Hierarchy) -->
    <div class="space-y-4">
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-base sm:text-lg font-black text-slate-900 dark:text-white tracking-tight flex items-center gap-2">
            <span>Shop Performance Summary</span>
          </h2>
          <p class="text-xs text-slate-400">Complete activity breakdown for {{ periodDisplayLabel }} without switching views</p>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <!-- 1. REPAIR SERVICE PERFORMANCE CARD -->
        <div class="bg-white/70 dark:bg-slate-900/70 backdrop-blur-md border border-slate-200/60 dark:border-slate-800/60 rounded-2xl p-5 shadow-sm hover:shadow-md transition-all flex flex-col justify-between">
          <div>
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2.5">
                <div class="w-8 h-8 rounded-xl bg-amber-500/10 text-amber-600 dark:text-amber-400 flex items-center justify-center">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path></svg>
                </div>
                <h3 class="text-sm font-bold text-slate-900 dark:text-white">Repair Jobs & Net Profit</h3>
              </div>
              <router-link to="/repairs" class="text-xs font-bold text-amber-600 dark:text-amber-400 hover:text-amber-700 flex items-center gap-1">
                <span>View All</span>
                <span>→</span>
              </router-link>
            </div>

            <div class="grid grid-cols-3 gap-2 mt-4">
              <div>
                <p class="text-[11px] text-slate-400">Repair Revenue</p>
                <p class="text-xl font-black text-amber-600 dark:text-amber-400 tabular-nums mt-0.5">
                  ₹{{ formatAmount(repairStats.total_earnings || 0) }}
                </p>
              </div>
              <div>
                <p class="text-[11px] text-slate-400">Net Profit</p>
                <p class="text-xl font-black text-emerald-600 dark:text-emerald-400 tabular-nums mt-0.5">
                  {{ showProfits ? `₹${formatAmount(repairStats.net_profit || financialOverview.repair_net_profit || 0)}` : '••••' }}
                </p>
              </div>
              <div class="text-right">
                <p class="text-[11px] text-slate-400">Active Jobs</p>
                <p class="text-xl font-black text-slate-900 dark:text-white tabular-nums mt-0.5">
                  {{ repairStats.active_repairs_count || 0 }}
                </p>
              </div>
            </div>
          </div>

          <!-- Breakdown Sub-row -->
          <div class="mt-4 pt-3 border-t border-slate-100 dark:border-slate-800/80 grid grid-cols-4 gap-2 text-center text-xs">
            <div class="p-1.5 rounded-lg bg-slate-50 dark:bg-slate-950/60">
              <span class="text-[10px] text-slate-400 block">Parts Cost</span>
              <span class="font-bold text-slate-700 dark:text-slate-300 tabular-nums">₹{{ formatAmount(repairStats.parts_cost || 0) }}</span>
            </div>
            <div class="p-1.5 rounded-lg bg-slate-50 dark:bg-slate-950/60">
              <span class="text-[10px] text-slate-400 block">Tech Payout</span>
              <span class="font-bold text-slate-700 dark:text-slate-300 tabular-nums">₹{{ formatAmount(repairStats.technician_cost || 0) }}</span>
            </div>
            <div class="p-1.5 rounded-lg bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300">
              <span class="text-[10px] text-emerald-600/80 dark:text-emerald-400/80 block">Ready Pickup</span>
              <span class="font-black tabular-nums">{{ repairStats.ready_count || 0 }} Jobs</span>
            </div>
            <div class="p-1.5 rounded-lg bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-300">
              <span class="text-[10px] text-rose-600/80 dark:text-rose-400/80 block">Repair Dues</span>
              <span class="font-black tabular-nums">₹{{ formatAmount(repairStats.total_due || 0) }}</span>
            </div>
          </div>
        </div>

        <!-- 2. SALES & COUNTER POS PERFORMANCE CARD -->
        <div class="bg-white/70 dark:bg-slate-900/70 backdrop-blur-md border border-slate-200/60 dark:border-slate-800/60 rounded-2xl p-5 shadow-sm hover:shadow-md transition-all flex flex-col justify-between">
          <div>
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2.5">
                <div class="w-8 h-8 rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"></path></svg>
                </div>
                <h3 class="text-sm font-bold text-slate-900 dark:text-white">Sales & Revenue</h3>
              </div>
              <router-link to="/sales" class="text-xs font-bold text-emerald-600 dark:text-emerald-400 hover:text-emerald-700 flex items-center gap-1">
                <span>View All</span>
                <span>→</span>
              </router-link>
            </div>

            <div class="grid grid-cols-3 gap-2 mt-4">
              <div>
                <p class="text-[11px] text-slate-400">Sales Revenue</p>
                <p class="text-xl font-black text-indigo-600 dark:text-indigo-400 tabular-nums mt-0.5">
                  ₹{{ formatAmount(salesStats.total_sales || 0) }}
                </p>
              </div>
              <div>
                <div class="flex items-center gap-1">
                  <span class="text-[11px] text-slate-400">Sales Profit</span>
                  <span v-if="salesStats.profit_margin > 0" class="px-1.5 py-0.2 rounded text-[9px] font-black bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300">
                    {{ salesStats.profit_margin }}%
                  </span>
                </div>
                <p class="text-xl font-black text-emerald-600 dark:text-emerald-400 tabular-nums mt-0.5">
                  {{ showProfits ? `₹${formatAmount(salesStats.net_profit || 0)}` : '••••' }}
                </p>
              </div>
              <div class="text-right">
                <p class="text-[11px] text-slate-400">Invoices</p>
                <p class="text-xl font-black text-slate-900 dark:text-white tabular-nums mt-0.5">
                  {{ salesStats.total_count || 0 }}
                </p>
              </div>
            </div>
          </div>

          <!-- Breakdown Sub-row -->
          <div class="mt-4 pt-3 border-t border-slate-100 dark:border-slate-800/80 grid grid-cols-3 gap-2 text-center text-xs">
            <div class="p-1.5 rounded-lg bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300">
              <span class="text-[10px] text-emerald-600/80 dark:text-emerald-400/80 block">Collected</span>
              <span class="font-black tabular-nums">₹{{ formatAmount(salesStats.total_collected || 0) }}</span>
            </div>
            <div class="p-1.5 rounded-lg bg-slate-50 dark:bg-slate-950/60">
              <span class="text-[10px] text-slate-400 block">Item Cost</span>
              <span class="font-bold text-slate-700 dark:text-slate-300 tabular-nums">₹{{ formatAmount(salesStats.total_cost || 0) }}</span>
            </div>
            <div class="p-1.5 rounded-lg bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-300">
              <span class="text-[10px] text-rose-600/80 dark:text-rose-400/80 block">Sales Dues</span>
              <span class="font-black tabular-nums">₹{{ formatAmount(salesStats.total_due || 0) }}</span>
            </div>
          </div>
        </div>

        <!-- 3. USED MOBILES (BUY / SELL) PERFORMANCE CARD -->
        <div class="bg-white/70 dark:bg-slate-900/70 backdrop-blur-md border border-slate-200/60 dark:border-slate-800/60 rounded-2xl p-5 shadow-sm hover:shadow-md transition-all flex flex-col justify-between">
          <div>
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2.5">
                <div class="w-8 h-8 rounded-xl bg-sky-500/10 text-sky-600 dark:text-sky-400 flex items-center justify-center">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"/></svg>
                </div>
                <h3 class="text-sm font-bold text-slate-900 dark:text-white">Used Mobiles & Profit</h3>
              </div>
              <router-link to="/used-mobiles" class="text-xs font-bold text-sky-600 dark:text-sky-400 hover:text-sky-700 flex items-center gap-1">
                <span>View All</span>
                <span>→</span>
              </router-link>
            </div>

            <div class="grid grid-cols-2 gap-2 mt-4">
              <div>
                <p class="text-[11px] text-slate-400">Sales Revenue ({{ usedMobileStats.sold_count || 0 }} Sold)</p>
                <p class="text-xl font-black text-sky-600 dark:text-sky-400 tabular-nums mt-0.5">
                  ₹{{ formatAmount(usedMobileStats.total_sales || 0) }}
                </p>
              </div>
              <div>
                <div class="flex items-center gap-1">
                  <span class="text-[11px] text-slate-400">Total Profit</span>
                  <span v-if="usedMobileProfitMargin > 0" class="px-1.5 py-0.2 rounded text-[9px] font-black bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300">
                    {{ usedMobileProfitMargin }}%
                  </span>
                </div>
                <p class="text-xl font-black text-emerald-600 dark:text-emerald-400 tabular-nums mt-0.5">
                  {{ showProfits ? `₹${formatAmount(usedMobileStats.total_profit || 0)}` : '••••' }}
                </p>
              </div>
            </div>
          </div>

          <!-- Stock Strip Sub-row -->
          <div class="mt-4 pt-3 border-t border-slate-100 dark:border-slate-800/80 p-2.5 rounded-xl bg-sky-50/70 dark:bg-sky-950/30 border border-sky-100 dark:border-sky-900/40 flex items-center justify-between text-xs">
            <div class="flex items-center gap-1.5">
              <svg class="w-4 h-4 text-sky-600 dark:text-sky-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/></svg>
              <span class="font-extrabold text-sky-900 dark:text-sky-200">In-Stock: {{ usedMobileStats.in_stock_count || 0 }} Phones</span>
            </div>
            <span class="font-bold text-sky-700 dark:text-sky-300 tabular-nums">Investment: ₹{{ formatAmount(usedMobileStats.in_stock_investment || 0) }}</span>
          </div>
        </div>

        <!-- 4. INVENTORY PURCHASES (STOCK-IN) PERFORMANCE CARD -->
        <div class="bg-white/70 dark:bg-slate-900/70 backdrop-blur-md border border-slate-200/60 dark:border-slate-800/60 rounded-2xl p-5 shadow-sm hover:shadow-md transition-all flex flex-col justify-between">
          <div>
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2.5">
                <div class="w-8 h-8 rounded-xl bg-purple-500/10 text-purple-600 dark:text-purple-400 flex items-center justify-center">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
                </div>
                <h3 class="text-sm font-bold text-slate-900 dark:text-white">Inventory Purchases</h3>
              </div>
              <router-link to="/purchases" class="text-xs font-bold text-purple-600 dark:text-purple-400 hover:text-purple-700 flex items-center gap-1">
                <span>View All</span>
                <span>→</span>
              </router-link>
            </div>

            <div class="grid grid-cols-2 gap-2 mt-4">
              <div>
                <p class="text-[11px] text-slate-400">Total Purchases</p>
                <p class="text-xl font-black text-purple-600 dark:text-purple-400 tabular-nums mt-0.5">
                  ₹{{ formatAmount(purchaseStats.total_purchases || 0) }}
                </p>
              </div>
              <div>
                <p class="text-[11px] text-slate-400">Orders</p>
                <p class="text-xl font-black text-slate-900 dark:text-white tabular-nums mt-0.5">
                  {{ purchaseStats.total_count || 0 }}
                </p>
              </div>
            </div>
          </div>

          <!-- Breakdown Sub-row -->
          <div class="mt-4 pt-3 border-t border-slate-100 dark:border-slate-800/80 grid grid-cols-2 gap-2 text-center text-xs">
            <div class="p-1.5 rounded-lg bg-slate-50 dark:bg-slate-950/60">
              <span class="text-[10px] text-slate-400 block">Amount Paid</span>
              <span class="font-bold text-slate-700 dark:text-slate-300 tabular-nums">₹{{ formatAmount(purchaseStats.total_paid || 0) }}</span>
            </div>
            <div class="p-1.5 rounded-lg bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-300">
              <span class="text-[10px] text-rose-600/80 dark:text-rose-400/80 block">Vendor Dues</span>
              <span class="font-black tabular-nums">₹{{ formatAmount(purchaseStats.total_outstanding || purchaseStats.all_time_vendor_dues || 0) }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Two Side-by-Side Cards: INVENTORY STOCK & SHOP EXPENSES -->
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <!-- Card 5: Inventory Stock -->
        <router-link
          to="/inventory"
          class="bg-white/70 dark:bg-slate-900/70 backdrop-blur-md border border-slate-200/60 dark:border-slate-800/60 rounded-2xl p-5 shadow-sm hover:border-emerald-500/50 hover:shadow-md transition-all group cursor-pointer flex flex-col justify-between"
        >
          <div>
            <div class="flex items-center justify-between">
              <div class="w-8 h-8 rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/></svg>
              </div>
              <div class="flex items-center gap-1.5">
                <span v-if="inventoryStats.low_stock_count > 0" class="px-2 py-0.5 rounded text-[10px] font-extrabold bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-300">
                  {{ inventoryStats.low_stock_count }} Low
                </span>
                <span v-if="inventoryStats.out_of_stock_count > 0" class="px-2 py-0.5 rounded text-[10px] font-extrabold bg-rose-100 text-rose-800 dark:bg-rose-950 dark:text-rose-300">
                  {{ inventoryStats.out_of_stock_count }} Out
                </span>
              </div>
            </div>
            <p class="text-[11px] font-bold text-slate-400 uppercase tracking-wider mt-3">Inventory Valuation</p>
            <p class="text-2xl font-black text-slate-900 dark:text-white tabular-nums mt-0.5">
              ₹{{ formatAmount(inventoryStats.total_stock_value || 0) }}
            </p>
          </div>
          <p class="text-xs text-slate-500 dark:text-slate-400 mt-3 flex items-center justify-between">
            <span>{{ inventoryStats.total_items || 0 }} total spare parts & accessories</span>
            <span class="font-bold text-emerald-600 dark:text-emerald-400 group-hover:translate-x-1 transition-transform">Manage →</span>
          </p>
        </router-link>

        <!-- Card 6: Shop Expenses (Kharcha) -->
        <router-link
          to="/expenses"
          class="bg-white/70 dark:bg-slate-900/70 backdrop-blur-md border border-slate-200/60 dark:border-slate-800/60 rounded-2xl p-5 shadow-sm hover:border-rose-500/50 hover:shadow-md transition-all group cursor-pointer flex flex-col justify-between"
        >
          <div>
            <div class="flex items-center justify-between">
              <div class="w-8 h-8 rounded-xl bg-rose-500/10 text-rose-600 dark:text-rose-400 flex items-center justify-center">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 14l6-6m-5.5.5h.01m4.99 5h.01M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16l3.5-2 3.5 2 3.5-2 3.5 2z"/></svg>
              </div>
              <span v-if="expenseStats.top_category?.name" class="px-2 py-0.5 rounded text-[10px] font-extrabold bg-rose-100 text-rose-800 dark:bg-rose-950 dark:text-rose-300">
                Top: {{ expenseStats.top_category.name }}
              </span>
            </div>
            <p class="text-[11px] font-bold text-slate-400 uppercase tracking-wider mt-3">Shop Expenses (Kharcha)</p>
            <p class="text-2xl font-black text-rose-600 dark:text-rose-400 tabular-nums mt-0.5">
              ₹{{ formatAmount(expenseStats.total_expenses_sum || 0) }}
            </p>
          </div>
          <p class="text-xs text-slate-500 dark:text-slate-400 mt-3 flex items-center justify-between">
            <span>{{ expenseStats.top_category?.name ? `Major spending: ${expenseStats.top_category.name} (₹${formatAmount(expenseStats.top_category.amount)})` : 'Daily overheads, rent, bills' }}</span>
            <span class="font-bold text-rose-600 dark:text-rose-400 group-hover:translate-x-1 transition-transform">View →</span>
          </p>
        </router-link>
      </div>
    </div>

    <!-- 7. RECENT ACTIVITY TIMELINE & DETAILED INTAKES -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- 7A. Recent Activity Stream (Chronological merged feed across shop operations) -->
      <div class="bg-white/70 dark:bg-slate-900/70 backdrop-blur-md border border-slate-200/60 dark:border-slate-800/60 rounded-2xl overflow-hidden shadow-sm hover:shadow-md transition-all flex flex-col">
        <div class="p-5 border-b border-slate-200/60 dark:border-slate-800/60 flex items-center justify-between">
          <div class="flex items-center gap-2.5">
            <div class="w-8 h-8 rounded-xl bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 flex items-center justify-center">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
            </div>
            <div>
              <h3 class="text-sm font-bold text-slate-900 dark:text-white">Recent Shop Activity</h3>
              <p class="text-[11px] text-slate-400">Merged live events timeline</p>
            </div>
          </div>
          <router-link to="/reports" class="text-xs font-bold text-indigo-600 dark:text-indigo-400 hover:text-indigo-700">Audit →</router-link>
        </div>

        <div v-if="loading" class="p-8 text-center text-xs text-slate-400 font-semibold">
          Loading activity stream...
        </div>
        <div v-else-if="recentActivity.length === 0" class="p-8 text-center text-slate-400 text-xs flex-1 flex flex-col justify-center items-center">
          <p>No recent activity recorded.</p>
        </div>
        <div v-else class="divide-y divide-slate-100 dark:divide-slate-800/60 flex-1">
          <div
            v-for="(act, idx) in recentActivity"
            :key="idx"
            class="flex items-center justify-between p-3.5 hover:bg-slate-50 dark:hover:bg-slate-800/40 transition-colors text-xs"
          >
            <div class="flex items-center gap-2.5 min-w-0 pr-2">
              <div
                class="w-7 h-7 rounded-lg flex items-center justify-center shrink-0"
                :class="getActivityTypeBadgeClass(act.type)"
              >
                <span class="text-xs font-bold">{{ getActivityTypeSymbol(act.type) }}</span>
              </div>
              <div class="min-w-0">
                <p class="font-bold text-slate-900 dark:text-white truncate">{{ act.title }}</p>
                <p class="text-[11px] text-slate-400 truncate">{{ act.subtitle }}</p>
              </div>
            </div>
            <div class="text-right shrink-0">
              <p class="font-black text-slate-900 dark:text-white tabular-nums">₹{{ formatAmount(act.amount) }}</p>
              <p class="text-[10px] text-slate-400">{{ act.time }}</p>
            </div>
          </div>
        </div>
      </div>

      <!-- 7B. Recent Repairs Card -->
      <div class="bg-white/70 dark:bg-slate-900/70 backdrop-blur-md border border-slate-200/60 dark:border-slate-800/60 rounded-2xl overflow-hidden shadow-sm hover:shadow-md transition-all flex flex-col">
        <div class="p-5 border-b border-slate-200/60 dark:border-slate-800/60 flex items-center justify-between">
          <div class="flex items-center gap-2.5">
            <div class="w-8 h-8 rounded-xl bg-amber-500/10 text-amber-600 dark:text-amber-400 flex items-center justify-center">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path></svg>
            </div>
            <div>
              <h3 class="text-sm font-bold text-slate-900 dark:text-white">Recent Repair Jobs</h3>
              <p class="text-[11px] text-slate-400">Intakes & service orders</p>
            </div>
          </div>
          <router-link to="/repairs" class="text-xs font-bold text-amber-600 dark:text-amber-400 hover:text-amber-700 flex items-center gap-1">
            <span>View All</span>
            <span>→</span>
          </router-link>
        </div>

        <div v-if="loading" class="p-8 text-center text-xs text-slate-400 font-semibold">
          Loading repairs...
        </div>
        <div v-else-if="recentRepairs.length === 0" class="p-8 text-center text-slate-400 text-xs flex-1 flex flex-col justify-center items-center">
          <p>No repair jobs matching period.</p>
          <router-link to="/repairs/new" class="text-indigo-600 font-bold text-xs mt-2 inline-block">Create first repair job →</router-link>
        </div>
        <div v-else class="divide-y divide-slate-100 dark:divide-slate-800/60 flex-1">
          <router-link
            v-for="repair in recentRepairs"
            :key="repair.id"
            :to="`/repairs/${repair.id}`"
            class="flex items-center justify-between p-3.5 hover:bg-slate-50 dark:hover:bg-slate-800/40 transition-colors cursor-pointer group"
          >
            <div class="min-w-0 flex-1 pr-2">
              <div class="flex items-center gap-1.5">
                <span class="text-xs font-black text-slate-900 dark:text-white group-hover:text-amber-600 dark:group-hover:text-amber-400 transition-colors">
                  #{{ repair.job_number || repair.jobNumber || ('JOB-' + String(repair.id).padStart(6, '0')) }}
                </span>
                <span class="text-xs font-semibold text-slate-700 dark:text-slate-300 truncate">
                  {{ repair.customer?.name || repair.customer_name || 'Walk-in Customer' }}
                </span>
              </div>
              <p class="text-[11px] text-slate-400 mt-0.5 truncate">
                {{ repair.device?.model || repair.device?.brand || repair.device_model || 'Device Repair' }}
              </p>
            </div>

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

      <!-- 7C. Recent Sales Card -->
      <div class="bg-white/70 dark:bg-slate-900/70 backdrop-blur-md border border-slate-200/60 dark:border-slate-800/60 rounded-2xl overflow-hidden shadow-sm hover:shadow-md transition-all flex flex-col">
        <div class="p-5 border-b border-slate-200/60 dark:border-slate-800/60 flex items-center justify-between">
          <div class="flex items-center gap-2.5">
            <div class="w-8 h-8 rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"></path></svg>
            </div>
            <div>
              <h3 class="text-sm font-bold text-slate-900 dark:text-white">Recent Sales & Invoices</h3>
              <p class="text-[11px] text-slate-400">Bills & counter sales</p>
            </div>
          </div>
          <router-link to="/sales" class="text-xs font-bold text-emerald-600 dark:text-emerald-400 hover:text-emerald-700 flex items-center gap-1">
            <span>View All</span>
            <span>→</span>
          </router-link>
        </div>

        <div v-if="loading" class="p-8 text-center text-xs text-slate-400 font-semibold">
          Loading sales...
        </div>
        <div v-else-if="recentSales.length === 0" class="p-8 text-center text-slate-400 text-xs flex-1 flex flex-col justify-center items-center">
          <p>No recent sales invoices.</p>
          <router-link to="/sales/new" class="text-emerald-600 font-bold text-xs mt-2 inline-block">Create first sale invoice →</router-link>
        </div>
        <div v-else class="divide-y divide-slate-100 dark:divide-slate-800/60 flex-1">
          <router-link
            v-for="sale in recentSales"
            :key="sale.id"
            :to="`/sales/${sale.id}`"
            class="flex items-center justify-between p-3.5 hover:bg-slate-50 dark:hover:bg-slate-800/40 transition-colors cursor-pointer group"
          >
            <div class="min-w-0 flex-1 pr-2">
              <div class="flex items-center gap-1.5">
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
import { formatDate } from '@/utils/date';
import SearchableSelect from '@/components/common/SearchableSelect.vue';

const router = useRouter();
const authStore = useAuthStore();
const filterStore = useFilterStore();

const loading = ref(true);
const dashboardData = ref({});
const recentRepairs = ref([]);
const recentSales = ref([]);
const totalCustomersCount = ref(0);
const showProfits = ref(true);

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

const isNetProfitPositive = computed(() => {
  return (Number(financialOverview.value?.net_profit) || 0) >= 0;
});

const salesStats = computed(() => {
  return dashboardData.value?.data?.sales || dashboardData.value?.sales || {};
});

const repairStats = computed(() => {
  return dashboardData.value?.data?.repairs || dashboardData.value?.repairs || {};
});

const usedMobileStats = computed(() => {
  return dashboardData.value?.data?.used_mobiles || dashboardData.value?.used_mobiles || {};
});

const usedMobileProfitMargin = computed(() => {
  const stats = usedMobileStats.value;
  if (stats.profit_margin !== undefined && stats.profit_margin !== null) {
    return Number(stats.profit_margin);
  }
  const sales = Number(stats.total_sales || 0);
  const profit = Number(stats.total_profit || 0);
  return sales > 0 && profit > 0 ? Math.round((profit / sales) * 100) : 0;
});

const purchaseStats = computed(() => {
  return dashboardData.value?.data?.purchases || dashboardData.value?.purchases || {};
});

const inventoryStats = computed(() => {
  return dashboardData.value?.data?.inventory || dashboardData.value?.inventory || {};
});

const expenseStats = computed(() => {
  return dashboardData.value?.data?.expenses || dashboardData.value?.expenses || {};
});

const dashboardAttention = computed(() => {
  return dashboardData.value?.data?.attention || dashboardData.value?.attention || [];
});

const recentActivity = computed(() => {
  return dashboardData.value?.data?.recent_activity || dashboardData.value?.recent_activity || [];
});

function resolveAttentionLink(item) {
  if (item.action_url || item.url) return item.action_url || item.url;
  if (item.action_route === 'inventory') return '/inventory';
  if (item.action_route === 'sales') return '/sales';
  if (item.action_route === 'vendors' || item.action_route === 'purchases') return '/purchases';
  if (item.action_route === 'repairs') return '/repairs';
  return null;
}

function getActivityTypeBadgeClass(type) {
  switch (type) {
    case 'repair':
      return 'bg-amber-100 text-amber-700 dark:bg-amber-950/60 dark:text-amber-300';
    case 'sale':
      return 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-300';
    case 'purchase':
      return 'bg-purple-100 text-purple-700 dark:bg-purple-950/60 dark:text-purple-300';
    case 'expense':
      return 'bg-rose-100 text-rose-700 dark:bg-rose-950/60 dark:text-rose-300';
    case 'used_mobile':
      return 'bg-sky-100 text-sky-700 dark:bg-sky-950/60 dark:text-sky-300';
    default:
      return 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300';
  }
}

function getActivityTypeSymbol(type) {
  switch (type) {
    case 'repair': return '🔧';
    case 'sale': return '💰';
    case 'purchase': return '📦';
    case 'expense': return '🧾';
    case 'used_mobile': return '📱';
    default: return '⚡';
  }
}

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
