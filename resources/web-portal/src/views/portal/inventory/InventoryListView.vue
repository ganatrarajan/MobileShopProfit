<template>
  <div class="space-y-6 pb-12 font-['Outfit',sans-serif]">
    <!-- 1. Header & Actions -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <div class="flex items-center gap-2">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 border border-indigo-200/60 dark:border-indigo-800/60">
            Stock & Catalog Management
          </span>
          <span class="text-xs text-slate-400">Mobiles, Spare Parts, Displays & Accessories</span>
        </div>
        <h2 class="text-2xl font-black tracking-tight text-slate-900 dark:text-white mt-1">Shop Inventory Stock</h2>
        <p class="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
          Track real-time stock levels, purchase costs, selling margins, low stock alerts, and inward/outward adjustments.
        </p>
      </div>

      <div class="flex items-center gap-2.5">
        <button
          @click="openCreateModal"
          type="button"
          class="inline-flex items-center gap-1.5 px-4 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold shadow-md shadow-indigo-600/20 transition cursor-pointer hover:scale-[1.02] active:scale-[0.98]"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 4v16m8-8H4"/></svg>
          + Add Item / Part
        </button>
      </div>
    </div>

    <!-- 2. KPI Summary Metric Cards (Matching Flutter Mobile App) -->
    <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
      <!-- Total Catalog Items -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 sm:p-5 border border-slate-200/80 dark:border-slate-800/80 shadow-xs">
        <div class="flex items-center justify-between">
          <p class="text-[11px] text-slate-400 font-bold uppercase tracking-wider">Total Items</p>
          <div class="w-8 h-8 rounded-xl bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 flex items-center justify-center">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/></svg>
          </div>
        </div>
        <p class="text-2xl font-black text-slate-900 dark:text-white mt-2 tabular-nums">
          {{ metrics.total_items || 0 }}
        </p>
        <p class="text-[10px] text-slate-400 mt-0.5">Catalog items active</p>
      </div>

      <!-- In-Stock Valuation -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 sm:p-5 border border-slate-200/80 dark:border-slate-800/80 shadow-xs">
        <div class="flex items-center justify-between">
          <p class="text-[11px] text-slate-400 font-bold uppercase tracking-wider">Stock Valuation</p>
          <div class="w-8 h-8 rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
          </div>
        </div>
        <p class="text-2xl font-black text-slate-900 dark:text-white mt-2 tabular-nums">
          ₹{{ formatAmount(metrics.total_stock_value || 0) }}
        </p>
        <p class="text-[10px] text-slate-400 mt-0.5">Purchase cost valuation</p>
      </div>

      <!-- Low Stock Alert -->
      <div
        @click="filterByStatus('low_stock')"
        class="bg-white dark:bg-[#111827] rounded-2xl p-4 sm:p-5 border border-slate-200/80 dark:border-slate-800/80 shadow-xs cursor-pointer hover:border-amber-400/80 transition"
        :class="{ 'ring-2 ring-amber-500/40': stockFilter === 'low_stock' }"
      >
        <div class="flex items-center justify-between">
          <p class="text-[11px] text-amber-600 dark:text-amber-400 font-bold uppercase tracking-wider">Low Stock</p>
          <div class="w-8 h-8 rounded-xl bg-amber-500/10 text-amber-600 dark:text-amber-400 flex items-center justify-center">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
          </div>
        </div>
        <p class="text-2xl font-black text-amber-600 dark:text-amber-400 mt-2 tabular-nums">
          {{ metrics.low_stock_count || 0 }}
        </p>
        <p class="text-[10px] text-amber-500 dark:text-amber-400/80 mt-0.5">Below minimum alert</p>
      </div>

      <!-- Out of Stock -->
      <div
        @click="filterByStatus('out_of_stock')"
        class="bg-white dark:bg-[#111827] rounded-2xl p-4 sm:p-5 border border-slate-200/80 dark:border-slate-800/80 shadow-xs cursor-pointer hover:border-rose-400/80 transition"
        :class="{ 'ring-2 ring-rose-500/40': stockFilter === 'out_of_stock' }"
      >
        <div class="flex items-center justify-between">
          <p class="text-[11px] text-rose-600 dark:text-rose-400 font-bold uppercase tracking-wider">Out of Stock</p>
          <div class="w-8 h-8 rounded-xl bg-rose-500/10 text-rose-600 dark:text-rose-400 flex items-center justify-center">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636"/></svg>
          </div>
        </div>
        <p class="text-2xl font-black text-rose-600 dark:text-rose-400 mt-2 tabular-nums">
          {{ metrics.out_of_stock_count || 0 }}
        </p>
        <p class="text-[10px] text-rose-500 dark:text-rose-400/80 mt-0.5">Needs restocking</p>
      </div>
    </div>

    <!-- 3. Type Category Filter Chips -->
    <div class="flex items-center gap-2 overflow-x-auto pb-1 custom-scroll">
      <button
        v-for="cat in itemTypeTabs"
        :key="cat.value"
        @click="changeItemType(cat.value)"
        type="button"
        class="px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all whitespace-nowrap cursor-pointer flex items-center gap-1.5"
        :class="[
          selectedItemType === cat.value
            ? 'bg-indigo-600 text-white shadow-sm shadow-indigo-600/30'
            : 'bg-white dark:bg-[#111827] text-slate-600 dark:text-slate-300 border border-slate-200/80 dark:border-slate-800/80 hover:bg-slate-50 dark:hover:bg-slate-800'
        ]"
      >
        <span>{{ cat.icon }}</span>
        <span>{{ cat.label }}</span>
      </button>
    </div>

    <!-- 4. Search & Filter Bar -->
    <div class="bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-2xl p-4 shadow-sm flex flex-col md:flex-row gap-3 items-stretch md:items-center justify-between">
      <div class="relative flex-1">
        <span class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
        </span>
        <input
          v-model="searchQuery"
          @input="debounceSearch"
          type="text"
          class="w-full pl-10 pr-24 py-2 text-xs font-semibold bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 dark:focus:border-indigo-400 transition-all placeholder-slate-400 text-slate-800 dark:text-slate-100"
          placeholder="Search items by name, SKU, barcode, brand, model, or IMEI..."
        />
        <button
          type="button"
          @click="openScanner('search', 'Scan Barcode or IMEI to Search', 'camera')"
          class="absolute inset-y-1.5 right-1.5 px-2.5 flex items-center gap-1 text-[11px] font-bold text-indigo-600 dark:text-indigo-400 bg-indigo-50 dark:bg-indigo-950/60 hover:bg-indigo-100 dark:hover:bg-indigo-900 rounded-lg transition cursor-pointer"
          title="Scan barcode or IMEI"
        >
          <span>📷</span>
          <span>Scan</span>
        </button>
      </div>

      <div class="flex items-center gap-2 flex-wrap">
        <SearchableSelect
          v-model="stockFilter"
          :options="stockFilterOptions"
          @change="currentPage = 1; fetchItems()"
          placeholder="All Stock Levels"
          minWidth="160px"
        />

        <SearchableSelect
          v-model="sortFilter"
          :options="sortFilterOptions"
          @change="currentPage = 1; fetchItems()"
          placeholder="Sort By"
          minWidth="180px"
          :searchable="false"
        />

        <button
          v-if="searchQuery || stockFilter || sortFilter !== 'newest' || selectedItemType !== 'all'"
          @click="resetFilters"
          type="button"
          class="px-3 py-2 bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-600 dark:text-slate-300 rounded-xl text-xs font-bold transition-all cursor-pointer"
        >
          Reset
        </button>
      </div>
    </div>

    <!-- 5. Inventory Data Table Card -->
    <div class="bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-2xl overflow-hidden shadow-sm">
      <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="border-b border-slate-100 dark:border-slate-800/80 text-[11px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider bg-slate-50/60 dark:bg-slate-900/40">
              <th class="py-3.5 px-4 pl-6">Item / Model Details</th>
              <th class="py-3.5 px-4">SKU / Barcode</th>
              <th class="py-3.5 px-4">Type</th>
              <th class="py-3.5 px-4">Stock Level</th>
              <th class="py-3.5 px-4">Cost Price</th>
              <th class="py-3.5 px-4">Selling Price</th>
              <th class="py-3.5 px-4">Stock Valuation</th>
              <th class="py-3.5 px-4 pr-6 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100 dark:divide-slate-800/60 text-sm">
            <tr v-if="loading">
              <td colspan="8" class="py-12 text-center text-xs text-slate-400">
                <div class="inline-block animate-spin w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full mb-2"></div>
                <div>Loading inventory catalog...</div>
              </td>
            </tr>
            <tr v-else-if="items.length === 0">
              <td colspan="8" class="py-12 text-center text-slate-400 dark:text-slate-500 text-xs">
                No inventory items found matching criteria.
              </td>
            </tr>
            <tr
              v-for="item in items"
              :key="item.id"
              class="hover:bg-slate-50/70 dark:hover:bg-slate-800/40 transition-colors group"
            >
              <!-- Item Details -->
              <td class="py-3.5 px-4 pl-6">
                <div class="flex items-start gap-3">
                  <div
                    class="w-9 h-9 rounded-xl flex items-center justify-center shrink-0 text-sm"
                    :class="getItemTypeBadgeClasses(item.item_type).iconBg"
                  >
                    {{ getItemTypeBadgeClasses(item.item_type).icon }}
                  </div>
                  <div>
                    <div class="font-bold text-slate-900 dark:text-white flex items-center gap-1.5">
                      {{ item.name }}
                      <span v-if="item.brand" class="text-[10px] font-semibold px-1.5 py-0.2 rounded bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                        {{ item.brand }} {{ item.model || '' }}
                      </span>
                    </div>
                    <div class="flex items-center gap-2 mt-0.5 text-[11px] text-slate-400 flex-wrap">
                      <span class="font-semibold text-slate-600 dark:text-slate-300">{{ item.category || 'General' }}</span>
                      <span>• 📅 {{ formatDate(item.created_at) }}</span>
                      <span v-if="item.unit">• Unit: {{ item.unit }}</span>
                      <span v-if="item.imei1 || item.serials?.[0]?.imei1" class="text-indigo-600 dark:text-indigo-400 font-mono text-[10px] font-semibold bg-indigo-50 dark:bg-indigo-950/50 px-1.5 py-0.5 rounded">
                        IMEI: {{ item.imei1 || item.serials[0].imei1 }}
                      </span>
                      <span v-else-if="item.serials && item.serials.length > 0" class="text-indigo-500 font-semibold">
                        • {{ item.serials.length }} Serial(s)/IMEI
                      </span>
                    </div>
                  </div>
                </div>
              </td>

              <!-- SKU / Barcode -->
              <td class="py-3.5 px-4">
                <div class="flex items-center gap-1.5">
                  <span class="font-mono text-xs text-slate-600 dark:text-slate-300 bg-slate-100 dark:bg-slate-800 px-2 py-0.5 rounded border border-slate-200 dark:border-slate-700/60">
                    {{ item.sku || item.barcode || 'NO-SKU' }}
                  </span>
                  <button
                    v-if="item.sku || item.barcode"
                    @click="copyText(item.sku || item.barcode)"
                    type="button"
                    class="opacity-0 group-hover:opacity-100 transition text-slate-400 hover:text-indigo-600"
                    title="Copy SKU"
                  >
                    <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"/></svg>
                  </button>
                </div>
              </td>

              <!-- Item Type -->
              <td class="py-3.5 px-4">
                <span
                  class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-semibold border"
                  :class="getItemTypeBadgeClasses(item.item_type).badge"
                >
                  {{ getItemTypeBadgeClasses(item.item_type).label }}
                </span>
              </td>

              <!-- Stock Level -->
              <td class="py-3.5 px-4">
                <div>
                  <span :class="getStockBadgeClass(item)" class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-bold">
                    <span class="w-1.5 h-1.5 rounded-full" :class="getStockDotClass(item)"></span>
                    {{ item.current_stock ?? item.stock_quantity ?? 0 }} {{ item.unit || 'units' }}
                  </span>
                  <div class="text-[10px] text-slate-400 mt-0.5">
                    Min alert: {{ item.minimum_stock ?? 2 }}
                  </div>
                </div>
              </td>

              <!-- Cost Price -->
              <td class="py-3.5 px-4">
                <span class="font-bold text-slate-700 dark:text-slate-300 tabular-nums">
                  ₹{{ formatAmount(item.purchase_price || item.cost_price || 0) }}
                </span>
              </td>

              <!-- Selling Price & Margin -->
              <td class="py-3.5 px-4">
                <div>
                  <span class="font-extrabold text-slate-900 dark:text-white tabular-nums">
                    ₹{{ formatAmount(item.selling_price || item.unit_price || 0) }}
                  </span>
                  <div class="text-[10px] font-semibold text-emerald-600 dark:text-emerald-400 mt-0.5">
                    {{ calculateMargin(item) }}
                  </div>
                </div>
              </td>

              <!-- Stock Valuation -->
              <td class="py-3.5 px-4">
                <span class="font-bold text-slate-900 dark:text-white tabular-nums">
                  ₹{{ formatAmount(calculateStockValuation(item)) }}
                </span>
              </td>

              <!-- Actions -->
              <td class="py-3.5 px-4 pr-6 text-right">
                <div class="flex items-center justify-end gap-1">
                  <!-- + Inward Stock -->
                  <button
                    @click="openAddStockModal(item)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-500 hover:text-emerald-600 hover:bg-emerald-50 dark:hover:bg-emerald-950/40 transition cursor-pointer"
                    title="+ Add Inward Stock"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" d="M12 4v16m8-8H4"/></svg>
                  </button>

                  <!-- ⚡ Adjust Stock -->
                  <button
                    @click="openAdjustStockModal(item)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-500 hover:text-amber-600 hover:bg-amber-50 dark:hover:bg-amber-950/40 transition cursor-pointer"
                    title="Stock Adjustment (Damaged/Lost/Correction)"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4"/></svg>
                  </button>

                  <!-- 📜 Stock Movements Ledger -->
                  <button
                    @click="openMovementsModal(item)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-500 hover:text-indigo-600 hover:bg-indigo-50 dark:hover:bg-indigo-950/40 transition cursor-pointer"
                    title="View Stock Movement Audit Trail"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                  </button>

                  <!-- Edit -->
                  <button
                    @click="editItem(item)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-500 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-slate-800 transition cursor-pointer"
                    title="Edit Item"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
                  </button>

                  <!-- Delete -->
                  <button
                    @click="confirmDeleteItem(item)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/40 transition cursor-pointer"
                    title="Delete Item"
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

    <!-- ============================================================== -->
    <!-- MODAL 1: ADD / EDIT INVENTORY ITEM                             -->
    <!-- ============================================================== -->
    <div
      v-if="modalOpen"
      class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-slate-900/60 backdrop-blur-sm overflow-hidden"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-[#111827] w-full max-w-2xl rounded-2xl shadow-2xl border border-slate-200/80 dark:border-slate-800/80 overflow-hidden flex flex-col max-h-[90vh] animate-in fade-in zoom-in-95">
        <!-- Modal Header (Pinned at Top) -->
        <div class="px-6 py-4 border-b border-slate-100 dark:border-slate-800/80 flex justify-between items-center bg-slate-50/50 dark:bg-slate-900/30 shrink-0">
          <div>
            <h3 class="text-base font-bold text-slate-900 dark:text-white">
              {{ editingId ? 'Edit Inventory Item' : 'Add New Inventory Item' }}
            </h3>
            <p class="text-[11px] text-slate-400">Configure catalog specs, pricing, tax rates, and initial stock</p>
          </div>
          <button @click="modalOpen = false" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition cursor-pointer text-lg">✕</button>
        </div>

        <!-- Scrollable Form Body -->
        <form id="inventoryItemForm" @submit.prevent="saveItem" class="p-6 space-y-4 overflow-y-auto custom-scroll flex-1 min-h-0">
          <!-- Item Type Selection -->
          <div>
            <label class="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Item Classification <span class="text-rose-500">*</span></label>
            <div class="grid grid-cols-4 gap-2">
              <button
                v-for="t in [
                  { id: 'spare_part', label: 'Spare Part', icon: '🔧' },
                  { id: 'mobile', label: 'Mobile Phone', icon: '📱' },
                  { id: 'accessory', label: 'Accessory', icon: '🔌' },
                  { id: 'other', label: 'Other', icon: '📦' },
                ]"
                :key="t.id"
                type="button"
                @click="onSelectClassification(t.id)"
                class="py-2.5 px-2 rounded-xl text-xs font-bold border transition flex flex-col items-center gap-1 text-center cursor-pointer"
                :class="[
                  form.item_type === t.id
                    ? 'border-indigo-600 bg-indigo-50 dark:bg-indigo-950/40 text-indigo-700 dark:text-indigo-300 ring-2 ring-indigo-500/30'
                    : 'border-slate-200 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-300'
                ]"
              >
                <span class="text-base">{{ t.icon }}</span>
                <span>{{ t.label }}</span>
              </button>
            </div>
          </div>

          <!-- ========================================================= -->
          <!-- A) MOBILE PHONE SPECIFIC FORM LAYOUT                       -->
          <!-- ========================================================= -->
          <div v-if="form.item_type === 'mobile'" class="space-y-4">
            <!-- 1. Mobile Brand & Model Section -->
            <div class="p-4 rounded-2xl bg-indigo-50/50 dark:bg-indigo-950/20 border border-indigo-100 dark:border-indigo-900/40 space-y-3">
              <div class="flex items-center justify-between">
                <h4 class="text-xs font-bold uppercase tracking-wider text-indigo-700 dark:text-indigo-300 flex items-center gap-1.5">
                  <span>📱</span> Mobile Brand & Model
                </h4>
                <span class="text-[10px] text-indigo-500 font-medium">Select brand to load dynamic models</span>
              </div>

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <label class="block text-[11px] font-semibold text-slate-600 dark:text-slate-400 mb-1">Brand *</label>
                    <SearchableSelect
                      v-model="form.brand"
                      :options="catalogBrands"
                      placeholder="Select or type brand..."
                      searchPlaceholder="Search mobile brands..."
                      :allowCustom="true"
                      :clearable="true"
                      :fullWidth="true"
                      @change="onBrandSelected"
                    />
                  </div>

                  <!-- Dynamic Model Select -->
                  <div>
                    <div class="flex items-center justify-between mb-1">
                      <label class="block text-[11px] font-semibold text-slate-600 dark:text-slate-400">Model *</label>
                      <span v-if="catalogModels.length" class="text-[10px] text-slate-400 font-medium">({{ catalogModels.length }} models)</span>
                    </div>
                    <SearchableSelect
                      v-model="form.model"
                      :options="catalogModels"
                      :placeholder="catalogModels.length ? `Select or type model (${catalogModels.length} available)...` : 'Select or type model...'"
                      searchPlaceholder="Search mobile models..."
                      :allowCustom="true"
                      :clearable="true"
                      :fullWidth="true"
                      @change="autoFormatMobileName"
                    />
                  </div>
                </div>

              <!-- Specs: RAM, Storage & Color -->
              <div class="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-1">
                <div>
                  <label class="block text-[11px] font-semibold text-slate-600 dark:text-slate-400 mb-1">RAM</label>
                  <SearchableSelect
                    v-model="form.ram"
                    :options="ramOptions"
                    placeholder="Select RAM"
                    searchPlaceholder="Search or enter RAM..."
                    :allowCustom="true"
                    :clearable="true"
                    :fullWidth="true"
                    direction="down"
                    @change="autoFormatMobileName"
                  />
                </div>

                <div>
                  <label class="block text-[11px] font-semibold text-slate-600 dark:text-slate-400 mb-1">Storage</label>
                  <SearchableSelect
                    v-model="form.storage"
                    :options="storageOptions"
                    placeholder="Select Storage"
                    searchPlaceholder="Search or enter Storage..."
                    :allowCustom="true"
                    :clearable="true"
                    :fullWidth="true"
                    direction="down"
                    @change="autoFormatMobileName"
                  />
                </div>

                <div>
                  <label class="block text-[11px] font-semibold text-slate-600 dark:text-slate-400 mb-1">Color / Variant</label>
                  <input
                    v-model="form.color"
                    @input="autoFormatMobileName"
                    type="text"
                    class="w-full px-3 py-2 text-xs bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100"
                    placeholder="e.g. Midnight Black, Sierra Blue"
                  />
                </div>
              </div>

              <!-- Formatted Item Name display & edit -->
              <div class="pt-2 border-t border-indigo-100 dark:border-indigo-900/40">
                <div class="flex items-center justify-between mb-1">
                  <label class="text-[11px] font-bold uppercase tracking-wider text-slate-600 dark:text-slate-400">
                    Composed Item Name <span class="text-rose-500">*</span>
                  </label>
                  <button
                    type="button"
                    @click="autoFormatMobileName"
                    class="text-[10px] font-bold text-indigo-600 hover:text-indigo-700 hover:underline cursor-pointer flex items-center gap-1"
                  >
                    <span>🔄</span> Auto-Format Name
                  </button>
                </div>
                <input
                  v-model="form.name"
                  type="text"
                  required
                  class="w-full px-3 py-2 text-sm font-bold bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500 text-indigo-700 dark:text-indigo-300"
                  placeholder="e.g. Apple iPhone 13 (8 GB / 128 GB - Midnight Black)"
                />
              </div>
            </div>

            <!-- 2. Device Identifiers Card (IMEI 1, IMEI 2, Serial) -->
            <div class="p-4 rounded-2xl bg-slate-50 dark:bg-slate-900/50 border border-slate-200/80 dark:border-slate-800/80 space-y-3">
              <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                <div>
                  <h4 class="text-xs font-bold uppercase tracking-wider text-slate-800 dark:text-slate-200 flex items-center gap-1.5">
                    <span>🏷️</span> Device Identifiers (IMEI & Serial)
                  </h4>
                  <p class="text-[10px] text-slate-400">Required if opening stock is added (1 unit per IMEI)</p>
                </div>

                <!-- Auto-Scan Box Sticker Button -->
                <button
                  type="button"
                  @click="openScanner('box', 'Auto-Scan Phone Box Sticker', 'box')"
                  class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-500 hover:to-purple-500 text-white text-xs font-bold shadow-sm shadow-indigo-600/20 transition cursor-pointer self-start sm:self-auto"
                >
                  <span>⚡</span>
                  <span>Auto-Scan Box Sticker</span>
                </button>
              </div>

              <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <!-- IMEI 1 -->
                <div>
                  <div class="flex items-center justify-between mb-1">
                    <label class="text-[11px] font-semibold text-slate-700 dark:text-slate-300">
                      Primary IMEI 1 (Optional)
                    </label>
                    <button
                      type="button"
                      @click="openScanner('imei1', 'Scan Primary IMEI 1', 'camera')"
                      class="text-[10px] font-bold text-indigo-600 hover:text-indigo-700 flex items-center gap-0.5 cursor-pointer"
                    >
                      <span>📷</span> Scan
                    </button>
                  </div>
                  <div class="relative">
                    <input
                      v-model="form.imei1"
                      @blur="checkImeiAvailability(form.imei1)"
                      type="text"
                      maxlength="16"
                      class="w-full pl-3 pr-8 py-2 text-sm font-mono font-bold bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100"
                      placeholder="15-digit IMEI 1"
                    />
                    <button
                      type="button"
                      @click="openScanner('imei1', 'Scan Primary IMEI 1', 'camera')"
                      class="absolute inset-y-1 right-1 px-2 flex items-center text-slate-400 hover:text-indigo-600 cursor-pointer"
                      title="Scan IMEI 1"
                    >
                      📷
                    </button>
                  </div>
                </div>

                <!-- IMEI 2 -->
                <div>
                  <div class="flex items-center justify-between mb-1">
                    <label class="text-[11px] font-semibold text-slate-700 dark:text-slate-300">
                      Secondary IMEI 2 (Optional)
                    </label>
                    <button
                      type="button"
                      @click="openScanner('imei2', 'Scan Secondary IMEI 2', 'camera')"
                      class="text-[10px] font-bold text-indigo-600 hover:text-indigo-700 flex items-center gap-0.5 cursor-pointer"
                    >
                      <span>📷</span> Scan
                    </button>
                  </div>
                  <div class="relative">
                    <input
                      v-model="form.imei2"
                      @blur="checkImeiAvailability(form.imei2)"
                      type="text"
                      maxlength="16"
                      class="w-full pl-3 pr-8 py-2 text-sm font-mono font-bold bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100"
                      placeholder="15-digit IMEI 2"
                    />
                    <button
                      type="button"
                      @click="openScanner('imei2', 'Scan Secondary IMEI 2', 'camera')"
                      class="absolute inset-y-1 right-1 px-2 flex items-center text-slate-400 hover:text-indigo-600 cursor-pointer"
                      title="Scan IMEI 2"
                    >
                      📷
                    </button>
                  </div>
                </div>

                <!-- Serial Number -->
                <div>
                  <div class="flex items-center justify-between mb-1">
                    <label class="text-[11px] font-semibold text-slate-700 dark:text-slate-300">Serial Number</label>
                    <button
                      type="button"
                      @click="openScanner('serial', 'Scan Serial Number', 'camera')"
                      class="text-[10px] font-bold text-indigo-600 hover:text-indigo-700 flex items-center gap-0.5 cursor-pointer"
                    >
                      <span>📷</span> Scan
                    </button>
                  </div>
                  <div class="relative">
                    <input
                      v-model="form.serial_number"
                      type="text"
                      class="w-full pl-3 pr-8 py-2 text-sm font-mono bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100"
                      placeholder="e.g. F2LL80XYZ001"
                    />
                    <button
                      type="button"
                      @click="openScanner('serial', 'Scan Serial Number', 'camera')"
                      class="absolute inset-y-1 right-1 px-2 flex items-center text-slate-400 hover:text-indigo-600 cursor-pointer"
                      title="Scan Serial"
                    >
                      📷
                    </button>
                  </div>
                </div>

                <!-- SKU / Barcode -->
                <div>
                  <div class="flex items-center justify-between mb-1">
                    <label class="text-[11px] font-semibold text-slate-700 dark:text-slate-300">SKU / Barcode</label>
                    <div class="flex items-center gap-2">
                      <button
                        type="button"
                        @click="openScanner('sku', 'Scan Product Barcode / SKU', 'camera')"
                        class="text-[10px] font-bold text-indigo-600 hover:text-indigo-700 flex items-center gap-0.5 cursor-pointer"
                      >
                        <span>📷</span> Scan
                      </button>
                      <button
                        type="button"
                        @click="generateSku"
                        class="text-[10px] font-bold text-indigo-600 hover:text-indigo-700 flex items-center gap-0.5 cursor-pointer"
                      >
                        <span>⚡</span> Gen
                      </button>
                    </div>
                  </div>
                  <input
                    v-model="form.sku"
                    type="text"
                    class="w-full px-3 py-2 text-sm font-mono bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100"
                    placeholder="e.g. MOB-APP-4820"
                  />
                </div>
              </div>
            </div>
          </div>

          <!-- ========================================================= -->
          <!-- B) NON-MOBILE ITEM LAYOUT (Spare Part, Accessory, Other)   -->
          <!-- ========================================================= -->
          <div v-else class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div class="sm:col-span-2">
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Item Name <span class="text-rose-500">*</span></label>
              <input
                v-model="form.name"
                type="text"
                required
                class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400 font-semibold"
                placeholder="e.g. iPhone 13 OLED Display Assembly"
              />
            </div>

            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Category (Optional)</label>
              <SearchableSelect
                v-model="form.category"
                :options="catalogCategories"
                placeholder="Select or type category..."
                searchPlaceholder="Search categories..."
                :allowCustom="true"
                :clearable="true"
                :fullWidth="true"
                direction="down"
              />
            </div>

            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Brand</label>
              <SearchableSelect
                v-model="form.brand"
                :options="catalogBrands"
                placeholder="Select or type brand..."
                searchPlaceholder="Search brands..."
                :allowCustom="true"
                :clearable="true"
                :fullWidth="true"
                @change="onBrandSelected"
              />
            </div>

            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Model Compatibility</label>
              <SearchableSelect
                v-model="form.model"
                :options="catalogModels"
                :placeholder="catalogModels.length ? `Select or type model (${catalogModels.length} available)...` : 'e.g. iPhone 13 / 13 Pro'"
                searchPlaceholder="Search or type models..."
                :allowCustom="true"
                :clearable="true"
                :fullWidth="true"
              />
            </div>

            <!-- SKU & Barcode -->
            <div>
              <div class="flex items-center justify-between mb-1.5">
                <label class="text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">SKU / Barcode</label>
                <div class="flex items-center gap-2">
                  <button
                    type="button"
                    @click="openScanner('sku', 'Scan Product Barcode / SKU', 'camera')"
                    class="text-[10px] font-bold text-indigo-600 hover:text-indigo-700 flex items-center gap-0.5 cursor-pointer"
                  >
                    <span>📷</span> Scan
                  </button>
                  <button
                    type="button"
                    @click="generateSku"
                    class="text-[10px] font-bold text-indigo-600 hover:underline cursor-pointer"
                  >
                    ⚡ Generate SKU
                  </button>
                </div>
              </div>
              <div class="relative">
                <input
                  v-model="form.sku"
                  type="text"
                  class="w-full pl-3 pr-8 py-2 text-sm font-mono bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400"
                  placeholder="e.g. DISP-IP13-001"
                />
                <button
                  type="button"
                  @click="openScanner('sku', 'Scan Product Barcode / SKU', 'camera')"
                  class="absolute inset-y-1 right-1 px-2 flex items-center text-slate-400 hover:text-indigo-600 cursor-pointer"
                  title="Scan SKU / Barcode"
                >
                  📷
                </button>
              </div>
            </div>
          </div>

          <!-- Pricing & Margins -->
          <div class="p-4 rounded-xl bg-slate-50 dark:bg-slate-900/40 border border-slate-200/80 dark:border-slate-800/80 space-y-3">
            <h4 class="text-xs font-bold uppercase tracking-wider text-slate-600 dark:text-slate-300">Pricing & Margins</h4>
            <div class="grid grid-cols-2 sm:grid-cols-3 gap-3">
              <div>
                <label class="block text-[11px] font-semibold text-slate-500 mb-1">Purchase Cost (₹) <span class="text-rose-500">*</span></label>
                <input
                  v-model.number="form.purchase_price"
                  type="number"
                  step="0.01"
                  min="0"
                  required
                  class="w-full px-3 py-2 text-sm font-bold bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500"
                />
              </div>

              <div>
                <label class="block text-[11px] font-semibold text-slate-500 mb-1">Selling Price (₹) <span class="text-rose-500">*</span></label>
                <input
                  v-model.number="form.selling_price"
                  type="number"
                  step="0.01"
                  min="0"
                  required
                  class="w-full px-3 py-2 text-sm font-bold bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500"
                />
              </div>

              <div class="col-span-2 sm:col-span-1 flex flex-col justify-end">
                <div class="p-2 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200/60 text-emerald-700 dark:text-emerald-300 text-center">
                  <p class="text-[10px] font-bold uppercase">Estimated Margin</p>
                  <p class="text-sm font-extrabold mt-0.5">
                    {{ previewMargin }}
                  </p>
                </div>
              </div>
            </div>

            <!-- GST Rates -->
            <div class="grid grid-cols-2 gap-3 pt-2 border-t border-slate-200/60 dark:border-slate-800/60">
              <div>
                <label class="block text-[11px] font-semibold text-slate-500 mb-1">GST Tax Rate (%)</label>
                <SearchableSelect
                  v-model.number="form.tax_rate"
                  :options="taxRateOptions"
                  placeholder="Select GST rate"
                  :fullWidth="true"
                  direction="down"
                />
              </div>

              <div>
                <label class="block text-[11px] font-semibold text-slate-500 mb-1">Tax Application</label>
                <SearchableSelect
                  v-model="form.tax_type"
                  :options="taxTypeOptions"
                  placeholder="Select application"
                  :fullWidth="true"
                  direction="down"
                />
              </div>
            </div>
          </div>

          <!-- Stock & Units Controls -->
          <div class="grid grid-cols-3 gap-3">
            <div v-if="!editingId">
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Opening Stock</label>
              <input
                v-model.number="form.opening_stock"
                type="number"
                min="0"
                class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500"
              />
            </div>

            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Min Alert Level</label>
              <input
                v-model.number="form.minimum_stock"
                type="number"
                min="0"
                class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500"
              />
            </div>

            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Unit</label>
              <SearchableSelect
                v-model="form.unit"
                :options="unitOptions"
                placeholder="Select unit"
                :allowCustom="true"
                :fullWidth="true"
                direction="down"
              />
            </div>
          </div>


          <!-- Description / Notes -->
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Description / Internal Notes</label>
            <textarea
              v-model="form.description"
              rows="2"
              class="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400"
              placeholder="Supplier source, rack storage bin, warranty details..."
            ></textarea>
          </div>

          <!-- Error message alert -->
          <div v-if="formError" class="p-3 rounded-xl bg-rose-50 dark:bg-rose-950/50 border border-rose-200 text-rose-600 dark:text-rose-400 text-xs">
            {{ formError }}
          </div>
        </form>

        <!-- Sticky Modal Footer (Pinned at Bottom) -->
        <div class="px-6 py-3.5 bg-slate-50/80 dark:bg-slate-900/50 border-t border-slate-100 dark:border-slate-800/80 flex items-center justify-end gap-2.5 shrink-0">
          <button
            type="button"
            @click="modalOpen = false"
            class="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-200/60 dark:hover:bg-slate-800 rounded-xl transition cursor-pointer"
          >
            Cancel
          </button>
          <button
            form="inventoryItemForm"
            type="submit"
            :disabled="saving"
            class="px-5 py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 rounded-xl shadow-md shadow-indigo-600/20 transition cursor-pointer hover:scale-[1.01] active:scale-[0.99]"
          >
            {{ saving ? 'Saving...' : (editingId ? 'Update Item' : 'Add Item to Catalog') }}
          </button>
        </div>
      </div>
    </div>

    <!-- ============================================================== -->
    <!-- MODAL 2: INCOMING / ADD STOCK                                  -->
    <!-- ============================================================== -->
    <div
      v-if="addStockModalOpen"
      class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-slate-900/60 backdrop-blur-sm overflow-hidden"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-[#111827] w-full max-w-md rounded-2xl shadow-2xl border border-slate-200/80 dark:border-slate-800/80 overflow-hidden flex flex-col max-h-[90vh] animate-in fade-in zoom-in-95">
        <div class="px-6 py-4 border-b border-slate-100 dark:border-slate-800/80 flex justify-between items-center bg-slate-50/50 dark:bg-slate-900/30 shrink-0">
          <div>
            <h3 class="text-base font-bold text-slate-900 dark:text-white">Inward Stock (+ Restock)</h3>
            <p class="text-[11px] text-slate-400">Add physical units to shop inventory</p>
          </div>
          <button @click="addStockModalOpen = false" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition cursor-pointer text-lg">✕</button>
        </div>

        <form id="addStockForm" @submit.prevent="submitAddStock" class="p-6 space-y-4 overflow-y-auto custom-scroll flex-1 min-h-0">
          <!-- Item Info Card -->
          <div class="p-3 rounded-xl bg-slate-50 dark:bg-slate-900/50 border border-slate-200/80 dark:border-slate-800/80 flex items-center justify-between">
            <div>
              <p class="text-xs font-bold text-slate-900 dark:text-white">{{ activeStockItem?.name }}</p>
              <p class="text-[10px] text-slate-400 font-mono mt-0.5">SKU: {{ activeStockItem?.sku || activeStockItem?.barcode || 'N/A' }}</p>
            </div>
            <div class="text-right">
              <p class="text-[10px] text-slate-400 uppercase font-semibold">Current Stock</p>
              <p class="text-sm font-extrabold text-indigo-600 dark:text-indigo-400">{{ activeStockItem?.current_stock ?? 0 }} {{ activeStockItem?.unit || 'units' }}</p>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-xs font-semibold text-slate-600 dark:text-slate-400 mb-1">Quantity to Inward <span class="text-rose-500">*</span></label>
              <input
                v-model.number="addStockForm.quantity"
                type="number"
                min="1"
                required
                class="w-full px-3 py-2 text-sm font-bold bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500"
              />
            </div>

            <div>
              <label class="block text-xs font-semibold text-slate-600 dark:text-slate-400 mb-1">Unit Cost Price (₹)</label>
              <input
                v-model.number="addStockForm.unit_cost"
                type="number"
                step="0.01"
                min="0"
                class="w-full px-3 py-2 text-sm font-bold bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500"
              />
            </div>
          </div>

          <!-- Mobile IMEI Fields if mobile -->
          <div v-if="activeStockItem?.item_type === 'mobile'" class="space-y-3 p-3.5 rounded-xl bg-indigo-50/50 dark:bg-indigo-950/20 border border-indigo-100 dark:border-indigo-900/40">
            <div class="flex items-center justify-between pb-1 border-b border-indigo-100 dark:border-indigo-900/40">
              <span class="text-xs font-bold text-indigo-700 dark:text-indigo-300 flex items-center gap-1">
                <span>📱</span> Device Identifiers
              </span>
              <button
                type="button"
                @click="openScanner('stock_box', 'Auto-Scan Phone Box Sticker', 'box')"
                class="px-2.5 py-1 text-[11px] font-bold text-white bg-indigo-600 hover:bg-indigo-500 rounded-lg shadow-sm transition cursor-pointer flex items-center gap-1"
              >
                <span>⚡</span> Auto-Scan Box
              </button>
            </div>

            <div>
              <div class="flex items-center justify-between mb-1">
                <label class="text-[11px] font-semibold text-slate-700 dark:text-slate-300">Primary IMEI 1 (Optional)</label>
                <button
                  type="button"
                  @click="openScanner('stock_imei1', 'Scan Primary IMEI 1', 'camera')"
                  class="text-[10px] font-bold text-indigo-600 hover:text-indigo-700 flex items-center gap-0.5 cursor-pointer"
                >
                  <span>📷</span> Scan
                </button>
              </div>
              <div class="relative">
                <input
                  v-model="addStockForm.imei1"
                  type="text"
                  maxlength="16"
                  class="w-full pl-3 pr-8 py-2 text-xs font-mono font-bold bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl"
                  placeholder="15-digit IMEI 1 (Optional)"
                />
                <button
                  type="button"
                  @click="openScanner('stock_imei1', 'Scan Primary IMEI 1', 'camera')"
                  class="absolute inset-y-1 right-1 px-2 flex items-center text-slate-400 hover:text-indigo-600 cursor-pointer"
                >
                  📷
                </button>
              </div>
            </div>

            <div>
              <div class="flex items-center justify-between mb-1">
                <label class="text-[11px] font-semibold text-slate-700 dark:text-slate-300">Secondary IMEI 2 (Optional)</label>
                <button
                  type="button"
                  @click="openScanner('stock_imei2', 'Scan Secondary IMEI 2', 'camera')"
                  class="text-[10px] font-bold text-indigo-600 hover:text-indigo-700 flex items-center gap-0.5 cursor-pointer"
                >
                  <span>📷</span> Scan
                </button>
              </div>
              <div class="relative">
                <input
                  v-model="addStockForm.imei2"
                  type="text"
                  maxlength="16"
                  class="w-full pl-3 pr-8 py-2 text-xs font-mono font-bold bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl"
                  placeholder="15-digit IMEI 2"
                />
                <button
                  type="button"
                  @click="openScanner('stock_imei2', 'Scan Secondary IMEI 2', 'camera')"
                  class="absolute inset-y-1 right-1 px-2 flex items-center text-slate-400 hover:text-indigo-600 cursor-pointer"
                >
                  📷
                </button>
              </div>
            </div>

            <div>
              <div class="flex items-center justify-between mb-1">
                <label class="text-[11px] font-semibold text-slate-700 dark:text-slate-300">Serial Number (Optional)</label>
                <button
                  type="button"
                  @click="openScanner('stock_serial', 'Scan Serial Number', 'camera')"
                  class="text-[10px] font-bold text-indigo-600 hover:text-indigo-700 flex items-center gap-0.5 cursor-pointer"
                >
                  <span>📷</span> Scan
                </button>
              </div>
              <div class="relative">
                <input
                  v-model="addStockForm.serial_number"
                  type="text"
                  class="w-full pl-3 pr-8 py-2 text-xs font-mono bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl"
                  placeholder="Serial No."
                />
                <button
                  type="button"
                  @click="openScanner('stock_serial', 'Scan Serial Number', 'camera')"
                  class="absolute inset-y-1 right-1 px-2 flex items-center text-slate-400 hover:text-indigo-600 cursor-pointer"
                >
                  📷
                </button>
              </div>
            </div>
          </div>

          <div>
            <label class="block text-xs font-semibold text-slate-600 dark:text-slate-400 mb-1">Notes / Supplier Reference</label>
            <input
              v-model="addStockForm.notes"
              type="text"
              class="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500"
              placeholder="e.g. Wholesale invoice #8921"
            />
          </div>

          <div v-if="addStockError" class="p-3 rounded-xl bg-rose-50 dark:bg-rose-950/50 border border-rose-200 text-rose-600 dark:text-rose-400 text-xs">
            {{ addStockError }}
          </div>
        </form>

        <div class="px-6 py-3.5 bg-slate-50/80 dark:bg-slate-900/50 border-t border-slate-100 dark:border-slate-800/80 flex items-center justify-end gap-2.5 shrink-0">
          <button
            type="button"
            @click="addStockModalOpen = false"
            class="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 rounded-xl"
          >
            Cancel
          </button>
          <button
            form="addStockForm"
            type="submit"
            :disabled="submittingStock"
            class="px-4 py-2 text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-500 disabled:opacity-50 rounded-xl shadow-md shadow-emerald-600/20"
          >
            {{ submittingStock ? 'Adding Stock...' : 'Confirm Inward Stock' }}
          </button>
        </div>
      </div>
    </div>

    <!-- ============================================================== -->
    <!-- MODAL 3: ADJUST STOCK (Damaged / Lost / Return / Correction)    -->
    <!-- ============================================================== -->
    <div
      v-if="adjustStockModalOpen"
      class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-slate-900/60 backdrop-blur-sm overflow-hidden"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-[#111827] w-full max-w-md rounded-2xl shadow-2xl border border-slate-200/80 dark:border-slate-800/80 overflow-hidden flex flex-col max-h-[90vh] animate-in fade-in zoom-in-95">
        <div class="px-6 py-4 border-b border-slate-100 dark:border-slate-800/80 flex justify-between items-center bg-slate-50/50 dark:bg-slate-900/30 shrink-0">
          <div>
            <h3 class="text-base font-bold text-slate-900 dark:text-white">Stock Adjustment</h3>
            <p class="text-[11px] text-slate-400">Record damaged, lost, return, or audit discrepancies</p>
          </div>
          <button @click="adjustStockModalOpen = false" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition cursor-pointer text-lg">✕</button>
        </div>

        <form id="adjustStockForm" @submit.prevent="submitAdjustStock" class="p-6 space-y-4 overflow-y-auto custom-scroll flex-1 min-h-0">
          <!-- Item Info Card -->
          <div class="p-3 rounded-xl bg-slate-50 dark:bg-slate-900/50 border border-slate-200/80 dark:border-slate-800/80 flex items-center justify-between">
            <div>
              <p class="text-xs font-bold text-slate-900 dark:text-white">{{ activeStockItem?.name }}</p>
              <p class="text-[10px] text-slate-400 mt-0.5">Type: {{ activeStockItem?.item_type }}</p>
            </div>
            <div class="text-right">
              <p class="text-[10px] text-slate-400 uppercase font-semibold">Current Balance</p>
              <p class="text-sm font-extrabold text-amber-600 dark:text-amber-400">{{ activeStockItem?.current_stock ?? 0 }} {{ activeStockItem?.unit || 'units' }}</p>
            </div>
          </div>

          <!-- Reason / Type Selector -->
          <div>
            <label class="block text-xs font-semibold text-slate-600 dark:text-slate-400 mb-1">Adjustment Type <span class="text-rose-500">*</span></label>
            <div class="grid grid-cols-2 gap-2">
              <button
                v-for="adj in [
                  { id: 'damaged', label: 'Damaged (-)', color: 'text-rose-600 border-rose-200 dark:border-rose-900/50 bg-rose-50/50 dark:bg-rose-950/20' },
                  { id: 'lost', label: 'Lost / Stolen (-)', color: 'text-amber-600 border-amber-200 dark:border-amber-900/50 bg-amber-50/50 dark:bg-amber-950/20' },
                  { id: 'return', label: 'Customer Return (+)', color: 'text-emerald-600 border-emerald-200 dark:border-emerald-900/50 bg-emerald-50/50 dark:bg-emerald-950/20' },
                  { id: 'correction', label: 'Physical Audit (+/-)', color: 'text-blue-600 border-blue-200 dark:border-blue-900/50 bg-blue-50/50 dark:bg-blue-950/20' },
                ]"
                :key="adj.id"
                type="button"
                @click="adjustForm.adjustment_type = adj.id"
                class="p-2.5 rounded-xl text-xs font-bold border transition text-center cursor-pointer"
                :class="[
                  adjustForm.adjustment_type === adj.id
                    ? `${adj.color} ring-2 ring-indigo-500/30`
                    : 'border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-400 hover:bg-slate-50'
                ]"
              >
                {{ adj.label }}
              </button>
            </div>
          </div>

          <div>
            <label class="block text-xs font-semibold text-slate-600 dark:text-slate-400 mb-1">Quantity <span class="text-rose-500">*</span></label>
            <input
              v-model.number="adjustForm.quantity"
              type="number"
              min="1"
              required
              class="w-full px-3 py-2 text-sm font-bold bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500"
            />
          </div>

          <div>
            <label class="block text-xs font-semibold text-slate-600 dark:text-slate-400 mb-1">Mandatory Reason / Audit Notes <span class="text-rose-500">*</span></label>
            <textarea
              v-model="adjustForm.notes"
              rows="2"
              required
              class="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500"
              placeholder="Explain why stock is being adjusted..."
            ></textarea>
          </div>

          <div v-if="adjustStockError" class="p-3 rounded-xl bg-rose-50 dark:bg-rose-950/50 border border-rose-200 text-rose-600 dark:text-rose-400 text-xs">
            {{ adjustStockError }}
          </div>
        </form>

        <div class="px-6 py-3.5 bg-slate-50/80 dark:bg-slate-900/50 border-t border-slate-100 dark:border-slate-800/80 flex items-center justify-end gap-2.5 shrink-0">
          <button
            type="button"
            @click="adjustStockModalOpen = false"
            class="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 rounded-xl"
          >
            Cancel
          </button>
          <button
            form="adjustStockForm"
            type="submit"
            :disabled="submittingAdjust"
            class="px-4 py-2 text-xs font-bold text-white bg-amber-600 hover:bg-amber-500 disabled:opacity-50 rounded-xl shadow-md shadow-amber-600/20"
          >
            {{ submittingAdjust ? 'Applying Adjustment...' : 'Apply Stock Adjustment' }}
          </button>
        </div>
      </div>
    </div>

    <!-- ============================================================== -->
    <!-- MODAL 4: MOVEMENT HISTORY & SERIALS AUDIT TRAIL                -->
    <!-- ============================================================== -->
    <div
      v-if="movementsModalOpen"
      class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-slate-900/60 backdrop-blur-sm overflow-hidden"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-[#111827] w-full max-w-2xl rounded-2xl shadow-2xl border border-slate-200/80 dark:border-slate-800/80 overflow-hidden flex flex-col max-h-[90vh] animate-in fade-in zoom-in-95">
        <div class="px-6 py-4 border-b border-slate-100 dark:border-slate-800/80 flex justify-between items-center bg-slate-50/50 dark:bg-slate-900/30 shrink-0">
          <div>
            <h3 class="text-base font-bold text-slate-900 dark:text-white flex items-center gap-2">
              <span>📜 Stock Movement History</span>
              <span class="text-xs px-2 py-0.5 rounded-full bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 font-semibold">{{ activeStockItem?.name }}</span>
            </h3>
            <p class="text-[11px] text-slate-400">Complete audit trail of stock inward, usage in repairs, and sales</p>
          </div>
          <button @click="movementsModalOpen = false" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition cursor-pointer text-lg">✕</button>
        </div>

        <div class="p-6 overflow-y-auto custom-scroll flex-1 min-h-0 space-y-4">
          <div v-if="loadingMovements" class="py-12 text-center text-xs text-slate-400">
            <div class="inline-block animate-spin w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full mb-2"></div>
            <div>Loading movement audit trail...</div>
          </div>
          <div v-else-if="movements.length === 0" class="py-12 text-center text-slate-400 text-xs">
            No stock movements recorded for this item yet.
          </div>
          <div v-else class="space-y-2.5">
            <div
              v-for="m in movements"
              :key="m.id"
              class="p-3.5 rounded-xl border border-slate-100 dark:border-slate-800/80 bg-slate-50/50 dark:bg-slate-900/40 flex items-center justify-between"
            >
              <div class="flex items-center gap-3">
                <span
                  class="px-2 py-1 rounded-lg text-[10px] font-bold uppercase tracking-wider border"
                  :class="getMovementBadgeClasses(m.movement_type)"
                >
                  {{ formatMovementType(m.movement_type) }}
                </span>
                <div>
                  <p class="text-xs font-semibold text-slate-800 dark:text-slate-200">
                    {{ m.notes || 'Inventory movement' }}
                  </p>
                  <p class="text-[10px] text-slate-400 mt-0.5">
                    {{ formatDate(m.created_at) }}
                  </p>
                </div>
              </div>

              <div class="text-right">
                <span
                  class="text-sm font-black tabular-nums"
                  :class="m.quantity >= 0 ? 'text-emerald-600 dark:text-emerald-400' : 'text-rose-600 dark:text-rose-400'"
                >
                  {{ m.quantity >= 0 ? `+${m.quantity}` : m.quantity }}
                </span>
                <p v-if="m.unit_cost" class="text-[10px] text-slate-400 tabular-nums">
                  @ ₹{{ formatAmount(m.unit_cost) }}
                </p>
              </div>
            </div>
          </div>
        </div>

        <div class="px-6 py-3.5 bg-slate-50/80 dark:bg-slate-900/50 border-t border-slate-100 dark:border-slate-800/80 flex justify-end shrink-0">
          <button
            type="button"
            @click="movementsModalOpen = false"
            class="px-4 py-2 text-xs font-bold text-slate-700 dark:text-slate-300 hover:bg-slate-200/60 dark:hover:bg-slate-800 rounded-xl"
          >
            Close
          </button>
        </div>
      </div>
    </div>

    <!-- ============================================================== -->
    <!-- MODAL 5: DELETE ITEM CONFIRMATION                              -->
    <!-- ============================================================== -->
    <div
      v-if="deleteModalOpen"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-4 overflow-hidden"
      @wheel.stop
    >
      <div class="bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-2xl w-full max-w-sm shadow-2xl p-6 text-center animate-in fade-in zoom-in-95">
        <div class="w-12 h-12 rounded-full bg-rose-50 dark:bg-rose-950/60 text-rose-600 dark:text-rose-400 flex items-center justify-center mx-auto mb-3">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
        </div>
        <h3 class="text-base font-bold text-slate-900 dark:text-white">Delete Catalog Item?</h3>
        <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
          Are you sure you want to delete <span class="font-bold text-slate-700 dark:text-slate-300">{{ itemToDelete?.name }}</span>? All stock and movement logs will be permanently removed.
        </p>
        <div class="flex items-center justify-center gap-2 mt-5">
          <button
            @click="deleteModalOpen = false"
            class="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition cursor-pointer"
          >
            Cancel
          </button>
          <button
            @click="executeDeleteItem"
            :disabled="deleting"
            class="px-4 py-2 rounded-xl text-xs font-semibold bg-rose-600 hover:bg-rose-500 text-white shadow-md shadow-rose-600/20 disabled:opacity-50 transition cursor-pointer"
          >
            {{ deleting ? 'Deleting...' : 'Yes, Delete' }}
          </button>
        </div>
      </div>
    </div>

    <!-- ============================================================== -->
    <!-- MODAL 6: BARCODE & IMEI SCANNER MODAL                          -->
    <!-- ============================================================== -->
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
import { ref, reactive, computed, onMounted, watch } from 'vue';
import { useToastStore } from '@/stores/toast';
import { inventoryApi, deviceApi } from '@/api/endpoints';
import PaginationBar from '@/components/common/PaginationBar.vue';
import SearchableSelect from '@/components/common/SearchableSelect.vue';
import BarcodeScannerModal from '@/components/common/BarcodeScannerModal.vue';
import { formatDate } from '@/utils/date';

