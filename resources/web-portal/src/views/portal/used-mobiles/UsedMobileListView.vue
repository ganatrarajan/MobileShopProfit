<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <div class="flex items-center gap-2">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-purple-50 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400 border border-purple-200/60 dark:border-purple-800/60">
            Showroom Inventory & Resale
          </span>
          <span class="text-xs text-slate-400">Pre-owned Mobile Management</span>
        </div>
        <h2 class="text-2xl font-bold tracking-tight text-slate-900 dark:text-white mt-1">Used Mobiles (Buy & Sell)</h2>
        <p class="text-sm text-slate-500 dark:text-slate-400">Track device intakes, repair & refurbishment costs, customer sales and margins</p>
      </div>
      <button
        @click="openBuyModal"
        class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-purple-600 hover:bg-purple-500 text-white text-xs font-bold shadow-md shadow-purple-600/20 transition-all hover:scale-[1.02] active:scale-[0.98] cursor-pointer"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
        </svg>
        <span>+ Buy Second-hand Phone</span>
      </button>
    </div>

    <!-- Top KPI Summary Cards -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
      <!-- In-Stock Showroom -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-xs flex items-center gap-3.5">
        <div class="w-12 h-12 rounded-xl bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 flex items-center justify-center shrink-0 border border-indigo-100 dark:border-indigo-900/40">
          <span class="text-xl">📱</span>
        </div>
        <div class="min-w-0">
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">In Showroom Stock</p>
          <div class="flex items-baseline gap-1 mt-0.5">
            <h3 class="text-xl font-black text-slate-900 dark:text-white">{{ summaryStats.inStockCount }}</h3>
            <span class="text-xs font-bold text-slate-400">Phones</span>
          </div>
          <p class="text-[11px] text-indigo-600 dark:text-indigo-400 font-semibold truncate">
            ₹{{ formatNumber(summaryStats.inStockInvestment) }} invested
          </p>
        </div>
      </div>

      <!-- Sold Phones -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-xs flex items-center gap-3.5">
        <div class="w-12 h-12 rounded-xl bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center shrink-0 border border-emerald-100 dark:border-emerald-900/40">
          <span class="text-xl">🤝</span>
        </div>
        <div class="min-w-0">
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Phones Sold</p>
          <div class="flex items-baseline gap-1 mt-0.5">
            <h3 class="text-xl font-black text-slate-900 dark:text-white">{{ summaryStats.soldCount }}</h3>
            <span class="text-xs font-bold text-slate-400">Sold</span>
          </div>
          <p class="text-[11px] text-emerald-600 dark:text-emerald-400 font-semibold truncate">
            ₹{{ formatNumber(summaryStats.totalSaleRevenue) }} revenue
          </p>
        </div>
      </div>

      <!-- Net Profit Earned -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-xs flex items-center gap-3.5">
        <div class="w-12 h-12 rounded-xl bg-purple-50 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400 flex items-center justify-center shrink-0 border border-purple-100 dark:border-purple-900/40">
          <span class="text-xl">💰</span>
        </div>
        <div class="min-w-0">
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Net Profit Earned</p>
          <h3 class="text-xl font-black text-emerald-600 dark:text-emerald-400 mt-0.5 truncate">
            +₹{{ formatNumber(summaryStats.totalProfit) }}
          </h3>
          <p class="text-[11px] text-slate-400 truncate">
            {{ summaryStats.margin > 0 ? `${summaryStats.margin}% margin` : 'Net margin' }}
          </p>
        </div>
      </div>

      <!-- Lifetime Intake -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-xs flex items-center gap-3.5">
        <div class="w-12 h-12 rounded-xl bg-amber-50 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 flex items-center justify-center shrink-0 border border-amber-100 dark:border-amber-900/40">
          <span class="text-xl">📦</span>
        </div>
        <div class="min-w-0">
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Total Acquired</p>
          <div class="flex items-baseline gap-1 mt-0.5">
            <h3 class="text-xl font-black text-slate-900 dark:text-white">{{ summaryStats.totalPurchasedCount }}</h3>
            <span class="text-xs font-bold text-slate-400">Intakes</span>
          </div>
          <p class="text-[11px] text-slate-400 truncate">
            ₹{{ formatNumber(summaryStats.totalPurchasedAmount) }} total cost
          </p>
        </div>
      </div>
    </div>

    <!-- Filter, Search & Brand Bar -->
    <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-sm space-y-3">
      <div class="flex flex-col md:flex-row items-stretch md:items-center gap-3">
        <!-- Search Input -->
        <div class="relative flex-1">
          <svg class="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <input
            v-model="search"
            type="text"
            placeholder="Search brand, model, IMEI, serial, seller or buyer..."
            class="w-full pl-10 pr-28 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-purple-500 focus:border-purple-500 text-slate-800 dark:text-slate-100 placeholder-slate-400"
          />
          <div class="absolute right-1.5 top-1/2 -translate-y-1/2 flex items-center gap-1">
            <button
              v-if="search"
              @click="search = ''"
              class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 text-xs cursor-pointer p-1"
            >
              ✕
            </button>
            <button
              type="button"
              @click="openScanner('search', 'Scan IMEI or Barcode to Search', 'camera')"
              class="px-2.5 py-1 text-[11px] font-bold text-purple-600 dark:text-purple-400 bg-purple-50 dark:bg-purple-950/60 hover:bg-purple-100 dark:hover:bg-purple-900 rounded-lg transition cursor-pointer flex items-center gap-1"
              title="Scan IMEI or Barcode to search"
            >
              <span>📷</span>
              <span>Scan</span>
            </button>
          </div>
        </div>

        <!-- Status Filter Dropdown -->
        <div class="w-full md:w-48 shrink-0">
          <SearchableSelect
            v-model="statusFilter"
            :options="statusOptions"
            placeholder="Filter Status"
            :searchable="false"
            :fullWidth="true"
          />
        </div>

        <!-- Period Date Filter Dropdown -->
        <div class="w-full md:w-44 shrink-0">
          <SearchableSelect
            v-model="periodFilter"
            :options="periodOptions"
            placeholder="Filter Period"
            :searchable="false"
            :fullWidth="true"
          />
        </div>

        <!-- Sort Filter Dropdown -->
        <div class="w-full md:w-48 shrink-0">
          <SearchableSelect
            v-model="sortFilter"
            :options="sortOptions"
            placeholder="Sort Devices"
            :searchable="false"
            :fullWidth="true"
            prefixIcon="↕️"
          />
        </div>
      </div>

      <!-- Brand Filter Pills -->
      <div v-if="availableBrands.length > 0" class="flex items-center gap-1.5 overflow-x-auto custom-scroll pt-1 pb-1">
        <button
          type="button"
          @click="selectedBrand = 'all'"
          :class="selectedBrand === 'all'
            ? 'bg-purple-600 text-white font-bold shadow-xs'
            : 'bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 hover:bg-slate-200/80'"
          class="px-2.5 py-1 rounded-xl text-xs whitespace-nowrap transition cursor-pointer flex items-center gap-1"
        >
          <span>All Brands</span>
          <span class="text-[10px] opacity-80">({{ mobiles.length }})</span>
        </button>

        <button
          v-for="b in availableBrands"
          :key="b.name"
          type="button"
          @click="selectedBrand = b.name"
          :class="selectedBrand === b.name
            ? 'bg-purple-600 text-white font-bold shadow-xs'
            : 'bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 hover:bg-slate-200/80'"
          class="px-2.5 py-1 rounded-xl text-xs whitespace-nowrap transition cursor-pointer flex items-center gap-1"
        >
          <span>{{ b.name }}</span>
          <span class="text-[10px] opacity-80">({{ b.count }})</span>
        </button>
      </div>
    </div>

    <!-- Table Card -->
    <div class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800/80 shadow-sm overflow-hidden">
      <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="border-b border-slate-100 dark:border-slate-800/80 bg-slate-50/60 dark:bg-slate-900/40 text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              <th class="py-3.5 px-4 pl-6">Device & Specs</th>
              <th class="py-3.5 px-4">Intake & Seller</th>
              <th class="py-3.5 px-4">Investment Cost</th>
              <th class="py-3.5 px-4">Selling & Margin</th>
              <th class="py-3.5 px-4">Status</th>
              <th class="py-3.5 px-4 pr-6 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100 dark:divide-slate-800/60 text-sm">
            <tr v-if="loading">
              <td colspan="6" class="text-center py-16 text-slate-400">
                <div class="inline-block animate-spin w-6 h-6 border-2 border-purple-600 border-t-transparent rounded-full mb-2"></div>
                <div>Loading showroom inventory...</div>
              </td>
            </tr>
            <tr v-else-if="filteredMobiles.length === 0">
              <td colspan="6" class="text-center py-16 text-slate-400 dark:text-slate-500">
                <div class="max-w-xs mx-auto text-center space-y-2">
                  <div class="w-12 h-12 rounded-2xl bg-purple-50 dark:bg-purple-950/40 text-purple-600 dark:text-purple-400 flex items-center justify-center mx-auto text-xl">
                    📱
                  </div>
                  <p class="font-bold text-slate-700 dark:text-slate-300">No used phones found</p>
                  <p class="text-xs text-slate-400">Record a pre-owned phone purchase or adjust your filter query.</p>
                </div>
              </td>
            </tr>
            <tr
              v-for="m in paginatedMobiles"
              :key="m.id"
              class="hover:bg-slate-50/70 dark:hover:bg-slate-800/40 transition group"
            >
              <!-- Device & Specs Column -->
              <td class="py-3.5 px-4 pl-6">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 rounded-xl bg-purple-50 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400 font-bold flex items-center justify-center text-sm border border-purple-200/60 dark:border-purple-800/60 shrink-0">
                    📱
                  </div>
                  <div class="min-w-0">
                    <router-link
                      :to="`/used-mobiles/${m.id}`"
                      class="font-bold text-slate-900 dark:text-white hover:text-purple-600 dark:hover:text-purple-400 transition truncate block"
                    >
                      {{ m.brand }} {{ m.model }}
                    </router-link>
                    <div class="flex items-center gap-1.5 flex-wrap mt-0.5">
                      <span v-if="m.imei1 || m.imei" class="font-mono text-[10px] text-slate-400">
                        IMEI: {{ m.imei1 || m.imei }}
                      </span>
                      <span v-if="m.storage" class="inline-flex items-center px-1.5 py-0.2 rounded text-[10px] font-semibold bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                        {{ m.storage }}
                      </span>
                      <span v-if="m.device_condition" class="inline-flex items-center px-1.5 py-0.2 rounded text-[10px] font-semibold bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 capitalize">
                        {{ m.device_condition }}
                      </span>
                    </div>
                  </div>
                </div>
              </td>

              <!-- Intake & Seller -->
              <td class="py-3.5 px-4">
                <div class="text-xs">
                  <div class="font-bold text-slate-800 dark:text-slate-200">{{ m.seller_name || 'Direct Seller' }}</div>
                  <div class="text-[11px] text-slate-400 font-mono flex items-center gap-1 mt-0.5">
                    <span>{{ m.seller_phone || '-' }}</span>
                    <a
                      v-if="m.seller_phone"
                      :href="`https://wa.me/91${cleanPhone(m.seller_phone)}?text=Hello%20${encodeURIComponent(m.seller_name)},%20regarding%20the%20${encodeURIComponent(m.brand + ' ' + m.model)}%20purchased%20from%20you.`"
                      target="_blank"
                      class="text-emerald-500 hover:text-emerald-600 transition"
                      title="WhatsApp Seller"
                    >
                      <WhatsAppIcon sizeClass="w-3 h-3 text-emerald-600 dark:text-emerald-400" />
                    </a>
                  </div>
                  <div class="text-[10px] text-slate-400 mt-0.5">
                    📅 {{ formatDate(m.purchase_date || m.created_at) }}
                  </div>
                </div>
              </td>

              <!-- Investment Cost -->
              <td class="py-3.5 px-4">
                <div class="text-xs">
                  <div class="font-bold text-slate-800 dark:text-slate-200">
                    ₹{{ formatNumber(m.purchase_price) }}
                  </div>
                  <div v-if="Number(m.repair_cost || m.repair_expense) > 0" class="text-[10px] text-amber-600 dark:text-amber-400 font-semibold mt-0.5">
                    +₹{{ formatNumber(m.repair_cost || m.repair_expense) }} repair
                  </div>
                  <div class="text-[11px] font-black text-slate-900 dark:text-white mt-0.5">
                    Total: ₹{{ formatNumber(m.total_cost || (Number(m.purchase_price || 0) + Number(m.repair_cost || m.repair_expense || 0))) }}
                  </div>
                </div>
              </td>

              <!-- Selling & Margin -->
              <td class="py-3.5 px-4">
                <div v-if="m.status === 'sold'" class="text-xs">
                  <div class="font-bold text-slate-900 dark:text-white">
                    ₹{{ formatNumber(m.selling_price) }}
                  </div>
                  <div class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px] font-bold text-emerald-700 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/60 border border-emerald-200/60 dark:border-emerald-800/60 mt-0.5">
                    <span>+₹{{ formatNumber(m.profit || ((Number(m.selling_price) || 0) - (Number(m.total_cost) || (Number(m.purchase_price) || 0)))) }}</span>
                    <span>profit</span>
                  </div>
                  <div v-if="m.buyer_name" class="text-[10px] text-slate-400 mt-0.5 truncate max-w-[120px]">
                    To: {{ m.buyer_name }}
                  </div>
                </div>
                <div v-else class="text-xs">
                  <span v-if="m.expected_selling_price" class="text-slate-600 dark:text-slate-400">
                    Exp: ₹{{ formatNumber(m.expected_selling_price) }}
                  </span>
                  <span v-else class="text-slate-400 italic">Ready to Sell</span>
                </div>
              </td>

              <!-- Status -->
              <td class="py-3.5 px-4">
                <span
                  :class="m.status === 'sold'
                    ? 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-900/40'
                    : 'bg-indigo-50 dark:bg-indigo-950/40 text-indigo-600 dark:text-indigo-400 border border-indigo-200 dark:border-indigo-900/40'"
                  class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold capitalize border"
                >
                  <span class="w-1.5 h-1.5 rounded-full mr-1.5" :class="m.status === 'sold' ? 'bg-emerald-500' : 'bg-indigo-500 animate-pulse'"></span>
                  <span>{{ m.status === 'sold' ? 'Sold' : 'In Stock' }}</span>
                </span>
              </td>

              <!-- Actions -->
              <td class="py-3.5 px-4 pr-6 text-right whitespace-nowrap">
                <div class="flex items-center justify-end gap-1.5">
                  <!-- Quick Sell Button -->
                  <button
                    v-if="m.status !== 'sold'"
                    @click="openSellModal(m)"
                    type="button"
                    class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-xs font-bold bg-emerald-600 hover:bg-emerald-500 text-white shadow-xs transition cursor-pointer"
                    title="Sell this device"
                  >
                    <span>Sell</span>
                  </button>

                  <!-- Quick Add Repair Expense -->
                  <button
                    v-if="m.status !== 'sold'"
                    @click="openRepairModal(m)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-400 hover:text-indigo-600 hover:bg-indigo-50 dark:hover:bg-indigo-950/40 transition cursor-pointer"
                    title="Add Repair / Refurbishment Expense"
                  >
                    <span class="text-sm">🔧</span>
                  </button>

                  <!-- View Full Details -->
                  <router-link
                    :to="`/used-mobiles/${m.id}`"
                    class="p-1.5 rounded-lg text-slate-400 hover:text-purple-600 hover:bg-purple-50 dark:hover:bg-purple-950/40 transition cursor-pointer"
                    title="View Full Profile"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                    </svg>
                  </router-link>

                  <!-- Edit Profile -->
                  <router-link
                    v-if="m.status !== 'sold'"
                    :to="`/used-mobiles/${m.id}`"
                    class="p-1.5 rounded-lg text-slate-400 hover:text-indigo-600 hover:bg-indigo-50 dark:hover:bg-indigo-950/40 transition cursor-pointer"
                    title="Edit Phone Profile"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                    </svg>
                  </router-link>

                  <!-- Delete -->
                  <button
                    @click="confirmDeleteMobile(m)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/40 transition cursor-pointer"
                    title="Delete Used Phone"
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
        :total-pages="totalPages"
        :total="filteredMobiles.length"
        :per-page="perPage"
        @page-change="onPageChange"
      />
    </div>

    <!-- MODAL 1: BUY SECOND-HAND PHONE (INTAKE) -->
    <div
      v-if="showBuyModal"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 overflow-y-auto flex items-center justify-center p-3 sm:p-5"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-3xl w-full max-w-2xl shadow-2xl max-h-[calc(100vh-2.5rem)] my-auto flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        <!-- Pinned Header -->
        <div class="px-6 py-4 border-b border-slate-100 dark:border-slate-800/80 flex justify-between items-center bg-purple-50/50 dark:bg-purple-950/30 shrink-0">
          <div>
            <h3 class="font-bold text-slate-900 dark:text-white flex items-center gap-2">
              <span>📱</span>
              <span>Purchase Second-Hand Phone (Intake)</span>
            </h3>
            <p class="text-xs text-slate-400">Record customer trade-in or old phone purchase</p>
          </div>
          <button @click="closeBuyModal" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 cursor-pointer">✕</button>
        </div>

        <form @submit.prevent="saveUsedPhone" class="flex flex-col flex-1 overflow-hidden min-h-0">
          <div class="p-6 space-y-4 overflow-y-auto custom-scroll flex-1 pb-8">
            <!-- Device Brand & Model -->
            <div class="p-3.5 rounded-2xl bg-purple-50/40 dark:bg-purple-950/20 border border-purple-100 dark:border-purple-900/40 space-y-3">
              <div class="flex items-center justify-between">
                <label class="block text-xs font-bold uppercase tracking-wider text-purple-700 dark:text-purple-300">
                  📱 Device Brand & Model <span class="text-rose-500">*</span>
                </label>
                <span class="text-[10px] text-purple-600 dark:text-purple-400 font-medium">Select brand to load dynamic models</span>
              </div>

              <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <!-- Brand Searchable Select -->
                <div>
                  <label class="block text-[11px] font-semibold text-slate-600 dark:text-slate-400 mb-1">Brand *</label>
                  <SearchableSelect
                    v-model="buyForm.brand"
                    :options="catalogBrands"
                    placeholder="Select or type brand..."
                    searchPlaceholder="Search mobile brands..."
                    :allowCustom="true"
                    :clearable="true"
                    :fullWidth="true"
                    direction="down"
                    @change="onBrandSelected"
                  />
                </div>

                <!-- Model Searchable Select -->
                <div>
                  <div class="flex items-center justify-between mb-1">
                    <label class="block text-[11px] font-semibold text-slate-600 dark:text-slate-400">Model *</label>
                    <span v-if="loadingModels" class="text-[10px] text-purple-600 font-semibold animate-pulse">Loading...</span>
                    <span v-else-if="catalogModels.length" class="text-[10px] text-slate-400 font-medium">({{ catalogModels.length }} models)</span>
                  </div>
                  <SearchableSelect
                    v-model="buyForm.model"
                    :options="catalogModels"
                    :placeholder="catalogModels.length ? `Select or type model (${catalogModels.length} available)...` : 'Select or type model...'"
                    searchPlaceholder="Search mobile models..."
                    :allowCustom="true"
                    :clearable="true"
                    :fullWidth="true"
                    direction="down"
                  />
                </div>
              </div>

              <!-- Color / Variant -->
              <div>
                <label class="block text-[11px] font-semibold text-slate-600 dark:text-slate-400 mb-1">
                  Color / Variant
                </label>
                <input
                  v-model="buyForm.color"
                  type="text"
                  class="w-full px-3 py-2 text-sm bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-purple-500 text-slate-900 dark:text-slate-100 font-semibold"
                  placeholder="e.g. Midnight Black, Sierra Blue"
                />
              </div>
            </div>

            <!-- IMEI 1 & IMEI 2 / Serial -->
            <div class="p-3.5 rounded-2xl bg-purple-50/40 dark:bg-purple-950/20 border border-purple-100 dark:border-purple-900/40 space-y-3">
              <div class="flex items-center justify-between pb-1 border-b border-purple-100 dark:border-purple-900/40">
                <span class="text-xs font-bold text-purple-700 dark:text-purple-300 flex items-center gap-1.5">
                  <span>🏷️</span> Device Identifiers (IMEI & Serial)
                </span>
                <button
                  type="button"
                  @click="openScanner('box', 'Auto-Scan Phone Box Sticker', 'box')"
                  class="px-2.5 py-1 text-[11px] font-bold text-white bg-purple-600 hover:bg-purple-500 rounded-lg shadow-sm transition cursor-pointer flex items-center gap-1"
                >
                  <span>⚡</span> Auto-Scan Box
                </button>
              </div>

              <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <div class="flex items-center justify-between mb-1">
                    <label class="text-[11px] font-semibold text-slate-700 dark:text-slate-300">
                      IMEI 1 (15 digits)
                    </label>
                    <button
                      type="button"
                      @click="openScanner('imei1', 'Scan Primary IMEI 1', 'camera')"
                      class="text-[10px] font-bold text-purple-600 hover:text-purple-700 flex items-center gap-0.5 cursor-pointer"
                    >
                      <span>📷</span> Scan
                    </button>
                  </div>
                  <div class="relative">
                    <input
                      v-model="buyForm.imei1"
                      type="text"
                      maxlength="18"
                      class="w-full pl-3 pr-8 py-2 text-sm bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-purple-500 text-slate-900 dark:text-slate-100 font-mono font-bold"
                      placeholder="e.g. 864201948102931"
                    />
                    <button
                      type="button"
                      @click="openScanner('imei1', 'Scan Primary IMEI 1', 'camera')"
                      class="absolute inset-y-1 right-1 px-2 flex items-center text-slate-400 hover:text-purple-600 cursor-pointer"
                    >
                      📷
                    </button>
                  </div>
                </div>

                <div>
                  <div class="flex items-center justify-between mb-1">
                    <label class="text-[11px] font-semibold text-slate-700 dark:text-slate-300">
                      IMEI 2 or Serial Number (Optional)
                    </label>
                    <button
                      type="button"
                      @click="openScanner('imei2', 'Scan Secondary IMEI 2 / Serial', 'camera')"
                      class="text-[10px] font-bold text-purple-600 hover:text-purple-700 flex items-center gap-0.5 cursor-pointer"
                    >
                      <span>📷</span> Scan
                    </button>
                  </div>
                  <div class="relative">
                    <input
                      v-model="buyForm.imei2"
                      type="text"
                      class="w-full pl-3 pr-8 py-2 text-sm bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-purple-500 text-slate-900 dark:text-slate-100 font-mono font-bold"
                      placeholder="Second IMEI or Serial"
                    />
                    <button
                      type="button"
                      @click="openScanner('imei2', 'Scan Secondary IMEI 2 / Serial', 'camera')"
                      class="absolute inset-y-1 right-1 px-2 flex items-center text-slate-400 hover:text-purple-600 cursor-pointer"
                    >
                      📷
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <!-- RAM & Storage & Battery -->
            <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div>
                <label class="block text-[11px] font-semibold text-slate-600 dark:text-slate-400 mb-1">RAM</label>
                <SearchableSelect
                  v-model="buyForm.ram"
                  :options="ramOptions"
                  placeholder="Select RAM"
                  searchPlaceholder="Search or enter RAM..."
                  :allowCustom="true"
                  :clearable="true"
                  :fullWidth="true"
                  direction="down"
                />
              </div>
              <div>
                <label class="block text-[11px] font-semibold text-slate-600 dark:text-slate-400 mb-1">Storage</label>
                <SearchableSelect
                  v-model="buyForm.storage"
                  :options="storageOptions"
                  placeholder="Select Storage"
                  searchPlaceholder="Search or enter Storage..."
                  :allowCustom="true"
                  :clearable="true"
                  :fullWidth="true"
                  direction="down"
                />
              </div>
              <div>
                <label class="block text-[11px] font-semibold text-slate-600 dark:text-slate-400 mb-1">Battery Health %</label>
                <input
                  v-model="buyForm.battery_health"
                  type="text"
                  class="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-purple-500 text-slate-900 dark:text-slate-100 font-semibold"
                  placeholder="e.g. 88%"
                />
              </div>
            </div>

            <!-- Device Condition & Accessories -->
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                  Device Condition
                </label>
                <SearchableSelect
                  v-model="buyForm.device_condition"
                  :options="conditionOptions"
                  placeholder="Select Condition"
                  minWidth="100%"
                  :searchable="false"
                />
              </div>
              <div>
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                  Accessories Included
                </label>
                <div class="flex flex-wrap gap-2 pt-1">
                  <label v-for="acc in availableAccessories" :key="acc" class="flex items-center gap-1.5 text-xs text-slate-700 dark:text-slate-300 cursor-pointer">
                    <input
                      type="checkbox"
                      :value="acc"
                      v-model="buyForm.accessories_included"
                      class="rounded text-purple-600 focus:ring-purple-500 w-3.5 h-3.5"
                    />
                    <span>{{ acc }}</span>
                  </label>
                </div>
              </div>
            </div>

            <!-- Seller Details -->
            <div class="pt-2 border-t border-slate-100 dark:border-slate-800/80">
              <h4 class="text-xs font-bold uppercase tracking-wider text-slate-400 mb-3">Seller (Customer) Details</h4>
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                    Seller Name <span class="text-rose-500">*</span>
                  </label>
                  <input
                    v-model="buyForm.seller_name"
                    type="text"
                    class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-purple-500 text-slate-900 dark:text-slate-100"
                    placeholder="Full name"
                    required
                  />
                </div>
                <div>
                  <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                    Seller Mobile <span class="text-rose-500">*</span>
                  </label>
                  <input
                    v-model="buyForm.seller_phone"
                    type="tel"
                    maxlength="10"
                    class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-purple-500 text-slate-900 dark:text-slate-100 font-mono"
                    placeholder="10-digit mobile"
                    required
                  />
                </div>
              </div>

              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mt-3">
                <div>
                  <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                    ID Proof Type (Optional)
                  </label>
                  <SearchableSelect
                    v-model="buyForm.id_proof_type"
                    :options="idProofOptions"
                    placeholder="Select ID Proof"
                    minWidth="100%"
                    :searchable="false"
                  />
                </div>
                <div>
                  <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                    ID Proof Number
                  </label>
                  <input
                    v-model="buyForm.id_proof_number"
                    type="text"
                    class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-purple-500 text-slate-900 dark:text-slate-100 font-mono"
                    placeholder="e.g. Aadhaar 12-digit / DL number"
                  />
                </div>
              </div>
            </div>

            <!-- Financials (Purchase Price & Expected Resale) -->
            <div class="pt-2 border-t border-slate-100 dark:border-slate-800/80">
              <h4 class="text-xs font-bold uppercase tracking-wider text-slate-400 mb-3">Financials & Pricing</h4>
              <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div>
                  <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                    Purchase Price (₹) <span class="text-rose-500">*</span>
                  </label>
                  <input
                    v-model.number="buyForm.purchase_price"
                    type="number"
                    step="0.01"
                    min="1"
                    class="w-full px-3 py-2 text-sm font-bold bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-purple-500 text-slate-900 dark:text-slate-100"
                    placeholder="e.g. 12000"
                    required
                  />
                </div>
                <div>
                  <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                    Initial Repair (₹)
                  </label>
                  <input
                    v-model.number="buyForm.repair_cost"
                    type="number"
                    step="0.01"
                    min="0"
                    class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-purple-500 text-slate-900 dark:text-slate-100"
                    placeholder="e.g. 1500"
                  />
                </div>
                <div>
                  <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                    Target Resale (₹)
                  </label>
                  <input
                    v-model.number="buyForm.expected_selling_price"
                    type="number"
                    step="0.01"
                    min="0"
                    class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-purple-500 text-slate-900 dark:text-slate-100"
                    placeholder="e.g. 16500"
                  />
                </div>
              </div>

              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mt-3">
                <div>
                  <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                    Purchase Date <span class="text-rose-500">*</span>
                  </label>
                  <input
                    v-model="buyForm.purchase_date"
                    type="date"
                    class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-purple-500 text-slate-900 dark:text-slate-100"
                    required
                  />
                </div>
                <div>
                  <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                    Payment Mode
                  </label>
                  <SearchableSelect
                    v-model="buyForm.payment_mode"
                    :options="paymentModeOptions"
                    placeholder="Payment Mode"
                    minWidth="100%"
                  />
                </div>
              </div>
            </div>
          </div>

          <!-- Pinned Footer -->
          <div class="px-6 py-3.5 border-t border-slate-100 dark:border-slate-800/80 bg-slate-50/50 dark:bg-slate-900/30 flex justify-end gap-2 shrink-0">
            <button
              type="button"
              @click="closeBuyModal"
              class="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-xl transition cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="saving"
              class="px-5 py-2 text-xs font-bold text-white bg-purple-600 hover:bg-purple-500 rounded-xl shadow-md shadow-purple-600/20 disabled:opacity-50 transition cursor-pointer"
            >
              {{ saving ? 'Recording Intake...' : 'Confirm Phone Purchase' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- MODAL 2: SELL USED PHONE -->
    <div
      v-if="sellModalOpen"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 overflow-y-auto flex items-center justify-center p-3 sm:p-5"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-3xl w-full max-w-lg shadow-2xl max-h-[calc(100vh-2.5rem)] my-auto flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        <div class="px-6 py-4 border-b border-slate-100 dark:border-slate-800/80 flex justify-between items-center bg-emerald-50/50 dark:bg-emerald-950/30 shrink-0">
          <div>
            <h3 class="font-bold text-slate-900 dark:text-white flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-emerald-500"></span>
              Sell Used Mobile
            </h3>
            <p v-if="mobileToSell" class="text-xs text-slate-400 mt-0.5">
              {{ mobileToSell.brand }} {{ mobileToSell.model }} (IMEI: {{ mobileToSell.imei1 || mobileToSell.imei || 'N/A' }})
            </p>
            <p v-else class="text-xs text-slate-400 mt-0.5">
              Select an in-stock device and record customer sale
            </p>
          </div>
          <button @click="closeSellModal" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 cursor-pointer">✕</button>
        </div>

        <form @submit.prevent="executeSellMobile" class="flex flex-col flex-1 overflow-hidden min-h-0">
          <div class="p-6 space-y-4 overflow-y-auto custom-scroll flex-1 pb-8">
            <!-- Device Selector (when opened from navigation or when multiple in-stock phones exist) -->
            <div v-if="isGlobalSell || !mobileToSell" class="p-3.5 bg-emerald-50/60 dark:bg-emerald-950/40 rounded-2xl border border-emerald-200/80 dark:border-emerald-800/60">
              <label class="block text-xs font-bold uppercase tracking-wider text-emerald-800 dark:text-emerald-300 mb-1.5">
                Select Phone to Sell from Showroom <span class="text-rose-500">*</span>
              </label>
              <div v-if="inStockMobileOptions.length > 0">
                <SearchableSelect
                  v-model="selectedMobileIdToSell"
                  :options="inStockMobileOptions"
                  placeholder="Choose an in-stock phone..."
                  minWidth="100%"
                  :searchable="true"
                  searchPlaceholder="Search phone by model or IMEI..."
                  @change="onSelectMobileToSell"
                />
                <div v-if="mobileToSell" class="flex items-center gap-3 mt-2 text-xs text-slate-600 dark:text-slate-300 font-medium">
                  <span>Investment: <strong class="text-slate-900 dark:text-white">₹{{ formatNumber(mobileToSell.total_cost || mobileToSell.purchase_price) }}</strong></span>
                  <span v-if="mobileToSell.expected_selling_price">Target Resale: <strong class="text-emerald-600 dark:text-emerald-400">₹{{ formatNumber(mobileToSell.expected_selling_price) }}</strong></span>
                  <span v-if="mobileToSell.device_condition" class="capitalize">({{ mobileToSell.device_condition }})</span>
                </div>
              </div>
              <div v-else class="text-xs text-rose-600 dark:text-rose-400 font-semibold py-1">
                ⚠️ No phones currently in showroom stock. Please purchase/intake a phone first.
              </div>
            </div>

            <!-- Buyer Details -->
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Buyer Name <span class="text-rose-500">*</span></label>
                <input v-model="sellForm.buyer_name" type="text" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-emerald-500 text-slate-900 dark:text-slate-100" placeholder="Customer name" required />
              </div>
              <div>
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Buyer Phone <span class="text-rose-500">*</span></label>
                <input v-model="sellForm.buyer_phone" type="tel" maxlength="10" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-emerald-500 text-slate-900 dark:text-slate-100 font-mono" placeholder="10-digit mobile" required />
              </div>
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Selling Price (₹) <span class="text-rose-500">*</span></label>
                <input v-model.number="sellForm.selling_price" type="number" step="1" min="1" class="w-full px-3 py-2 text-sm font-bold bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-emerald-500 text-slate-900 dark:text-slate-100" required />
              </div>
              <div>
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Sale Date <span class="text-rose-500">*</span></label>
                <input v-model="sellForm.sale_date" type="date" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-emerald-500 text-slate-900 dark:text-slate-100" required />
              </div>
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Payment Mode</label>
                <SearchableSelect
                  v-model="sellForm.sale_payment_mode"
                  :options="paymentModeOptions"
                  placeholder="Select Mode"
                  minWidth="100%"
                />
              </div>
              <div>
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Testing Warranty</label>
                <SearchableSelect
                  v-model="sellForm.warranty_days"
                  :options="warrantyOptions"
                  placeholder="Select Warranty"
                  minWidth="100%"
                  :searchable="false"
                />
              </div>
            </div>

            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Customer Address (Optional)</label>
              <input v-model="sellForm.buyer_address" type="text" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-emerald-500 text-slate-900 dark:text-slate-100 placeholder-slate-400" placeholder="City or street address" />
            </div>

            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Sale Notes / Remarks</label>
              <input v-model="sellForm.sale_notes" type="text" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-emerald-500 text-slate-900 dark:text-slate-100 placeholder-slate-400" placeholder="Charger given, condition accepted, etc." />
            </div>
          </div>

          <div class="px-6 py-3.5 border-t border-slate-100 dark:border-slate-800/80 bg-slate-50/50 dark:bg-slate-900/30 flex justify-end gap-2 shrink-0">
            <button type="button" @click="closeSellModal" class="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-xl transition cursor-pointer">Cancel</button>
            <button
              type="submit"
              :disabled="selling || (isGlobalSell && !selectedMobileIdToSell)"
              class="px-5 py-2 text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-500 rounded-xl shadow-md shadow-emerald-600/20 disabled:opacity-50 transition cursor-pointer"
            >
              {{ selling ? 'Recording Sale...' : 'Confirm Sale' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- MODAL 3: ADD REPAIR EXPENSE -->
    <div
      v-if="repairModalOpen"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 overflow-y-auto flex items-center justify-center p-3 sm:p-5"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-3xl w-full max-w-md shadow-2xl max-h-[calc(100vh-2.5rem)] my-auto flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        <div class="px-6 py-4 border-b border-slate-100 dark:border-slate-800/80 flex justify-between items-center bg-indigo-50/50 dark:bg-indigo-950/30 shrink-0">
          <div>
            <h3 class="font-bold text-slate-900 dark:text-white flex items-center gap-2">
              <span>🔧</span>
              <span>Add Refurbishment Cost</span>
            </h3>
            <p class="text-xs text-slate-400 mt-0.5">{{ mobileToRepair?.brand }} {{ mobileToRepair?.model }}</p>
          </div>
          <button @click="repairModalOpen = false" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 cursor-pointer">✕</button>
        </div>

        <form @submit.prevent="executeAddRepair" class="flex flex-col flex-1 overflow-hidden min-h-0">
          <div class="p-6 space-y-4 overflow-y-auto custom-scroll flex-1 pb-8">
            <div class="p-3.5 rounded-2xl bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-800/40 text-xs">
              <span class="text-amber-700 dark:text-amber-400 font-bold block mb-1">Current Device Cost:</span>
              <div class="flex items-center justify-between text-slate-700 dark:text-slate-300">
                <span>Purchase Price:</span>
                <span class="font-bold">₹{{ formatNumber(mobileToRepair?.purchase_price) }}</span>
              </div>
              <div class="flex items-center justify-between text-slate-700 dark:text-slate-300 mt-0.5">
                <span>Previous Repairs:</span>
                <span class="font-bold text-amber-600">₹{{ formatNumber(mobileToRepair?.repair_cost || mobileToRepair?.repair_expense || 0) }}</span>
              </div>
            </div>

            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                New Total Repair Cost (₹) <span class="text-rose-500">*</span>
              </label>
              <input
                v-model.number="repairForm.repair_cost"
                type="number"
                step="0.01"
                min="0"
                class="w-full px-3 py-2 text-sm font-bold bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100"
                placeholder="e.g. 1500"
                required
              />
            </div>

            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Repair Details
              </label>
              <textarea
                v-model="repairForm.repair_details"
                rows="3"
                class="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100"
                placeholder="e.g. Changed display combo, battery replacement"
              ></textarea>
            </div>
          </div>

          <div class="px-6 py-3.5 border-t border-slate-100 dark:border-slate-800/80 bg-slate-50/50 dark:bg-slate-900/30 flex justify-end gap-2 shrink-0">
            <button type="button" @click="repairModalOpen = false" class="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-xl transition cursor-pointer">Cancel</button>
            <button
              type="submit"
              :disabled="submittingRepair"
              class="px-5 py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-500 rounded-xl shadow-md shadow-indigo-600/20 disabled:opacity-50 transition cursor-pointer"
            >
              {{ submittingRepair ? 'Saving...' : 'Save Repair Expense' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- MODAL 4: DELETE CONFIRMATION -->
    <div
      v-if="deleteModalOpen"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-3 sm:p-5"
      @wheel.stop
    >
      <div class="bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-2xl w-full max-w-sm shadow-2xl p-6 text-center animate-in fade-in zoom-in-95">
        <div class="w-12 h-12 rounded-full bg-rose-50 dark:bg-rose-950/60 text-rose-600 dark:text-rose-400 flex items-center justify-center mx-auto mb-3">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
        </div>
        <h3 class="text-base font-bold text-slate-900 dark:text-white">Delete Used Phone?</h3>
        <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
          Are you sure you want to delete <span class="font-bold text-slate-700 dark:text-slate-300">{{ mobileToDelete?.brand }} {{ mobileToDelete?.model }}</span>?
        </p>
        <div class="flex items-center justify-center gap-2 mt-5">
          <button
            @click="deleteModalOpen = false"
            class="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition cursor-pointer"
          >
            Cancel
          </button>
          <button
            @click="executeDeleteMobile"
            :disabled="deleting"
            class="px-4 py-2 rounded-xl text-xs font-semibold bg-rose-600 hover:bg-rose-500 text-white shadow-md shadow-rose-600/20 disabled:opacity-50 transition cursor-pointer"
          >
            {{ deleting ? 'Deleting...' : 'Yes, Delete' }}
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
import { ref, reactive, computed, onMounted, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useToastStore } from '@/stores/toast';
import { usedMobileApi, deviceApi } from '@/api/endpoints';
import PaginationBar from '@/components/common/PaginationBar.vue';
import SearchableSelect from '@/components/common/SearchableSelect.vue';
import WhatsAppIcon from '@/components/common/WhatsAppIcon.vue';
import BarcodeScannerModal from '@/components/common/BarcodeScannerModal.vue';
import { formatDate, toInputDate } from '@/utils/date';

const route = useRoute();
const router = useRouter();
const toast = useToastStore();

const mobiles = ref([]);
const summaryData = ref({});
const loading = ref(false);
const search = ref('');
const statusFilter = ref('');
const periodFilter = ref('this_month');
const sortFilter = ref('newest');
const sortOptions = [
  { value: 'newest', label: 'Newest First (Recent)' },
  { value: 'oldest', label: 'Oldest First' },
  { value: 'price_high', label: 'Price (High to Low)' },
  { value: 'price_low', label: 'Price (Low to High)' },
];
const selectedBrand = ref('all');

// Barcode & IMEI Scanner State
const scannerOpen = ref(false);
const scannerTitle = ref('Scan Barcode or IMEI');
const scannerInitialMode = ref('camera');
const scannerTarget = ref('');

function openScanner(target, title = 'Scan Barcode or IMEI', mode = 'camera') {
  scannerTarget.value = target;
  scannerTitle.value = title;
  scannerInitialMode.value = mode;
  scannerOpen.value = true;
}

function cleanCode(raw) {
  if (!raw) return '';
  return raw.replace(/^(s\/n|sn|serial|imei1|imei2|imei|p\/n|pn)[:\s-]+/i, '').trim();
}

function handleScanResult(code) {
  if (!code) return;
  const clean = cleanCode(code);
  if (scannerTarget.value === 'imei1') {
    buyForm.imei1 = clean;
    toast.success(`Scanned IMEI 1: ${clean}`, 'Scanned');
  } else if (scannerTarget.value === 'imei2') {
    buyForm.imei2 = clean;
    toast.success(`Scanned IMEI 2 / Serial: ${clean}`, 'Scanned');
  } else if (scannerTarget.value === 'search') {
    search.value = clean;
    toast.success(`Searching for: ${clean}`, 'Scanned');
  }
  scannerOpen.value = false;
}

function handleBoxResult(res) {
  if (scannerTarget.value === 'box') {
    if (res.imei1) buyForm.imei1 = res.imei1;
    if (res.imei2) buyForm.imei2 = res.imei2;
    else if (res.serialNumber) buyForm.imei2 = res.serialNumber;
    toast.success('Extracted identifiers from box sticker!', 'Auto-Scan Success');
  }
  scannerOpen.value = false;
}

const showBuyModal = ref(false);
const saving = ref(false);

const sellModalOpen = ref(false);
const mobileToSell = ref(null);
const selectedMobileIdToSell = ref(null);
const isGlobalSell = ref(false);
const selling = ref(false);

const repairModalOpen = ref(false);
const mobileToRepair = ref(null);
const submittingRepair = ref(false);

const deleteModalOpen = ref(false);
const mobileToDelete = ref(null);
const deleting = ref(false);

const currentPage = ref(1);
const perPage = ref(15);

const catalogBrands = ref([]);
const catalogModels = ref([]);
const loadingModels = ref(false);

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

async function fetchCatalogBrands() {
  try {
    const res = await deviceApi.brands();
    if (res.data?.data && Array.isArray(res.data.data)) {
      catalogBrands.value = res.data.data;
    }
  } catch (_) {}
}

async function fetchModelsForBrand(brand) {
  if (!brand || brand.trim().length < 2) {
    catalogModels.value = [];
    return;
  }
  loadingModels.value = true;
  try {
    const res = await deviceApi.models({ brand: brand.trim() });
    catalogModels.value = res.data?.data || res.data || [];
  } catch {
    catalogModels.value = [];
  } finally {
    loadingModels.value = false;
  }
}

function onBrandSelected(brand) {
  if (brand && typeof brand === 'string') {
    buyForm.brand = brand;
  }
  fetchModelsForBrand(buyForm.brand);
}

function setBuyBrand(b) {
  buyForm.brand = b;
  buyForm.model = '';
  fetchModelsForBrand(b);
}

const availableAccessories = ['Original Box', 'Charger & Cable', 'Bill / Invoice', 'Earphones'];

const statusOptions = [
  { value: '', label: 'All Inventory' },
  { value: 'in_stock', label: 'Showroom Stock (In Stock)' },
  { value: 'sold', label: 'Sold Phones' },
];

const periodOptions = [
  { value: 'this_month', label: 'This Month' },
  { value: 'today', label: 'Today' },
  { value: 'yesterday', label: 'Yesterday' },
  { value: 'this_week', label: 'This Week' },
  { value: 'last_month', label: 'Last Month' },
  { value: 'this_year', label: 'This Year' },
  { value: 'all_time', label: 'All Time' },
];

const conditionOptions = [
  { value: 'mint', label: 'Mint (Like New)' },
  { value: 'good', label: 'Good Condition' },
  { value: 'fair', label: 'Fair / Minor Scratches' },
  { value: 'damaged', label: 'Damaged / Needs Repair' },
];

const idProofOptions = [
  { value: 'Aadhaar Card', label: 'Aadhaar Card' },
  { value: 'Driving License', label: 'Driving License' },
  { value: 'PAN Card', label: 'PAN Card' },
  { value: 'Voter ID', label: 'Voter ID' },
  { value: 'Passport', label: 'Passport' },
];

const paymentModeOptions = [
  { value: 'Cash', label: 'Cash', icon: '💵' },
  { value: 'UPI / Online', label: 'UPI / PhonePe / GPay', icon: '⚡' },
  { value: 'Debit / Credit Card', label: 'Debit / Credit Card', icon: '💳' },
  { value: 'Bank Transfer', label: 'Bank Transfer', icon: '🏦' },
];

const warrantyOptions = [
  { value: 0, label: 'No Warranty' },
  { value: 7, label: '7 Days Testing Warranty' },
  { value: 15, label: '15 Days (Recommended)' },
  { value: 30, label: '30 Days Testing' },
  { value: 60, label: '60 Days Warranty' },
  { value: 90, label: '90 Days Warranty' },
];

const buyForm = reactive({
  brand: 'Apple',
  model: '',
  color: '',
  imei1: '',
  imei2: '',
  ram: '',
  storage: '128GB',
  battery_health: '',
  device_condition: 'good',
  accessories_included: ['Original Box'],
  seller_name: '',
  seller_phone: '',
  id_proof_type: 'Aadhaar Card',
  id_proof_number: '',
  purchase_price: '',
  repair_cost: 0,
  expected_selling_price: '',
  purchase_date: toInputDate(new Date()),
  payment_mode: 'Cash',
});

const sellForm = reactive({
  buyer_name: '',
  buyer_phone: '',
  buyer_address: '',
  selling_price: 0,
  sale_date: toInputDate(new Date()),
  sale_payment_mode: 'Cash',
  warranty_days: 15,
  sale_notes: '',
});

const repairForm = reactive({
  repair_cost: 0,
  repair_details: '',
});

async function fetchMobiles() {
  loading.value = true;
  try {
    const res = await usedMobileApi.list({
      status: statusFilter.value || undefined,
      sort: sortFilter.value || 'newest',
    });
    if (res.data?.success) {
      mobiles.value = res.data.data || [];
      summaryData.value = res.data.summary || {};
    } else {
      const payload = res.data?.data;
      mobiles.value = payload?.data || (Array.isArray(payload) ? payload : []);
    }
  } catch (err) {
    console.error('Failed to load used mobiles:', err);
    toast.error('Failed to load used phones', 'Error');
  } finally {
    loading.value = false;
  }
}

watch([statusFilter, sortFilter], () => {
  currentPage.value = 1;
  fetchMobiles();
});

const summaryStats = computed(() => {
  const inStockList = mobiles.value.filter(m => m.status !== 'sold');
  const soldList = mobiles.value.filter(m => m.status === 'sold');

  const inStockCount = summaryData.value?.in_stock_count ?? inStockList.length;
  const inStockInvestment = summaryData.value?.in_stock_investment ?? inStockList.reduce((sum, m) => sum + Number(m.total_cost || m.purchase_price || 0), 0);

  const soldCount = summaryData.value?.sold_count ?? soldList.length;
  const totalSaleRevenue = summaryData.value?.total_sale_revenue ?? soldList.reduce((sum, m) => sum + Number(m.selling_price || 0), 0);
  const totalProfit = summaryData.value?.total_profit_earned ?? soldList.reduce((sum, m) => {
    const profit = m.profit !== null && m.profit !== undefined
      ? Number(m.profit)
      : (Number(m.selling_price || 0) - Number(m.total_cost || m.purchase_price || 0));
    return sum + profit;
  }, 0);

  const margin = totalSaleRevenue > 0 ? Math.round((totalProfit / totalSaleRevenue) * 100) : 0;

  const totalPurchasedCount = summaryData.value?.total_purchased_count ?? mobiles.value.length;
  const totalPurchasedAmount = summaryData.value?.total_purchased_amount ?? mobiles.value.reduce((sum, m) => sum + Number(m.purchase_price || 0), 0);

  return {
    inStockCount,
    inStockInvestment,
    soldCount,
    totalSaleRevenue,
    totalProfit,
    margin,
    totalPurchasedCount,
    totalPurchasedAmount,
  };
});

const availableBrands = computed(() => {
  const map = {};
  for (const m of mobiles.value) {
    const b = (m.brand || '').trim();
    if (b) {
      map[b] = (map[b] || 0) + 1;
    }
  }
  return Object.keys(map).map(name => ({ name, count: map[name] })).sort((a, b) => b.count - a.count);
});

const filteredMobiles = computed(() => {
  let list = mobiles.value;

  if (statusFilter.value) {
    list = list.filter(m => m.status === statusFilter.value);
  }

  if (selectedBrand.value !== 'all') {
    list = list.filter(m => (m.brand || '').trim().toLowerCase() === selectedBrand.value.trim().toLowerCase());
  }

  if (search.value) {
    const q = search.value.toLowerCase().trim();
    list = list.filter(m =>
      (m.brand && m.brand.toLowerCase().includes(q)) ||
      (m.model && m.model.toLowerCase().includes(q)) ||
      (m.imei && String(m.imei).includes(q)) ||
      (m.imei1 && String(m.imei1).includes(q)) ||
      (m.imei2 && String(m.imei2).includes(q)) ||
      (m.serial_number && m.serial_number.toLowerCase().includes(q)) ||
      (m.seller_name && m.seller_name.toLowerCase().includes(q)) ||
      (m.seller_phone && String(m.seller_phone).includes(q)) ||
      (m.buyer_name && m.buyer_name.toLowerCase().includes(q))
    );
  }

  return list;
});

const totalPages = computed(() => Math.max(1, Math.ceil(filteredMobiles.value.length / perPage.value)));

const paginatedMobiles = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredMobiles.value.slice(start, start + perPage.value);
});

watch([search, statusFilter, selectedBrand, periodFilter], () => {
  currentPage.value = 1;
});

function onPageChange(page) {
  currentPage.value = page;
}

function formatNumber(num) {
  if (num === null || num === undefined) return '0';
  return Number(num).toLocaleString('en-IN');
}

function cleanPhone(phone) {
  return String(phone || '').replace(/\D/g, '').slice(-10);
}

const inStockMobileOptions = computed(() => {
  return mobiles.value
    .filter(m => m.status !== 'sold')
    .map(m => {
      const imeiStr = m.imei1 || m.imei ? ` | IMEI: ${m.imei1 || m.imei}` : '';
      const cost = m.total_cost || m.purchase_price;
      const costStr = cost ? ` (Cost: ₹${formatNumber(cost)})` : '';
      return {
        value: m.id,
        label: `${m.brand} ${m.model}${imeiStr}${costStr}`,
      };
    });
});

function onSelectMobileToSell(val) {
  const m = mobiles.value.find(item => item.id === val);
  if (m) {
    mobileToSell.value = m;
    sellForm.selling_price = Number(m.expected_selling_price || m.selling_price || m.total_cost || m.purchase_price || 0);
  }
}

function openBuyModal() {
  Object.assign(buyForm, {
    brand: 'Apple',
    model: '',
    color: '',
    imei1: '',
    imei2: '',
    ram: '',
    storage: '128GB',
    battery_health: '',
    device_condition: 'good',
    accessories_included: ['Original Box'],
    seller_name: '',
    seller_phone: '',
    id_proof_type: 'Aadhaar Card',
    id_proof_number: '',
    purchase_price: '',
    repair_cost: 0,
    expected_selling_price: '',
    purchase_date: toInputDate(new Date()),
    payment_mode: 'Cash',
  });
  fetchModelsForBrand(buyForm.brand);
  showBuyModal.value = true;
}

function closeBuyModal() {
  showBuyModal.value = false;
  if (route.query.action === 'buy') {
    router.replace({ path: '/used-mobiles' });
  }
}

async function saveUsedPhone() {
  saving.value = true;
  try {
    const title = `${buyForm.brand} ${buyForm.model}`;
    await usedMobileApi.create({
      ...buyForm,
      purchase_price: Number(buyForm.purchase_price),
      repair_cost: Number(buyForm.repair_cost || 0),
      expected_selling_price: buyForm.expected_selling_price ? Number(buyForm.expected_selling_price) : null,
    });
    closeBuyModal();
    toast.success(`Used device "${title}" intake recorded!`, 'Device Saved');
    fetchMobiles();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to save used phone intake';
    toast.error(msg, 'Intake Failed');
  } finally {
    saving.value = false;
  }
}

function openSellModal(m) {
  mobileToSell.value = m;
  selectedMobileIdToSell.value = m.id;
  isGlobalSell.value = false;
  Object.assign(sellForm, {
    buyer_name: '',
    buyer_phone: '',
    buyer_address: '',
    selling_price: Number(m.expected_selling_price || m.selling_price || m.total_cost || m.purchase_price || 0),
    sale_date: toInputDate(new Date()),
    sale_payment_mode: 'Cash',
    warranty_days: 15,
    sale_notes: '',
  });
  sellModalOpen.value = true;
}

function openGlobalSellModal() {
  const inStock = mobiles.value.filter(m => m.status !== 'sold');
  isGlobalSell.value = true;
  if (inStock.length > 0) {
    selectedMobileIdToSell.value = inStock[0].id;
    mobileToSell.value = inStock[0];
    Object.assign(sellForm, {
      buyer_name: '',
      buyer_phone: '',
      buyer_address: '',
      selling_price: Number(inStock[0].expected_selling_price || inStock[0].selling_price || inStock[0].total_cost || inStock[0].purchase_price || 0),
      sale_date: new Date().toISOString().slice(0, 10),
      sale_payment_mode: 'Cash',
      warranty_days: 15,
      sale_notes: '',
    });
  } else {
    selectedMobileIdToSell.value = null;
    mobileToSell.value = null;
    Object.assign(sellForm, {
      buyer_name: '',
      buyer_phone: '',
      buyer_address: '',
      selling_price: 0,
      sale_date: new Date().toISOString().slice(0, 10),
      sale_payment_mode: 'Cash',
      warranty_days: 15,
      sale_notes: '',
    });
  }
  sellModalOpen.value = true;
}

function closeSellModal() {
  sellModalOpen.value = false;
  mobileToSell.value = null;
  selectedMobileIdToSell.value = null;
  isGlobalSell.value = false;
  if (route.query.action === 'sell') {
    router.replace({ path: '/used-mobiles' });
  }
}

async function executeSellMobile() {
  const targetId = mobileToSell.value?.id || selectedMobileIdToSell.value;
  if (!targetId) {
    toast.error('Please select an in-stock phone to sell', 'Validation Error');
    return;
  }
  selling.value = true;
  try {
    await usedMobileApi.sell(targetId, sellForm);
    toast.success(`Used mobile marked as SOLD!`, 'Device Sold');
    closeSellModal();
    fetchMobiles();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to complete sale';
    toast.error(msg, 'Sale Failed');
  } finally {
    selling.value = false;
  }
}

function openRepairModal(m) {
  mobileToRepair.value = m;
  Object.assign(repairForm, {
    repair_cost: Number(m.repair_cost || m.repair_expense || 0),
    repair_details: m.repair_details || '',
  });
  repairModalOpen.value = true;
}

async function executeAddRepair() {
  if (!mobileToRepair.value) return;
  submittingRepair.value = true;
  try {
    await usedMobileApi.addRepairExpense(mobileToRepair.value.id, repairForm);
    toast.success('Repair expense logged successfully!', 'Expense Added');
    repairModalOpen.value = false;
    mobileToRepair.value = null;
    fetchMobiles();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to update repair expense';
    toast.error(msg, 'Update Failed');
  } finally {
    submittingRepair.value = false;
  }
}

function confirmDeleteMobile(m) {
  mobileToDelete.value = m;
  deleteModalOpen.value = true;
}

async function executeDeleteMobile() {
  if (!mobileToDelete.value) return;
  deleting.value = true;
  try {
    const title = `${mobileToDelete.value.brand} ${mobileToDelete.value.model}`;
    await usedMobileApi.delete(mobileToDelete.value.id);
    deleteModalOpen.value = false;
    mobileToDelete.value = null;
    toast.success(`Used device "${title}" removed.`, 'Device Deleted');
    fetchMobiles();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to delete used phone';
    toast.error(msg, 'Delete Failed');
  } finally {
    deleting.value = false;
  }
}

function handleRouteAction() {
  const action = route.query.action;
  if (action === 'buy') {
    openBuyModal();
  } else if (action === 'sell') {
    statusFilter.value = 'in_stock';
    openGlobalSellModal();
  }
}

watch(() => route.query.action, (newAction) => {
  if (newAction === 'buy') {
    openBuyModal();
  } else if (newAction === 'sell') {
    statusFilter.value = 'in_stock';
    openGlobalSellModal();
  } else if (!newAction) {
    showBuyModal.value = false;
    sellModalOpen.value = false;
    isGlobalSell.value = false;
  }
});

onMounted(async () => {
  fetchCatalogBrands();
  await fetchMobiles();
  handleRouteAction();
});
</script>