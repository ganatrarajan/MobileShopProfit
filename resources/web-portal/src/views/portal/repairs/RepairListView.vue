<template>
  <div class="space-y-6">
    <!-- Header Actions -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <div class="flex items-center gap-2">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 border border-indigo-200/60 dark:border-indigo-800/60">
            Work Orders
          </span>
          <span class="text-xs text-slate-400">Device Diagnostics & Delivery</span>
        </div>
        <h1 class="text-2xl font-bold tracking-tight text-slate-900 dark:text-white mt-1">Repair Orders Directory</h1>
        <p class="text-xs sm:text-sm text-slate-500 dark:text-slate-400">Track device intakes, technician diagnostics, repair parts, and delivery statuses.</p>
      </div>
      <router-link
        to="/repairs/new"
        class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold shadow-md shadow-indigo-600/20 transition-all hover:scale-[1.02] active:scale-[0.98]"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" d="M12 4v16m8-8H4"/></svg>
        + New Repair Job
      </router-link>
    </div>

    <!-- Summary Metrics (Matching Mobile App Top Volume Bar with Net Profit Strip) -->
    <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3 sm:gap-4">
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-sm flex items-center justify-between">
        <div>
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Total Billed</p>
          <p class="text-xl font-extrabold text-slate-900 dark:text-white mt-1 tabular-nums">₹{{ formatAmount(summary.totalVolume) }}</p>
        </div>
        <div class="w-10 h-10 rounded-xl bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 flex items-center justify-center shrink-0">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 14l6-6m-5.5.5h.01m4.99 5h.01M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16l3.5-2 3.5 2 3.5-2 3.5 2z"/></svg>
        </div>
      </div>

      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-sm flex items-center justify-between">
        <div>
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Paid / Collected</p>
          <p class="text-xl font-extrabold text-emerald-600 dark:text-emerald-400 mt-1 tabular-nums">₹{{ formatAmount(summary.totalPaid) }}</p>
        </div>
        <div class="w-10 h-10 rounded-xl bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center shrink-0">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
        </div>
      </div>

      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-sm flex items-center justify-between">
        <div>
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Pending Balance</p>
          <p class="text-xl font-extrabold text-rose-600 dark:text-rose-400 mt-1 tabular-nums">₹{{ formatAmount(summary.totalDue) }}</p>
        </div>
        <div class="w-10 h-10 rounded-xl bg-rose-50 dark:bg-rose-950/60 text-rose-600 dark:text-rose-400 flex items-center justify-center shrink-0">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
        </div>
      </div>

      <!-- Net Profit Card (Matching Mobile App Screen Profit Strip) -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-emerald-500/30 dark:border-emerald-500/30 shadow-sm flex items-center justify-between bg-gradient-to-br from-emerald-500/5 to-transparent">
        <div>
          <div class="flex items-center gap-1.5">
            <p class="text-[11px] font-bold uppercase tracking-wider text-emerald-700 dark:text-emerald-400">Net Profit</p>
            <span class="px-1.5 py-0.2 rounded text-[9px] font-black bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20">Realized</span>
          </div>
          <p class="text-xl font-black text-emerald-600 dark:text-emerald-400 mt-1 tabular-nums">₹{{ formatAmount(summary.totalNetProfit) }}</p>
          <p class="text-[10px] text-slate-400 font-medium mt-0.5">Tech: ₹{{ formatAmount(summary.totalTechCost) }}</p>
        </div>
        <div class="w-10 h-10 rounded-xl bg-emerald-100 dark:bg-emerald-950/80 text-emerald-600 dark:text-emerald-400 flex items-center justify-center shrink-0 shadow-xs">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/></svg>
        </div>
      </div>

      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-sm flex items-center justify-between">
        <div>
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Total Job Cards</p>
          <p class="text-xl font-extrabold text-indigo-600 dark:text-indigo-400 mt-1 tabular-nums">{{ totalCount }}</p>
        </div>
        <div class="w-10 h-10 rounded-xl bg-sky-50 dark:bg-sky-950/60 text-sky-600 dark:text-sky-400 flex items-center justify-center shrink-0">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/></svg>
        </div>
      </div>
    </div>

    <!-- Filter & Search Bar (Exact Mobile App Statuses) -->
    <div class="relative z-20 bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-2xl p-4 shadow-sm flex flex-col md:flex-row gap-3 items-stretch md:items-center justify-between">
      <div class="relative flex-1">
        <span class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
        </span>
        <input
          v-model="searchQuery"
          @input="debounceSearch"
          type="text"
          class="w-full pl-10 pr-4 py-2 text-xs font-semibold bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 dark:focus:border-indigo-400 transition-all placeholder-slate-400 text-slate-800 dark:text-slate-100"
          placeholder="Search by Job #, Customer, Phone, Device, IMEI, Problem..."
        />
      </div>

      <div class="flex flex-wrap items-center gap-2">
        <!-- Status Filter (Searchable Popover Dropdown matching design) -->
        <SearchableSelect
          v-model="selectedStatus"
          :options="filterStore.repairStatusOptions"
          @change="onFilterChange"
          placeholder="All Statuses"
          searchPlaceholder="Search status..."
          minWidth="145px"
        />

        <!-- Date Preset Filter (Synced globally with Dashboard) -->
        <SearchableSelect
          v-model="filterStore.selectedPeriod"
          :options="filterStore.periodOptions"
          @change="onFilterChange"
          placeholder="Select Period"
          searchPlaceholder="Search period..."
          minWidth="140px"
        />

        <button
          v-if="searchQuery || selectedStatus || filterStore.selectedPeriod !== 'this_month'"
          @click="resetFilters"
          type="button"
          class="px-3 py-2 bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-600 dark:text-slate-300 rounded-xl text-xs font-bold transition-all cursor-pointer"
        >
          Reset
        </button>
      </div>
    </div>

    <!-- Data Table Card -->
    <div class="bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-2xl overflow-hidden shadow-sm">
      <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="border-b border-slate-100 dark:border-slate-800/80 text-[11px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider bg-slate-50/60 dark:bg-slate-900/40">
              <th class="py-3.5 px-4 pl-6">Job Info</th>
              <th class="py-3.5 px-4">Customer</th>
              <th class="py-3.5 px-4">Device & Problem</th>
              <th class="py-3.5 px-4">Delivery Dates</th>
              <th class="py-3.5 px-4">Technician & Fee</th>
              <th class="py-3.5 px-4">Status</th>
              <th class="py-3.5 px-4">Amount & Profit</th>
              <th class="py-3.5 px-4 pr-6 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100 dark:divide-slate-800/60 text-sm">
            <tr v-if="loading">
              <td colspan="8" class="py-12 text-center text-xs text-slate-400">
                <div class="inline-block animate-spin w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full mb-2"></div>
                <div>Loading repair jobs...</div>
              </td>
            </tr>
            <tr v-else-if="repairs.length === 0">
              <td colspan="8" class="py-12 text-center text-slate-400 dark:text-slate-500 text-xs">
                No repair orders found matching criteria.
              </td>
            </tr>
            <tr
              v-for="repair in repairs"
              :key="repair.id"
              class="hover:bg-slate-50/70 dark:hover:bg-slate-800/40 transition-colors group"
            >
              <!-- Job Info -->
              <td class="py-3.5 px-4 pl-6">
                <div class="font-bold font-mono text-indigo-600 dark:text-indigo-400">
                  {{ repair.job_number || repair.jobNumber || ('#JOB-' + String(repair.id).padStart(6, '0')) }}
                </div>
                <div class="text-[11px] text-slate-400 mt-0.5">
                  Intake: {{ formatDate(repair.date_received || repair.dateReceived || repair.created_at) }}
                </div>
              </td>

              <!-- Customer -->
              <td class="py-3.5 px-4">
                <div class="font-bold text-slate-900 dark:text-slate-100">
                  {{ repair.customer?.name || repair.customer_name || 'Walk-in' }}
                </div>
                <div class="text-[11px] text-slate-400 font-mono flex items-center gap-1.5 mt-0.5">
                  <span>{{ repair.customer?.mobile || repair.customer?.phone || repair.customer_phone || '-' }}</span>
                  <a
                    v-if="getCustomerPhone(repair)"
                    :href="`https://wa.me/91${getCustomerPhone(repair)}?text=Hello%20${encodeURIComponent(repair.customer?.name || 'Customer')},%20regarding%20your%20repair%20order%20${encodeURIComponent(repair.job_number || repair.jobNumber || '#JOB-' + repair.id)}%20at%20MyRepairHub.`"
                    target="_blank"
                    class="p-1 rounded-md bg-emerald-50 hover:bg-emerald-100 dark:bg-emerald-950/50 dark:hover:bg-emerald-900/50 text-emerald-600 dark:text-emerald-400 border border-emerald-200/60 dark:border-emerald-800/60 transition inline-flex items-center justify-center"
                    title="Chat on WhatsApp"
                  >
                    <WhatsAppIcon sizeClass="w-3.5 h-3.5" />
                  </a>
                </div>
              </td>

              <!-- Device & Problem -->
              <td class="py-3.5 px-4">
                <div class="font-bold text-slate-800 dark:text-slate-200">
                  {{ getDeviceName(repair) }}
                </div>
                <div class="text-[11px] text-slate-500 dark:text-slate-400 max-w-xs truncate mt-0.5">
                  <span class="text-slate-400">Issue:</span> {{ repair.problem_description || repair.problemDescription || 'General Repair' }}
                </div>
                <div v-if="repair.device?.imei1 || repair.imei" class="text-[10px] font-mono text-slate-400">
                  IMEI: {{ repair.device?.imei1 || repair.imei }}
                </div>
              </td>

              <!-- Delivery Dates (Estimate & Actual Delivered Date) -->
              <td class="py-3.5 px-4 whitespace-nowrap">
                <div class="flex items-center gap-1.5 text-xs text-slate-700 dark:text-slate-300">
                  <svg class="w-3.5 h-3.5 text-indigo-500 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
                  <span class="text-slate-400">Est:</span>
                  <span :class="repair.expected_delivery_date || repair.expectedDeliveryDate ? 'font-bold' : 'italic text-slate-400'">
                    {{ formatDate(repair.expected_delivery_date || repair.expectedDeliveryDate) }}
                  </span>
                </div>
                <div class="flex items-center gap-1.5 text-xs mt-1">
                  <svg class="w-3.5 h-3.5 shrink-0" :class="isDelivered(repair) ? 'text-emerald-500' : 'text-slate-400'" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                  <span class="text-slate-400">Actual:</span>
                  <span v-if="isDelivered(repair)" class="font-bold text-emerald-600 dark:text-emerald-400">
                    {{ formatDate(repair.delivered_date || repair.deliveredDate) !== '-' ? formatDate(repair.delivered_date || repair.deliveredDate) : 'Delivered' }}
                  </span>
                  <span v-else class="text-[11px] text-amber-600 dark:text-amber-400 font-semibold">
                    Pending
                  </span>
                </div>
              </td>

              <!-- Technician & Fee -->
              <td class="py-3.5 px-4 whitespace-nowrap">
                <div>
                  <span
                    v-if="repair.technician_name || repair.technicianName"
                    class="inline-flex items-center px-2 py-0.5 rounded-md text-xs font-semibold bg-indigo-50 dark:bg-indigo-950/60 text-indigo-700 dark:text-indigo-300 border border-indigo-200/60 dark:border-indigo-800/60"
                  >
                    {{ repair.technician_name || repair.technicianName }}
                  </span>
                  <span v-else class="text-xs text-slate-400 italic">Unassigned</span>
                </div>
                <div class="text-[11px] font-bold text-slate-600 dark:text-slate-300 mt-1 flex items-center gap-1">
                  <span class="text-slate-400 font-medium">Tech Pay:</span>
                  <span class="text-indigo-600 dark:text-indigo-400 font-black tabular-nums">
                    ₹{{ formatAmount(repair.technician_earning || repair.technicianCost || 0) }}
                  </span>
                </div>
              </td>

              <!-- Status Badge (Matching App Colors) -->
              <td class="py-3.5 px-4 whitespace-nowrap">
                <span
                  :class="getStatusBadgeClass(repair.repair_status || repair.repairStatus || repair.status)"
                  class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold capitalize shadow-xs"
                >
                  <span class="w-1.5 h-1.5 rounded-full mr-1.5" :class="getStatusDotClass(repair.repair_status || repair.repairStatus || repair.status)"></span>
                  {{ getStatusLabel(repair.repair_status || repair.repairStatus || repair.status) }}
                </span>
              </td>

              <!-- Amount & Profit (Billed, Due & Realized Net Profit) -->
              <td class="py-3.5 px-4 whitespace-nowrap">
                <div class="font-black text-slate-900 dark:text-white tabular-nums text-sm">
                  ₹{{ formatAmount(getRepairTotal(repair)) }}
                </div>
                <div v-if="getRepairDue(repair) > 0" class="text-[11px] font-bold text-rose-600 dark:text-rose-400 mt-0.5">
                  Due: ₹{{ formatAmount(getRepairDue(repair)) }}
                </div>
                <div v-else class="text-[10px] font-bold text-emerald-600 dark:text-emerald-400 mt-0.5">
                  Paid Full
                </div>
                <div class="mt-1">
                  <span class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px] font-black bg-emerald-50 dark:bg-emerald-950/50 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20">
                    <span class="text-[9px] uppercase font-bold text-emerald-700 dark:text-emerald-300">Profit:</span>
                    ₹{{ formatAmount(getRepairProfit(repair)) }}
                  </span>
                </div>
              </td>

              <!-- Actions (Matching App: View, Edit, WhatsApp, Print, Delete) -->
              <td class="py-3.5 px-4 pr-6 text-right">
                <div class="flex items-center justify-end gap-1">
                  <!-- View -->
                  <router-link
                    :to="`/repairs/${repair.id}`"
                    class="p-1.5 rounded-lg text-slate-500 hover:text-indigo-600 hover:bg-indigo-50 dark:hover:bg-slate-800 transition"
                    title="View Job Card"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                  </router-link>

                  <!-- Edit (Only if not delivered) -->
                  <router-link
                    v-if="repair.repair_status !== 'delivered'"
                    :to="`/repairs/${repair.id}/edit`"
                    class="p-1.5 rounded-lg text-slate-500 hover:text-amber-600 hover:bg-amber-50 dark:hover:bg-slate-800 transition"
                    title="Edit Order"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
                  </router-link>
                  <span
                    v-else
                    class="p-1.5 text-slate-300 dark:text-slate-600 cursor-not-allowed select-none"
                    title="Delivered orders are frozen and cannot be edited"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/></svg>
                  </span>

                  <!-- Delete (Only if not delivered) -->
                  <button
                    v-if="repair.repair_status !== 'delivered'"
                    @click="confirmDeleteRepair(repair)"
                    class="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/40 transition cursor-pointer"
                    title="Delete Repair Order"
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

    <!-- Delete Confirmation Modal -->
    <div
      v-if="deleteModalOpen"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 overflow-y-auto flex min-h-full items-center justify-center p-4 py-6"
      @wheel.stop
    >
      <div class="bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-2xl w-full max-w-sm shadow-2xl p-6 text-center animate-in fade-in zoom-in-95">
        <div class="w-12 h-12 rounded-full bg-rose-50 dark:bg-rose-950/60 text-rose-600 dark:text-rose-400 flex items-center justify-center mx-auto mb-3">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
        </div>
        <h3 class="text-base font-bold text-slate-900 dark:text-white">Delete Repair Order?</h3>
        <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
          Are you sure you want to delete order <span class="font-mono font-bold text-slate-700 dark:text-slate-300">{{ repairToDelete?.job_number || repairToDelete?.jobNumber || ('#JOB-' + repairToDelete?.id) }}</span>? This action cannot be undone.
        </p>
        <div class="flex items-center justify-center gap-2 mt-5">
          <button
            @click="deleteModalOpen = false"
            class="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition"
          >
            Cancel
          </button>
          <button
            @click="executeDeleteRepair"
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
import { ref, reactive, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useFilterStore } from '@/stores/filter';
import { useToastStore } from '@/stores/toast';
import { repairApi } from '@/api/endpoints';
import PaginationBar from '@/components/common/PaginationBar.vue';
import SearchableSelect from '@/components/common/SearchableSelect.vue';
import WhatsAppIcon from '@/components/common/WhatsAppIcon.vue';