const toast = useToastStore();

// --- Filter State ---
const selectedItemType = ref('all');
const stockFilter = ref('');
const searchQuery = ref('');
let searchTimer = null;

const itemTypeTabs = [
  { value: 'all', label: 'All Catalog', icon: '🗂️' },
  { value: 'spare_part', label: 'Spare Parts', icon: '🔧' },
  { value: 'mobile', label: 'Mobile Phones', icon: '📱' },
  { value: 'accessory', label: 'Accessories', icon: '🔌' },
  { value: 'other', label: 'Other', icon: '📦' },
];

const stockFilterOptions = [
  { value: '', label: 'All Stock Levels' },
  { value: 'in_stock', label: 'In Stock (> 0)' },
  { value: 'low_stock', label: '⚠️ Low Stock (< Min)' },
  { value: 'out_of_stock', label: '🚨 Out of Stock (0)' },
];

const sortFilter = ref('newest');
const sortFilterOptions = [
  { value: 'newest', label: 'Newest First (Recent)' },
  { value: 'oldest', label: 'Oldest First' },
  { value: 'name_asc', label: 'Name (A to Z)' },
  { value: 'name_desc', label: 'Name (Z to A)' },
  { value: 'price_high', label: 'Price (High to Low)' },
  { value: 'price_low', label: 'Price (Low to High)' },
  { value: 'stock_high', label: 'Stock (High to Low)' },
  { value: 'stock_low', label: 'Stock (Low to High)' },
];

