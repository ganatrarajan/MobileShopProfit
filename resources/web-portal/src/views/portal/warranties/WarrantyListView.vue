<template>
  <div class="space-y-6 pb-12 font-['Outfit',sans-serif]">
    <!-- 1. Header & Quick Actions -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <div class="flex items-center gap-2">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 border border-indigo-200/60 dark:border-indigo-800/60">
            Assurance
          </span>
          <span class="text-xs text-slate-400">Device & Spare Protection</span>
        </div>
        <h2 class="text-2xl font-black tracking-tight text-slate-900 dark:text-white mt-1">Warranties & Guarantees</h2>
        <p class="text-xs text-slate-500 dark:text-slate-400 mt-0.5">Track repair guarantees, manage customer claims, and resolve warranty service requests.</p>
      </div>

      <div class="flex items-center gap-2.5">
        <button
          @click="openCreateWarrantyModal"
          type="button"
          class="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold shadow-md shadow-indigo-600/20 transition cursor-pointer"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 4v16m8-8H4"/></svg>
          + Issue Warranty
        </button>
      </div>
    </div>

    <!-- 2. Metric Summary Cards (Matching Mobile App) -->
    <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
      <!-- Active Warranties -->
      <div
        @click="activeTab = 'warranties'; statusFilter = 'active'"
        class="bg-white dark:bg-[#111827] rounded-2xl p-4 sm:p-5 border border-slate-200/80 dark:border-slate-800/80 shadow-xs cursor-pointer hover:border-emerald-400 transition"
      >
        <div class="flex items-center justify-between">
          <p class="text-[11px] text-slate-400 font-bold uppercase tracking-wider">Active Protection</p>
          <div class="w-8 h-8 rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/></svg>
          </div>
        </div>
        <p class="text-2xl font-black text-emerald-600 dark:text-emerald-400 mt-2 tabular-nums">
          {{ activeWarrantiesCount }}
        </p>
        <p class="text-[10px] text-slate-400 mt-0.5">Valid customer warranties</p>
      </div>

      <!-- Expiring Soon -->
      <div
        @click="activeTab = 'warranties'; statusFilter = 'expiring_soon'"
        class="bg-white dark:bg-[#111827] rounded-2xl p-4 sm:p-5 border border-slate-200/80 dark:border-slate-800/80 shadow-xs cursor-pointer hover:border-amber-400 transition"
      >
        <div class="flex items-center justify-between">
          <p class="text-[11px] text-slate-400 font-bold uppercase tracking-wider">Expiring Soon</p>
          <div class="w-8 h-8 rounded-xl bg-amber-500/10 text-amber-600 dark:text-amber-400 flex items-center justify-center">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
          </div>
        </div>
        <p class="text-2xl font-black text-amber-600 dark:text-amber-400 mt-2 tabular-nums">
          {{ expiringSoonCount }}
        </p>
        <p class="text-[10px] text-slate-400 mt-0.5">Ending within 15 days</p>
      </div>

      <!-- Expired Protection -->
      <div
        @click="activeTab = 'warranties'; statusFilter = 'expired'"
        class="bg-white dark:bg-[#111827] rounded-2xl p-4 sm:p-5 border border-slate-200/80 dark:border-slate-800/80 shadow-xs cursor-pointer hover:border-rose-400 transition"
      >
        <div class="flex items-center justify-between">
          <p class="text-[11px] text-slate-400 font-bold uppercase tracking-wider">Expired Protection</p>
          <div class="w-8 h-8 rounded-xl bg-rose-500/10 text-rose-600 dark:text-rose-400 flex items-center justify-center">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636"/></svg>
          </div>
        </div>
        <p class="text-2xl font-black text-slate-700 dark:text-slate-300 mt-2 tabular-nums">
          {{ expiredCount }}
        </p>
        <p class="text-[10px] text-slate-400 mt-0.5">Out of coverage</p>
      </div>

      <!-- Warranty Claims Filed -->
      <div
        @click="activeTab = 'claims'; claimStatusFilter = ''"
        class="bg-white dark:bg-[#111827] rounded-2xl p-4 sm:p-5 border border-slate-200/80 dark:border-slate-800/80 shadow-xs cursor-pointer hover:border-purple-400 transition"
      >
        <div class="flex items-center justify-between">
          <p class="text-[11px] text-slate-400 font-bold uppercase tracking-wider">Customer Claims</p>
          <div class="w-8 h-8 rounded-xl bg-purple-500/10 text-purple-600 dark:text-purple-400 flex items-center justify-center">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/></svg>
          </div>
        </div>
        <p class="text-2xl font-black text-purple-600 dark:text-purple-400 mt-2 tabular-nums">
          {{ totalClaimsCount }}
        </p>
        <p class="text-[10px] text-slate-400 mt-0.5">Service & replacement claims</p>
      </div>
    </div>

    <!-- 3. Primary Navigation Tabs: Warranties vs Claims -->
    <div class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800/80 shadow-xs p-1.5 flex items-center gap-1.5">
      <button
        @click="activeTab = 'warranties'"
        type="button"
        :class="[
          'flex-1 py-2.5 px-4 rounded-xl text-xs font-bold transition flex items-center justify-center gap-2 cursor-pointer',
          activeTab === 'warranties'
            ? 'bg-indigo-600 text-white shadow-sm shadow-indigo-600/20'
            : 'text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800'
        ]"
      >
        <span>🛡️ All Warranties</span>
        <span class="px-2 py-0.5 rounded-full text-[10px] font-extrabold bg-white/20 text-white">
          {{ warranties.length }}
        </span>
      </button>

      <button
        @click="activeTab = 'claims'; fetchClaims()"
        type="button"
        :class="[
          'flex-1 py-2.5 px-4 rounded-xl text-xs font-bold transition flex items-center justify-center gap-2 cursor-pointer',
          activeTab === 'claims'
            ? 'bg-indigo-600 text-white shadow-sm shadow-indigo-600/20'
            : 'text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800'
        ]"
      >
        <span>⚠️ Warranty Claims</span>
        <span class="px-2 py-0.5 rounded-full text-[10px] font-extrabold bg-purple-100 text-purple-700 dark:bg-purple-950 dark:text-purple-300">
          {{ claims.length }}
        </span>
      </button>
    </div>

    <!-- 4. Filter & Search Bar -->
    <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-sm flex flex-col md:flex-row items-stretch md:items-center gap-3">
      <!-- Search -->
      <div class="relative flex-1">
        <svg class="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
        <input
          v-model="search"
          type="text"
          :placeholder="activeTab === 'warranties' ? 'Search by warranty #, customer name, device or IMEI...' : 'Search claims by claim #, complaint, customer...'"
          class="w-full pl-10 pr-4 py-2 text-xs font-medium bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-slate-800 dark:text-slate-100 placeholder-slate-400"
        />
      </div>

      <!-- Warranties Filters -->
      <div v-if="activeTab === 'warranties'" class="flex flex-wrap items-center gap-2">
        <SearchableSelect
          v-model="statusFilter"
          :options="warrantyStatusOptions"
          placeholder="All Statuses"
          searchPlaceholder="Filter status..."
          minWidth="135px"
        />

        <SearchableSelect
          v-model="typeFilter"
          :options="warrantyTypeOptions"
          placeholder="All Types"
          searchPlaceholder="Filter type..."
          minWidth="125px"
        />

        <SearchableSelect
          v-model="sortFilter"
          :options="sortOptions"
          placeholder="Sort By"
          minWidth="140px"
          prefixIcon="↕️"
        />

        <button
          v-if="search || statusFilter || typeFilter || sortFilter !== 'newest'"
          @click="search = ''; statusFilter = ''; typeFilter = ''; sortFilter = 'newest'"
          type="button"
          class="px-3 py-2 text-xs font-bold text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200 cursor-pointer"
        >
          Reset
        </button>
      </div>

      <!-- Claims Filters -->
      <div v-else class="flex flex-wrap items-center gap-2">
        <SearchableSelect
          v-model="claimStatusFilter"
          :options="claimStatusOptions"
          placeholder="All Claim Statuses"
          searchPlaceholder="Filter status..."
          minWidth="150px"
        />

        <button
          v-if="search || claimStatusFilter"
          @click="search = ''; claimStatusFilter = ''"
          type="button"
          class="px-3 py-2 text-xs font-bold text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200 cursor-pointer"
        >
          Reset
        </button>
      </div>
    </div>

    <!-- 5A. TAB 1: WARRANTIES TABLE -->
    <div v-if="activeTab === 'warranties'" class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800/80 shadow-sm overflow-hidden">
      <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="border-b border-slate-100 dark:border-slate-800/80 bg-slate-50/60 dark:bg-slate-900/40 text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              <th class="py-3.5 px-4">Warranty #</th>
              <th class="py-3.5 px-4">Customer</th>
              <th class="py-3.5 px-4">Device & Origin</th>
              <th class="py-3.5 px-4">Period & Validity</th>
              <th class="py-3.5 px-4 text-center">Claims</th>
              <th class="py-3.5 px-4">Status</th>
              <th class="py-3.5 px-4 pr-6 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100 dark:divide-slate-800/60 text-xs font-medium">
            <tr v-if="loading">
              <td colspan="7" class="text-center py-12 text-slate-400">
                <div class="inline-block animate-spin w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full mb-2"></div>
                <div>Loading customer warranties...</div>
              </td>
            </tr>
            <tr v-else-if="filteredWarranties.length === 0">
              <td colspan="7" class="text-center py-12 text-slate-400 dark:text-slate-500">
                <div class="text-2xl mb-1">🛡️</div>
                No warranties match your criteria.
              </td>
            </tr>
            <tr
              v-for="w in paginatedWarranties"
              :key="w.id"
              class="hover:bg-slate-50/70 dark:hover:bg-slate-800/40 transition group"
            >
              <!-- Warranty # -->
              <td class="py-3.5 px-4">
                <button
                  @click="openWarrantyDetail(w)"
                  type="button"
                  class="font-mono font-bold text-indigo-600 dark:text-indigo-400 hover:underline text-left block cursor-pointer"
                >
                  {{ w.warranty_number || ('WAR-' + String(w.id).padStart(6, '0')) }}
                </button>
                <div class="flex items-center gap-1.5 mt-0.5">
                  <span class="inline-block text-[10px] font-bold uppercase px-1.5 py-0.2 rounded bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400">
                    {{ w.warranty_type === 'sale' ? 'Sale POS' : 'Repair Job' }}
                  </span>
                  <span class="text-[10px] text-slate-400">
                    📅 {{ formatDate(w.warranty_start_date || w.created_at) }}
                  </span>
                </div>
              </td>

              <!-- Customer -->
              <td class="py-3.5 px-4">
                <div class="font-bold text-slate-900 dark:text-white">{{ w.customer?.name || w.customer_name || 'Walk-in Customer' }}</div>
                <div class="text-[11px] font-mono text-slate-400 flex items-center gap-1.5 mt-0.5">
                  <span>{{ w.customer?.mobile || w.customer?.phone || '-' }}</span>
                  <a
                    v-if="w.customer?.mobile || w.customer?.phone"
                    :href="`https://wa.me/91${String(w.customer.mobile || w.customer.phone).replace(/[^0-9]/g, '').slice(-10)}?text=${encodeURIComponent(`Hello ${w.customer.name}, your warranty ${w.warranty_number || ('#WAR-' + w.id)} is active until ${formatDate(w.warranty_end_date)}.`)}`"
                    target="_blank"
                    class="text-emerald-500 hover:text-emerald-600 transition"
                    title="Send WhatsApp confirmation"
                  >
                    <WhatsAppIcon sizeClass="w-3.5 h-3.5" />
                  </a>
                </div>
              </td>

              <!-- Device / Item -->
              <td class="py-3.5 px-4">
                <div class="font-bold text-slate-800 dark:text-slate-200">
                  {{ w.device ? `${w.device.brand} ${w.device.model}` : (w.repair?.device_model || 'Repaired Device') }}
                </div>
                <div class="text-[10.5px] text-slate-400 flex items-center gap-1.5 mt-0.5">
                  <span v-if="w.repair?.job_number" class="text-indigo-600 dark:text-indigo-400 font-mono font-semibold">
                    Job #{{ w.repair.job_number }}
                  </span>
                  <span v-else-if="w.sale?.invoice_number" class="text-emerald-600 dark:text-emerald-400 font-mono font-semibold">
                    Inv #{{ w.sale.invoice_number }}
                  </span>
                  <span v-if="w.device?.imei_1" class="font-mono text-slate-400">
                    • IMEI: {{ w.device.imei_1 }}
                  </span>
                </div>
              </td>

              <!-- Period & Validity -->
              <td class="py-3.5 px-4">
                <div class="font-bold text-slate-900 dark:text-white">
                  {{ w.duration_days ? `${w.duration_days} Days` : '30 Days' }}
                </div>
                <div class="text-[11px] text-slate-400 mt-0.5">
                  <span>Valid until: </span>
                  <span class="font-semibold text-slate-700 dark:text-slate-300">{{ formatDate(w.warranty_end_date) }}</span>
                </div>
                <!-- Days left pill -->
                <div class="mt-1">
                  <span
                    v-if="w.days_remaining > 15"
                    class="inline-block px-2 py-0.2 rounded-full text-[10px] font-extrabold bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300"
                  >
                    {{ w.days_remaining }} days left
                  </span>
                  <span
                    v-else-if="w.days_remaining > 0"
                    class="inline-block px-2 py-0.2 rounded-full text-[10px] font-extrabold bg-amber-50 text-amber-700 dark:bg-amber-950/40 dark:text-amber-300"
                  >
                    Expiring in {{ w.days_remaining }} days
                  </span>
                  <span
                    v-else
                    class="inline-block px-2 py-0.2 rounded-full text-[10px] font-extrabold bg-rose-50 text-rose-700 dark:bg-rose-950/40 dark:text-rose-300"
                  >
                    Expired
                  </span>
                </div>
              </td>

              <!-- Claims Count -->
              <td class="py-3.5 px-4 text-center">
                <span
                  class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold"
                  :class="Number(w.claims_count) > 0 ? 'bg-purple-100 text-purple-700 dark:bg-purple-950 dark:text-purple-300' : 'bg-slate-100 text-slate-500 dark:bg-slate-800 dark:text-slate-400'"
                >
                  {{ w.claims_count || 0 }} Claims
                </span>
              </td>

              <!-- Status -->
              <td class="py-3.5 px-4">
                <span
                  class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold uppercase tracking-wider"
                  :class="getStatusBadgeClass(w.status || (isExpired(w.warranty_end_date) ? 'expired' : 'active'))"
                >
                  <span class="w-1.5 h-1.5 rounded-full" :class="getStatusDotClass(w.status || (isExpired(w.warranty_end_date) ? 'expired' : 'active'))"></span>
                  <span>{{ formatStatus(w.status || (isExpired(w.warranty_end_date) ? 'expired' : 'active')) }}</span>
                </span>
              </td>

              <!-- Actions -->
              <td class="py-3.5 px-4 pr-6 text-right whitespace-nowrap">
                <div class="flex items-center justify-end gap-1.5">
                  <!-- Register Claim Shortcut -->
                  <button
                    @click="openRegisterClaimModal(w)"
                    type="button"
                    class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-xs font-bold bg-purple-50 text-purple-700 dark:bg-purple-950/50 dark:text-purple-300 hover:bg-purple-100 transition shadow-xs cursor-pointer"
                    title="Register a customer warranty claim"
                  >
                    <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
                    <span>+ Claim</span>
                  </button>

                  <!-- View Warranty Details -->
                  <button
                    @click="openWarrantyDetail(w)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-500 hover:text-indigo-600 hover:bg-indigo-50 dark:hover:bg-slate-800 transition cursor-pointer"
                    title="View Warranty Details & Claims History"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                  </button>

                  <!-- Delete Warranty -->
                  <button
                    @click="confirmDeleteWarranty(w)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/40 transition cursor-pointer"
                    title="Delete Warranty"
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
        :total="filteredWarranties.length"
        :per-page="perPage"
        @page-change="onPageChange"
      />
    </div>

    <!-- 5B. TAB 2: CLAIMS TABLE (Matching Mobile App Claim Management) -->
    <div v-else class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800/80 shadow-sm overflow-hidden">
      <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="border-b border-slate-100 dark:border-slate-800/80 bg-slate-50/60 dark:bg-slate-900/40 text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              <th class="py-3.5 px-4">Claim #</th>
              <th class="py-3.5 px-4">Warranty & Customer</th>
              <th class="py-3.5 px-4">Device</th>
              <th class="py-3.5 px-4">Complaint / Issue</th>
              <th class="py-3.5 px-4">Resolution / Notes</th>
              <th class="py-3.5 px-4">Claim Status</th>
              <th class="py-3.5 px-4 pr-6 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100 dark:divide-slate-800/60 text-xs font-medium">
            <tr v-if="loadingClaims">
              <td colspan="7" class="text-center py-12 text-slate-400">
                <div class="inline-block animate-spin w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full mb-2"></div>
                <div>Loading warranty claims...</div>
              </td>
            </tr>
            <tr v-else-if="filteredClaims.length === 0">
              <td colspan="7" class="text-center py-12 text-slate-400 dark:text-slate-500">
                <div class="text-2xl mb-1">📋</div>
                No warranty claims recorded matching filters.
              </td>
            </tr>
            <tr
              v-for="c in paginatedClaims"
              :key="c.id"
              class="hover:bg-slate-50/70 dark:hover:bg-slate-800/40 transition group"
            >
              <!-- Claim # -->
              <td class="py-3.5 px-4">
                <span class="font-mono font-bold text-purple-600 dark:text-purple-400">
                  {{ c.claim_number || ('CLM-' + String(c.id).padStart(6, '0')) }}
                </span>
                <p class="text-[10px] text-slate-400 mt-0.5">{{ formatDate(c.claim_date || c.created_at) }}</p>
              </td>

              <!-- Warranty & Customer -->
              <td class="py-3.5 px-4">
                <span class="font-mono font-bold text-indigo-600 dark:text-indigo-400 block">
                  {{ c.warranty?.warranty_number || ('#WAR-' + c.warranty_id) }}
                </span>
                <p class="font-bold text-slate-900 dark:text-white mt-0.5">
                  {{ c.customer?.name || c.warranty?.customer?.name || 'Walk-in Customer' }}
                </p>
                <p class="text-[11px] font-mono text-slate-400">
                  {{ c.customer?.mobile || c.warranty?.customer?.mobile || '-' }}
                </p>
              </td>

              <!-- Device -->
              <td class="py-3.5 px-4">
                <div class="font-bold text-slate-800 dark:text-slate-200">
                  {{ c.device ? `${c.device.brand} ${c.device.model}` : (c.warranty?.device ? `${c.warranty.device.brand} ${c.warranty.device.model}` : 'Covered Device') }}
                </div>
              </td>

              <!-- Complaint -->
              <td class="py-3.5 px-4 max-w-xs">
                <p class="font-bold text-slate-900 dark:text-white break-words">{{ c.complaint }}</p>
                <p v-if="c.notes" class="text-[11px] text-slate-400 mt-0.5 italic">Note: {{ c.notes }}</p>
              </td>

              <!-- Resolution -->
              <td class="py-3.5 px-4 max-w-xs">
                <span v-if="c.resolution" class="text-slate-700 dark:text-slate-300">{{ c.resolution }}</span>
                <span v-else class="text-slate-400 italic">No resolution recorded</span>
              </td>

              <!-- Status -->
              <td class="py-3.5 px-4">
                <span
                  class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold uppercase tracking-wider"
                  :class="getClaimStatusBadgeClass(c.claim_status)"
                >
                  {{ c.claim_status }}
                </span>
              </td>

              <!-- Actions -->
              <td class="py-3.5 px-4 pr-6 text-right whitespace-nowrap">
                <div class="flex items-center justify-end gap-1.5">
                  <!-- Update Claim Status -->
                  <button
                    @click="openUpdateClaimModal(c)"
                    type="button"
                    class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-xs font-bold bg-indigo-50 text-indigo-700 dark:bg-indigo-950/50 dark:text-indigo-300 hover:bg-indigo-100 transition shadow-xs cursor-pointer"
                  >
                    <span>Update Status</span>
                    <span>→</span>
                  </button>

                  <!-- Delete Claim -->
                  <button
                    @click="confirmDeleteClaim(c)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/40 transition cursor-pointer"
                    title="Delete Claim"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Claims Pagination -->
      <PaginationBar
        :current-page="currentClaimsPage"
        :total-pages="totalClaimsPages"
        :total="filteredClaims.length"
        :per-page="perPage"
        label="claims"
        @page-change="onClaimsPageChange"
      />
    </div>

    <!-- ========================================================================= -->
    <!-- MODAL 1: REGISTER WARRANTY CLAIM                                          -->
    <!-- ========================================================================= -->
    <div v-if="claimModalOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4 overflow-y-auto">
      <div @click="claimModalOpen = false" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm"></div>

      <div class="relative w-full max-w-lg bg-white dark:bg-[#111827] rounded-3xl border border-slate-200/80 dark:border-slate-800/80 shadow-2xl p-6 z-10 space-y-4">
        <div class="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-2xl bg-purple-500/10 text-purple-600 dark:text-purple-400 flex items-center justify-center">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
            </div>
            <div>
              <h3 class="text-base font-black text-slate-900 dark:text-white">Register Warranty Claim</h3>
              <p class="text-xs text-slate-400 font-mono">{{ activeWarrantyForClaim?.warranty_number }}</p>
            </div>
          </div>
          <button @click="claimModalOpen = false" class="p-2 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
          </button>
        </div>

        <!-- Warranty Summary Strip -->
        <div class="p-3 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200/60 dark:border-slate-800/60 text-xs">
          <div class="flex items-center justify-between">
            <span class="text-slate-500">Customer:</span>
            <span class="font-bold text-slate-900 dark:text-white">{{ activeWarrantyForClaim?.customer?.name }}</span>
          </div>
          <div class="flex items-center justify-between mt-1">
            <span class="text-slate-500">Device:</span>
            <span class="font-bold text-slate-900 dark:text-white">
              {{ activeWarrantyForClaim?.device ? `${activeWarrantyForClaim.device.brand} ${activeWarrantyForClaim.device.model}` : 'Covered Device' }}
            </span>
          </div>
        </div>

        <!-- Form -->
        <form @submit.prevent="submitClaim" class="space-y-4">
          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
              Customer Complaint / Problem <span class="text-rose-500">*</span>
            </label>
            <textarea
              v-model="claimForm.complaint"
              required
              rows="3"
              placeholder="Describe the issue reported by the customer (e.g. touch not responding, replaced battery draining quickly)..."
              class="w-full px-3.5 py-2.5 text-xs font-medium bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-white"
            ></textarea>
          </div>

          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
              Internal Notes (Optional)
            </label>
            <input
              v-model="claimForm.notes"
              type="text"
              placeholder="e.g. customer brought invoice copy, device inspection done"
              class="w-full px-3.5 py-2.5 text-xs font-medium bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-white"
            />
          </div>

          <div class="pt-3 border-t border-slate-100 dark:border-slate-800 flex justify-end gap-2.5">
            <button
              @click="claimModalOpen = false"
              type="button"
              class="px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-300 text-xs font-bold cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="submittingClaim"
              class="px-5 py-2 rounded-xl bg-purple-600 hover:bg-purple-500 text-white text-xs font-bold shadow-md shadow-purple-600/20 disabled:opacity-50 transition cursor-pointer"
            >
              {{ submittingClaim ? 'Submitting...' : 'File Claim' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- ========================================================================= -->
    <!-- MODAL 2: UPDATE CLAIM STATUS & RESOLUTION                                 -->
    <!-- ========================================================================= -->
    <div v-if="updateClaimModalOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4 overflow-y-auto">
      <div @click="updateClaimModalOpen = false" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm"></div>

      <div class="relative w-full max-w-lg bg-white dark:bg-[#111827] rounded-3xl border border-slate-200/80 dark:border-slate-800/80 shadow-2xl p-6 z-10 space-y-4">
        <div class="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
          <div>
            <h3 class="text-base font-black text-slate-900 dark:text-white">Update Claim Status</h3>
            <p class="text-xs text-purple-600 dark:text-purple-400 font-mono font-bold">{{ claimToUpdate?.claim_number }}</p>
          </div>
          <button @click="updateClaimModalOpen = false" class="p-2 text-slate-400 hover:text-slate-600">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
          </button>
        </div>

        <form @submit.prevent="submitClaimUpdate" class="space-y-4">
          <!-- Status Selector -->
          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
              Claim Status <span class="text-rose-500">*</span>
            </label>
            <div class="grid grid-cols-3 sm:grid-cols-4 gap-1.5">
              <button
                v-for="st in ['open', 'checking', 'approved', 'repairing', 'resolved', 'rejected', 'closed']"
                :key="st"
                type="button"
                @click="updateClaimForm.claim_status = st"
                :class="[
                  'py-2 px-2.5 rounded-xl text-xs font-bold uppercase transition cursor-pointer border text-center',
                  updateClaimForm.claim_status === st
                    ? 'bg-indigo-600 text-white border-indigo-600 shadow-xs'
                    : 'bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-400'
                ]"
              >
                {{ st }}
              </button>
            </div>
          </div>

          <!-- Resolution Summary -->
          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
              Resolution Action / Outcome
            </label>
            <textarea
              v-model="updateClaimForm.resolution"
              rows="3"
              placeholder="e.g. Free screen replacement done, re-soldered touch connector, or rejected due to water contact..."
              class="w-full px-3.5 py-2.5 text-xs font-medium bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-white"
            ></textarea>
          </div>

          <!-- Notes -->
          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
              Internal Notes
            </label>
            <input
              v-model="updateClaimForm.notes"
              type="text"
              placeholder="e.g. customer satisfied, delivered on 19 Nov"
              class="w-full px-3.5 py-2.5 text-xs font-medium bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-white"
            />
          </div>

          <div class="pt-3 border-t border-slate-100 dark:border-slate-800 flex justify-end gap-2.5">
            <button
              @click="updateClaimModalOpen = false"
              type="button"
              class="px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-300 text-xs font-bold cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="savingClaimUpdate"
              class="px-5 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold shadow-md shadow-indigo-600/20 disabled:opacity-50 transition cursor-pointer"
            >
              {{ savingClaimUpdate ? 'Saving...' : 'Save Resolution' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- ========================================================================= -->
    <!-- MODAL 3: WARRANTY DETAIL DRAWER                                           -->
    <!-- ========================================================================= -->
    <div v-if="detailModalOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4 overflow-y-auto">
      <div @click="detailModalOpen = false" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm"></div>

      <div class="relative w-full max-w-2xl bg-white dark:bg-[#111827] rounded-3xl border border-slate-200/80 dark:border-slate-800/80 shadow-2xl p-6 z-10 space-y-5 max-h-[85vh] overflow-y-auto">
        <!-- Header -->
        <div class="flex items-start justify-between pb-4 border-b border-slate-100 dark:border-slate-800">
          <div>
            <div class="flex items-center gap-2">
              <span class="font-mono font-black text-lg text-indigo-600 dark:text-indigo-400">
                {{ selectedWarranty?.warranty_number || ('#WAR-' + selectedWarranty?.id) }}
              </span>
              <span
                class="px-2.5 py-0.5 rounded-full text-xs font-bold uppercase"
                :class="getStatusBadgeClass(selectedWarranty?.status)"
              >
                {{ selectedWarranty?.status }}
              </span>
            </div>
            <p class="text-xs text-slate-400 mt-1">
              Issued by <span class="font-bold text-slate-700 dark:text-slate-300">{{ selectedWarranty?.creator_name || 'Owner' }}</span> on {{ formatDate(selectedWarranty?.created_at) }}
            </p>
          </div>
          <div class="flex items-center gap-2">
            <button
              @click="printWarrantyCard"
              type="button"
              class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-200 text-xs font-semibold hover:bg-slate-50 transition cursor-pointer print:hidden"
            >
              <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4H7v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"/></svg>
              Print / PDF
            </button>
            <button @click="detailModalOpen = false" class="p-2 text-slate-400 hover:text-slate-600 print:hidden">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
            </button>
          </div>
        </div>

        <!-- 3-Column Info Strip -->
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <div class="p-3.5 rounded-2xl bg-slate-50 dark:bg-slate-900/60 border border-slate-100 dark:border-slate-800 text-xs">
            <span class="text-slate-400 block font-semibold">Customer</span>
            <p class="font-bold text-slate-900 dark:text-white text-sm mt-0.5">{{ selectedWarranty?.customer?.name }}</p>
            <p class="font-mono text-slate-500 mt-0.5">{{ selectedWarranty?.customer?.mobile }}</p>
          </div>

          <div class="p-3.5 rounded-2xl bg-slate-50 dark:bg-slate-900/60 border border-slate-100 dark:border-slate-800 text-xs">
            <span class="text-slate-400 block font-semibold">Protected Device</span>
            <p class="font-bold text-slate-900 dark:text-white text-sm mt-0.5">
              {{ selectedWarranty?.device ? `${selectedWarranty.device.brand} ${selectedWarranty.device.model}` : 'Covered Device' }}
            </p>
            <p v-if="selectedWarranty?.device?.imei_1" class="font-mono text-[11px] text-slate-400 mt-0.5">
              IMEI: {{ selectedWarranty.device.imei_1 }}
            </p>
          </div>

          <div class="p-3.5 rounded-2xl bg-slate-50 dark:bg-slate-900/60 border border-slate-100 dark:border-slate-800 text-xs">
            <span class="text-slate-400 block font-semibold">Coverage Period</span>
            <p class="font-bold text-indigo-600 dark:text-indigo-400 text-sm mt-0.5">{{ selectedWarranty?.duration_days }} Days</p>
            <p class="text-[11px] text-slate-400 mt-0.5">Ends: {{ formatDate(selectedWarranty?.warranty_end_date) }}</p>
          </div>
        </div>

        <!-- Terms & Conditions -->
        <div v-if="selectedWarranty?.warranty_terms" class="p-3.5 rounded-2xl bg-indigo-50/50 dark:bg-indigo-950/20 border border-indigo-100 dark:border-indigo-900/40 text-xs">
          <span class="font-bold text-indigo-900 dark:text-indigo-200 block mb-1">📜 Warranty Terms & Protection Scope</span>
          <p class="text-slate-600 dark:text-slate-400 leading-relaxed">{{ selectedWarranty.warranty_terms }}</p>
        </div>

        <!-- Linked Claims for this warranty -->
        <div class="space-y-2.5">
          <div class="flex items-center justify-between">
            <h4 class="text-xs font-bold uppercase tracking-wider text-slate-700 dark:text-slate-300">
              Claims Filed ({{ selectedWarranty?.claims?.length || 0 }})
            </h4>
            <button
              @click="openRegisterClaimModal(selectedWarranty)"
              type="button"
              class="inline-flex items-center gap-1 text-xs font-bold text-purple-600 hover:text-purple-700 cursor-pointer"
            >
              + File New Claim
            </button>
          </div>

          <div v-if="!selectedWarranty?.claims || selectedWarranty.claims.length === 0" class="text-center py-6 border border-dashed border-slate-200 dark:border-slate-800 rounded-2xl text-xs text-slate-400">
            No claims filed under this warranty.
          </div>
          <div v-else class="space-y-2">
            <div
              v-for="cl in selectedWarranty.claims"
              :key="cl.id"
              class="p-3 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200/60 dark:border-slate-800/60 flex items-center justify-between text-xs"
            >
              <div>
                <div class="flex items-center gap-2">
                  <span class="font-mono font-bold text-purple-600 dark:text-purple-400">{{ cl.claim_number }}</span>
                  <span class="px-2 py-0.2 rounded text-[10px] font-bold uppercase" :class="getClaimStatusBadgeClass(cl.claim_status)">
                    {{ cl.claim_status }}
                  </span>
                </div>
                <p class="font-semibold text-slate-800 dark:text-slate-200 mt-1">{{ cl.complaint }}</p>
                <p v-if="cl.resolution" class="text-[11px] text-emerald-600 dark:text-emerald-400 mt-0.5">Res: {{ cl.resolution }}</p>
              </div>

              <button
                @click="openUpdateClaimModal(cl)"
                class="px-2.5 py-1 rounded-lg text-xs font-bold bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 transition cursor-pointer"
              >
                Resolve →
              </button>
            </div>
          </div>
        </div>

        <div class="pt-3 border-t border-slate-100 dark:border-slate-800 flex justify-end">
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
    <!-- MODAL 4: CREATE WARRANTY MODAL                                            -->
    <!-- ========================================================================= -->
    <div v-if="createWarrantyModalOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4 overflow-y-auto">
      <div @click="createWarrantyModalOpen = false" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm"></div>

      <div class="relative w-full max-w-lg bg-white dark:bg-[#111827] rounded-3xl border border-slate-200/80 dark:border-slate-800/80 shadow-2xl p-6 z-10 space-y-4">
        <div class="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-2xl bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 flex items-center justify-center">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/></svg>
            </div>
            <div>
              <h3 class="text-base font-black text-slate-900 dark:text-white">Issue Warranty / Guarantee</h3>
              <p class="text-xs text-slate-400">Protect repair service or sold product</p>
            </div>
          </div>
          <button @click="createWarrantyModalOpen = false" class="p-2 text-slate-400 hover:text-slate-600">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
          </button>
        </div>

        <form @submit.prevent="submitCreateWarranty" class="space-y-4">
          <!-- Warranty Type: Repair vs Sale -->
          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
              Warranty Coverage Type <span class="text-rose-500">*</span>
            </label>
            <div class="grid grid-cols-2 gap-2">
              <button
                type="button"
                @click="createForm.warranty_type = 'repair'"
                :class="[
                  'py-2 px-3 rounded-xl text-xs font-bold transition flex items-center justify-center gap-1.5 cursor-pointer border',
                  createForm.warranty_type === 'repair'
                    ? 'bg-indigo-600 text-white border-indigo-600 shadow-sm'
                    : 'bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-400'
                ]"
              >
                <span>🔧</span>
                <span>Repair Service</span>
              </button>
              <button
                type="button"
                @click="createForm.warranty_type = 'sale'"
                :class="[
                  'py-2 px-3 rounded-xl text-xs font-bold transition flex items-center justify-center gap-1.5 cursor-pointer border',
                  createForm.warranty_type === 'sale'
                    ? 'bg-indigo-600 text-white border-indigo-600 shadow-sm'
                    : 'bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-400'
                ]"
              >
                <span>🛍️</span>
                <span>Product Sale / Item</span>
              </button>
            </div>
          </div>

          <!-- Customer Selection -->
          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
              Select Customer
            </label>
            <select
              v-model="createForm.customer_id"
              class="w-full px-3.5 py-2.5 text-xs font-semibold bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-white"
            >
              <option :value="null">Walk-in Customer / Unassigned</option>
              <option v-for="c in customersList" :key="c.id" :value="c.id">
                {{ c.name }} ({{ c.mobile || c.phone }})
              </option>
            </select>
          </div>

          <!-- Customer Device Selection (if customer has devices) -->
          <div v-if="createForm.customer_id && customerDevices.length > 0">
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
              Link Registered Device
            </label>
            <select
              v-model="createForm.device_id"
              class="w-full px-3.5 py-2.5 text-xs font-semibold bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-white"
            >
              <option :value="null">-- Select Protected Device (Optional) --</option>
              <option v-for="dev in customerDevices" :key="dev.id" :value="dev.id">
                {{ dev.brand }} {{ dev.model }} {{ dev.imei_1 ? `(IMEI: ${dev.imei_1})` : '' }}
              </option>
            </select>
          </div>

          <!-- Duration Preset Chips -->
          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
              Duration Period <span class="text-rose-500">*</span>
            </label>
            <div class="grid grid-cols-4 gap-1.5 mb-2">
              <button
                v-for="d in [7, 15, 30, 90, 180, 365]"
                :key="d"
                type="button"
                @click="createForm.duration_days = d"
                :class="[
                  'py-1.5 px-2 rounded-lg text-xs font-bold transition cursor-pointer border text-center',
                  createForm.duration_days === d
                    ? 'bg-indigo-50 text-indigo-600 dark:bg-indigo-950/60 dark:text-indigo-400 border-indigo-300 dark:border-indigo-700 font-extrabold'
                    : 'bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-400'
                ]"
              >
                {{ d >= 30 ? (d === 365 ? '1 Year' : Math.round(d/30) + ' Mo') : d + ' Days' }}
              </button>
            </div>
            <input
              v-model.number="createForm.duration_days"
              type="number"
              min="1"
              max="3650"
              required
              placeholder="Or enter custom days"
              class="w-full px-3.5 py-2 text-xs font-bold bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-white"
            />
          </div>

          <!-- Terms -->
          <div>
            <div class="flex items-center justify-between mb-1.5">
              <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider">
                Warranty Terms
              </label>
              <span class="text-[10px] text-slate-400 font-medium">Click to auto-fill:</span>
            </div>
            <!-- Quick preset chips -->
            <div class="flex flex-wrap gap-1.5 mb-2">
              <button
                type="button"
                v-for="preset in warrantyPresets"
                :key="preset.label"
                @click="createForm.warranty_terms = preset.text"
                class="px-2.5 py-1 rounded-lg text-[11px] font-semibold border transition cursor-pointer"
                :class="createForm.warranty_terms === preset.text
                  ? 'bg-indigo-600 text-white border-indigo-600 shadow-xs'
                  : 'bg-indigo-50/70 dark:bg-indigo-950/40 text-indigo-700 dark:text-indigo-300 border-indigo-200/60 dark:border-indigo-800/60 hover:bg-indigo-100 dark:hover:bg-indigo-900/50'"
              >
                {{ preset.label }}
              </button>
            </div>
            <textarea
              v-model="createForm.warranty_terms"
              rows="2"
              class="w-full px-3.5 py-2 text-xs font-medium bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-white"
            ></textarea>
          </div>

          <div class="pt-3 border-t border-slate-100 dark:border-slate-800 flex justify-end gap-2.5">
            <button
              @click="createWarrantyModalOpen = false"
              type="button"
              class="px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-300 text-xs font-bold cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="savingNewWarranty"
              class="px-5 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold shadow-md shadow-indigo-600/20 disabled:opacity-50 transition cursor-pointer"
            >
              {{ savingNewWarranty ? 'Issuing...' : 'Issue Warranty' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- ========================================================================= -->
    <!-- PRINTABLE WARRANTY CERTIFICATE (Print Media Only)                         -->
    <!-- ========================================================================= -->
    <div id="printable-warranty-card" class="hidden print:block font-['Outfit',sans-serif] p-8 text-slate-900 bg-white">
      <div class="border-2 border-indigo-600 rounded-3xl p-8 relative overflow-hidden">
        <!-- Certificate Header -->
        <div class="flex items-start justify-between border-b-2 border-indigo-100 pb-6 mb-6">
          <div>
            <span class="text-xs font-black tracking-widest uppercase text-indigo-600">Official Protection Certificate</span>
            <h1 class="text-2xl font-black text-slate-900 mt-1">{{ authStore.shop?.name || 'MyRepairHub Service Center' }}</h1>
            <p class="text-xs text-slate-500 mt-0.5">{{ authStore.shop?.address || '' }} {{ authStore.shop?.phone ? '• Tel: ' + authStore.shop?.phone : '' }}</p>
          </div>
          <div class="text-right">
            <div class="inline-block px-3 py-1 bg-indigo-50 border border-indigo-200 rounded-xl font-mono font-black text-sm text-indigo-700">
              {{ selectedWarranty?.warranty_number || ('#WAR-' + selectedWarranty?.id) }}
            </div>
            <p class="text-[11px] text-slate-400 mt-1">Issue Date: {{ formatDate(selectedWarranty?.created_at) }}</p>
          </div>
        </div>

        <!-- Protection Details Grid -->
        <div class="grid grid-cols-2 gap-6 pb-6 mb-6 border-b border-slate-100">
          <div>
            <h3 class="text-[11px] font-bold text-slate-400 uppercase tracking-wider">Beneficiary (Customer)</h3>
            <p class="text-base font-bold text-slate-900 mt-1">{{ selectedWarranty?.customer?.name || 'Walk-in Customer' }}</p>
            <p class="text-xs font-mono text-slate-600">{{ selectedWarranty?.customer?.mobile || selectedWarranty?.customer?.phone || '-' }}</p>
          </div>

          <div>
            <h3 class="text-[11px] font-bold text-slate-400 uppercase tracking-wider">Protected Device / Product</h3>
            <p class="text-base font-bold text-slate-900 mt-1">
              {{ selectedWarranty?.device ? `${selectedWarranty.device.brand} ${selectedWarranty.device.model}` : (selectedWarranty?.repair?.device_model || 'Service Device') }}
            </p>
            <p v-if="selectedWarranty?.device?.imei_1" class="text-xs font-mono text-slate-500">
              IMEI: {{ selectedWarranty.device.imei_1 }}
            </p>
          </div>
        </div>

        <div class="grid grid-cols-3 gap-4 pb-6 mb-6 border-b border-slate-100 bg-slate-50 p-4 rounded-2xl">
          <div>
            <span class="text-[10px] uppercase font-bold text-slate-400">Warranty Type</span>
            <p class="text-xs font-extrabold text-slate-800 uppercase mt-0.5">{{ selectedWarranty?.warranty_type === 'sale' ? 'Sale POS' : 'Repair Service' }}</p>
          </div>
          <div>
            <span class="text-[10px] uppercase font-bold text-slate-400">Duration</span>
            <p class="text-xs font-extrabold text-indigo-600 mt-0.5">{{ selectedWarranty?.duration_days }} Days</p>
          </div>
          <div>
            <span class="text-[10px] uppercase font-bold text-slate-400">Valid Until</span>
            <p class="text-xs font-extrabold text-emerald-600 mt-0.5">{{ formatDate(selectedWarranty?.warranty_end_date) }}</p>
          </div>
        </div>

        <!-- Terms -->
        <div class="mb-8">
          <h4 class="text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">Terms & Scope of Guarantee:</h4>
          <p class="text-xs text-slate-600 leading-relaxed bg-indigo-50/40 p-3.5 rounded-xl border border-indigo-100">
            {{ selectedWarranty?.warranty_terms || 'Covers parts repaired and workmanship only. Physical breakage, water exposure, burnt components, and customer tamper voids warranty.' }}
          </p>
        </div>

        <!-- Footer Signatures -->
        <div class="flex items-end justify-between pt-8 border-t border-slate-200">
          <div>
            <p class="text-[10px] text-slate-400 uppercase font-bold">Customer Signature</p>
            <div class="w-40 border-b border-dashed border-slate-400 mt-8"></div>
          </div>
          <div class="text-right">
            <p class="text-[10px] text-slate-400 uppercase font-bold">Authorized Stamp & Signature</p>
            <div class="w-48 border-b border-dashed border-slate-400 mt-8 inline-block"></div>
            <p class="text-[11px] font-bold text-slate-700 mt-1">{{ authStore.shop?.name || 'Shop Authorized Representative' }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch, onMounted } from 'vue';
import { warrantyApi, customerApi, deviceApi } from '@/api/endpoints';
import { useToastStore } from '@/stores/toast';
import { useAuthStore } from '@/stores/auth';
import PaginationBar from '@/components/common/PaginationBar.vue';
import SearchableSelect from '@/components/common/SearchableSelect.vue';
import WhatsAppIcon from '@/components/common/WhatsAppIcon.vue';
import { formatDate } from '@/utils/date';

const toastStore = useToastStore();
const authStore = useAuthStore();

const activeTab = ref('warranties'); // 'warranties' or 'claims'

const warranties = ref([]);
const claims = ref([]);
const loading = ref(false);
const loadingClaims = ref(false);
const customersList = ref([]);

const search = ref('');
const statusFilter = ref('');
const typeFilter = ref('');
const claimStatusFilter = ref('');
const sortFilter = ref('newest');
const sortOptions = [
  { value: 'newest', label: 'Newest First (Recent)' },
  { value: 'oldest', label: 'Oldest First' },
  { value: 'expiring_soon', label: 'Expiring Soonest' },
];

const currentPage = ref(1);
const perPage = ref(15);

// Metric Counts
const activeWarrantiesCount = computed(() => {
  return warranties.value.filter((w) => (w.status || '').toLowerCase() === 'active' || (!isExpired(w.warranty_end_date) && w.status !== 'voided')).length;
});

const expiringSoonCount = computed(() => {
  return warranties.value.filter((w) => {
    if (w.status === 'expiring_soon') return true;
    const days = Number(w.days_remaining);
    return days > 0 && days <= 15;
  }).length;
});

const expiredCount = computed(() => {
  return warranties.value.filter((w) => (w.status || '').toLowerCase() === 'expired' || isExpired(w.warranty_end_date)).length;
});

const totalClaimsCount = computed(() => {
  return claims.value.length || warranties.value.reduce((acc, w) => acc + (Number(w.claims_count) || 0), 0);
});

// Dropdown filter options
const warrantyStatusOptions = [
  { value: '', label: 'All Statuses' },
  { value: 'active', label: 'Active Coverage' },
  { value: 'expiring_soon', label: 'Expiring Soon' },
  { value: 'expired', label: 'Expired' },
  { value: 'voided', label: 'Voided' },
];

const warrantyTypeOptions = [
  { value: '', label: 'All Types' },
  { value: 'repair', label: 'Repair Services' },
  { value: 'sale', label: 'POS Product Sales' },
];

const claimStatusOptions = [
  { value: '', label: 'All Claim Statuses' },
  { value: 'open', label: 'Open' },
  { value: 'checking', label: 'Checking' },
  { value: 'approved', label: 'Approved' },
  { value: 'repairing', label: 'Repairing' },
  { value: 'resolved', label: 'Resolved' },
  { value: 'rejected', label: 'Rejected' },
  { value: 'closed', label: 'Closed' },
];

// Modals State
const claimModalOpen = ref(false);
const activeWarrantyForClaim = ref(null);
const submittingClaim = ref(false);
const claimForm = reactive({
  complaint: '',
  notes: '',
});

const updateClaimModalOpen = ref(false);
const claimToUpdate = ref(null);
const savingClaimUpdate = ref(false);
const updateClaimForm = reactive({
  claim_status: 'checking',
  resolution: '',
  notes: '',
});

const detailModalOpen = ref(false);
const selectedWarranty = ref(null);

const warrantyPresets = [
  {
    label: 'Service Center Warranty',
    text: 'Official Brand Service Center Warranty. Customer can claim directly at authorized service center with invoice.',
  },
  {
    label: 'Shop Testing Warranty',
    text: 'Shop Testing Warranty. Covers hardware & manufacturing defects. Physical and liquid damage void.',
  },
  {
    label: 'Display & Touch Only',
    text: 'Covers screen and touch failure only. Glass crack, black spot, lines, drop or liquid damage strictly void.',
  },
  {
    label: 'Parts Replaced Only',
    text: 'Covers repair & replaced parts only. Physical damage, water ingress, or unauthorized opening voids warranty.',
  },
  {
    label: 'Full Device Warranty',
    text: 'Comprehensive device warranty covering internal components. Excludes physical drop and liquid exposure.',
  },
];

const createWarrantyModalOpen = ref(false);
const savingNewWarranty = ref(false);
const customerDevices = ref([]);
const loadingCustomerDevices = ref(false);
const createForm = reactive({
  warranty_type: 'repair',
  customer_id: null,
  device_id: null,
  duration_days: 30,
  warranty_terms: 'Covers repair & parts replaced only. Physical and liquid damage not covered under warranty.',
});

watch(() => createForm.customer_id, async (newVal) => {
  createForm.device_id = null;
  customerDevices.value = [];
  if (!newVal) return;
  loadingCustomerDevices.value = true;
  try {
    const res = await deviceApi.listForCustomer(newVal);
    const data = res.data?.data;
    customerDevices.value = Array.isArray(data) ? data : (data?.data || []);
  } catch (err) {
    console.error('Failed to load customer devices:', err);
  } finally {
    loadingCustomerDevices.value = false;
  }
});

// Filtered Warranties
const filteredWarranties = computed(() => {
  return warranties.value.filter((w) => {
    // Status Filter
    if (statusFilter.value) {
      const s = (w.status || '').toLowerCase();
      if (statusFilter.value === 'active' && s !== 'active') return false;
      if (statusFilter.value === 'expiring_soon' && s !== 'expiring_soon' && (w.days_remaining <= 0 || w.days_remaining > 15)) return false;
      if (statusFilter.value === 'expired' && s !== 'expired' && !isExpired(w.warranty_end_date)) return false;
      if (statusFilter.value === 'voided' && s !== 'voided') return false;
    }

    // Type Filter
    if (typeFilter.value && (w.warranty_type || '').toLowerCase() !== typeFilter.value.toLowerCase()) {
      return false;
    }

    // Search Query
    if (search.value) {
      const q = search.value.toLowerCase();
      const code = String(w.warranty_number || w.id).toLowerCase();
      const cust = String(w.customer?.name || w.customer_name || '').toLowerCase();
      const phone = String(w.customer?.mobile || w.customer?.phone || '').toLowerCase();
      const dev = String(w.device?.model || w.device?.brand || w.repair?.device_model || '').toLowerCase();
      const imei = String(w.device?.imei_1 || '').toLowerCase();
      if (!code.includes(q) && !cust.includes(q) && !phone.includes(q) && !dev.includes(q) && !imei.includes(q)) {
        return false;
      }
    }

    return true;
  });
});

const totalPages = computed(() => Math.max(1, Math.ceil(filteredWarranties.value.length / perPage.value)));

const paginatedWarranties = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredWarranties.value.slice(start, start + perPage.value);
});