const route = useRoute();
const filterStore = useFilterStore();
const toast = useToastStore();

const repairs = ref([]);
const loading = ref(false);
const searchQuery = ref(route.query.search || '');
const selectedStatus = ref(route.query.status || '');
const currentPage = ref(1);
const totalPages = ref(1);
const totalCount = ref(0);
const perPage = ref(10);
let searchTimer = null;

const deleteModalOpen = ref(false);
const repairToDelete = ref(null);
const deleting = ref(false);

const summary = reactive({
  totalVolume: 0,
  totalPaid: 0,
  totalDue: 0,
  totalNetProfit: 0,
  totalTechCost: 0,
});

function debounceSearch() {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => {
    currentPage.value = 1;
    fetchRepairs();
  }, 350);
}

function resetFilters() {
  searchQuery.value = '';
  selectedStatus.value = '';
  filterStore.setPeriod('this_month');
  currentPage.value = 1;
  fetchRepairs();
}

function onFilterChange() {
  filterStore.setPeriod(filterStore.selectedPeriod);
  currentPage.value = 1;
  fetchRepairs();
}

async function fetchRepairs() {
  loading.value = true;
  try {
    const periodVal = filterStore.selectedPeriod;
    const res = await repairApi.list({
      page: currentPage.value,
      per_page: perPage.value,
      search: searchQuery.value || undefined,
      status: selectedStatus.value || undefined,
      repair_status: selectedStatus.value || undefined,
      period: periodVal !== 'all_time' ? periodVal : undefined,
    });
    const payload = res.data?.data;
    if (payload?.data) {
      repairs.value = payload.data;
      currentPage.value = payload.current_page || 1;
      totalCount.value = payload.total || payload.data.length;
      totalPages.value = payload.last_page || Math.max(1, Math.ceil(totalCount.value / perPage.value));
      if (payload.per_page) perPage.value = payload.per_page;
    } else if (res.data?.meta) {
      repairs.value = Array.isArray(payload) ? payload : [];
      currentPage.value = res.data.meta.current_page || 1;
      totalCount.value = res.data.meta.total || repairs.value.length;
      totalPages.value = res.data.meta.last_page || Math.max(1, Math.ceil(totalCount.value / perPage.value));
      if (res.data.meta.per_page) perPage.value = res.data.meta.per_page;
    } else {
      repairs.value = Array.isArray(payload) ? payload : [];
      totalCount.value = repairs.value.length;
      totalPages.value = Math.max(1, Math.ceil(repairs.value.length / perPage.value));
    }

    // Compute summary
    let vol = 0;
    let paid = 0;
    let due = 0;
    let profit = 0;
    let tech = 0;
    repairs.value.forEach(r => {
      const tot = getRepairTotal(r);
      const d = getRepairDue(r);
      const p = Number(r.amount_paid || r.amountPaid || (tot - d)) || 0;
      vol += tot;
      paid += p;
      due += d;
      profit += getRepairProfit(r);
      tech += Number(r.technician_earning || r.technicianCost || 0);
    });
    summary.totalVolume = vol;
    summary.totalPaid = paid;
    summary.totalDue = due;
    summary.totalNetProfit = profit;
    summary.totalTechCost = tech;
  } catch (err) {
    console.error('Failed to load repairs:', err);
  } finally {
    loading.value = false;
  }
}