// --- Items and Metrics State ---
const items = ref([]);
const metrics = reactive({
  total_items: 0,
  total_stock_value: 0,
  low_stock_count: 0,
  out_of_stock_count: 0,
});
const loading = ref(false);
const currentPage = ref(1);
const totalPages = ref(1);
const totalCount = ref(0);
const perPage = ref(15);

// Catalog brands, RAM and Storage options
const catalogBrands = ref([]);
const catalogModels = ref([]);

const ramOptions = [
  '2 GB',
  '3 GB',
  '4 GB',
  '6 GB',
  '8 GB',
  '12 GB',
  '16 GB',
  '24 GB',
];

const storageOptions = [
  '32 GB',
  '64 GB',
  '128 GB',
  '256 GB',
  '512 GB',
  '1 TB',
];

const catalogCategories = [
  'Display / Screen',
  'Battery',
  'Charging Port / Flex',
  'Camera Module',
  'Back Glass / Housing',
  'Speaker / Earpiece',
  'Motherboard IC',
  'Tempered Glass',
  'Case / Cover',
  'Charger & Cable',
  'Earphones / Audio',
  'Touch Glass / Digitizer',
  'Sim Tray',
  'Fingerprint Sensor / Flex',
  'Power / Volume Flex',
  'Tools & Consumables',
  'General Spare Part',
];