// Filtered Claims
const filteredClaims = computed(() => {
  return claims.value.filter((c) => {
    if (claimStatusFilter.value && (c.claim_status || '').toLowerCase() !== claimStatusFilter.value.toLowerCase()) {
      return false;
    }

    if (search.value) {
      const q = search.value.toLowerCase();
      const clmNum = String(c.claim_number || c.id).toLowerCase();
      const warNum = String(c.warranty?.warranty_number || c.warranty_id || '').toLowerCase();
      const comp = String(c.complaint || '').toLowerCase();
      const cust = String(c.customer?.name || c.warranty?.customer?.name || '').toLowerCase();
      if (!clmNum.includes(q) && !warNum.includes(q) && !comp.includes(q) && !cust.includes(q)) {
        return false;
      }
    }

    return true;
  });
});

const currentClaimsPage = ref(1);
const totalClaimsPages = computed(() => Math.max(1, Math.ceil(filteredClaims.value.length / perPage.value)));
const paginatedClaims = computed(() => {
  const start = (currentClaimsPage.value - 1) * perPage.value;
  return filteredClaims.value.slice(start, start + perPage.value);
});

function onPageChange(page) {
  currentPage.value = page;
}

function onClaimsPageChange(page) {
  currentClaimsPage.value = page;
}