function changePage(p) {
  currentPage.value = p;
  fetchRepairs();
}

function getCustomerPhone(repair) {
  const p = repair.customer?.mobile || repair.customer?.phone || repair.customer_phone;
  if (!p) return '';
  return String(p).replace(/[^0-9]/g, '').slice(-10);
}

function getDeviceName(repair) {
  if (repair.device_name) return repair.device_name;
  if (repair.device?.brand || repair.device?.model) {
    return `${repair.device.brand || ''} ${repair.device.model || ''}`.trim();
  }
  if (repair.device_brand || repair.device_model) {
    return `${repair.device_brand || ''} ${repair.device_model || ''}`.trim();
  }
  return 'Device Repair';
}

function getRepairTotal(repair) {
  return Number(repair.final_cost || repair.finalCost || repair.estimated_cost || repair.estimatedCost || repair.final_amount || 0);
}

function getRepairDue(repair) {
  if (repair.amount_due !== undefined) return Number(repair.amount_due) || 0;
  if (repair.amountDue !== undefined) return Number(repair.amountDue) || 0;
  if (repair.due_amount !== undefined) return Number(repair.due_amount) || 0;
  const tot = getRepairTotal(repair);
  const paid = Number(repair.amount_paid || repair.amountPaid || 0);
  return Math.max(0, tot - paid);
}