const taxRateOptions = [
  { value: 0, label: '0% (Exempt)' },
  { value: 5, label: '5% GST' },
  { value: 12, label: '12% GST' },
  { value: 18, label: '18% GST (Standard)' },
  { value: 28, label: '28% GST' },
];

const taxTypeOptions = [
  { value: 'exclusive', label: 'Exclusive (Price + Tax)' },
  { value: 'inclusive', label: 'Inclusive (Price includes Tax)' },
];

const unitOptions = [
  { value: 'pcs', label: 'Pieces (pcs)' },
  { value: 'units', label: 'Units' },
  { value: 'sets', label: 'Sets' },
  { value: 'meters', label: 'Meters' },
];

// Barcode & IMEI Scanner State
const scannerOpen = ref(false);
const scannerTitle = ref('Scan Barcode or IMEI');
const scannerInitialMode = ref('camera');
const scannerTarget = ref('');

// --- Modal 1: Add / Edit Item State ---
const modalOpen = ref(false);
const editingId = ref(null);
const saving = ref(false);
const formError = ref(null);

const form = reactive({
  name: '',
  category: 'Display / Screen',
  brand: '',
  model: '',
  ram: '',
  storage: '',
  color: '',
  sku: '',
  item_type: 'spare_part',
  purchase_price: 0,
  selling_price: 0,
  tax_rate: 18,
  tax_type: 'exclusive',
  opening_stock: 0,
  minimum_stock: 2,
  unit: 'pcs',
  description: '',
  imei1: '',
  imei2: '',
  serial_number: '',
});