watch([search, statusFilter, typeFilter, sortFilter, activeTab], () => {
  currentPage.value = 1;
  if (activeTab.value === 'warranties') {
    fetchWarranties();
  }
});

watch([search, claimStatusFilter, activeTab], () => {
  currentClaimsPage.value = 1;
});


function isExpired(dateStr) {
  if (!dateStr) return false;
  return new Date(dateStr) < new Date();
}

function formatStatus(status) {
  const map = {
    active: 'Active',
    expiring_soon: 'Expiring Soon',
    expired: 'Expired',
    voided: 'Voided',
  };
  return map[status] || status || 'Active';
}

function getStatusBadgeClass(status) {
  switch ((status || '').toLowerCase()) {
    case 'active':
      return 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800/60';
    case 'expiring_soon':
      return 'bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-300 border border-amber-200 dark:border-amber-800/60';
    case 'expired':
      return 'bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-300 border border-rose-200 dark:border-rose-800/60';
    case 'voided':
      return 'bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-300 dark:border-slate-700';
    default:
      return 'bg-slate-50 text-slate-600 border border-slate-200';
  }
}

function getStatusDotClass(status) {
  switch ((status || '').toLowerCase()) {
    case 'active': return 'bg-emerald-500';
    case 'expiring_soon': return 'bg-amber-500 animate-pulse';
    case 'expired': return 'bg-rose-500';
    default: return 'bg-slate-400';
  }
}

