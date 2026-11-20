<template>
  <div class="space-y-6 pb-12 font-['Outfit',sans-serif]">
    <!-- 1. Header & Actions -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <div class="flex items-center gap-2">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 border border-indigo-200/60 dark:border-indigo-800/60">
            Procurement & Supply Chain
          </span>
          <span class="text-xs text-slate-400">Wholesale Inward & Vendor Accounts</span>
        </div>
        <h2 class="text-2xl font-black tracking-tight text-slate-900 dark:text-white mt-1">Purchases & Vendors</h2>
        <p class="text-xs text-slate-500 dark:text-slate-400 mt-0.5">Manage wholesale mobile stock purchases, spare parts procurement, vendor ledgers, and supplier payables.</p>
      </div>

      <div class="flex items-center gap-2.5">
        <button
          v-if="activeTab === 'vendors'"
          @click="openAddVendorModal"
          type="button"
          class="inline-flex items-center gap-1.5 px-4 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold shadow-md shadow-indigo-600/20 transition cursor-pointer"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 4v16m8-8H4"/></svg>
          + Add Vendor
        </button>
        <button
          v-else
          @click="openCreatePurchaseModal"
          type="button"
          class="inline-flex items-center gap-1.5 px-4 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold shadow-md shadow-indigo-600/20 transition cursor-pointer"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 4v16m8-8H4"/></svg>
          + Record Purchase
        </button>
      </div>
    </div>

    <!-- 2. KPI Summary Metric Cards (Matching Mobile App) -->
    <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
      <!-- Total Volume -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 sm:p-5 border border-slate-200/80 dark:border-slate-800/80 shadow-xs">
        <div class="flex items-center justify-between">
          <p class="text-[11px] text-slate-400 font-bold uppercase tracking-wider">
            {{ activeTab === 'purchases' ? 'Total Purchased' : 'Total Billed' }}
          </p>
          <div class="w-8 h-8 rounded-xl bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 flex items-center justify-center">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"/></svg>
          </div>
        </div>
        <p class="text-2xl font-black text-slate-900 dark:text-white mt-2 tabular-nums">
          ₹{{ formatAmount(activeTab === 'purchases' ? purchaseMetrics.total_amount : vendorMetrics.total_purchases) }}
        </p>
        <p class="text-[10px] text-slate-400 mt-0.5">
          {{ activeTab === 'purchases' ? `${purchaseMetrics.total_purchases || 0} purchase orders` : `${vendorMetrics.total_vendors || 0} suppliers` }}
        </p>
      </div>

      <!-- Paid to Vendors -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 sm:p-5 border border-slate-200/80 dark:border-slate-800/80 shadow-xs">
        <div class="flex items-center justify-between">
          <p class="text-[11px] text-slate-400 font-bold uppercase tracking-wider">Paid to Vendors</p>
          <div class="w-8 h-8 rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
          </div>
        </div>
        <p class="text-2xl font-black text-emerald-600 dark:text-emerald-400 mt-2 tabular-nums">
          ₹{{ formatAmount(activeTab === 'purchases' ? purchaseMetrics.total_paid : vendorMetrics.total_paid) }}
        </p>
        <p class="text-[10px] text-slate-400 mt-0.5">Settled supplier payments</p>
      </div>

      <!-- Outstanding Payables -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 sm:p-5 border border-slate-200/80 dark:border-slate-800/80 shadow-xs">
        <div class="flex items-center justify-between">
          <p class="text-[11px] text-slate-400 font-bold uppercase tracking-wider">Vendor Dues (Payable)</p>
          <div class="w-8 h-8 rounded-xl bg-rose-500/10 text-rose-600 dark:text-rose-400 flex items-center justify-center">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
          </div>
        </div>
        <p class="text-2xl font-black text-rose-600 dark:text-rose-400 mt-2 tabular-nums">
          ₹{{ formatAmount(activeTab === 'purchases' ? purchaseMetrics.total_outstanding : vendorMetrics.total_outstanding) }}
        </p>
        <p class="text-[10px] text-slate-400 mt-0.5">Pending payment balance</p>
      </div>

      <!-- Active Supplier / Order Counter -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 sm:p-5 border border-slate-200/80 dark:border-slate-800/80 shadow-xs">
        <div class="flex items-center justify-between">
          <p class="text-[11px] text-slate-400 font-bold uppercase tracking-wider">
            {{ activeTab === 'purchases' ? 'Total Bills' : 'Registered Suppliers' }}
          </p>
          <div class="w-8 h-8 rounded-xl bg-purple-500/10 text-purple-600 dark:text-purple-400 flex items-center justify-center">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/></svg>
          </div>
        </div>
        <p class="text-2xl font-black text-purple-600 dark:text-purple-400 mt-2 tabular-nums">
          {{ activeTab === 'purchases' ? purchaseMetrics.total_purchases : vendorMetrics.total_vendors }}
        </p>
        <p class="text-[10px] text-slate-400 mt-0.5">
          {{ activeTab === 'purchases' ? 'Inward transactions' : 'Active vendor contacts' }}
        </p>
      </div>
    </div>

    <!-- 3. Navigation Tabs: Purchases vs Vendors -->
    <div class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800/80 shadow-xs p-1.5 flex items-center gap-1.5">
      <button
        type="button"
        @click="activeTab = 'purchases'"
        :class="[
          'flex-1 py-2.5 px-4 rounded-xl text-xs font-bold transition flex items-center justify-center gap-2 cursor-pointer',
          activeTab === 'purchases'
            ? 'bg-indigo-600 text-white shadow-sm'
            : 'text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800'
        ]"
      >
        <span>🛍️</span>
        <span>Purchase Orders & Bills</span>
        <span
          class="px-2 py-0.5 rounded-full text-[10px]"
          :class="activeTab === 'purchases' ? 'bg-white/20 text-white' : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400'"
        >
          {{ purchasesTotalCount }}
        </span>
      </button>

      <button
        type="button"
        @click="activeTab = 'vendors'"
        :class="[
          'flex-1 py-2.5 px-4 rounded-xl text-xs font-bold transition flex items-center justify-center gap-2 cursor-pointer',
          activeTab === 'vendors'
            ? 'bg-indigo-600 text-white shadow-sm'
            : 'text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800'
        ]"
      >
        <span>🏢</span>
        <span>Vendors & Suppliers Directory</span>
        <span
          class="px-2 py-0.5 rounded-full text-[10px]"
          :class="activeTab === 'vendors' ? 'bg-white/20 text-white' : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400'"
        >
          {{ vendorsTotalCount }}
        </span>
      </button>
    </div>

    <!-- 4. Filter & Search Bar -->
    <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-sm flex flex-col md:flex-row items-stretch md:items-center gap-3">
      <!-- Search -->
      <div class="relative flex-1">
        <svg class="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
        </svg>
        <input
          v-model="searchQuery"
          @input="debounceSearch"
          type="text"
          :placeholder="activeTab === 'purchases' ? 'Search by Bill #, Supplier name, notes...' : 'Search vendor by name, phone, email, GSTIN...'"
          class="w-full pl-10 pr-4 py-2 text-xs font-medium bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-slate-800 dark:text-slate-100 placeholder-slate-400"
        />
      </div>

      <!-- Purchases Tab Filters -->
      <div v-if="activeTab === 'purchases'" class="flex flex-wrap items-center gap-2">
        <SearchableSelect
          v-model="paymentStatusFilter"
          :options="paymentStatusOptions"
          @change="onFilterChange"
          placeholder="All Payment Status"
          searchPlaceholder="Filter payment..."
          minWidth="145px"
        />

        <SearchableSelect
          v-model="filterStore.selectedPeriod"
          :options="filterStore.periodOptions"
          @change="onFilterChange"
          placeholder="Select Period"
          searchPlaceholder="Search period..."
          minWidth="140px"
        />

        <SearchableSelect
          v-model="sortBy"
          :options="sortOptions"
          @change="onFilterChange"
          placeholder="Sort By"
          minWidth="150px"
          prefixIcon="↕️"
        />

        <button
          v-if="searchQuery || paymentStatusFilter || filterStore.selectedPeriod !== 'this_month' || sortBy !== 'newest'"
          @click="resetPurchaseFilters"
          type="button"
          class="px-3 py-2 text-xs font-bold text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200 cursor-pointer"
        >
          Reset
        </button>
      </div>

      <!-- Vendors Tab Filters -->
      <div v-else class="flex items-center gap-2">
        <button
          v-if="searchQuery"
          @click="searchQuery = ''; currentPage = 1; fetchVendors()"
          type="button"
          class="px-3 py-2 text-xs font-bold text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200 cursor-pointer"
        >
          Clear
        </button>
      </div>
    </div>

    <!-- ========================================================================= -->
    <!-- 5A. TAB 1: PURCHASES TABLE                                                -->
    <!-- ========================================================================= -->
    <div v-if="activeTab === 'purchases'" class="bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-2xl overflow-hidden shadow-sm">
      <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse text-xs">
          <thead>
            <tr class="border-b border-slate-100 dark:border-slate-800/80 text-[11px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider bg-slate-50/60 dark:bg-slate-900/40">
              <th class="py-3.5 px-4 pl-6">Purchase Bill #</th>
              <th class="py-3.5 px-4">Supplier / Vendor</th>
              <th class="py-3.5 px-4">Items / Details</th>
              <th class="py-3.5 px-4">Grand Total</th>
              <th class="py-3.5 px-4">Payment Status</th>
              <th class="py-3.5 px-4">Stock Status</th>
              <th class="py-3.5 px-4 pr-6 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100 dark:divide-slate-800/60 font-medium">
            <tr v-if="loadingPurchases">
              <td colspan="7" class="py-12 text-center text-slate-400">
                <div class="inline-block animate-spin w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full mb-2"></div>
                <div>Loading purchase orders...</div>
              </td>
            </tr>
            <tr v-else-if="purchases.length === 0">
              <td colspan="7" class="py-14 text-center text-slate-400 dark:text-slate-500">
                <div class="text-3xl mb-1">📦</div>
                <p class="font-bold text-slate-700 dark:text-slate-300">No purchase records found</p>
                <p class="text-xs text-slate-400 mt-0.5">Click "+ Record Purchase" to record wholesale mobile stock or parts inward.</p>
              </td>
            </tr>
            <tr
              v-for="p in purchases"
              :key="p.id"
              class="hover:bg-slate-50/70 dark:hover:bg-slate-800/40 transition-colors group cursor-pointer"
              @click="openPurchaseDetail(p)"
            >
              <!-- Bill # -->
              <td class="py-3.5 px-4 pl-6" @click.stop="openPurchaseDetail(p)">
                <div class="font-bold font-mono text-indigo-600 dark:text-indigo-400">
                  {{ p.purchase_number || ('#PUR-' + p.id) }}
                </div>
                <div class="text-[11px] text-slate-400 mt-0.5 flex items-center gap-1">
                  <span>📅 {{ formatDate(p.purchase_date || p.created_at) }}</span>
                </div>
              </td>

              <!-- Vendor Info -->
              <td class="py-3.5 px-4" @click.stop>
                <div class="font-bold text-slate-900 dark:text-slate-100 flex items-center gap-1.5">
                  <span>{{ p.vendor?.name || p.vendor_name || 'Direct Wholesale' }}</span>
                </div>
                <div class="text-[11px] font-mono text-slate-400 flex items-center gap-1.5 mt-0.5">
                  <span>{{ p.vendor?.phone || '-' }}</span>
                  <a
                    v-if="p.vendor?.phone"
                    :href="`https://wa.me/91${cleanPhone(p.vendor.phone)}?text=${encodeURIComponent(`Hello ${p.vendor.name}, regarding Purchase Bill ${p.purchase_number || ('#PUR-' + p.id)}: ₹${formatAmount(p.grand_total || p.total_amount)}.`)}`"
                    target="_blank"
                    class="text-emerald-500 hover:text-emerald-600 transition"
                    title="Send WhatsApp"
                  >
                    <WhatsAppIcon sizeClass="w-3.5 h-3.5" />
                  </a>
                </div>
              </td>

              <!-- Items Breakdown with Quantity & Stock -->
              <td class="py-3.5 px-4">
                <div class="text-slate-800 dark:text-slate-200 font-bold line-clamp-1 flex items-center gap-1.5" :title="getPurchaseItemsPreview(p)">
                  <span>{{ getPurchaseItemsPreview(p) }}</span>
                </div>
                <div class="text-[11px] text-slate-400 mt-0.5 flex items-center gap-1.5">
                  <span class="inline-flex items-center px-1.5 py-0.2 rounded font-bold text-[10px] bg-indigo-50 dark:bg-indigo-950/60 text-indigo-700 dark:text-indigo-300 border border-indigo-200/60 dark:border-indigo-800/60">
                    Total: {{ getTotalPurchaseQuantity(p) }} pcs
                  </span>
                  <span v-if="p.items && p.items.length > 1" class="text-slate-400 font-semibold">
                    • {{ p.items.length }} line items
                  </span>
                </div>
              </td>

              <!-- Total Amount & Paid -->
              <td class="py-3.5 px-4">
                <div class="font-black text-slate-900 dark:text-white tabular-nums text-sm">
                  ₹{{ formatAmount(p.grand_total || p.total_amount || 0) }}
                </div>
                <div class="text-[10.5px] text-slate-400 tabular-nums mt-0.5">
                  Paid: ₹{{ formatAmount(p.amount_paid || 0) }}
                </div>
              </td>

              <!-- Payment Status -->
              <td class="py-3.5 px-4">
                <span
                  v-if="(Number(p.outstanding_amount || p.due_amount) > 0) || p.payment_status === 'pending'"
                  class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-900/40"
                >
                  Due: ₹{{ formatAmount(p.outstanding_amount || p.due_amount || 0) }}
                </span>
                <span
                  v-else-if="p.payment_status === 'partial'"
                  class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-300 border border-amber-200 dark:border-amber-900/40"
                >
                  Partial
                </span>
                <span
                  v-else
                  class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-900/40"
                >
                  ✓ Fully Paid
                </span>
              </td>

              <!-- Stock Inward Status -->
              <td class="py-3.5 px-4" @click.stop>
                <span
                  v-if="p.is_stock_added || p.stock_added || p.is_inwarded"
                  class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-[11px] font-bold bg-teal-50 dark:bg-teal-950/50 text-teal-700 dark:text-teal-300 border border-teal-200 dark:border-teal-800"
                >
                  <svg class="w-3.5 h-3.5 text-teal-600 dark:text-teal-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"/></svg>
                  <span>In Stock ({{ getTotalPurchaseQuantity(p) }} pcs)</span>
                </span>
                <button
                  v-else
                  @click="inwardStockToInventory(p)"
                  type="button"
                  class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-[11px] font-bold bg-amber-50 dark:bg-amber-950/50 text-amber-700 dark:text-amber-300 border border-amber-300 dark:border-amber-800 hover:bg-amber-100 transition cursor-pointer"
                  title="Click to add these items to shop inventory stock"
                >
                  <svg class="w-3.5 h-3.5 text-amber-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" d="M12 4v16m8-8H4"/></svg>
                  <span>Inward Stock ({{ getTotalPurchaseQuantity(p) }} pcs)</span>
                </button>
              </td>

              <!-- Actions -->
              <td class="py-3.5 px-4 pr-6 text-right" @click.stop>
                <div class="flex items-center justify-end gap-1.5">
                  <!-- Record Payment Button -->
                  <button
                    v-if="(Number(p.outstanding_amount || p.due_amount) > 0) || p.payment_status !== 'paid'"
                    @click="openAddPaymentModal(p)"
                    type="button"
                    class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-xs font-bold bg-emerald-50 text-emerald-700 dark:bg-emerald-950/50 dark:text-emerald-300 hover:bg-emerald-100 transition cursor-pointer"
                    title="Pay Vendor"
                  >
                    <span>💳 Pay</span>
                  </button>

                  <!-- View Details -->
                  <button
                    @click="openPurchaseDetail(p)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-400 hover:text-indigo-600 hover:bg-indigo-50 dark:hover:bg-slate-800 transition cursor-pointer"
                    title="View Purchase Invoice & Items"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                  </button>

                  <!-- Delete -->
                  <button
                    @click="confirmDeletePurchase(p)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/40 transition cursor-pointer"
                    title="Delete Purchase"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Pagination -->
      <PaginationBar
        :current-page="currentPage"
        :total-pages="purchasesTotalPages"
        :total="purchasesTotalCount"
        :per-page="perPage"
        label="purchases"
        @page-change="onPurchasesPageChange"
      />
    </div>

    <!-- ========================================================================= -->
    <!-- 5B. TAB 2: VENDORS / SUPPLIERS TABLE                                      -->
    <!-- ========================================================================= -->
    <div v-else class="bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-2xl overflow-hidden shadow-sm">
      <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse text-xs">
          <thead>
            <tr class="border-b border-slate-100 dark:border-slate-800/80 text-[11px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider bg-slate-50/60 dark:bg-slate-900/40">
              <th class="py-3.5 px-4 pl-6">Vendor / Supplier</th>
              <th class="py-3.5 px-4">Contact Details</th>
              <th class="py-3.5 px-4">GST / Tax ID</th>
              <th class="py-3.5 px-4">City / Address</th>
              <th class="py-3.5 px-4">Total Purchases</th>
              <th class="py-3.5 px-4">Outstanding Due</th>
              <th class="py-3.5 px-4 pr-6 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100 dark:divide-slate-800/60 font-medium">
            <tr v-if="loadingVendors">
              <td colspan="7" class="py-12 text-center text-slate-400">
                <div class="inline-block animate-spin w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full mb-2"></div>
                <div>Loading suppliers directory...</div>
              </td>
            </tr>
            <tr v-else-if="vendors.length === 0">
              <td colspan="7" class="py-14 text-center text-slate-400 dark:text-slate-500">
                <div class="text-3xl mb-1">🏢</div>
                <p class="font-bold text-slate-700 dark:text-slate-300">No vendor suppliers registered</p>
                <p class="text-xs text-slate-400 mt-0.5">Click "+ Add Vendor" to create your suppliers directory.</p>
              </td>
            </tr>
            <tr
              v-for="v in vendors"
              :key="v.id"
              class="hover:bg-slate-50/70 dark:hover:bg-slate-800/40 transition-colors group cursor-pointer"
              @click="openVendorDetail(v)"
            >
              <!-- Vendor Name & Avatar -->
              <td class="py-3.5 px-4 pl-6">
                <div class="flex items-center gap-3">
                  <div class="w-9 h-9 rounded-xl bg-purple-50 dark:bg-purple-950/50 border border-purple-200/80 dark:border-purple-800 text-purple-700 dark:text-purple-400 font-extrabold text-xs flex items-center justify-center flex-shrink-0">
                    {{ (v.name || 'V').substring(0, 1).toUpperCase() }}
                  </div>
                  <div>
                    <div class="font-bold text-slate-900 dark:text-white">{{ v.name }}</div>
                    <div v-if="v.contact_person" class="text-[11px] text-slate-400">Contact: {{ v.contact_person }}</div>
                  </div>
                </div>
              </td>

              <!-- Contact -->
              <td class="py-3.5 px-4" @click.stop>
                <div class="font-mono text-slate-800 dark:text-slate-200 font-semibold flex items-center gap-1.5">
                  <span>{{ v.phone || '-' }}</span>
                  <a
                    v-if="v.phone"
                    :href="`https://wa.me/91${cleanPhone(v.phone)}?text=${encodeURIComponent(`Hello ${v.name}, checking from ${authStore.shopName}.`)}`"
                    target="_blank"
                    class="text-emerald-500 hover:text-emerald-600 transition"
                    title="Send WhatsApp"
                  >
                    <WhatsAppIcon sizeClass="w-3.5 h-3.5" />
                  </a>
                </div>
                <div v-if="v.email" class="text-[10.5px] text-slate-400 truncate max-w-[150px]">{{ v.email }}</div>
              </td>

              <!-- GSTIN -->
              <td class="py-3.5 px-4">
                <span v-if="v.gst_number || v.gstin" class="font-mono text-[11px] font-bold bg-slate-100 dark:bg-slate-800 px-2 py-0.5 rounded text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700">
                  {{ v.gst_number || v.gstin }}
                </span>
                <span v-else class="text-slate-400 text-xs">—</span>
              </td>

              <!-- City / Address -->
              <td class="py-3.5 px-4 text-slate-600 dark:text-slate-400 max-w-[160px] truncate">
                {{ v.city || v.address || 'Local' }}
              </td>

              <!-- Total Purchases -->
              <td class="py-3.5 px-4">
                <div class="font-black text-slate-900 dark:text-white tabular-nums">
                  ₹{{ formatAmount(v.total_purchase || 0) }}
                </div>
                <div class="text-[10.5px] text-slate-400">
                  {{ v.purchases_count || 0 }} orders
                </div>
              </td>

              <!-- Outstanding Due -->
              <td class="py-3.5 px-4">
                <span
                  v-if="Number(v.outstanding_amount || 0) > 0"
                  class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-bold bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-900/40"
                >
                  ₹{{ formatAmount(v.outstanding_amount) }} Due
                </span>
                <span v-else class="text-emerald-600 dark:text-emerald-400 font-bold text-xs">
                  ✓ Settled
                </span>
              </td>

              <!-- Actions -->
              <td class="py-3.5 px-4 pr-6 text-right" @click.stop>
                <div class="flex items-center justify-end gap-1.5">
                  <!-- View Ledger -->
                  <button
                    @click="openVendorDetail(v)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-400 hover:text-indigo-600 hover:bg-indigo-50 dark:hover:bg-slate-800 transition cursor-pointer"
                    title="View Vendor Ledger & Order History"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                  </button>

                  <!-- Edit -->
                  <button
                    @click="openEditVendorModal(v)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-400 hover:text-amber-600 hover:bg-amber-50 dark:hover:bg-slate-800 transition cursor-pointer"
                    title="Edit Vendor"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
                  </button>

                  <!-- Delete -->
                  <button
                    @click="confirmDeleteVendor(v)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/40 transition cursor-pointer"
                    title="Delete Vendor"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Pagination -->
      <PaginationBar
        :current-page="vendorCurrentPage"
        :total-pages="vendorsTotalPages"
        :total="vendorsTotalCount"
        :per-page="perPage"
        label="vendors"
        @page-change="onVendorsPageChange"
      />
    </div>

    <!-- ========================================================================= -->
    <!-- MODAL 1: RECORD PURCHASE (Full Multi-Item Order Creation)                 -->
    <!-- ========================================================================= -->
    <div v-if="createPurchaseModalOpen" class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 overflow-y-auto">
      <div @click="createPurchaseModalOpen = false" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm"></div>

      <div class="relative w-full max-w-3xl bg-white dark:bg-[#111827] rounded-3xl border border-slate-200/80 dark:border-slate-800/80 shadow-2xl p-6 z-10 space-y-4 max-h-[90vh] overflow-y-auto custom-scroll">
        <!-- Header -->
        <div class="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-2xl bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 flex items-center justify-center font-bold">
              🛍️
            </div>
            <div>
              <h3 class="text-base font-black text-slate-900 dark:text-white">Record Wholesale Purchase</h3>
              <p class="text-xs text-slate-400">Inward mobile devices, spare parts & supplier bills</p>
            </div>
          </div>
          <button @click="createPurchaseModalOpen = false" class="p-2 text-slate-400 hover:text-slate-600 cursor-pointer">✕</button>
        </div>

        <form @submit.prevent="submitCreatePurchase" class="space-y-4 text-xs">
          <!-- Top Row: Vendor & Purchase Date -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <!-- Vendor Selection -->
            <div>
              <div class="flex items-center justify-between mb-1.5">
                <label class="font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider">
                  Supplier / Vendor <span class="text-rose-500">*</span>
                </label>
                <button
                  type="button"
                  @click="openAddVendorModalInline"
                  class="text-[11px] font-bold text-indigo-600 hover:text-indigo-500 cursor-pointer"
                >
                  + New Vendor
                </button>
              </div>
              <select
                v-model="purchaseForm.vendor_id"
                required
                class="w-full px-3.5 py-2.5 text-xs font-semibold bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-white"
              >
                <option :value="null" disabled>-- Select Vendor --</option>
                <option v-for="v in allVendorsList" :key="v.id" :value="v.id">
                  {{ v.name }} ({{ v.phone || 'No phone' }})
                </option>
              </select>
            </div>

            <!-- Purchase Date -->
            <div>
              <label class="block font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
                Purchase Bill Date <span class="text-rose-500">*</span>
              </label>
              <DatePicker v-model="purchaseForm.purchase_date" required />
            </div>
          </div>

          <!-- Line Items Section -->
          <div class="p-4 rounded-2xl bg-slate-50/70 dark:bg-slate-900/50 border border-slate-200/80 dark:border-slate-800/80 space-y-3">
            <div class="flex items-center justify-between">
              <span class="font-black text-slate-800 dark:text-slate-200 uppercase tracking-wider text-[11px]">
                📦 Inward Line Items ({{ purchaseForm.items.length }})
              </span>
              <button
                type="button"
                @click="addLineItem"
                class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-xs font-bold bg-indigo-600 text-white hover:bg-indigo-500 transition shadow-xs cursor-pointer"
              >
                + Add Item Row
              </button>
            </div>

            <!-- Items Table -->
            <div class="space-y-2.5">
              <div
                v-for="(item, idx) in purchaseForm.items"
                :key="idx"
                class="p-3 bg-white dark:bg-[#111827] rounded-xl border border-slate-200 dark:border-slate-800 space-y-2"
              >
                <div class="grid grid-cols-12 gap-2 items-center">
                  <!-- Select / Name -->
                  <div class="col-span-5">
                    <div class="flex items-center justify-between mb-1">
                      <label class="block text-[10px] text-slate-400 font-bold uppercase">Item / Part Name</label>
                      <button
                        type="button"
                        @click="openPurchaseScanner('item_picker', idx, 'Scan Barcode or IMEI to Pick Item', 'camera')"
                        class="text-[10px] font-bold text-indigo-600 dark:text-indigo-400 hover:underline flex items-center gap-0.5 cursor-pointer"
                        title="Scan barcode or IMEI to select item from catalog"
                      >
                        <span>📷</span> Scan Item
                      </button>
                    </div>
                    <select
                      v-model="item.inventory_item_id"
                      @change="onSelectInventoryItem(item)"
                      class="w-full px-2.5 py-1.5 text-xs font-semibold bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-lg text-slate-800 dark:text-white"
                    >
                      <option :value="null">-- Select Catalog Item (or enter below) --</option>
                      <option v-for="inv in allInventoryItems" :key="inv.id" :value="inv.id">
                        {{ inv.name }} (Stock: {{ inv.current_stock ?? inv.stock_quantity ?? 0 }})
                      </option>
                    </select>
                    <input
                      v-if="!item.inventory_item_id"
                      v-model="item.item_name"
                      type="text"
                      placeholder="Or enter custom item / part name..."
                      class="w-full mt-1.5 px-2.5 py-1 text-[11px] font-semibold bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-lg text-slate-800 dark:text-white placeholder-slate-400"
                    />
                  </div>

                  <!-- Qty -->
                  <div class="col-span-2">
                    <label class="block text-[10px] text-slate-400 font-bold uppercase mb-1">Qty</label>
                    <input
                      v-model.number="item.quantity"
                      type="number"
                      min="1"
                      required
                      class="w-full px-2.5 py-1.5 text-xs font-bold bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-lg text-center"
                    />
                  </div>

                  <!-- Rate -->
                  <div class="col-span-2">
                    <label class="block text-[10px] text-slate-400 font-bold uppercase mb-1">Cost Rate (₹)</label>
                    <input
                      v-model.number="item.purchase_rate"
                      type="number"
                      step="0.01"
                      min="0"
                      required
                      class="w-full px-2.5 py-1.5 text-xs font-bold bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-lg text-right font-mono"
                    />
                  </div>

                  <!-- Line Total -->
                  <div class="col-span-2 text-right">
                    <label class="block text-[10px] text-slate-400 font-bold uppercase mb-1">Total</label>
                    <div class="font-black text-indigo-600 dark:text-indigo-400 font-mono text-sm py-1">
                      ₹{{ formatAmount((item.quantity || 1) * (item.purchase_rate || 0)) }}
                    </div>
                  </div>

                  <!-- Remove -->
                  <div class="col-span-1 text-center pt-3">
                    <button
                      v-if="purchaseForm.items.length > 1"
                      type="button"
                      @click="removeLineItem(idx)"
                      class="text-rose-500 hover:text-rose-600 p-1 cursor-pointer font-bold"
                      title="Remove Item"
                    >
                      ✕
                    </button>
                  </div>
                </div>

                <!-- Enhanced Device Identifiers & Serial Numbers Card -->
                <div class="p-3 rounded-xl bg-slate-50/80 dark:bg-slate-900/60 border border-slate-200/90 dark:border-slate-800/90 space-y-2 mt-2">
                  <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-1.5 pb-1 border-b border-slate-200/60 dark:border-slate-800/60">
                    <div class="flex items-center gap-2">
                      <span class="text-xs font-bold text-slate-800 dark:text-slate-200 flex items-center gap-1.5">
                        <span>🏷️</span> Device Identifiers (IMEI & Serial)
                      </span>
                      <span v-if="isMobileItem(item)" class="text-[10px] font-bold px-2 py-0.5 rounded-full bg-indigo-100 dark:bg-indigo-950/60 text-indigo-700 dark:text-indigo-300">
                        📱 Mobile Phone
                      </span>
                      <span v-else class="text-[10px] font-medium text-slate-400">
                        Optional for spare parts & accessories
                      </span>
                    </div>

                    <!-- Quick action buttons: Auto-Fetch, Auto-Scan Box, Clear -->
                    <div class="flex items-center gap-1.5">
                      <button
                        v-if="item.imei1 || item.imei2 || item.serial_number"
                        type="button"
                        @click="clearItemIdentifiers(item)"
                        class="inline-flex items-center gap-1 px-2 py-1 rounded-lg text-[10px] font-bold text-rose-600 dark:text-rose-400 bg-rose-50 dark:bg-rose-950/60 hover:bg-rose-100 transition cursor-pointer"
                        title="Clear all IMEI and serial identifiers"
                      >
                        <span>✕</span> Clear
                      </button>

                      <button
                        v-if="item.inventory_item_id"
                        type="button"
                        @click="autoFetchItemDetails(item)"
                        class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-[10px] font-bold text-indigo-700 dark:text-indigo-300 bg-indigo-50 dark:bg-indigo-950/60 hover:bg-indigo-100 dark:hover:bg-indigo-900/60 border border-indigo-200 dark:border-indigo-800/80 transition cursor-pointer"
                        title="Auto-fetch IMEI, Serial and cost rate from inventory catalog"
                      >
                        <span>⚡</span>
                        <span>Auto-Fetch</span>
                      </button>

                      <button
                        type="button"
                        @click="openPurchaseScanner('box', idx, 'Auto-Scan Phone Box Sticker', 'box')"
                        class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-[10px] font-bold text-white bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-500 hover:to-purple-500 transition shadow-xs cursor-pointer"
                        title="Scan phone box sticker to extract IMEI 1, IMEI 2, and Serial"
                      >
                        <span>⚡</span>
                        <span>Auto-Scan Box</span>
                      </button>
                    </div>
                  </div>

                  <div class="grid grid-cols-1 sm:grid-cols-3 gap-2.5 pt-1">
                    <!-- Primary IMEI 1 -->
                    <div>
                      <div class="flex items-center justify-between mb-1">
                        <label class="text-[10px] font-bold uppercase tracking-wider text-slate-600 dark:text-slate-400">
                          Primary IMEI 1 (Optional)
                        </label>
                        <button
                          type="button"
                          @click="openPurchaseScanner('imei1', idx, 'Scan Primary IMEI 1', 'camera')"
                          class="text-[10px] font-bold text-indigo-600 dark:text-indigo-400 hover:underline flex items-center gap-0.5 cursor-pointer"
                        >
                          <span>📷</span> Scan
                        </button>
                      </div>
                      <div class="relative">
                        <input
                          v-model="item.imei1"
                          type="text"
                          maxlength="16"
                          placeholder="15-digit IMEI 1 (Optional)"
                          class="w-full pl-2.5 pr-7 py-1.5 text-xs font-mono font-bold bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400"
                        />
                        <button
                          type="button"
                          @click="openPurchaseScanner('imei1', idx, 'Scan Primary IMEI 1', 'camera')"
                          class="absolute inset-y-0 right-1 px-1.5 flex items-center text-slate-400 hover:text-indigo-600 cursor-pointer"
                          title="Scan IMEI 1"
                        >
                          📷
                        </button>
                      </div>
                    </div>

                    <!-- Secondary IMEI 2 -->
                    <div>
                      <div class="flex items-center justify-between mb-1">
                        <label class="text-[10px] font-bold uppercase tracking-wider text-slate-600 dark:text-slate-400">
                          Secondary IMEI 2 <span class="text-slate-400 font-normal lowercase">(optional)</span>
                        </label>
                        <button
                          type="button"
                          @click="openPurchaseScanner('imei2', idx, 'Scan Secondary IMEI 2', 'camera')"
                          class="text-[10px] font-bold text-indigo-600 dark:text-indigo-400 hover:underline flex items-center gap-0.5 cursor-pointer"
                        >
                          <span>📷</span> Scan
                        </button>
                      </div>
                      <div class="relative">
                        <input
                          v-model="item.imei2"
                          type="text"
                          maxlength="16"
                          placeholder="15-digit IMEI 2"
                          class="w-full pl-2.5 pr-7 py-1.5 text-xs font-mono font-bold bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400"
                        />
                        <button
                          type="button"
                          @click="openPurchaseScanner('imei2', idx, 'Scan Secondary IMEI 2', 'camera')"
                          class="absolute inset-y-0 right-1 px-1.5 flex items-center text-slate-400 hover:text-indigo-600 cursor-pointer"
                          title="Scan IMEI 2"
                        >
                          📷
                        </button>
                      </div>
                    </div>

                    <!-- Serial Number / Box Barcode -->
                    <div>
                      <div class="flex items-center justify-between mb-1">
                        <label class="text-[10px] font-bold uppercase tracking-wider text-slate-600 dark:text-slate-400">
                          Serial # / Barcode <span class="text-slate-400 font-normal lowercase">(optional)</span>
                        </label>
                        <button
                          type="button"
                          @click="openPurchaseScanner('serial', idx, 'Scan Serial Number', 'camera')"
                          class="text-[10px] font-bold text-indigo-600 dark:text-indigo-400 hover:underline flex items-center gap-0.5 cursor-pointer"
                        >
                          <span>📷</span> Scan
                        </button>
                      </div>
                      <div class="relative">
                        <input
                          v-model="item.serial_number"
                          type="text"
                          placeholder="e.g. SN12984X / Barcode"
                          class="w-full pl-2.5 pr-7 py-1.5 text-xs font-mono font-bold bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400"
                        />
                        <button
                          type="button"
                          @click="openPurchaseScanner('serial', idx, 'Scan Serial Number', 'camera')"
                          class="absolute inset-y-0 right-1 px-1.5 flex items-center text-slate-400 hover:text-indigo-600 cursor-pointer"
                          title="Scan Serial"
                        >
                          📷
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Calculations Strip -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
            <!-- Left: Notes & Inward options -->
            <div class="space-y-3">
              <div>
                <label class="block font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1">
                  Supplier Notes / Invoice Ref
                </label>
                <textarea
                  v-model="purchaseForm.notes"
                  rows="2"
                  placeholder="e.g. Supplier invoice #INV-4921, received in good condition..."
                  class="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500"
                ></textarea>
              </div>

              <!-- Payment Mode & Status -->
              <div class="grid grid-cols-2 gap-2">
                <div>
                  <label class="block font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1">
                    Payment Status
                  </label>
                  <select
                    v-model="purchaseForm.payment_status"
                    class="w-full px-3 py-2 text-xs font-semibold bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl"
                  >
                    <option value="pending">Pending (Unpaid)</option>
                    <option value="partial">Partial Payment</option>
                    <option value="paid">Fully Paid</option>
                  </select>
                </div>

                <div>
                  <label class="block font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1">
                    Amount Paid Now (₹)
                  </label>
                  <input
                    v-model.number="purchaseForm.amount_paid"
                    type="number"
                    step="0.01"
                    min="0"
                    :max="calculatedGrandTotal"
                    class="w-full px-3 py-2 text-xs font-bold bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl font-mono text-right"
                  />
                </div>
              </div>
            </div>

            <!-- Right: Subtotal, Discount, Charges, Grand Total -->
            <div class="p-4 rounded-2xl bg-indigo-50/40 dark:bg-indigo-950/20 border border-indigo-100 dark:border-indigo-900/40 space-y-2">
              <div class="flex justify-between items-center text-slate-600 dark:text-slate-400">
                <span>Items Subtotal:</span>
                <span class="font-mono font-bold text-slate-900 dark:text-white">₹{{ formatAmount(calculatedSubtotal) }}</span>
              </div>

              <div class="flex justify-between items-center text-slate-600 dark:text-slate-400">
                <span>Discount (₹):</span>
                <input
                  v-model.number="purchaseForm.discount"
                  type="number"
                  min="0"
                  class="w-24 px-2 py-0.5 text-right font-mono font-semibold bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-lg"
                />
              </div>

              <div class="flex justify-between items-center text-slate-600 dark:text-slate-400">
                <span>Freight / Extra Charges (₹):</span>
                <input
                  v-model.number="purchaseForm.additional_charges"
                  type="number"
                  min="0"
                  class="w-24 px-2 py-0.5 text-right font-mono font-semibold bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-lg"
                />
              </div>

              <div class="pt-2 border-t border-indigo-200/60 dark:border-indigo-800/60 flex justify-between items-center">
                <span class="font-extrabold text-slate-900 dark:text-white">Grand Total:</span>
                <span class="text-base font-black text-indigo-600 dark:text-indigo-400 font-mono">₹{{ formatAmount(calculatedGrandTotal) }}</span>
              </div>

              <div class="flex justify-between items-center text-xs pt-1">
                <span class="text-slate-500 font-semibold">Remaining Due:</span>
                <span class="font-mono font-bold text-rose-600">₹{{ formatAmount(Math.max(0, calculatedGrandTotal - (purchaseForm.amount_paid || 0))) }}</span>
              </div>
            </div>
          </div>

          <div class="pt-3 border-t border-slate-100 dark:border-slate-800 flex justify-end gap-2.5">
            <button
              @click="createPurchaseModalOpen = false"
              type="button"
              class="px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-300 text-xs font-bold cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="savingPurchase"
              class="px-5 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold shadow-md shadow-indigo-600/20 disabled:opacity-50 transition cursor-pointer"
            >
              {{ savingPurchase ? 'Saving Order...' : 'Confirm & Save Purchase' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- ========================================================================= -->
    <!-- MODAL 2: PURCHASE DETAILS & PRINT RECEIPT                                 -->
    <!-- ========================================================================= -->
    <div v-if="detailModalOpen" class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 overflow-y-auto">
      <div @click="detailModalOpen = false" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm"></div>

      <div class="relative w-full max-w-2xl bg-white dark:bg-[#111827] rounded-3xl border border-slate-200/80 dark:border-slate-800/80 shadow-2xl p-6 z-10 space-y-4 max-h-[85vh] overflow-y-auto custom-scroll">
        <!-- Header -->
        <div class="flex items-start justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
          <div>
            <div class="flex items-center gap-2">
              <span class="font-mono font-black text-lg text-indigo-600 dark:text-indigo-400">
                {{ selectedPurchase?.purchase_number || ('#PUR-' + selectedPurchase?.id) }}
              </span>
              <span
                class="px-2.5 py-0.5 rounded-full text-xs font-bold uppercase"
                :class="selectedPurchase?.payment_status === 'paid' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' : 'bg-rose-50 text-rose-700 border border-rose-200'"
              >
                {{ selectedPurchase?.payment_status || 'Pending' }}
              </span>
            </div>
            <p class="text-xs text-slate-400 mt-0.5">
              Purchased on {{ formatDate(selectedPurchase?.purchase_date || selectedPurchase?.created_at) }}
            </p>
          </div>
          <div class="flex items-center gap-2">
            <button
              @click="printPurchaseReceipt"
              type="button"
              class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-200 text-xs font-semibold hover:bg-slate-50 transition cursor-pointer"
            >
              <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4H7v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"/></svg>
              Print Bill
            </button>
            <button @click="detailModalOpen = false" class="p-2 text-slate-400 hover:text-slate-600">✕</button>
          </div>
        </div>

        <!-- Vendor & Bill Info Strip -->
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-3 text-xs">
          <div class="p-3 rounded-2xl bg-slate-50 dark:bg-slate-900/60 border border-slate-100 dark:border-slate-800">
            <span class="text-slate-400 block font-semibold">Vendor / Supplier</span>
            <p class="font-bold text-slate-900 dark:text-white text-sm mt-0.5">{{ selectedPurchase?.vendor?.name || selectedPurchase?.vendor_name || 'Direct Wholesale' }}</p>
            <p class="font-mono text-slate-500 mt-0.5">{{ selectedPurchase?.vendor?.phone || '-' }}</p>
          </div>

          <div class="p-3 rounded-2xl bg-slate-50 dark:bg-slate-900/60 border border-slate-100 dark:border-slate-800">
            <span class="text-slate-400 block font-semibold">Financials</span>
            <p class="font-bold text-indigo-600 dark:text-indigo-400 text-sm mt-0.5">Total: ₹{{ formatAmount(selectedPurchase?.grand_total || selectedPurchase?.total_amount) }}</p>
            <p class="text-slate-500 mt-0.5">Paid: ₹{{ formatAmount(selectedPurchase?.amount_paid || 0) }}</p>
          </div>

          <div class="p-3 rounded-2xl bg-slate-50 dark:bg-slate-900/60 border border-slate-100 dark:border-slate-800">
            <span class="text-slate-400 block font-semibold">Outstanding Balance</span>
            <p class="font-bold text-rose-600 text-sm mt-0.5">₹{{ formatAmount(selectedPurchase?.outstanding_amount || selectedPurchase?.due_amount || 0) }}</p>
            <button
              v-if="Number(selectedPurchase?.outstanding_amount || selectedPurchase?.due_amount) > 0"
              @click="openAddPaymentModal(selectedPurchase)"
              class="mt-1 px-2 py-0.5 rounded bg-emerald-600 text-white font-bold text-[10px] hover:bg-emerald-500 cursor-pointer"
            >
              + Record Payment
            </button>
          </div>
        </div>

        <!-- Purchased Line Items -->
        <div class="space-y-2">
          <h4 class="text-xs font-bold uppercase tracking-wider text-slate-700 dark:text-slate-300">
            Purchased Products & Parts
          </h4>
          <div class="overflow-x-auto rounded-xl border border-slate-200 dark:border-slate-800">
            <table class="w-full text-left text-xs">
              <thead class="bg-slate-50 dark:bg-slate-900 text-slate-500 font-bold uppercase text-[10px]">
                <tr>
                  <th class="py-2.5 px-3">Item Name</th>
                  <th class="py-2.5 px-3 text-center">Qty</th>
                  <th class="py-2.5 px-3 text-right">Cost Rate</th>
                  <th class="py-2.5 px-3 text-right">Line Total</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 dark:divide-slate-800 font-medium">
                <tr v-for="(it, i) in (selectedPurchase?.items || [])" :key="i">
                  <td class="py-2 px-3">
                    <p class="font-bold text-slate-900 dark:text-white">{{ it.item_name || it.inventory_item?.name || 'Part' }}</p>
                    <p v-if="it.imei1 || it.serial_number" class="text-[10px] font-mono text-slate-400">
                      {{ it.imei1 ? `IMEI: ${it.imei1}` : '' }} {{ it.serial_number ? `S/N: ${it.serial_number}` : '' }}
                    </p>
                  </td>
                  <td class="py-2 px-3 text-center font-bold">{{ it.quantity }}</td>
                  <td class="py-2 px-3 text-right font-mono">₹{{ formatAmount(it.purchase_rate || it.cost_price) }}</td>
                  <td class="py-2 px-3 text-right font-mono font-bold text-slate-900 dark:text-white">
                    ₹{{ formatAmount(it.total_amount || (it.quantity * it.purchase_rate)) }}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- Payments Made -->
        <div v-if="selectedPurchase?.payments && selectedPurchase.payments.length > 0" class="space-y-2">
          <h4 class="text-xs font-bold uppercase tracking-wider text-slate-700 dark:text-slate-300">
            Payments Settled ({{ selectedPurchase.payments.length }})
          </h4>
          <div class="space-y-1.5">
            <div
              v-for="pm in selectedPurchase.payments"
              :key="pm.id"
              class="p-2.5 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200/60 dark:border-slate-800/60 flex items-center justify-between text-xs"
            >
              <div>
                <span class="font-bold text-emerald-600 font-mono">₹{{ formatAmount(pm.amount) }}</span>
                <span class="text-slate-400 ml-2">via {{ pm.payment_method }}</span>
                <p v-if="pm.notes" class="text-[11px] text-slate-400 mt-0.5">{{ pm.notes }}</p>
              </div>
              <span class="text-slate-400 text-[11px]">{{ formatDate(pm.payment_date || pm.created_at) }}</span>
            </div>
          </div>
        </div>

        <div class="pt-3 border-t border-slate-100 dark:border-slate-800 flex justify-end gap-2">
          <button
            @click="detailModalOpen = false"
            type="button"
            class="px-5 py-2 rounded-xl bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 text-xs font-bold hover:bg-slate-200 cursor-pointer"
          >
            Close
          </button>
        </div>
      </div>
    </div>

    <!-- ========================================================================= -->
    <!-- MODAL 3: RECORD PAYMENT TO VENDOR                                         -->
    <!-- ========================================================================= -->
    <div v-if="paymentModalOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4 overflow-y-auto">
      <div @click="paymentModalOpen = false" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm"></div>

      <div class="relative w-full max-w-md bg-white dark:bg-[#111827] rounded-3xl border border-slate-200/80 dark:border-slate-800/80 shadow-2xl p-6 z-10 space-y-4">
        <div class="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
          <div>
            <h3 class="text-base font-black text-slate-900 dark:text-white">Record Payment to Vendor</h3>
            <p class="text-xs text-slate-400">
              For {{ activeTargetForPayment?.vendor?.name || activeTargetForPayment?.name || 'Supplier' }}
            </p>
          </div>
          <button @click="paymentModalOpen = false" class="p-2 text-slate-400 hover:text-slate-600">✕</button>
        </div>

        <form @submit.prevent="submitRecordPayment" class="space-y-4 text-xs">
          <div>
            <label class="block font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
              Payment Amount (₹) <span class="text-rose-500">*</span>
            </label>
            <input
              v-model.number="paymentForm.amount"
              type="number"
              step="0.01"
              min="1"
              required
              class="w-full px-3.5 py-2.5 text-sm font-black bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 font-mono text-slate-900 dark:text-white"
            />
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
                Payment Mode <span class="text-rose-500">*</span>
              </label>
              <select
                v-model="paymentForm.payment_method"
                class="w-full px-3.5 py-2 text-xs font-semibold bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl"
              >
                <option value="cash">Cash 💵</option>
                <option value="upi">UPI / GPay / PhonePe ⚡</option>
                <option value="bank_transfer">Bank Transfer / IMPS 🏦</option>
                <option value="card">Debit / Credit Card 💳</option>
              </select>
            </div>

            <div>
              <label class="block font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
                Payment Date
              </label>
              <DatePicker v-model="paymentForm.payment_date" />
            </div>
          </div>

          <div>
            <label class="block font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
              Reference / Note
            </label>
            <input
              v-model="paymentForm.notes"
              type="text"
              placeholder="e.g. UTR #, Cheque #, or counter cash receipt"
              class="w-full px-3.5 py-2 text-xs bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl"
            />
          </div>

          <div class="pt-3 border-t border-slate-100 dark:border-slate-800 flex justify-end gap-2.5">
            <button
              @click="paymentModalOpen = false"
              type="button"
              class="px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-300 font-bold"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="submittingPayment"
              class="px-5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-bold shadow-md shadow-emerald-600/20 disabled:opacity-50 transition cursor-pointer"
            >
              {{ submittingPayment ? 'Recording...' : 'Confirm Payment' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- ========================================================================= -->
    <!-- MODAL 4: ADD / EDIT VENDOR MODAL                                          -->
    <!-- ========================================================================= -->
    <div v-if="vendorModalOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4 overflow-y-auto">
      <div @click="vendorModalOpen = false" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm"></div>

      <div class="relative w-full max-w-lg bg-white dark:bg-[#111827] rounded-3xl border border-slate-200/80 dark:border-slate-800/80 shadow-2xl p-6 z-10 space-y-4">
        <div class="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
          <div>
            <h3 class="text-base font-black text-slate-900 dark:text-white">
              {{ isEditingVendor ? 'Edit Supplier Profile' : 'Add New Vendor / Supplier' }}
            </h3>
            <p class="text-xs text-slate-400">Manage procurement partner details</p>
          </div>
          <button @click="vendorModalOpen = false" class="p-2 text-slate-400 hover:text-slate-600">✕</button>
        </div>

        <form @submit.prevent="submitVendorForm" class="space-y-3.5 text-xs">
          <div>
            <label class="block font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1">
              Vendor Business Name <span class="text-rose-500">*</span>
            </label>
            <input
              v-model="vendorForm.name"
              type="text"
              required
              placeholder="e.g. Metro Mobile Wholesale"
              class="w-full px-3.5 py-2.5 text-xs font-semibold bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-white"
            />
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1">
                Phone Number <span class="text-rose-500">*</span>
              </label>
              <input
                v-model="vendorForm.phone"
                type="tel"
                required
                placeholder="10-digit mobile"
                class="w-full px-3.5 py-2 text-xs font-mono bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl"
              />
            </div>
            <div>
              <label class="block font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1">
                Contact Person
              </label>
              <input
                v-model="vendorForm.contact_person"
                type="text"
                placeholder="Manager / Owner name"
                class="w-full px-3.5 py-2 text-xs bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl"
              />
            </div>
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1">
                GSTIN / Tax ID
              </label>
              <input
                v-model="vendorForm.gst_number"
                type="text"
                placeholder="15-digit GSTIN"
                class="w-full px-3.5 py-2 text-xs font-mono uppercase bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl"
              />
            </div>
            <div>
              <label class="block font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1">
                Email Address
              </label>
              <input
                v-model="vendorForm.email"
                type="email"
                placeholder="vendor@domain.com"
                class="w-full px-3.5 py-2 text-xs bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl"
              />
            </div>
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1">
                City
              </label>
              <input
                v-model="vendorForm.city"
                type="text"
                placeholder="e.g. Mumbai, Surat"
                class="w-full px-3.5 py-2 text-xs bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl"
              />
            </div>
            <div>
              <label class="block font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1">
                Opening Balance Due (₹)
              </label>
              <input
                v-model.number="vendorForm.opening_balance"
                type="number"
                min="0"
                placeholder="0"
                class="w-full px-3.5 py-2 text-xs font-mono bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl"
              />
            </div>
          </div>

          <div>
            <label class="block font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1">
              Shop / Office Address
            </label>
            <textarea
              v-model="vendorForm.address"
              rows="2"
              placeholder="Market shop number, road, landmark..."
              class="w-full px-3.5 py-2 text-xs bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl"
            ></textarea>
          </div>

          <div class="pt-3 border-t border-slate-100 dark:border-slate-800 flex justify-end gap-2.5">
            <button
              @click="vendorModalOpen = false"
              type="button"
              class="px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-300 font-bold"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="savingVendor"
              class="px-5 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-bold shadow-md shadow-indigo-600/20 disabled:opacity-50 transition cursor-pointer"
            >
              {{ savingVendor ? 'Saving...' : (isEditingVendor ? 'Update Supplier' : 'Save Supplier') }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- ========================================================================= -->
    <!-- MODAL 5: VENDOR DETAIL & LEDGER DRAWER                                    -->
    <!-- ========================================================================= -->
    <div v-if="vendorDetailOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4 overflow-y-auto">
      <div @click="vendorDetailOpen = false" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm"></div>

      <div class="relative w-full max-w-2xl bg-white dark:bg-[#111827] rounded-3xl border border-slate-200/80 dark:border-slate-800/80 shadow-2xl p-6 z-10 space-y-4 max-h-[85vh] overflow-y-auto custom-scroll">
        <div class="flex items-start justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
          <div>
            <h3 class="text-base font-black text-slate-900 dark:text-white">{{ selectedVendor?.name }}</h3>
            <p class="text-xs text-slate-400 font-mono">{{ selectedVendor?.phone }} {{ selectedVendor?.city ? '• ' + selectedVendor.city : '' }}</p>
          </div>
          <button @click="vendorDetailOpen = false" class="p-2 text-slate-400 hover:text-slate-600">✕</button>
        </div>

        <div class="grid grid-cols-3 gap-3 text-xs">
          <div class="p-3 rounded-2xl bg-slate-50 dark:bg-slate-900 border border-slate-100 dark:border-slate-800">
            <span class="text-slate-400 block font-semibold">Total Purchases</span>
            <p class="font-bold text-slate-900 dark:text-white text-sm mt-0.5">₹{{ formatAmount(selectedVendor?.total_purchase || 0) }}</p>
          </div>
          <div class="p-3 rounded-2xl bg-slate-50 dark:bg-slate-900 border border-slate-100 dark:border-slate-800">
            <span class="text-slate-400 block font-semibold">Total Settled</span>
            <p class="font-bold text-emerald-600 text-sm mt-0.5">₹{{ formatAmount(selectedVendor?.total_paid || 0) }}</p>
          </div>
          <div class="p-3 rounded-2xl bg-slate-50 dark:bg-slate-900 border border-slate-100 dark:border-slate-800">
            <span class="text-slate-400 block font-semibold">Pending Due</span>
            <p class="font-bold text-rose-600 text-sm mt-0.5">₹{{ formatAmount(selectedVendor?.outstanding_amount || 0) }}</p>
          </div>
        </div>

        <!-- Vendor Orders List -->
        <div class="space-y-2">
          <div class="flex items-center justify-between">
            <h4 class="text-xs font-bold uppercase tracking-wider text-slate-700 dark:text-slate-300">
              Purchase Orders History
            </h4>
            <span v-if="selectedVendor?.purchases?.length" class="text-[11px] font-semibold text-slate-400">
              {{ selectedVendor.purchases.length }} bill(s)
            </span>
          </div>

          <div v-if="loadingVendorHistory" class="text-center py-6 border border-dashed border-slate-200 dark:border-slate-800 rounded-2xl text-xs text-slate-400">
            <div class="inline-block animate-spin w-5 h-5 border-2 border-indigo-600 border-t-transparent rounded-full mb-1.5"></div>
            <div>Loading purchase history...</div>
          </div>
          <div v-else-if="!selectedVendor?.purchases || selectedVendor.purchases.length === 0" class="text-center py-6 border border-dashed border-slate-200 dark:border-slate-800 rounded-2xl text-xs text-slate-400">
            No purchase orders logged with this vendor yet.
          </div>
          <div v-else class="space-y-2 max-h-64 overflow-y-auto custom-scroll pr-1">
            <div
              v-for="po in selectedVendor.purchases"
              :key="po.id"
              class="p-3 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 flex items-center justify-between text-xs hover:border-indigo-200 dark:hover:border-slate-700 transition"
            >
              <div>
                <div class="flex items-center gap-2">
                  <span class="font-mono font-bold text-indigo-600 dark:text-indigo-400">#{{ po.purchase_number || po.id }}</span>
                  <span
                    class="px-2 py-0.2 rounded-full text-[10px] font-bold border uppercase"
                    :class="getPaymentBadgeClasses(po.payment_status).badge"
                  >
                    {{ po.payment_status || 'unpaid' }}
                  </span>
                </div>
                <div class="text-slate-400 text-[11px] mt-0.5 flex items-center gap-2">
                  <span>{{ formatDate(po.purchase_date || po.created_at) }}</span>
                  <span>• Due: ₹{{ formatAmount(po.outstanding_amount ?? po.due_amount ?? 0) }}</span>
                  <span>• Paid: ₹{{ formatAmount(po.amount_paid || 0) }}</span>
                </div>
              </div>

              <div class="text-right">
                <span class="font-black text-slate-900 dark:text-white font-mono text-sm block">
                  ₹{{ formatAmount(po.grand_total ?? po.total_amount ?? 0) }}
                </span>
                <button
                  type="button"
                  @click="vendorDetailOpen = false; openPurchaseDetail(po)"
                  class="text-[10px] font-bold text-indigo-600 hover:underline mt-0.5 cursor-pointer"
                >
                  View Bill →
                </button>
              </div>
            </div>
          </div>
        </div>

        <div class="pt-3 border-t border-slate-100 dark:border-slate-800 flex justify-end">
          <button
            @click="vendorDetailOpen = false"
            class="px-5 py-2 rounded-xl bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 text-xs font-bold"
          >
            Close
          </button>
        </div>
      </div>
    </div>

    <!-- Barcode & IMEI Scanner Modal -->
    <BarcodeScannerModal
      :is-open="scannerOpen"
      :title="scannerTitle"
      :initial-mode="scannerInitialMode"
      @close="scannerOpen = false"
      @scan="handleScanResult"
      @box-result="handleBoxResult"
    />
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch, onMounted } from 'vue';
import { purchaseApi, vendorApi, inventoryApi } from '@/api/endpoints';
import { useToastStore } from '@/stores/toast';
import { useAuthStore } from '@/stores/auth';
import { useFilterStore } from '@/stores/filter';
import PaginationBar from '@/components/common/PaginationBar.vue';
import SearchableSelect from '@/components/common/SearchableSelect.vue';
import WhatsAppIcon from '@/components/common/WhatsAppIcon.vue';
import BarcodeScannerModal from '@/components/common/BarcodeScannerModal.vue';
import DatePicker from '@/components/common/DatePicker.vue';
import { formatDate, toInputDate } from '@/utils/date';

const toast = useToastStore();
const authStore = useAuthStore();
const filterStore = useFilterStore();

// Tabs: 'purchases' or 'vendors'
const activeTab = ref('purchases');

// Purchases State
const purchases = ref([]);
const loadingPurchases = ref(false);
const currentPage = ref(1);
const perPage = ref(15);
const purchasesTotalCount = ref(0);
const purchasesTotalPages = ref(1);
const purchaseMetrics = reactive({
  total_purchases: 0,
  total_amount: 0,
  total_paid: 0,
  total_outstanding: 0,
});

// Vendors State
const vendors = ref([]);
const loadingVendors = ref(false);
const vendorCurrentPage = ref(1);
const vendorsTotalCount = ref(0);
const vendorsTotalPages = ref(1);
const vendorMetrics = reactive({
  total_vendors: 0,
  total_purchases: 0,
  total_paid: 0,
  total_outstanding: 0,
});

// Filters
const searchQuery = ref('');
const paymentStatusFilter = ref('');
let searchDebounceTimer = null;

const paymentStatusOptions = [
  { value: '', label: 'All Payment Status' },
  { value: 'paid', label: 'Fully Paid' },
  { value: 'partial', label: 'Partial Payment' },
  { value: 'pending', label: 'Pending / Due' },
];

const sortBy = ref('newest');
const sortOptions = [
  { value: 'newest', label: 'Newest First (Recent)' },
  { value: 'oldest', label: 'Oldest First' },
  { value: 'amount_high', label: 'Amount (High to Low)' },
  { value: 'amount_low', label: 'Amount (Low to High)' },
];

// Auxiliary Data
const allVendorsList = ref([]);
const allInventoryItems = ref([]);

// Barcode & IMEI Scanner State
const scannerOpen = ref(false);
const scannerTitle = ref('Scan Barcode or IMEI');
const scannerInitialMode = ref('camera');
const scannerTargetField = ref('');
const scannerTargetIndex = ref(null);

// Modals State
const createPurchaseModalOpen = ref(false);
const savingPurchase = ref(false);
const purchaseForm = reactive({
  vendor_id: null,
  purchase_date: toInputDate(new Date()),
  items: [
    { inventory_item_id: null, item_name: '', quantity: 1, purchase_rate: 0, imei1: '', imei2: '', serial_number: '' }
  ],
  discount: 0,
  additional_charges: 0,
  payment_status: 'pending',
  amount_paid: 0,
  notes: '',
});

const detailModalOpen = ref(false);
const selectedPurchase = ref(null);

const paymentModalOpen = ref(false);
const activeTargetForPayment = ref(null);
const submittingPayment = ref(false);
const paymentForm = reactive({
  amount: 0,
  payment_method: 'cash',
  payment_date: new Date().toISOString().split('T')[0],
  notes: '',
});

const vendorModalOpen = ref(false);
const isEditingVendor = ref(false);
const savingVendor = ref(false);
const vendorForm = reactive({
  id: null,
  name: '',
  contact_person: '',
  phone: '',
  email: '',
  gst_number: '',
  city: '',
  address: '',
  opening_balance: 0,
});

const vendorDetailOpen = ref(false);
const selectedVendor = ref(null);
const loadingVendorHistory = ref(false);

// Calculations for purchase draft
const calculatedSubtotal = computed(() => {
  return purchaseForm.items.reduce((sum, item) => {
    return sum + ((Number(item.quantity) || 0) * (Number(item.purchase_rate) || 0));
  }, 0);
});

const calculatedGrandTotal = computed(() => {
  const net = calculatedSubtotal.value - (Number(purchaseForm.discount) || 0) + (Number(purchaseForm.additional_charges) || 0);
  return Math.max(0, net);
});

watch(() => purchaseForm.payment_status, (newStatus) => {
  if (newStatus === 'paid') {
    purchaseForm.amount_paid = calculatedGrandTotal.value;
  } else if (newStatus === 'pending') {
    purchaseForm.amount_paid = 0;
  }
});

// Watch filters to reset page to 1
watch([searchQuery, paymentStatusFilter, activeTab], () => {
  if (activeTab.value === 'purchases') {
    currentPage.value = 1;
  } else {
    vendorCurrentPage.value = 1;
  }
});

function debounceSearch() {
  clearTimeout(searchDebounceTimer);
  searchDebounceTimer = setTimeout(() => {
    if (activeTab.value === 'purchases') {
      currentPage.value = 1;
      fetchPurchases();
    } else {
      vendorCurrentPage.value = 1;
      fetchVendors();
    }
  }, 350);
}

function onFilterChange() {
  if (activeTab.value === 'purchases') {
    currentPage.value = 1;
    fetchPurchases();
  }
}

function resetPurchaseFilters() {
  searchQuery.value = '';
  paymentStatusFilter.value = '';
  sortBy.value = 'newest';
  filterStore.setPeriod('this_month');
  currentPage.value = 1;
  fetchPurchases();
}

function onPurchasesPageChange(p) {
  currentPage.value = p;
  fetchPurchases();
}

function onVendorsPageChange(p) {
  vendorCurrentPage.value = p;
  fetchVendors();
}

// Formatters
function formatAmount(val) {
  if (!val && val !== 0) return '0';
  return Number(val).toLocaleString('en-IN', { maximumFractionDigits: 2 });
}


function cleanPhone(phone) {
  return String(phone || '').replace(/\D/g, '').slice(-10);
}

// Line items management
function addLineItem() {
  purchaseForm.items.push({
    inventory_item_id: null,
    item_name: '',
    quantity: 1,
    purchase_rate: 0,
    imei1: '',
    imei2: '',
    serial_number: '',
  });
}

function clearItemIdentifiers(itemRow) {
  if (!itemRow) return;
  itemRow.imei1 = '';
  itemRow.imei2 = '';
  itemRow.serial_number = '';
}

function isMobileItem(item) {
  if (!item) return false;

  // 1. If catalog item selected, check its classification and category
  if (item.inventory_item_id) {
    const inv = allInventoryItems.value.find(i => i.id === item.inventory_item_id);
    if (inv) {
      if (inv.item_type && inv.item_type !== 'mobile') {
        return false;
      }
      if (inv.category) {
        const cat = inv.category.toLowerCase();
        if (
          cat.includes('cover') ||
          cat.includes('case') ||
          cat.includes('accessory') ||
          cat.includes('accessories') ||
          cat.includes('spare') ||
          cat.includes('part') ||
          cat.includes('glass') ||
          cat.includes('screen') ||
          cat.includes('battery') ||
          cat.includes('cable') ||
          cat.includes('charger')
        ) {
          return false;
        }
        if (cat === 'mobile phone' || cat === 'mobile phones' || cat === 'mobile' || cat === 'smartphones') {
          return true;
        }
      }
      if (inv.item_type === 'mobile') {
        return true;
      }
    }
  }

  // 2. Check item name keywords
  const name = (item.item_name || '').toLowerCase();

  // If item name indicates accessories or spare parts, it is NOT a mobile phone
  const nonMobileKeywords = [
    'cover', 'covers', 'case', 'cases', 'glass', 'guard', 'tempered',
    'screen', 'display', 'combo', 'battery', 'cable', 'charger', 'adapter',
    'earphone', 'headphone', 'speaker', 'mic', 'housing', 'flex', 'back glass'
  ];
  for (const kw of nonMobileKeywords) {
    if (name.includes(kw)) {
      return false;
    }
  }

  if (
    name.includes('iphone') ||
    name.includes('galaxy') ||
    name.includes('redmi') ||
    name.includes('oneplus') ||
    name.includes('pixel') ||
    name.includes('xiaomi') ||
    name.includes('realme') ||
    name.includes('vivo') ||
    name.includes('oppo') ||
    name.includes('motorola') ||
    name.includes('samsung')
  ) {
    return true;
  }
  return false;
}

function autoFetchItemDetails(itemRow) {
  if (!itemRow.inventory_item_id) {
    clearItemIdentifiers(itemRow);
    toast.info('Please select an inventory item first to auto-fetch details.');
    return;
  }
  const selected = allInventoryItems.value.find(i => i.id === itemRow.inventory_item_id);
  if (!selected) return;

  itemRow.item_name = selected.name;
  itemRow.purchase_rate = Number(selected.purchase_price || selected.cost_price || 0);

  // ALWAYS clear prior item's IMEI/serial numbers on product change!
  clearItemIdentifiers(itemRow);

  // If this item itself has pre-configured IMEI / Serial, populate them
  if (selected.imei1) itemRow.imei1 = selected.imei1;
  if (selected.imei2) itemRow.imei2 = selected.imei2;
  if (selected.serial_number || selected.sku) {
    itemRow.serial_number = selected.serial_number || selected.sku;
  }

  // Also query fresh item details from inventory API
  inventoryApi.get(selected.id).then(res => {
    const detail = res.data?.data || res.data;
    if (detail) {
      if (detail.purchase_price) itemRow.purchase_rate = Number(detail.purchase_price);
      const firstSerial = (Array.isArray(detail.serials) && detail.serials.length > 0) ? detail.serials[0] : null;
      if (firstSerial?.imei1) itemRow.imei1 = firstSerial.imei1;
      else if (detail.imei1) itemRow.imei1 = detail.imei1;

      if (firstSerial?.imei2) itemRow.imei2 = firstSerial.imei2;
      else if (detail.imei2) itemRow.imei2 = detail.imei2;

      if (firstSerial?.serial_number) itemRow.serial_number = firstSerial.serial_number;
      else if (detail.serial_number) itemRow.serial_number = detail.serial_number;
    }
  }).catch(() => {});

  if (isMobileItem(itemRow)) {
    toast.success(`Loaded mobile: ${selected.name}`, 'Item Selected');
  } else {
    toast.success(`Loaded catalog item: ${selected.name}`, 'Item Selected');
  }
}

function onSelectInventoryItem(itemRow) {
  // Clear previous IMEIs and Serial numbers immediately upon changing product
  clearItemIdentifiers(itemRow);

  if (!itemRow.inventory_item_id) {
    itemRow.item_name = '';
    itemRow.purchase_rate = 0;
    return;
  }
  autoFetchItemDetails(itemRow);
}

// Barcode & IMEI Scanner Handlers for Purchase
function openPurchaseScanner(field, index = null, title = 'Scan Barcode or IMEI', mode = 'camera') {
  scannerTargetField.value = field;
  scannerTargetIndex.value = index;
  scannerTitle.value = title;
  scannerInitialMode.value = mode;
  scannerOpen.value = true;
}

function cleanScannedCode(raw) {
  if (!raw) return '';
  return raw.replace(/^(s\/n|sn|serial|imei1|imei2|imei|p\/n|pn)[:\s-]+/i, '').trim();
}

function handleScanResult(code) {
  if (!code) return;
  const clean = cleanScannedCode(code);
  const idx = scannerTargetIndex.value;
  const targetItem = (idx !== null && purchaseForm.items[idx]) ? purchaseForm.items[idx] : null;

  switch (scannerTargetField.value) {
    case 'imei1':
      if (targetItem) {
        targetItem.imei1 = clean;
        toast.success(`Scanned Primary IMEI 1: ${clean}`, 'Scanned');
      }
      break;
    case 'imei2':
      if (targetItem) {
        targetItem.imei2 = clean;
        toast.success(`Scanned Secondary IMEI 2: ${clean}`, 'Scanned');
      }
      break;
    case 'serial':
      if (targetItem) {
        targetItem.serial_number = clean;
        toast.success(`Scanned Serial / Barcode: ${clean}`, 'Scanned');
      }
      break;
    case 'item_picker':
      const matched = allInventoryItems.value.find(i =>
        (i.sku && i.sku.toLowerCase() === clean.toLowerCase()) ||
        (i.barcode && i.barcode.toLowerCase() === clean.toLowerCase()) ||
        (i.imei1 && i.imei1 === clean) ||
        (i.imei2 && i.imei2 === clean) ||
        (i.serial_number && i.serial_number.toLowerCase() === clean.toLowerCase())
      );
      if (matched && targetItem) {
        targetItem.inventory_item_id = matched.id;
        autoFetchItemDetails(targetItem);
        toast.success(`Matched & auto-fetched: ${matched.name}`, 'Item Found');
      } else if (targetItem) {
        targetItem.serial_number = clean;
        toast.info(`Scanned Code: ${clean}`);
      }
      break;
  }
  scannerOpen.value = false;
}

function handleBoxResult(res) {
  const idx = scannerTargetIndex.value;
  const targetItem = (idx !== null && purchaseForm.items[idx]) ? purchaseForm.items[idx] : null;
  if (targetItem) {
    if (res.imei1) targetItem.imei1 = res.imei1;
    if (res.imei2) targetItem.imei2 = res.imei2;
    if (res.serialNumber) targetItem.serial_number = res.serialNumber;
    toast.success('Extracted IMEIs and Serial from box sticker!', 'Auto-Scan Success');
  }
  scannerOpen.value = false;
}

function removeLineItem(idx) {
  if (purchaseForm.items.length > 1) {
    purchaseForm.items.splice(idx, 1);
  }
}

function getTotalPurchaseQuantity(p) {
  if (!p) return 0;
  if (Array.isArray(p.items) && p.items.length > 0) {
    return p.items.reduce((sum, item) => sum + (Number(item.quantity) || 0), 0);
  }
  return 1;
}

function getPurchaseItemsPreview(p) {
  if (!p || !Array.isArray(p.items) || p.items.length === 0) {
    return p?.notes || 'Inventory Stock Package';
  }
  return p.items.map(i => {
    const name = i.item_name || i.inventory_item?.name || 'Part';
    const qty = Number(i.quantity) || 1;
    return `${name} (x${qty})`;
  }).join(', ');
}

function getPaymentBadgeClasses(status) {
  const s = String(status || '').toLowerCase();
  if (s === 'paid' || s === 'fully_paid') {
    return {
      badge: 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 border-emerald-200 dark:border-emerald-900/40',
      label: 'PAID',
    };
  }
  if (s === 'partial' || s === 'partially_paid') {
    return {
      badge: 'bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-300 border border-amber-200 dark:border-amber-900/40',
      label: 'PARTIAL',
    };
  }
  return {
    badge: 'bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-900/40',
    label: 'DUE',
  };
}

// Fetch APIs
async function fetchPurchases() {
  loadingPurchases.value = true;
  try {
    const periodVal = filterStore.selectedPeriod;
    const res = await purchaseApi.list({
      page: currentPage.value,
      per_page: perPage.value,
      search: searchQuery.value || undefined,
      payment_status: paymentStatusFilter.value || undefined,
      period: periodVal !== 'all_time' ? periodVal : undefined,
      sort: sortBy.value || 'newest',
    });

    const payload = res.data?.data;
    if (payload?.data) {
      purchases.value = payload.data;
      currentPage.value = payload.current_page || 1;
      purchasesTotalCount.value = payload.total || payload.data.length;
      purchasesTotalPages.value = payload.last_page || Math.max(1, Math.ceil(purchasesTotalCount.value / perPage.value));
    } else if (res.data?.meta) {
      purchases.value = Array.isArray(payload) ? payload : [];
      currentPage.value = res.data.meta.current_page || 1;
      purchasesTotalCount.value = res.data.meta.total || purchases.value.length;
      purchasesTotalPages.value = res.data.meta.last_page || Math.max(1, Math.ceil(purchasesTotalCount.value / perPage.value));
    } else {
      purchases.value = Array.isArray(payload) ? payload : [];
      purchasesTotalCount.value = purchases.value.length;
      purchasesTotalPages.value = Math.max(1, Math.ceil(purchases.value.length / perPage.value));
    }

    if (res.data?.metrics) {
      Object.assign(purchaseMetrics, res.data.metrics);
    }
  } catch (err) {
    console.error('Failed to load purchases:', err);
  } finally {
    loadingPurchases.value = false;
  }
}

async function fetchVendors() {
  loadingVendors.value = true;
  try {
    const res = await vendorApi.list({
      page: vendorCurrentPage.value,
      per_page: perPage.value,
      search: searchQuery.value || undefined,
    });

    const payload = res.data?.data;
    if (payload?.data) {
      vendors.value = payload.data;
      vendorCurrentPage.value = payload.current_page || 1;
      vendorsTotalCount.value = payload.total || payload.data.length;
      vendorsTotalPages.value = payload.last_page || Math.max(1, Math.ceil(vendorsTotalCount.value / perPage.value));
    } else if (res.data?.meta) {
      vendors.value = Array.isArray(payload) ? payload : [];
      vendorCurrentPage.value = res.data.meta.current_page || 1;
      vendorsTotalCount.value = res.data.meta.total || vendors.value.length;
      vendorsTotalPages.value = res.data.meta.last_page || Math.max(1, Math.ceil(vendorsTotalCount.value / perPage.value));
    } else {
      vendors.value = Array.isArray(payload) ? payload : [];
      vendorsTotalCount.value = vendors.value.length;
      vendorsTotalPages.value = Math.max(1, Math.ceil(vendors.value.length / perPage.value));
    }

    if (res.data?.metrics) {
      Object.assign(vendorMetrics, res.data.metrics);
    }
  } catch (err) {
    console.error('Failed to load vendors:', err);
  } finally {
    loadingVendors.value = false;
  }
}

async function loadAuxiliaryData() {
  try {
    const [vRes, invRes] = await Promise.all([
      vendorApi.list({ per_page: 150 }),
      inventoryApi.list({ per_page: 200 }),
    ]);
    const vPayload = vRes.data?.data;
    allVendorsList.value = vPayload?.data || (Array.isArray(vPayload) ? vPayload : []);

    const invPayload = invRes.data?.data;
    allInventoryItems.value = invPayload?.data || (Array.isArray(invPayload) ? invPayload : []);
  } catch (err) {
    console.error('Failed to load auxiliary vendor/inventory data:', err);
  }
}

// Purchase Actions
function openCreatePurchaseModal() {
  purchaseForm.vendor_id = allVendorsList.value.length > 0 ? allVendorsList.value[0].id : null;
  purchaseForm.purchase_date = toInputDate(new Date());
  purchaseForm.items = [
    { inventory_item_id: null, item_name: '', quantity: 1, purchase_rate: 0, imei1: '', imei2: '', serial_number: '' }
  ];
  purchaseForm.discount = 0;
  purchaseForm.additional_charges = 0;
  purchaseForm.payment_status = 'pending';
  purchaseForm.amount_paid = 0;
  purchaseForm.notes = '';
  createPurchaseModalOpen.value = true;
  loadAuxiliaryData();
}

async function submitCreatePurchase() {
  if (!purchaseForm.vendor_id) {
    toast.error('Please select a supplier / vendor.');
    return;
  }
  if (purchaseForm.items.length === 0) {
    toast.error('Please add at least one line item.');
    return;
  }

  savingPurchase.value = true;
  try {
    const itemsPayload = purchaseForm.items.map(item => ({
      inventory_item_id: item.inventory_item_id || undefined,
      item_name: item.item_name || 'Part',
      quantity: Number(item.quantity) || 1,
      purchase_rate: Number(item.purchase_rate) || 0,
      total_amount: (Number(item.quantity) || 1) * (Number(item.purchase_rate) || 0),
      imei1: item.imei1?.trim() || undefined,
      imei2: item.imei2?.trim() || undefined,
      serial_number: item.serial_number?.trim() || undefined,
    }));

    await purchaseApi.create({
      vendor_id: purchaseForm.vendor_id,
      purchase_date: purchaseForm.purchase_date,
      items: itemsPayload,
      discount: Number(purchaseForm.discount) || 0,
      additional_charges: Number(purchaseForm.additional_charges) || 0,
      payment_status: purchaseForm.payment_status,
      amount_paid: Number(purchaseForm.amount_paid) || 0,
      notes: purchaseForm.notes?.trim() || undefined,
    });

    toast.success('Wholesale purchase order recorded successfully!');
    createPurchaseModalOpen.value = false;
    await fetchPurchases();
    if (activeTab.value === 'vendors') await fetchVendors();
  } catch (err) {
    console.error('Failed to create purchase:', err);
    toast.error(err.response?.data?.message || 'Could not save purchase order.');
  } finally {
    savingPurchase.value = false;
  }
}

async function openPurchaseDetail(p) {
  selectedPurchase.value = p;
  detailModalOpen.value = true;
  try {
    const res = await purchaseApi.get(p.id);
    selectedPurchase.value = res.data?.data || p;
  } catch (err) {
    console.error('Failed to load full purchase details:', err);
  }
}

function viewPurchase(p) {
  return openPurchaseDetail(p);
}

function printPurchaseReceipt() {
  window.print();
}

async function inwardStockToInventory(p) {
  const confirmed = await toast.confirm({
    title: 'Inward Stock to Inventory?',
    message: `Add products and quantities from Bill #${p.purchase_number || p.id} into your active inventory stock?`,
    confirmText: 'Inward Stock Now',
    type: 'info',
  });

  if (confirmed) {
    try {
      await purchaseApi.addStock(p.id, {});
      toast.success('Items successfully added to shop stock!');
      await fetchPurchases();
    } catch (err) {
      console.error('Failed to add stock:', err);
      toast.error(err.response?.data?.message || 'Could not inward stock.');
    }
  }
}

async function confirmDeletePurchase(p) {
  const confirmed = await toast.confirm({
    title: 'Delete Purchase Order?',
    message: `Are you sure you want to delete purchase #${p.purchase_number || p.id}? Any stock movements associated with this bill will be reversed.`,
    confirmText: 'Delete Order',
    type: 'danger',
  });

  if (confirmed) {
    try {
      await purchaseApi.delete(p.id);
      toast.success('Purchase order deleted successfully');
      await fetchPurchases();
    } catch (err) {
      console.error('Failed to delete purchase:', err);
      toast.error('Could not delete purchase.');
    }
  }
}

// Payment Actions
function openAddPaymentModal(target) {
  activeTargetForPayment.value = target;
  paymentForm.amount = target.outstanding_amount || target.due_amount || 0;
  paymentForm.payment_method = 'cash';
  paymentForm.payment_date = toInputDate(new Date());
  paymentForm.notes = '';
  paymentModalOpen.value = true;
}

async function submitRecordPayment() {
  if (!paymentForm.amount || paymentForm.amount <= 0) {
    toast.error('Please enter a valid payment amount.');
    return;
  }

  submittingPayment.value = true;
  try {
    const target = activeTargetForPayment.value;
    if (target.purchase_number || target.items) {
      // It's a purchase bill
      await purchaseApi.addPayment(target.id, {
        amount: Number(paymentForm.amount),
        payment_method: paymentForm.payment_method,
        payment_date: paymentForm.payment_date,
        notes: paymentForm.notes?.trim() || undefined,
      });
    } else {
      // It's a vendor
      await vendorApi.addPayment(target.id, {
        amount: Number(paymentForm.amount),
        payment_method: paymentForm.payment_method,
        payment_date: paymentForm.payment_date,
        notes: paymentForm.notes?.trim() || undefined,
      });
    }

    toast.success('Payment recorded successfully!');
    paymentModalOpen.value = false;
    await fetchPurchases();
    await fetchVendors();
    if (detailModalOpen.value && selectedPurchase.value) {
      await openPurchaseDetail(selectedPurchase.value);
    }
  } catch (err) {
    console.error('Failed to record payment:', err);
    toast.error(err.response?.data?.message || 'Could not record payment.');
  } finally {
    submittingPayment.value = false;
  }
}

// Vendor Actions
function openAddVendorModal() {
  isEditingVendor.value = false;
  vendorForm.id = null;
  vendorForm.name = '';
  vendorForm.contact_person = '';
  vendorForm.phone = '';
  vendorForm.email = '';
  vendorForm.gst_number = '';
  vendorForm.city = '';
  vendorForm.address = '';
  vendorForm.opening_balance = 0;
  vendorModalOpen.value = true;
}

function openAddVendorModalInline() {
  openAddVendorModal();
}

function openEditVendorModal(v) {
  isEditingVendor.value = true;
  vendorForm.id = v.id;
  vendorForm.name = v.name || '';
  vendorForm.contact_person = v.contact_person || '';
  vendorForm.phone = v.phone || '';
  vendorForm.email = v.email || '';
  vendorForm.gst_number = v.gst_number || v.gstin || '';
  vendorForm.city = v.city || '';
  vendorForm.address = v.address || '';
  vendorForm.opening_balance = v.opening_balance || 0;
  vendorModalOpen.value = true;
}

async function submitVendorForm() {
  if (!vendorForm.name?.trim() || !vendorForm.phone?.trim()) {
    toast.error('Please enter vendor name and phone number.');
    return;
  }

  savingVendor.value = true;
  try {
    if (isEditingVendor.value) {
      await vendorApi.update(vendorForm.id, vendorForm);
      toast.success('Vendor profile updated successfully!');
    } else {
      const res = await vendorApi.create(vendorForm);
      toast.success('New vendor created successfully!');
      if (createPurchaseModalOpen.value && res.data?.data) {
        allVendorsList.value.push(res.data.data);
        purchaseForm.vendor_id = res.data.data.id;
      }
    }
    vendorModalOpen.value = false;
    await fetchVendors();
    await loadAuxiliaryData();
  } catch (err) {
    console.error('Failed to save vendor:', err);
    toast.error(err.response?.data?.message || 'Could not save vendor.');
  } finally {
    savingVendor.value = false;
  }
}

async function openVendorDetail(v) {
  selectedVendor.value = { ...v, purchases: [] };
  vendorDetailOpen.value = true;
  loadingVendorHistory.value = true;

  try {
    const res = await vendorApi.get(v.id);
    const vendorData = res.data?.data || v;
    let rawPurchases = res.data?.purchases || vendorData?.purchases;
    let purchasesList = [];

    if (Array.isArray(rawPurchases)) {
      purchasesList = rawPurchases;
    } else if (rawPurchases?.data && Array.isArray(rawPurchases.data)) {
      purchasesList = rawPurchases.data;
    }

    // Fallback 1: fetch from purchaseApi directly if empty
    if (!purchasesList || purchasesList.length === 0) {
      try {
        const pRes = await purchaseApi.list({ vendor_id: v.id, per_page: 50 });
        const pData = pRes.data?.data;
        if (Array.isArray(pData)) {
          purchasesList = pData;
        } else if (pData?.data && Array.isArray(pData.data)) {
          purchasesList = pData.data;
        }
      } catch (_) {}
    }

    // Fallback 2: match from loaded in-memory purchases list
    if ((!purchasesList || purchasesList.length === 0) && purchases.value && purchases.value.length > 0) {
      purchasesList = purchases.value.filter(p =>
        p.vendor_id === v.id ||
        p.vendor?.id === v.id ||
        (v.name && p.vendor_name?.toLowerCase() === v.name.toLowerCase()) ||
        (v.name && p.vendor?.name?.toLowerCase() === v.name.toLowerCase())
      );
    }

    selectedVendor.value = {
      ...vendorData,
      purchases: purchasesList || [],
    };
  } catch (err) {
    console.error('Failed to load full vendor details:', err);
    // Even on error, show in-memory matches
    if (purchases.value && purchases.value.length > 0) {
      const memoryMatches = purchases.value.filter(p =>
        p.vendor_id === v.id ||
        p.vendor?.id === v.id ||
        (v.name && p.vendor_name?.toLowerCase() === v.name.toLowerCase())
      );
      selectedVendor.value = { ...v, purchases: memoryMatches };
    }
  } finally {
    loadingVendorHistory.value = false;
  }
}

async function confirmDeleteVendor(v) {
  const confirmed = await toast.confirm({
    title: 'Delete Vendor?',
    message: `Are you sure you want to remove supplier "${v.name}"?`,
    confirmText: 'Delete Supplier',
    type: 'danger',
  });

  if (confirmed) {
    try {
      await vendorApi.delete(v.id);
      toast.success('Vendor removed');
      await fetchVendors();
      await loadAuxiliaryData();
    } catch (err) {
      console.error('Failed to delete vendor:', err);
      toast.error('Could not delete vendor.');
    }
  }
}

onMounted(() => {
  fetchPurchases();
  fetchVendors();
  loadAuxiliaryData();
});
</script>