// --- Modal 2: Add Stock State ---
const addStockModalOpen = ref(false);
const activeStockItem = ref(null);
const submittingStock = ref(false);
const addStockError = ref(null);
const addStockForm = reactive({
  quantity: 1,
  unit_cost: 0,
  notes: '',
  imei1: '',
  imei2: '',
  serial_number: '',
});

// --- Modal 3: Adjust Stock State ---
const adjustStockModalOpen = ref(false);
const submittingAdjust = ref(false);
const adjustStockError = ref(null);
const adjustForm = reactive({
  adjustment_type: 'damaged',
  quantity: 1,
  notes: '',
});

// --- Modal 4: Movements Audit Log ---
const movementsModalOpen = ref(false);
const loadingMovements = ref(false);
const movements = ref([]);

// --- Modal 5: Delete Item ---
const deleteModalOpen = ref(false);
const itemToDelete = ref(null);
const deleting = ref(false);

// --- Computed Helpers ---
const previewMargin = computed(() => {
  const p = Number(form.purchase_price) || 0;
  const s = Number(form.selling_price) || 0;
  if (s <= 0) return '0%';
  const profit = s - p;
  const pct = Math.round((profit / s) * 100);
  return `${pct}% (₹${profit.toFixed(0)})`;
});

function calculateMargin(item) {
  const p = Number(item.purchase_price || item.cost_price || 0);
  const s = Number(item.selling_price || item.unit_price || 0);
  if (s <= 0) return '0% margin';
  const profit = s - p;
  const pct = Math.round((profit / s) * 100);
  return `${pct}% (₹${profit.toFixed(0)})`;
}