function getClaimStatusBadgeClass(status) {
  switch ((status || '').toLowerCase()) {
    case 'open':
      return 'bg-blue-100 text-blue-700 dark:bg-blue-950/60 dark:text-blue-300';
    case 'checking':
      return 'bg-purple-100 text-purple-700 dark:bg-purple-950/60 dark:text-purple-300';
    case 'approved':
      return 'bg-teal-100 text-teal-700 dark:bg-teal-950/60 dark:text-teal-300';
    case 'repairing':
      return 'bg-indigo-100 text-indigo-700 dark:bg-indigo-950/60 dark:text-indigo-300';
    case 'resolved':
      return 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-300';
    case 'rejected':
      return 'bg-rose-100 text-rose-700 dark:bg-rose-950/60 dark:text-rose-300';
    default:
      return 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300';
  }
}

// Actions
function openRegisterClaimModal(warranty) {
  activeWarrantyForClaim.value = warranty;
  claimForm.complaint = '';
  claimForm.notes = '';
  claimModalOpen.value = true;
}

async function submitClaim() {
  if (!claimForm.complaint?.trim()) return;
  submittingClaim.value = true;
  try {
    await warrantyApi.addClaim(activeWarrantyForClaim.value.id, {
      complaint: claimForm.complaint.trim(),
      notes: claimForm.notes?.trim() || undefined,
    });
    toastStore.success('Warranty claim registered successfully');
    claimModalOpen.value = false;
    await fetchWarranties();
    if (activeTab.value === 'claims') await fetchClaims();
  } catch (err) {
    console.error('Failed to submit claim:', err);
    toastStore.error(err.response?.data?.message || 'Could not register claim.');
  } finally {
    submittingClaim.value = false;
  }
}