function getRepairProfit(repair) {
  if (repair.net_profit !== undefined && repair.net_profit !== null) {
    return Number(repair.net_profit) || 0;
  }
  if (repair.netProfit !== undefined && repair.netProfit !== null) {
    return Number(repair.netProfit) || 0;
  }
  const tot = getRepairTotal(repair);
  const paid = Number(repair.amount_paid || repair.amountPaid || 0);
  const tech = Number(repair.technician_earning || repair.technicianCost || 0);
  const parts = Number(repair.parts_cost_total || repair.partsCostTotal || 0);
  return Math.max(0, paid - tech - parts);
}

function isDelivered(repair) {
  const s = String(repair.repair_status || repair.repairStatus || repair.status || '').toLowerCase();
  return s.includes('delivered') || Boolean(repair.delivered_date || repair.deliveredDate);
}

function getStatusLabel(status) {
  if (!status) return 'Received';
  const s = String(status).toLowerCase();
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
    completed: 'Completed',
  };
  return map[s] || status.replace('_', ' ');
}

function getStatusBadgeClass(status) {
  const s = String(status || '').toLowerCase();
  if (s.includes('delivered') || s.includes('completed')) {
    return 'bg-emerald-50 dark:bg-emerald-950/50 text-emerald-600 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-900/40';
  }
  if (s.includes('ready')) {
    return 'bg-teal-50 dark:bg-teal-950/50 text-teal-600 dark:text-teal-400 border border-teal-200 dark:border-teal-900/40';
  }
  if (s.includes('repairing') || s.includes('progress')) {
    return 'bg-indigo-50 dark:bg-indigo-950/50 text-indigo-600 dark:text-indigo-400 border border-indigo-200 dark:border-indigo-900/40';
  }
  if (s.includes('waiting')) {
    return 'bg-amber-50 dark:bg-amber-950/50 text-amber-600 dark:text-amber-400 border border-amber-200 dark:border-amber-900/40';
  }
  if (s.includes('diagnosing')) {
    return 'bg-purple-50 dark:bg-purple-950/50 text-purple-600 dark:text-purple-400 border border-purple-200 dark:border-purple-900/40';
  }
  if (s.includes('cancel')) {
    return 'bg-rose-50 dark:bg-rose-950/50 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-900/40';
  }
  return 'bg-blue-50 dark:bg-blue-950/50 text-blue-600 dark:text-blue-400 border border-blue-200 dark:border-blue-900/40';
}