function calculateStockValuation(item) {
  const qty = Number(item.current_stock ?? item.stock_quantity ?? 0);
  const cost = Number(item.purchase_price || item.cost_price || 0);
  return qty * cost;
}

// Watch filters to reset page to 1
watch([selectedItemType, stockFilter], () => {
  currentPage.value = 1;
  fetchItems();
});

function debounceSearch() {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => {
    currentPage.value = 1;
    fetchItems();
  }, 350);
}

function resetFilters() {
  searchQuery.value = '';
  stockFilter.value = '';
  sortFilter.value = 'newest';
  selectedItemType.value = 'all';
  currentPage.value = 1;
  fetchItems();
}

function changeItemType(type) {
  selectedItemType.value = type;
}

function filterByStatus(status) {
  stockFilter.value = stockFilter.value === status ? '' : status;
  currentPage.value = 1;
  fetchItems();
}

async function fetchItems() {
  loading.value = true;
  try {
    const params = {
      page: currentPage.value,
      per_page: perPage.value,
      search: searchQuery.value || undefined,
      item_type: selectedItemType.value !== 'all' ? selectedItemType.value : undefined,
      stock_status: stockFilter.value || undefined,
      sort: sortFilter.value,
    };

    const res = await inventoryApi.list(params);
    const data = res.data;

    // Load Metrics
    if (data?.metrics) {
      metrics.total_items = data.metrics.total_items ?? 0;
      metrics.total_stock_value = data.metrics.total_stock_value ?? 0;
      metrics.low_stock_count = data.metrics.low_stock_count ?? 0;
      metrics.out_of_stock_count = data.metrics.out_of_stock_count ?? 0;
    }

    // Load Items List
    if (data?.data && Array.isArray(data.data)) {
      items.value = data.data;
    } else if (data?.data?.data && Array.isArray(data.data.data)) {
      items.value = data.data.data;
    } else {
      items.value = [];
    }

    // Load Meta Pagination
    if (data?.meta) {
      currentPage.value = data.meta.current_page || 1;
      totalPages.value = data.meta.last_page || 1;
      totalCount.value = data.meta.total || items.value.length;
    } else if (data?.data?.last_page) {
      currentPage.value = data.data.current_page || 1;
      totalPages.value = data.data.last_page || 1;
      totalCount.value = data.data.total || items.value.length;
    } else {
      totalCount.value = items.value.length;
      totalPages.value = Math.max(1, Math.ceil(items.value.length / perPage.value));
    }
  } catch (err) {
    console.error('Failed to load inventory list:', err);
    toast.error('Failed to load inventory items', 'Network Error');
  } finally {
    loading.value = false;
  }
}