function openUpdateClaimModal(claim) {
  claimToUpdate.value = claim;
  updateClaimForm.claim_status = claim.claim_status || 'checking';
  updateClaimForm.resolution = claim.resolution || '';
  updateClaimForm.notes = claim.notes || '';
  updateClaimModalOpen.value = true;
}

async function submitClaimUpdate() {
  savingClaimUpdate.value = true;
  try {
    await warrantyApi.updateClaim(claimToUpdate.value.id, {
      claim_status: updateClaimForm.claim_status,
      resolution: updateClaimForm.resolution?.trim() || undefined,
      notes: updateClaimForm.notes?.trim() || undefined,
    });
    toastStore.success('Claim status updated successfully');
    updateClaimModalOpen.value = false;
    await fetchClaims();
    await fetchWarranties();
  } catch (err) {
    console.error('Failed to update claim:', err);
    toastStore.error('Could not update claim status.');
  } finally {
    savingClaimUpdate.value = false;
  }
}

async function openWarrantyDetail(w) {
  selectedWarranty.value = w;
  detailModalOpen.value = true;
  try {
    const res = await warrantyApi.get(w.id);
    selectedWarranty.value = res.data?.data || res.data || w;
  } catch (err) {
    console.error('Failed to load warranty details:', err);
  }
}

