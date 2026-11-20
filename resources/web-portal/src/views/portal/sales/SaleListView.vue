<template>
  <div class="space-y-6 font-['Outfit',sans-serif]">
    <!-- Header Actions -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <div class="flex items-center gap-2">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 border border-emerald-200/60 dark:border-emerald-800/60">
            Billing & POS
          </span>
          <span class="text-xs text-slate-400">Invoices, Retail Receipts & Profit</span>
        </div>
        <h1 class="text-2xl font-bold tracking-tight text-slate-900 dark:text-white mt-1">Sales & Invoicing Directory</h1>
        <p class="text-xs sm:text-sm text-slate-500 dark:text-slate-400">Manage device sales, customer bills, outstanding dues, and profit margins.</p>
      </div>
      <div class="flex items-center gap-2.5">
        <router-link
          to="/sales/new"
          class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold shadow-md shadow-indigo-600/20 transition-all hover:scale-[1.02] active:scale-[0.98]"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" d="M12 4v16m8-8H4"/></svg>
          + New Sale / POS Bill
        </router-link>
      </div>
    </div>

    <!-- Summary Metrics (Matching Flutter SalesListScreen) -->
    <div class="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
      <!-- Total Billed -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-sm flex items-center justify-between">
        <div>
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Total Billed</p>
          <p class="text-xl font-extrabold text-slate-900 dark:text-white mt-1">₹{{ formatAmount(summary.total_billed) }}</p>
          <p class="text-[10px] text-slate-400 mt-0.5">{{ summary.total_count }} total invoices billed</p>
        </div>
        <div class="w-11 h-11 rounded-xl bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 flex items-center justify-center shrink-0">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 14l6-6m-5.5.5h.01m4.99 5h.01M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16l3.5-2 3.5 2 3.5-2 3.5 2z"/></svg>
        </div>
      </div>

      <!-- Paid / Collected -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-sm flex items-center justify-between">
        <div>
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Paid / Collected</p>
          <p class="text-xl font-extrabold text-emerald-600 dark:text-emerald-400 mt-1">₹{{ formatAmount(summary.total_paid) }}</p>
          <p class="text-[10px] text-slate-400 mt-0.5">Cash & online receipts</p>
        </div>
        <div class="w-11 h-11 rounded-xl bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center shrink-0">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
        </div>
      </div>

      <!-- Pending Due -->
      <div
        @click="setPaymentStatus(selectedPaymentStatus === 'unpaid' ? '' : 'unpaid')"
        class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-sm flex items-center justify-between cursor-pointer transition-all hover:border-rose-400 hover:shadow-md"
        :class="selectedPaymentStatus === 'unpaid' ? 'ring-2 ring-rose-500 bg-rose-50/20' : ''"
        title="Click to filter dues"
      >
        <div>
          <div class="flex items-center gap-1.5">
            <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Pending Outstanding</p>
            <span v-if="selectedPaymentStatus === 'unpaid'" class="px-1.5 py-0.2 rounded text-[10px] font-bold bg-rose-100 text-rose-700 dark:bg-rose-950 dark:text-rose-400">FILTERED</span>
          </div>
          <p class="text-xl font-extrabold text-rose-600 dark:text-rose-400 mt-1">₹{{ formatAmount(summary.total_due) }}</p>
          <p class="text-[10px] text-slate-400 mt-0.5">Customer balance to collect</p>
        </div>
        <div class="w-11 h-11 rounded-xl bg-rose-50 dark:bg-rose-950/60 text-rose-600 dark:text-rose-400 flex items-center justify-center shrink-0">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
        </div>
      </div>

      <!-- Net Profit Earned -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-sm flex items-center justify-between">
        <div>
          <div class="flex items-center gap-1.5">
            <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Net Profit Earned</p>
            <span v-if="profitMarginPercent > 0" class="px-1.5 py-0.2 rounded text-[10px] font-extrabold bg-emerald-100 dark:bg-emerald-950/60 text-emerald-700 dark:text-emerald-400">
              {{ profitMarginPercent }}%
            </span>
          </div>
          <p :class="summary.total_profit >= 0 ? 'text-emerald-600 dark:text-emerald-400' : 'text-rose-600 dark:text-rose-400'" class="text-xl font-extrabold mt-1">
            {{ summary.total_profit >= 0 ? '+' : '' }}₹{{ formatAmount(summary.total_profit) }}
          </p>
          <p class="text-[10px] text-slate-400 mt-0.5">Item Cost: ₹{{ formatAmount(summary.total_cost) }}</p>
        </div>
        <div class="w-11 h-11 rounded-xl bg-teal-50 dark:bg-teal-950/60 text-teal-600 dark:text-teal-400 flex items-center justify-center shrink-0">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/></svg>
        </div>
      </div>
    </div>

    <!-- Filter & Search Controls Bar -->
    <div class="bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-2xl p-4 shadow-sm space-y-3">
      <!-- Row 1: Search & Period Select -->
      <div class="flex flex-col md:flex-row gap-3 items-stretch md:items-center justify-between">
        <div class="relative flex-1">
          <span class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
          </span>
          <input
            v-model="searchQuery"
            @input="debounceSearch"
            type="text"
            class="w-full pl-10 pr-4 py-2.5 text-xs font-semibold bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 transition-all placeholder-slate-400 text-slate-800 dark:text-slate-100"
            placeholder="Search by Invoice #, Customer name, Phone, Product..."
          />
        </div>

        <div class="flex flex-wrap items-center gap-2">
          <!-- Date Period Dropdown (SearchableSelect with auto dropup) -->
          <SearchableSelect
            v-model="filterStore.selectedPeriod"
            :options="filterStore.periodOptions"
            @change="onPeriodChange"
            placeholder="Select Period"
            searchPlaceholder="Search period..."
            minWidth="140px"
          />

          <!-- Payment Status Dropdown -->
          <SearchableSelect
            v-model="selectedPaymentStatus"
            :options="paymentStatusOptions"
            @change="onStatusChange"
            placeholder="Payment Status"
            searchPlaceholder="Search status..."
            minWidth="160px"
          />

          <!-- Sort Dropdown -->
          <SearchableSelect
            v-model="sortBy"
            :options="sortOptions"
            @change="onSortChange"
            placeholder="Sort Sales"
            searchPlaceholder="Search sort..."
            minWidth="150px"
            prefixIcon="↕️"
          />

          <!-- Reset Button -->
          <button
            v-if="searchQuery || selectedPaymentStatus || selectedSaleType !== 'all' || filterStore.selectedPeriod !== 'this_month' || sortBy !== 'newest'"
            @click="resetFilters"
            type="button"
            class="px-3.5 py-2.5 bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-600 dark:text-slate-300 rounded-xl text-xs font-bold transition-all cursor-pointer flex items-center gap-1.5"
          >
            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
            Reset
          </button>
        </div>
      </div>

      <!-- Row 2: Quick Status & Type Pills -->
      <div class="flex flex-wrap items-center justify-between gap-2 pt-2 border-t border-slate-100 dark:border-slate-800/80">
        <!-- Status Pills -->
        <div class="flex flex-wrap items-center gap-1.5">
          <button
            v-for="st in statusPills"
            :key="st.value"
            @click="setPaymentStatus(st.value)"
            class="px-3 py-1 rounded-xl text-xs font-bold transition-all cursor-pointer flex items-center gap-1.5"
            :class="selectedPaymentStatus === st.value
              ? 'bg-indigo-600 text-white shadow-sm shadow-indigo-500/20'
              : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700'"
          >
            <span>{{ st.label }}</span>
          </button>
        </div>

        <!-- Sale Type Pills -->
        <div class="flex flex-wrap items-center gap-1.5">
          <button
            v-for="tp in typePills"
            :key="tp.value"
            @click="setSaleType(tp.value)"
            class="px-3 py-1 rounded-xl text-xs font-bold transition-all cursor-pointer flex items-center gap-1.5"
            :class="selectedSaleType === tp.value
              ? 'bg-amber-600 text-white shadow-sm shadow-amber-500/20'
              : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700'"
          >
            <span>{{ tp.label }}</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Data Table Card -->
    <div class="bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-2xl overflow-hidden shadow-sm">
      <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="border-b border-slate-100 dark:border-slate-800/80 text-[11px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider bg-slate-50/60 dark:bg-slate-900/40">
              <th class="py-3.5 px-4 pl-6">Invoice # & Date</th>
              <th class="py-3.5 px-4">Customer</th>
              <th class="py-3.5 px-4">Items & Quantity</th>
              <th class="py-3.5 px-4">Bill & Outstanding</th>
              <th class="py-3.5 px-4">Cost & Net Profit</th>
              <th class="py-3.5 px-4">Status</th>
              <th class="py-3.5 px-4 pr-6 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100 dark:divide-slate-800/60 text-sm">
            <tr v-if="loading">
              <td colspan="7" class="py-12 text-center text-xs text-slate-400">
                <div class="inline-block animate-spin w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full mb-2"></div>
                <div>Loading sales records...</div>
              </td>
            </tr>
            <tr v-else-if="sales.length === 0">
              <td colspan="7" class="py-12 text-center text-slate-400 dark:text-slate-500 text-xs">
                No sales records found matching selected period and criteria.
              </td>
            </tr>
            <tr
              v-for="sale in sales"
              :key="sale.id"
              class="hover:bg-slate-50/70 dark:hover:bg-slate-800/40 transition-colors group"
            >
              <!-- Invoice # & Date -->
              <td class="py-3.5 px-4 pl-6">
                <div class="flex items-center gap-1.5">
                  <span
                    v-if="sale.sale_type === 'quick'"
                    class="px-1.5 py-0.5 rounded text-[10px] font-black bg-amber-100 dark:bg-amber-950/60 text-amber-700 dark:text-amber-400"
                    title="Quick POS Sale"
                  >
                    ⚡ QUICK
                  </span>
                  <router-link
                    :to="`/sales/${sale.id}`"
                    class="font-bold font-mono text-indigo-600 dark:text-indigo-400 hover:underline"
                  >
                    #{{ sale.invoice_number || sale.invoice_no || sale.id }}
                  </router-link>
                </div>
                <div class="text-[11px] text-slate-400 mt-0.5">{{ formatDate(sale.sale_date || sale.created_at) }}</div>
              </td>

              <!-- Customer -->
              <td class="py-3.5 px-4">
                <div class="font-bold text-slate-900 dark:text-slate-100 flex items-center gap-1.5">
                  <span>{{ getCustomerName(sale) }}</span>
                </div>
                <div class="flex items-center gap-2 mt-0.5">
                  <span class="text-[11px] text-slate-400 font-mono">{{ getCustomerPhone(sale) || '-' }}</span>
                  <button
                    v-if="getCustomerPhone(sale)"
                    @click.stop="openWhatsAppDirect(sale)"
                    class="text-emerald-600 hover:text-emerald-700 dark:text-emerald-400 cursor-pointer p-0.5 rounded hover:bg-emerald-50 dark:hover:bg-emerald-950/40 transition"
                    title="Send WhatsApp Message"
                  >
                    <WhatsAppIcon sizeClass="w-3.5 h-3.5" />
                  </button>
                </div>
              </td>

              <!-- Items Summary & Quantity -->
              <td class="py-3.5 px-4">
                <div class="flex items-center gap-1.5">
                  <span class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-md text-xs font-bold bg-indigo-50 dark:bg-indigo-950/60 text-indigo-700 dark:text-indigo-300 border border-indigo-200/60 dark:border-indigo-800/60">
                    <span>📦</span>
                    <span>{{ getTotalSaleQuantity(sale) }} Qty</span>
                  </span>
                  <span v-if="sale.items && sale.items.length > 1" class="text-[10.5px] text-slate-400 font-semibold">
                    ({{ sale.items.length }} line items)
                  </span>
                </div>
                <p class="text-[11.5px] font-medium text-slate-800 dark:text-slate-200 truncate max-w-[240px] mt-1" :title="getItemsPreview(sale)">
                  {{ getItemsPreview(sale) }}
                </p>
              </td>

              <!-- Bill & Outstanding -->
              <td class="py-3.5 px-4">
                <div class="font-extrabold text-slate-900 dark:text-white tabular-nums">
                  ₹{{ formatAmount(sale.grand_total || sale.total_amount || 0) }}
                </div>
                <div class="flex items-center gap-1.5 mt-0.5">
                  <span class="text-[10px] text-slate-400">Paid: ₹{{ formatAmount(sale.amount_paid || 0) }}</span>
                  <span
                    v-if="Number(sale.amount_due || 0) > 0"
                    class="px-1.5 py-0.2 rounded text-[10px] font-bold bg-rose-50 dark:bg-rose-950/60 text-rose-600 dark:text-rose-400 border border-rose-200/60 dark:border-rose-900/40"
                  >
                    Due: ₹{{ formatAmount(sale.amount_due) }}
                  </span>
                  <span
                    v-else
                    class="px-1.5 py-0.2 rounded text-[10px] font-bold bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 border border-emerald-200/60 dark:border-emerald-900/40"
                  >
                    Paid Full
                  </span>
                </div>
              </td>

              <!-- Cost & Net Profit -->
              <td class="py-3.5 px-4">
                <div class="flex items-center gap-1.5">
                  <span
                    :class="Number(sale.net_profit || 0) >= 0 ? 'text-emerald-600 dark:text-emerald-400' : 'text-rose-600 dark:text-rose-400'"
                    class="font-extrabold tabular-nums"
                  >
                    {{ Number(sale.net_profit || 0) >= 0 ? '+' : '' }}₹{{ formatAmount(sale.net_profit || 0) }}
                  </span>
                  <span
                    v-if="Number(sale.profit_margin_percent || 0) > 0"
                    class="px-1.5 py-0.2 rounded text-[10px] font-black bg-emerald-100 dark:bg-emerald-950/60 text-emerald-700 dark:text-emerald-400"
                  >
                    {{ Math.round(sale.profit_margin_percent) }}%
                  </span>
                </div>
                <div class="text-[10px] text-slate-400 mt-0.5">
                  Cost: ₹{{ formatAmount(sale.total_cost || 0) }}
                </div>
              </td>

              <!-- Payment Status Badge -->
              <td class="py-3.5 px-4">
                <span
                  :class="getPaymentBadgeClass(sale.payment_status || (Number(sale.amount_due || 0) > 0 ? 'partial' : 'paid'))"
                  class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold uppercase shadow-xs tracking-wider"
                >
                  <span class="w-1.5 h-1.5 rounded-full mr-1.5" :class="getPaymentDotClass(sale.payment_status || (Number(sale.amount_due || 0) > 0 ? 'partial' : 'paid'))"></span>
                  {{ getPaymentStatusLabel(sale.payment_status || (Number(sale.amount_due || 0) > 0 ? 'partial' : 'paid')) }}
                </span>
              </td>

              <!-- Actions -->
              <td class="py-3.5 px-4 pr-6 text-right">
                <div class="flex items-center justify-end gap-1">
                  <!-- Quick Collect Payment Button (If Due > 0) -->
                  <button
                    v-if="Number(sale.amount_due || 0) > 0"
                    @click="openCollectPaymentModal(sale)"
                    class="p-1.5 rounded-lg text-emerald-600 hover:text-white hover:bg-emerald-600 dark:hover:bg-emerald-600 transition cursor-pointer"
                    title="Collect Payment Due"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
                  </button>

                  <!-- WhatsApp Bill (Only if mobile number exists) -->
                  <button
                    v-if="getCustomerPhone(sale)"
                    @click="openWhatsAppModal(sale)"
                    class="p-1.5 rounded-lg text-emerald-600 hover:bg-emerald-50 dark:hover:bg-emerald-950/40 transition cursor-pointer"
                    title="Send WhatsApp Bill"
                  >
                    <WhatsAppIcon sizeClass="w-4 h-4" />
                  </button>

                  <!-- View Details -->
                  <router-link
                    :to="`/sales/${sale.id}`"
                    class="p-1.5 rounded-lg text-slate-500 hover:text-indigo-600 hover:bg-indigo-50 dark:hover:bg-slate-800 transition"
                    title="View Bill Details"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                  </router-link>

                  <!-- Delete -->
                  <button
                    @click="confirmDeleteSale(sale)"
                    class="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/40 transition cursor-pointer"
                    title="Delete Sale Invoice"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Pagination Footer -->
      <PaginationBar
        :current-page="currentPage"
        :total-pages="totalPages"
        :total="totalCount"
        :per-page="perPage"
        @page-change="changePage"
      />
    </div>

    <!-- Quick Collect Payment Modal (Scroll-Safe, Non-Cutoff) -->
    <div
      v-if="collectModalOpen"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-3 sm:p-5"
      @wheel.stop
    >
      <div class="bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-3xl w-full max-w-md shadow-2xl flex flex-col max-h-[85vh] overflow-hidden animate-in fade-in zoom-in-95">
        <!-- Pinned Header -->
        <div class="p-5 sm:p-6 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between shrink-0 bg-slate-50/50 dark:bg-slate-900/50">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-2xl bg-emerald-50 dark:bg-emerald-950/50 text-emerald-600 dark:text-emerald-400 flex items-center justify-center font-bold">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
            </div>
            <div>
              <h3 class="text-base font-bold text-slate-900 dark:text-white">Collect Payment Due</h3>
              <p class="text-xs text-slate-400">Invoice #{{ collectingSale?.invoice_number || collectingSale?.id }}</p>
            </div>
          </div>
          <button @click="collectModalOpen = false" class="text-slate-400 hover:text-slate-600 p-1.5 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800">✕</button>
        </div>

        <!-- Scrollable Body -->
        <div class="overflow-y-auto custom-scroll flex-1 p-5 sm:p-6 space-y-4 pb-8">
          <!-- Outstanding Balance Banner -->
          <div class="p-4 rounded-2xl bg-amber-50 dark:bg-amber-950/40 border border-amber-200/80 dark:border-amber-800/80 flex items-center justify-between">
            <div>
              <p class="text-[11px] font-bold text-amber-800 dark:text-amber-400 uppercase tracking-wide">Outstanding Due Balance</p>
              <p class="text-2xl font-black text-amber-700 dark:text-amber-300 mt-0.5">₹{{ formatAmount(collectingSale?.amount_due) }}</p>
            </div>
            <div class="text-right text-xs text-slate-500">
              <p class="font-bold text-slate-700 dark:text-slate-300">{{ getCustomerName(collectingSale) }}</p>
              <p class="font-mono text-[11px]">{{ getCustomerPhone(collectingSale) }}</p>
            </div>
          </div>

          <!-- Payment Amount Input -->
          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">
              Collection Amount (₹) <span class="text-rose-500">*</span>
            </label>
            <div class="relative">
              <span class="absolute inset-y-0 left-0 pl-3.5 flex items-center text-slate-400 font-bold text-sm">₹</span>
              <input
                v-model.number="collectForm.amount"
                type="number"
                step="0.01"
                min="0.01"
                :max="collectingSale?.amount_due || 999999"
                required
                class="w-full pl-8 pr-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900 font-bold text-slate-900 dark:text-white text-sm focus:ring-2 focus:ring-emerald-500"
              />
            </div>
          </div>

          <!-- Payment Date -->
          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">
              Payment Date <span class="text-rose-500">*</span>
            </label>
            <DatePicker v-model="collectForm.payment_date" required />
          </div>

          <!-- Payment Mode -->
          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">
              Payment Mode <span class="text-rose-500">*</span>
            </label>
            <SearchableSelect
              v-model="collectForm.payment_method"
              :options="paymentMethodOptions"
              placeholder="Select Payment Mode"
              searchPlaceholder="Search method..."
              minWidth="100%"
            />
          </div>

          <!-- Notes -->
          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">
              Payment Notes (Optional)
            </label>
            <input
              v-model="collectForm.notes"
              type="text"
              placeholder="e.g. Cleared remaining balance via GPay"
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900 text-xs font-semibold"
            />
          </div>
        </div>

        <!-- Pinned Footer -->
        <div class="p-5 sm:p-6 border-t border-slate-100 dark:border-slate-800 flex items-center justify-end gap-2.5 shrink-0 bg-slate-50/50 dark:bg-slate-900/50">
          <button
            @click="collectModalOpen = false"
            type="button"
            class="px-4 py-2.5 rounded-xl text-xs font-bold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition"
          >
            Cancel
          </button>
          <button
            @click="submitCollectPayment"
            :disabled="collecting"
            class="px-5 py-2.5 rounded-xl text-xs font-bold bg-emerald-600 hover:bg-emerald-500 text-white shadow-md shadow-emerald-600/20 disabled:opacity-50 transition flex items-center gap-1.5"
          >
            <svg v-if="collecting" class="w-3.5 h-3.5 animate-spin" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path></svg>
            {{ collecting ? 'Saving...' : 'Confirm Collection' }}
          </button>
        </div>
      </div>
    </div>

    <!-- WhatsApp Share Modal (Scroll-Safe, Non-Cutoff) -->
    <div
      v-if="whatsAppModalOpen"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-3 sm:p-5"
      @wheel.stop
    >
      <div class="bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-3xl w-full max-w-lg shadow-2xl flex flex-col max-h-[85vh] overflow-hidden animate-in fade-in zoom-in-95">
        <!-- Pinned Header -->
        <div class="p-5 sm:p-6 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between shrink-0 bg-slate-50/50 dark:bg-slate-900/50">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-2xl bg-emerald-50 dark:bg-emerald-950/50 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
              <WhatsAppIcon sizeClass="w-5 h-5" />
            </div>
            <div>
              <h3 class="text-base font-bold text-slate-900 dark:text-white">Send WhatsApp Bill</h3>
              <p class="text-xs text-slate-400">{{ getCustomerName(activeWhatsAppSale) }} ({{ getCustomerPhone(activeWhatsAppSale) || 'No phone' }})</p>
            </div>
          </div>
          <button @click="whatsAppModalOpen = false" class="text-slate-400 hover:text-slate-600 p-1.5 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800">✕</button>
        </div>

        <!-- Scrollable Body -->
        <div class="overflow-y-auto custom-scroll flex-1 p-5 sm:p-6 space-y-4 pb-8">
          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">Message Text Preview</label>
            <textarea
              v-model="whatsAppMessageText"
              rows="7"
              class="w-full p-3 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900 font-mono text-xs leading-relaxed"
            ></textarea>
          </div>
        </div>

        <!-- Pinned Footer -->
        <div class="p-5 sm:p-6 border-t border-slate-100 dark:border-slate-800 flex items-center justify-end gap-2.5 shrink-0 bg-slate-50/50 dark:bg-slate-900/50">
          <button
            @click="whatsAppModalOpen = false"
            type="button"
            class="px-4 py-2.5 rounded-xl text-xs font-bold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition"
          >
            Cancel
          </button>
          <button
            @click="sendWhatsAppMessage"
            class="px-5 py-2.5 rounded-xl text-xs font-bold bg-[#25D366] hover:bg-[#20ba5a] text-white shadow-md shadow-green-600/20 transition flex items-center gap-1.5 cursor-pointer"
          >
            <WhatsAppIcon sizeClass="w-4 h-4 text-white" />
            <span>Open in WhatsApp</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <div
      v-if="deleteModalOpen"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-3 sm:p-5"
      @wheel.stop
    >
      <div class="bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-2xl w-full max-w-sm shadow-2xl p-6 text-center animate-in fade-in zoom-in-95">
        <div class="w-12 h-12 rounded-full bg-rose-50 dark:bg-rose-950/60 text-rose-600 dark:text-rose-400 flex items-center justify-center mx-auto mb-3">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
        </div>
        <h3 class="text-base font-bold text-slate-900 dark:text-white">Delete Sale Invoice?</h3>
        <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
          Are you sure you want to delete invoice <span class="font-mono font-bold text-slate-700 dark:text-slate-300">#{{ saleToDelete?.invoice_number || saleToDelete?.id }}</span>? This will revert inventory stock adjustments.
        </p>
        <div class="flex items-center justify-center gap-2 mt-5">
          <button
            @click="deleteModalOpen = false"
            class="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition"
          >
            Cancel
          </button>
          <button
            @click="executeDeleteSale"
            :disabled="deleting"
            class="px-4 py-2 rounded-xl text-xs font-semibold bg-rose-600 hover:bg-rose-500 text-white shadow-md shadow-rose-600/20 disabled:opacity-50 transition"
          >
            {{ deleting ? 'Deleting...' : 'Yes, Delete' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue';
import { useFilterStore } from '@/stores/filter';
import { useToastStore } from '@/stores/toast';
import { saleApi } from '@/api/endpoints';
import PaginationBar from '@/components/common/PaginationBar.vue';
import SearchableSelect from '@/components/common/SearchableSelect.vue';
import WhatsAppIcon from '@/components/common/WhatsAppIcon.vue';
import DatePicker from '@/components/common/DatePicker.vue';
import { formatDate } from '@/utils/date';

const filterStore = useFilterStore();
const toast = useToastStore();

const paymentStatusOptions = [
  { value: '', label: 'All Payment Statuses' },
  { value: 'paid', label: 'Paid Full' },
  { value: 'partial', label: 'Partially Paid' },
  { value: 'unpaid', label: 'Unpaid / Due' },
];

const sortBy = ref('newest');
const sortOptions = [
  { value: 'newest', label: 'Newest First (Recent)' },
  { value: 'oldest', label: 'Oldest First' },
  { value: 'amount_high', label: 'Amount (High to Low)' },
  { value: 'amount_low', label: 'Amount (Low to High)' },
];

const paymentMethodOptions = [
  { value: 'cash', label: 'Cash', icon: '💵' },
  { value: 'upi', label: 'UPI / PhonePe / GPay', icon: '⚡' },
  { value: 'card', label: 'Debit / Credit Card', icon: '💳' },
  { value: 'bank_transfer', label: 'Bank Transfer', icon: '🏦' },
];

const statusPills = [
  { value: '', label: 'All Sales' },
  { value: 'paid', label: 'PAID' },
  { value: 'partial', label: 'PARTIAL' },
  { value: 'unpaid', label: 'DUE' },
];

const typePills = [
  { value: 'all', label: 'All Types' },
  { value: 'quick', label: '⚡ Quick Sales' },
  { value: 'regular', label: '🧾 Tax Invoices' },
];

const sales = ref([]);
const loading = ref(false);
const searchQuery = ref('');
const selectedPaymentStatus = ref('');
const selectedSaleType = ref('all');
const currentPage = ref(1);
const totalPages = ref(1);
const totalCount = ref(0);
const perPage = ref(10);
let searchTimer = null;

// Summary metrics
const summary = reactive({
  total_billed: 0,
  total_paid: 0,
  total_due: 0,
  total_profit: 0,
  total_cost: 0,
  total_count: 0,
});

const profitMarginPercent = computed(() => {
  if (summary.total_billed > 0 && summary.total_profit > 0) {
    return Math.round((summary.total_profit / summary.total_billed) * 100);
  }
  return 0;
});

// Modals State
const deleteModalOpen = ref(false);
const saleToDelete = ref(null);
const deleting = ref(false);

const collectModalOpen = ref(false);
const collectingSale = ref(null);
const collecting = ref(false);
const collectForm = reactive({
  amount: 0,
  payment_date: new Date().toISOString().substring(0, 10),
  payment_method: 'cash',
  notes: '',
});

const whatsAppModalOpen = ref(false);
const activeWhatsAppSale = ref(null);
const whatsAppMessageText = ref('');

function debounceSearch() {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => {
    currentPage.value = 1;
    fetchSales();
  }, 350);
}

function onPeriodChange() {
  filterStore.setPeriod(filterStore.selectedPeriod);
  currentPage.value = 1;
  fetchSales();
}

function onStatusChange() {
  currentPage.value = 1;
  fetchSales();
}

function onSortChange() {
  currentPage.value = 1;
  fetchSales();
}

function setPaymentStatus(val) {
  selectedPaymentStatus.value = val;
  currentPage.value = 1;
  fetchSales();
}

function setSaleType(val) {
  selectedSaleType.value = val;
  currentPage.value = 1;
  fetchSales();
}

function resetFilters() {
  searchQuery.value = '';
  selectedPaymentStatus.value = '';
  selectedSaleType.value = 'all';
  sortBy.value = 'newest';
  filterStore.setPeriod('this_month');
  currentPage.value = 1;
  fetchSales();
}

async function fetchSales() {
  loading.value = true;
  try {
    const periodVal = filterStore.selectedPeriod;
    const res = await saleApi.list({
      page: currentPage.value,
      per_page: perPage.value,
      search: searchQuery.value || undefined,
      payment_status: selectedPaymentStatus.value || undefined,
      sale_type: selectedSaleType.value !== 'all' ? selectedSaleType.value : undefined,
      period: periodVal !== 'all_time' ? periodVal : undefined,
      sort: sortBy.value || 'newest',
    });

    const dataPayload = res.data?.data;
    const items = Array.isArray(dataPayload) ? dataPayload : (dataPayload?.data || []);
    sales.value = items;

    if (res.data?.summary) {
      summary.total_billed = Number(res.data.summary.total_billed || 0);
      summary.total_paid = Number(res.data.summary.total_paid || 0);
      summary.total_due = Number(res.data.summary.total_due || 0);
      summary.total_profit = Number(res.data.summary.total_profit || 0);
      summary.total_cost = Number(res.data.summary.total_cost || 0);
      summary.total_count = Number(res.data.summary.total_count || 0);
    } else {
      // Local fallback calculation
      let billed = 0;
      let paid = 0;
      let due = 0;
      let profit = 0;
      let cost = 0;
      items.forEach(s => {
        billed += Number(s.grand_total || s.total_amount || 0);
        paid += Number(s.amount_paid || 0);
        due += Number(s.amount_due || 0);
        profit += Number(s.net_profit || 0);
        cost += Number(s.total_cost || 0);
      });
      summary.total_billed = billed;
      summary.total_paid = paid;
      summary.total_due = due;
      summary.total_profit = profit;
      summary.total_cost = cost;
      summary.total_count = items.length;
    }

    if (res.data?.meta) {
      currentPage.value = res.data.meta.current_page || 1;
      totalCount.value = res.data.meta.total || items.length;
      totalPages.value = res.data.meta.last_page || 1;
    } else {
      totalCount.value = items.length;
      totalPages.value = 1;
    }
  } catch (err) {
    console.error('Failed to load sales:', err);
  } finally {
    loading.value = false;
  }
}

function changePage(p) {
  currentPage.value = p;
  fetchSales();
}

function getCustomerName(sale) {
  if (!sale) return 'Walk-in Customer';
  return sale.customer?.name || sale.customer_name || 'Walk-in Customer';
}

function getCustomerPhone(sale) {
  if (!sale) return '';
  return sale.customer?.mobile || sale.customer?.phone || sale.customer_mobile || sale.customer_phone || '';
}

function getTotalSaleQuantity(sale) {
  if (!sale) return 0;
  if (Array.isArray(sale.items) && sale.items.length > 0) {
    return sale.items.reduce((sum, item) => sum + (Number(item.quantity) || 1), 0);
  }
  return Number(sale.total_quantity || sale.quantity || sale.items_count || 1);
}

function getItemsCount(sale) {
  return getTotalSaleQuantity(sale);
}

function getItemsPreview(sale) {
  if (!sale || !Array.isArray(sale.items) || sale.items.length === 0) {
    return 'Retail POS Bill';
  }
  return sale.items.map(i => {
    const qty = Number(i.quantity) || 1;
    const name = i.product_name || i.item_name || 'Item';
    return `${name} (x${qty})`;
  }).join(', ');
}

function getPaymentStatusLabel(status) {
  const s = String(status || '').toLowerCase();
  if (s === 'paid') return 'PAID';
  if (s === 'partial' || s === 'partially_paid') return 'PARTIAL';
  if (s === 'unpaid' || s === 'due') return 'DUE';
  return String(status).toUpperCase();
}

function getPaymentBadgeClass(status) {
  const s = String(status || '').toLowerCase();
  if (s === 'paid') {
    return 'bg-emerald-50 dark:bg-emerald-950/50 text-emerald-600 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-900/40';
  }
  if (s === 'partial' || s === 'partially_paid') {
    return 'bg-amber-50 dark:bg-amber-950/50 text-amber-600 dark:text-amber-400 border border-amber-200 dark:border-amber-900/40';
  }
  return 'bg-rose-50 dark:bg-rose-950/50 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-900/40';
}

function getPaymentDotClass(status) {
  const s = String(status || '').toLowerCase();
  if (s === 'paid') return 'bg-emerald-500';
  if (s === 'partial' || s === 'partially_paid') return 'bg-amber-500';
  return 'bg-rose-500';
}

function formatAmount(amt) {
  return (Number(amt) || 0).toLocaleString('en-IN', { maximumFractionDigits: 2 });
}


// Collect Payment Actions
function openCollectPaymentModal(sale) {
  collectingSale.value = sale;
  collectForm.amount = Number(sale.amount_due || 0);
  collectForm.payment_date = new Date().toISOString().substring(0, 10);
  collectForm.payment_method = 'cash';
  collectForm.notes = '';
  collectModalOpen.value = true;
}

async function submitCollectPayment() {
  if (!collectingSale.value) return;
  if (!collectForm.amount || collectForm.amount <= 0) {
    toast.error('Please enter a valid payment amount.', 'Invalid Amount');
    return;
  }
  collecting.value = true;
  try {
    await saleApi.addPayment(collectingSale.value.id, {
      amount: collectForm.amount,
      payment_date: collectForm.payment_date,
      payment_method: collectForm.payment_method,
      notes: collectForm.notes || undefined,
    });
    collectModalOpen.value = false;
    toast.success(`Payment of ₹${formatAmount(collectForm.amount)} collected successfully!`, 'Payment Recorded');
    fetchSales();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to record payment.';
    toast.error(msg, 'Payment Failed');
  } finally {
    collecting.value = false;
  }
}

// WhatsApp Actions
function openWhatsAppModal(sale) {
  activeWhatsAppSale.value = sale;
  const custName = getCustomerName(sale);
  const invNo = sale.invoice_number || sale.invoice_no || sale.id;
  const grandTotal = formatAmount(sale.grand_total || sale.total_amount);
  const paid = formatAmount(sale.amount_paid);
  const due = formatAmount(sale.amount_due);

  whatsAppMessageText.value =
    `Hello ${custName} 👋\n\n` +
    `Thank you for your business! Here are your invoice details:\n\n` +
    `🧾 *Invoice #:* ${invNo}\n` +
    `📅 *Date:* ${formatDate(sale.sale_date || sale.created_at)}\n` +
    `💰 *Total Amount:* ₹${grandTotal}\n` +
    `✅ *Paid Amount:* ₹${paid}\n` +
    (Number(sale.amount_due) > 0 ? `⚠️ *Balance Due:* ₹${due}\n\n` : `🎉 *Payment Status:* Fully Settled\n\n`) +
    `Thank you for shopping with us!`;

  whatsAppModalOpen.value = true;
}

function openWhatsAppDirect(sale) {
  openWhatsAppModal(sale);
}

function sendWhatsAppMessage() {
  if (!activeWhatsAppSale.value) return;
  const phone = getCustomerPhone(activeWhatsAppSale.value);
  if (!phone) {
    toast.warning('No phone number recorded for this customer.', 'Phone Missing');
    return;
  }
  let cleanPhone = String(phone).replace(/\D/g, '');
  if (cleanPhone.length === 10) cleanPhone = '91' + cleanPhone;
  const encoded = encodeURIComponent(whatsAppMessageText.value);
  window.open(`https://wa.me/${cleanPhone}?text=${encoded}`, '_blank');
  whatsAppModalOpen.value = false;
  toast.success('WhatsApp chat opened!', 'WhatsApp');
}

// Delete Sale Actions
function confirmDeleteSale(sale) {
  saleToDelete.value = sale;
  deleteModalOpen.value = true;
}

async function executeDeleteSale() {
  if (!saleToDelete.value) return;
  deleting.value = true;
  try {
    const invNo = saleToDelete.value.invoice_number || saleToDelete.value.invoice_no || saleToDelete.value.id;
    await saleApi.delete(saleToDelete.value.id);
    deleteModalOpen.value = false;
    saleToDelete.value = null;
    toast.success(`Sale invoice #${invNo} deleted. Stock restored.`, 'Invoice Deleted');
    fetchSales();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to delete sale invoice';
    toast.error(msg, 'Delete Failed');
  } finally {
    deleting.value = false;
  }
}

onMounted(() => {
  fetchSales();
});
</script>