function changePage(p) {
  currentPage.value = p;
  fetchItems();
}

// --- Brand & Model Catalog Helpers ---
async function fetchCatalogBrands() {
  try {
    const res = await deviceApi.brands();
    if (res.data?.data && Array.isArray(res.data.data)) {
      catalogBrands.value = res.data.data;
    }
  } catch (_) {}
}

async function onBrandSelected(brand) {
  if (brand && typeof brand === 'string') {
    form.brand = brand;
  }
  autoFormatMobileName();
  if (!form.brand) {
    catalogModels.value = [];
    return;
  }
  try {
    const res = await deviceApi.models({ brand: form.brand });
    if (res.data?.data && Array.isArray(res.data.data)) {
      catalogModels.value = res.data.data;
    }
  } catch (_) {}
}

function setMobileBrand(b) {
  form.brand = b;
  form.model = '';
  onBrandSelected();
}

function onSelectClassification(typeId) {
  form.item_type = typeId;
  if (typeId === 'mobile') {
    form.category = 'Mobile Phone';
    form.unit = 'pcs';
    if (!editingId.value && (!form.opening_stock || Number(form.opening_stock) === 0)) {
      form.opening_stock = 1;
    }
    autoFormatMobileName();
  } else {
    if (form.category === 'Mobile Phone') {
      form.category = 'Display / Screen';
    }
  }
}

function autoFormatMobileName() {
  if (form.item_type !== 'mobile') return;
  const brand = (form.brand || '').trim();
  const model = (form.model || '').trim();
  const ram = (form.ram || '').trim();
  const storage = (form.storage || '').trim();
  const color = (form.color || '').trim();

  if (!brand && !model) return;

  const parts = [];
  if (brand) parts.push(brand);
  if (model) parts.push(model);

  const specs = [];
  if (ram && storage) {
    specs.push(`${ram} / ${storage}`);
  } else if (storage) {
    specs.push(storage);
  } else if (ram) {
    specs.push(ram);
  }

  if (color) {
    specs.push(color);
  }

  let fullName = parts.join(' ');
  if (specs.length > 0) {
    fullName += ` (${specs.join(' - ')})`;
  }

  form.name = fullName;
}

function generateSku() {
  const prefix = form.item_type === 'mobile' ? 'MOB' : form.item_type === 'spare_part' ? 'PART' : form.item_type === 'accessory' ? 'ACC' : 'ITM';
  const rand = Math.floor(1000 + Math.random() * 9000);
  const brandCode = form.brand ? form.brand.substring(0, 3).toUpperCase() : 'GEN';
  form.sku = `${prefix}-${brandCode}-${rand}`;
}

async function checkImeiAvailability(imei) {
  if (!imei || imei.trim().length < 8) return;
  try {
    const res = await inventoryApi.checkImei({
      imei: imei.trim(),
      exclude_item_id: editingId.value || undefined,
    });
    if (res.data?.in_stock) {
      const itemName = res.data?.item?.name ? ` (${res.data.item.name})` : '';
      formError.value = res.data.message || `IMEI ${imei} is already in stock for this shop${itemName}!`;
      toast.warning(formError.value, 'IMEI In Stock');
    } else {
      formError.value = null;
    }
  } catch (_) {}
}

// --- Barcode & IMEI Scanner Handlers ---
function openScanner(target, title = 'Scan Barcode or IMEI', mode = 'camera') {
  scannerTarget.value = target;
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
  switch (scannerTarget.value) {
    case 'imei1':
      form.imei1 = clean;
      checkImeiAvailability(clean);
      toast.success(`Scanned IMEI 1: ${clean}`, 'Scanned');
      break;
    case 'imei2':
      form.imei2 = clean;
      checkImeiAvailability(clean);
      toast.success(`Scanned IMEI 2: ${clean}`, 'Scanned');
      break;
    case 'serial':
      form.serial_number = clean;
      toast.success(`Scanned Serial: ${clean}`, 'Scanned');
      break;
    case 'sku':
      form.sku = clean;
      toast.success(`Scanned SKU: ${clean}`, 'Scanned');
      break;
    case 'stock_imei1':
      addStockForm.imei1 = clean;
      toast.success(`Scanned IMEI 1: ${clean}`, 'Scanned');
      break;
    case 'stock_imei2':
      addStockForm.imei2 = clean;
      toast.success(`Scanned IMEI 2: ${clean}`, 'Scanned');
      break;
    case 'stock_serial':
      addStockForm.serial_number = clean;
      toast.success(`Scanned Serial: ${clean}`, 'Scanned');
      break;
    case 'search':
      searchQuery.value = clean;
      debounceSearch();
      toast.success(`Searching: ${clean}`, 'Scanned');
      break;
  }
  scannerOpen.value = false;
}

function handleBoxResult(res) {
  if (scannerTarget.value === 'box') {
    if (res.imei1) form.imei1 = res.imei1;
    if (res.imei2) form.imei2 = res.imei2;
    if (res.serialNumber) form.serial_number = res.serialNumber;
    if (res.imei1) checkImeiAvailability(res.imei1);
    toast.success('Extracted IMEIs and Serial from box sticker!', 'Auto-Scan Success');
  } else if (scannerTarget.value === 'stock_box') {
    if (res.imei1) addStockForm.imei1 = res.imei1;
    if (res.imei2) addStockForm.imei2 = res.imei2;
    if (res.serialNumber) addStockForm.serial_number = res.serialNumber;
    toast.success('Extracted identifiers for inward stock!', 'Auto-Scan Success');
  }
  scannerOpen.value = false;
}

// --- Item Form Actions ---
function openCreateModal() {
  editingId.value = null;
  formError.value = null;
  const initialType = selectedItemType.value !== 'all' ? selectedItemType.value : 'spare_part';
  form.item_type = initialType;
  form.name = '';
  form.category = initialType === 'mobile' ? 'Mobile Phone' : 'Display / Screen';
  form.brand = '';
  form.model = '';
  form.ram = '';
  form.storage = '';
  form.color = '';
  form.sku = '';
  form.purchase_price = 0;
  form.selling_price = 0;
  form.tax_rate = 18;
  form.tax_type = 'exclusive';
  form.opening_stock = initialType === 'mobile' ? 1 : 0;
  form.minimum_stock = 2;
  form.unit = 'pcs';
  form.description = '';
  form.imei1 = '';
  form.imei2 = '';
  form.serial_number = '';
  modalOpen.value = true;
}

function editItem(item) {
  editingId.value = item.id;
  formError.value = null;
  form.name = item.name || '';
  form.category = item.category || 'General';
  form.brand = item.brand || '';
  form.model = item.model || '';
  form.sku = item.sku || item.barcode || '';
  
  let normalizedType = item.item_type || 'spare_part';
  if (normalizedType === 'mobile_phone') normalizedType = 'mobile';
  if (item.category === 'Mobile Phone' || item.category === 'Mobile Phones') normalizedType = 'mobile';
  form.item_type = normalizedType;

  form.purchase_price = Number(item.purchase_price || item.cost_price || 0);
  form.selling_price = Number(item.selling_price || item.unit_price || 0);
  form.tax_rate = Number(item.tax_rate ?? 0);
  form.tax_type = item.tax_type || 'exclusive';
  form.opening_stock = Number(item.current_stock ?? item.stock_quantity ?? 0);
  form.minimum_stock = Number(item.minimum_stock ?? 2);
  form.unit = item.unit || 'pcs';
  form.description = item.description || '';

  // Parse specs if present in description e.g. "RAM: 8 GB | Storage: 128 GB | Color: Black"
  let initialRam = '';
  let initialStorage = '';
  let initialColor = '';
  const desc = item.description || '';
  const ramMatch = desc.match(/RAM:\s*([0-9]+\s*GB)/i);
  if (ramMatch) initialRam = ramMatch[1];
  const storageMatch = desc.match(/Storage:\s*([0-9]+\s*(?:GB|TB))/i);
  if (storageMatch) initialStorage = storageMatch[1];
  const colorMatch = desc.match(/Color:\s*([^|\n]+)/i);
  if (colorMatch) initialColor = colorMatch[1].trim();

  form.ram = initialRam;
  form.storage = initialStorage;
  form.color = initialColor;

  const firstSerial = (Array.isArray(item.serials) && item.serials.length > 0) ? item.serials[0] : null;
  form.imei1 = item.imei1 || firstSerial?.imei1 || '';
  form.imei2 = item.imei2 || firstSerial?.imei2 || '';
  form.serial_number = item.serial_number || firstSerial?.serial_number || '';

  modalOpen.value = true;
  if (form.brand) onBrandSelected();

  // Load latest serials / IMEI details directly from backend to ensure accurate data
  if (item.id) {
    inventoryApi.get(item.id).then((res) => {
      const detail = res.data?.data || res.data;
      if (detail && editingId.value === item.id) {
        const s = (Array.isArray(detail.serials) && detail.serials.length > 0) ? detail.serials[0] : null;
        if (detail.imei1 || s?.imei1) form.imei1 = detail.imei1 || s?.imei1 || form.imei1;
        if (detail.imei2 || s?.imei2) form.imei2 = detail.imei2 || s?.imei2 || form.imei2;
        if (detail.serial_number || s?.serial_number) form.serial_number = detail.serial_number || s?.serial_number || form.serial_number;
      }
    }).catch((err) => {
      console.warn('Could not fetch full item serial details:', err);
    });
  }
}