async function confirmDeleteWarranty(w) {
  const confirmed = await toastStore.confirm({
    title: 'Delete Warranty?',
    message: `Are you sure you want to delete warranty ${w.warranty_number || ('#WAR-' + w.id)}? All associated customer claims will also be removed.`,
    confirmText: 'Delete Warranty',
    type: 'danger',
  });

  if (confirmed) {
    try {
      await warrantyApi.delete(w.id);
      toastStore.success('Warranty deleted successfully');
      await fetchWarranties();
    } catch (err) {
      console.error('Failed to delete warranty:', err);
      toastStore.error('Could not delete warranty.');
    }
  }
}

async function confirmDeleteClaim(c) {
  const confirmed = await toastStore.confirm({
    title: 'Delete Claim?',
    message: `Are you sure you want to delete claim ${c.claim_number}?`,
    confirmText: 'Delete Claim',
    type: 'danger',
  });

  if (confirmed) {
    try {
      await warrantyApi.deleteClaim(c.id);
      toastStore.success('Claim removed');
      await fetchClaims();
    } catch (err) {
      console.error('Failed to delete claim:', err);
      toastStore.error('Could not delete claim.');
    }
  }
}

async function openCreateWarrantyModal() {
  createForm.warranty_type = 'repair';
  createForm.customer_id = null;
  createForm.device_id = null;
  createForm.duration_days = 30;
  customerDevices.value = [];
  createWarrantyModalOpen.value = true;
  if (customersList.value.length === 0) {
    try {
      const res = await customerApi.list({ per_page: 100 });
      customersList.value = res.data?.data?.data || res.data?.data || [];
    } catch (e) {
      console.error('Could not load customers for warranty:', e);
    }
  }
}