function getStatusDotClass(status) {
  const s = String(status || '').toLowerCase();
  if (s.includes('delivered') || s.includes('completed')) return 'bg-emerald-500';
  if (s.includes('ready')) return 'bg-teal-500';
  if (s.includes('repairing') || s.includes('progress')) return 'bg-indigo-500';
  if (s.includes('waiting')) return 'bg-amber-500';
  if (s.includes('diagnosing')) return 'bg-purple-500';
  if (s.includes('cancel')) return 'bg-rose-500';
  return 'bg-blue-500';
}

function formatAmount(amt) {
  return (Number(amt) || 0).toLocaleString('en-IN');
}

function formatDate(d) {
  if (!d) return '-';
  const date = new Date(d);
  return date.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
}

function confirmDeleteRepair(repair) {
  repairToDelete.value = repair;
  deleteModalOpen.value = true;
}

async function executeDeleteRepair() {
  if (!repairToDelete.value) return;
  deleting.value = true;
  try {
    await repairApi.delete(repairToDelete.value.id);
    deleteModalOpen.value = false;
    repairToDelete.value = null;
    toast.success('Repair job order deleted successfully.', 'Job Deleted');
    fetchRepairs();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to delete repair order';
    toast.error(msg, 'Delete Failed');
  } finally {
    deleting.value = false;
  }
}

onMounted(() => {
  fetchRepairs();
});
</script>