async function saveItem() {
  formError.value = null;

  if (form.item_type === 'mobile') {
    if (!form.brand || !form.brand.trim()) {
      formError.value = 'Mobile Brand is required for Mobile Phones.';
      return;
    }
    if (!form.model || !form.model.trim()) {
      formError.value = 'Mobile Model is required for Mobile Phones.';
      return;
    }
    if (form.imei1 && form.imei1.trim().length > 0 && form.imei1.trim().length < 8) {
      formError.value = 'Please enter a valid IMEI number (typically 15 digits).';
      return;
    }
    if (form.imei1 && form.imei2 && form.imei1.trim() === form.imei2.trim()) {
      formError.value = 'Primary IMEI 1 and Secondary IMEI 2 cannot be identical.';
      return;
    }

    // Compose description with specs if not already present
    const specParts = [];
    if (form.ram && form.ram.trim()) specParts.push(`RAM: ${form.ram.trim()}`);
    if (form.storage && form.storage.trim()) specParts.push(`Storage: ${form.storage.trim()}`);
    if (form.color && form.color.trim()) specParts.push(`Color: ${form.color.trim()}`);
    if (specParts.length > 0) {
      const specsStr = specParts.join(' | ');
      if (!form.description) {
        form.description = specsStr;
      } else if (!form.description.includes('RAM:') && !form.description.includes('Storage:')) {
        form.description = `${form.description}\nSpecs: ${specsStr}`;
      }
    }
  }

  saving.value = true;

  try {
    const payload = {
      name: form.name,
      category: form.category,
      brand: form.brand || null,
      model: form.model || null,
      sku: form.sku || null,
      item_type: form.item_type,
      purchase_price: form.purchase_price,
      selling_price: form.selling_price,
      tax_rate: form.tax_rate,
      tax_type: form.tax_type,
      opening_stock: form.opening_stock,
      minimum_stock: form.minimum_stock,
      unit: form.unit,
      description: form.description || null,
      imei1: form.imei1 ? form.imei1.trim() : null,
      imei2: form.imei2 ? form.imei2.trim() : null,
      serial_number: form.serial_number ? form.serial_number.trim() : null,
    };

    if (editingId.value) {
      await inventoryApi.update(editingId.value, payload);
      toast.success(`Inventory item "${form.name}" updated successfully!`, 'Catalog Updated');
    } else {
      await inventoryApi.create(payload);
      toast.success(`New item "${form.name}" added to inventory catalog!`, 'Item Created');
    }

    modalOpen.value = false;
    fetchItems();
  } catch (err) {
    const msg = err.response?.data?.message || err.response?.data?.errors?.name?.[0] || 'Failed to save inventory item';
    formError.value = msg;
    toast.error(msg, 'Save Item Failed');
  } finally {
    saving.value = false;
  }
}

// --- Inward Stock Action ---
function openAddStockModal(item) {
  activeStockItem.value = item;
  addStockError.value = null;
  addStockForm.quantity = 1;
  addStockForm.unit_cost = Number(item.purchase_price || item.cost_price || 0);
  addStockForm.notes = '';
  addStockForm.imei1 = '';
  addStockForm.imei2 = '';
  addStockForm.serial_number = '';
  addStockModalOpen.value = true;
}

async function submitAddStock() {
  if (!activeStockItem.value) return;
  submittingStock.value = true;
  addStockError.value = null;

  try {
    const res = await inventoryApi.addStock(activeStockItem.value.id, {
      quantity: addStockForm.quantity,
      unit_cost: addStockForm.unit_cost,
      notes: addStockForm.notes || undefined,
      imei1: addStockForm.imei1 || undefined,
      imei2: addStockForm.imei2 || undefined,
      serial_number: addStockForm.serial_number || undefined,
    });

    toast.success(res.data?.message || `Added ${addStockForm.quantity} stock successfully!`, 'Stock Inwarded');
    addStockModalOpen.value = false;
    fetchItems();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to inward stock';
    addStockError.value = msg;
    toast.error(msg, 'Add Stock Failed');
  } finally {
    submittingStock.value = false;
  }
}

// --- Adjust Stock Action ---
function openAdjustStockModal(item) {
  activeStockItem.value = item;
  adjustStockError.value = null;
  adjustForm.adjustment_type = 'damaged';
  adjustForm.quantity = 1;
  adjustForm.notes = '';
  adjustStockModalOpen.value = true;
}

async function submitAdjustStock() {
  if (!activeStockItem.value) return;
  submittingAdjust.value = true;
  adjustStockError.value = null;

  try {
    const res = await inventoryApi.adjustStock(activeStockItem.value.id, {
      adjustment_type: adjustForm.adjustment_type,
      quantity: adjustForm.quantity,
      notes: adjustForm.notes,
    });

    toast.success(res.data?.message || 'Stock adjusted successfully!', 'Adjustment Applied');
    adjustStockModalOpen.value = false;
    fetchItems();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to adjust stock';
    adjustStockError.value = msg;
    toast.error(msg, 'Adjustment Failed');
  } finally {
    submittingAdjust.value = false;
  }
}

// --- Stock Movements History Modal ---
async function openMovementsModal(item) {
  activeStockItem.value = item;
  movementsModalOpen.value = true;
  loadingMovements.value = true;
  movements.value = [];

  try {
    const res = await inventoryApi.movements(item.id);
    movements.value = res.data?.data || [];
  } catch (err) {
    console.error('Failed to load movements:', err);
    toast.error('Failed to load item movement history', 'Error');
  } finally {
    loadingMovements.value = false;
  }
}

// --- Delete Item Actions ---
function confirmDeleteItem(item) {
  itemToDelete.value = item;
  deleteModalOpen.value = true;
}

async function executeDeleteItem() {
  if (!itemToDelete.value) return;
  deleting.value = true;
  try {
    const name = itemToDelete.value.name;
    await inventoryApi.delete(itemToDelete.value.id);
    deleteModalOpen.value = false;
    itemToDelete.value = null;
    toast.success(`Item "${name}" permanently deleted from catalog.`, 'Item Deleted');
    fetchItems();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to delete item';
    toast.error(msg, 'Delete Item Failed');
  } finally {
    deleting.value = false;
  }
}

// --- Visual Helpers ---
function formatAmount(amt) {
  return (Number(amt) || 0).toLocaleString('en-IN');
}

function copyText(val) {
  if (!val) return;
  navigator.clipboard?.writeText(val);
  toast.success(`Copied: ${val}`);
}

function getStockBadgeClass(item) {
  const qty = Number(item.current_stock ?? item.stock_quantity ?? 0);
  const min = Number(item.minimum_stock ?? 2);
  if (qty <= 0) {
    return 'bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-900/40';
  }
  if (qty <= min) {
    return 'bg-amber-50 dark:bg-amber-950/40 text-amber-600 dark:text-amber-400 border border-amber-200 dark:border-amber-900/40';
  }
  return 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-900/40';
}

function getStockDotClass(item) {
  const qty = Number(item.current_stock ?? item.stock_quantity ?? 0);
  const min = Number(item.minimum_stock ?? 2);
  if (qty <= 0) return 'bg-rose-500 animate-pulse';
  if (qty <= min) return 'bg-amber-500';
  return 'bg-emerald-500';
}

function getItemTypeBadgeClasses(type) {
  switch (type) {
    case 'mobile':
      return {
        label: 'Mobile Phone',
        icon: '📱',
        iconBg: 'bg-indigo-50 dark:bg-indigo-950/50 text-indigo-600',
        badge: 'bg-indigo-50 dark:bg-indigo-950/40 text-indigo-600 dark:text-indigo-400 border-indigo-200 dark:border-indigo-800/40',
      };
    case 'spare_part':
      return {
        label: 'Spare Part',
        icon: '🔧',
        iconBg: 'bg-amber-50 dark:bg-amber-950/50 text-amber-600',
        badge: 'bg-amber-50 dark:bg-amber-950/40 text-amber-600 dark:text-amber-400 border-amber-200 dark:border-amber-800/40',
      };
    case 'accessory':
      return {
        label: 'Accessory',
        icon: '🔌',
        iconBg: 'bg-purple-50 dark:bg-purple-950/50 text-purple-600',
        badge: 'bg-purple-50 dark:bg-purple-950/40 text-purple-600 dark:text-purple-400 border-purple-200 dark:border-purple-800/40',
      };
    default:
      return {
        label: 'Other',
        icon: '📦',
        iconBg: 'bg-slate-100 dark:bg-slate-800 text-slate-600',
        badge: 'bg-slate-50 dark:bg-slate-800 text-slate-600 dark:text-slate-400 border-slate-200 dark:border-slate-700/60',
      };
  }
}

function formatMovementType(type) {
  const map = {
    opening_stock: 'Opening Stock',
    purchase: 'Purchase Inward',
    sale: 'POS Sale Out',
    repair_usage: 'Repair Part Usage',
    damaged: 'Damaged / Broken',
    lost: 'Lost / Discrepancy',
    return: 'Customer Return',
    adjustment: 'Stock Audit',
  };
  return map[type] || type || 'Movement';
}

function getMovementBadgeClasses(type) {
  switch (type) {
    case 'purchase':
    case 'opening_stock':
    case 'return':
      return 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 border-emerald-200 dark:border-emerald-900/40';
    case 'sale':
    case 'repair_usage':
      return 'bg-indigo-50 dark:bg-indigo-950/40 text-indigo-600 dark:text-indigo-400 border-indigo-200 dark:border-indigo-900/40';
    case 'damaged':
    case 'lost':
      return 'bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 border-rose-200 dark:border-rose-900/40';
    default:
      return 'bg-blue-50 dark:bg-blue-950/40 text-blue-600 dark:text-blue-400 border-blue-200 dark:border-blue-900/40';
  }
}

onMounted(() => {
  fetchCatalogBrands();
  fetchItems();
});
</script>