async function submitCreateWarranty() {
  savingNewWarranty.value = true;
  try {
    await warrantyApi.create({
      warranty_type: createForm.warranty_type,
      customer_id: createForm.customer_id || undefined,
      device_id: createForm.device_id || undefined,
      duration_days: Number(createForm.duration_days) || 30,
      warranty_terms: createForm.warranty_terms || undefined,
    });
    toastStore.success('New warranty issued successfully');
    createWarrantyModalOpen.value = false;
    await fetchWarranties();
  } catch (err) {
    console.error('Failed to create warranty:', err);
    toastStore.error(err.response?.data?.message || 'Could not issue warranty.');
  } finally {
    savingNewWarranty.value = false;
  }
}

function printWarrantyCard() {
  window.print();
}

async function fetchWarranties() {
  loading.value = true;
  try {
    const res = await warrantyApi.list({
      sort: sortFilter.value || 'newest',
      status: statusFilter.value || undefined,
      warranty_type: typeFilter.value || undefined,
    });
    const payload = res.data?.data;
    warranties.value = payload?.data || (Array.isArray(payload) ? payload : []);
  } catch (err) {
    console.error('Failed to load warranties:', err);
  } finally {
    loading.value = false;
  }
}

async function fetchClaims() {
  loadingClaims.value = true;
  try {
    const res = await warrantyApi.allClaims();
    const payload = res.data?.data;
    claims.value = payload?.data || (Array.isArray(payload) ? payload : []);
  } catch (err) {
    console.error('Failed to load claims:', err);
  } finally {
    loadingClaims.value = false;
  }
}

onMounted(() => {
  fetchWarranties();
  fetchClaims();
});
</script>

<style scoped>
@media print {
  body * {
    visibility: hidden;
  }
  #printable-warranty-card,
  #printable-warranty-card * {
    visibility: visible;
  }
  #printable-warranty-card {
    position: absolute;
    left: 0;
    top: 0;
    width: 100%;
    margin: 0;
    padding: 24px;
    background: #ffffff;
    display: block !important;
  }
}
</style>
