<template>
  <div class="space-y-6 pb-12">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <div class="flex items-center gap-2">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 border border-indigo-200/60 dark:border-indigo-800/60">
            Workforce
          </span>
          <span class="text-xs text-slate-400">Repair Specialists & Commission</span>
        </div>
        <h1 class="text-2xl font-black tracking-tight text-slate-900 dark:text-white mt-1">Technicians Management</h1>
        <p class="text-xs sm:text-sm text-slate-500 dark:text-slate-400">Track assigned repair specialists, workload queue, earnings, and payable dues.</p>
      </div>

      <button
        @click="openAddModal"
        class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold shadow-md shadow-indigo-600/20 transition-all hover:scale-[1.02] active:scale-[0.98] cursor-pointer"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" /></svg>
        <span>+ Add Technician</span>
      </button>
    </div>

    <!-- Summary Metrics Cards (Matching Mobile App Screen Overview) -->
    <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3 sm:gap-4">
      <!-- 1. Total Specialists -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-sm flex items-center justify-between">
        <div>
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Specialists</p>
          <p class="text-xl font-extrabold text-slate-900 dark:text-white mt-1 tabular-nums">
            {{ summary.total_technicians || technicians.length }}
          </p>
          <p class="text-[10px] text-emerald-600 dark:text-emerald-400 font-bold mt-0.5">
            {{ summary.active_technicians || activeCount }} Active
          </p>
        </div>
        <div class="w-10 h-10 rounded-xl bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 flex items-center justify-center shrink-0">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
        </div>
      </div>

      <!-- 2. Active Repairs Queue -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-sm flex items-center justify-between">
        <div>
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">In Progress</p>
          <p class="text-xl font-extrabold text-indigo-600 dark:text-indigo-400 mt-1 tabular-nums">
            {{ summary.in_progress_jobs || 0 }} Jobs
          </p>
          <p class="text-[10px] text-slate-400 font-medium mt-0.5">
            {{ summary.pending_jobs || 0 }} in queue
          </p>
        </div>
        <div class="w-10 h-10 rounded-xl bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 flex items-center justify-center shrink-0">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
        </div>
      </div>

      <!-- 3. Completed Repairs -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-sm flex items-center justify-between">
        <div>
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Completed Jobs</p>
          <p class="text-xl font-extrabold text-emerald-600 dark:text-emerald-400 mt-1 tabular-nums">
            {{ summary.completed_jobs || 0 }} Jobs
          </p>
          <p class="text-[10px] text-slate-400 font-medium mt-0.5">Ready & delivered</p>
        </div>
        <div class="w-10 h-10 rounded-xl bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center shrink-0">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
        </div>
      </div>

      <!-- 4. Total Tech Earnings -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-sm flex items-center justify-between">
        <div>
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Total Tech Earnings</p>
          <p class="text-xl font-black text-slate-900 dark:text-white mt-1 tabular-nums">
            ₹{{ formatAmount(totalEarningsSum) }}
          </p>
          <p class="text-[10px] text-slate-400 mt-0.5">Paid: ₹{{ formatAmount(totalPaidSum) }}</p>
        </div>
        <div class="w-10 h-10 rounded-xl bg-purple-50 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400 flex items-center justify-center shrink-0">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
        </div>
      </div>

      <!-- 5. Total Tech Payable (Outstanding Dues to Techs) -->
      <div
        class="bg-white dark:bg-[#111827] rounded-2xl p-4 border shadow-sm flex items-center justify-between"
        :class="totalPayableSum > 0 ? 'border-amber-500/40 bg-amber-500/5' : 'border-slate-200/80 dark:border-slate-800/80'"
      >
        <div>
          <div class="flex items-center gap-1.5">
            <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Total Tech Payable</p>
            <span
              v-if="totalPayableSum > 0"
              class="px-1.5 py-0.2 rounded text-[9px] font-black bg-amber-500/10 text-amber-600 dark:text-amber-400 border border-amber-500/20"
            >
              Pending
            </span>
          </div>
          <p
            class="text-xl font-black mt-1 tabular-nums"
            :class="totalPayableSum > 0 ? 'text-amber-600 dark:text-amber-400' : 'text-slate-900 dark:text-white'"
          >
            ₹{{ formatAmount(totalPayableSum) }}
          </p>
          <p class="text-[10px] text-slate-400 mt-0.5">Outstanding payout due</p>
        </div>
        <div
          class="w-10 h-10 rounded-xl flex items-center justify-center shrink-0"
          :class="totalPayableSum > 0 ? 'bg-amber-100 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400' : 'bg-slate-100 dark:bg-slate-800 text-slate-400'"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
        </div>
      </div>
    </div>

    <!-- Filter & Search Bar -->
    <div class="relative z-20 bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-sm flex flex-col md:flex-row items-stretch md:items-center justify-between gap-3">
      <div class="relative flex-1">
        <svg class="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
        <input
          v-model="search"
          type="text"
          placeholder="Search by name, mobile, or specialization..."
          class="w-full pl-10 pr-4 py-2 text-xs font-semibold bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-800 dark:text-slate-100 placeholder-slate-400"
        />
      </div>

      <div class="flex items-center gap-2">
        <SearchableSelect
          v-model="selectedStatus"
          :options="statusFilterOptions"
          placeholder="All Specialists"
          minWidth="140px"
        />

        <SearchableSelect
          v-model="sortBy"
          :options="sortOptions"
          placeholder="Sort By"
          minWidth="140px"
          prefixIcon="↕️"
        />

        <button
          v-if="search || selectedStatus !== 'all' || sortBy !== 'newest'"
          @click="resetFilters"
          type="button"
          class="px-3 py-2 text-xs font-bold bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-600 dark:text-slate-300 rounded-xl transition cursor-pointer"
        >
          Reset
        </button>
      </div>
    </div>

    <!-- Technicians Table Card -->
    <div class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800/80 shadow-sm overflow-hidden">
      <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="border-b border-slate-100 dark:border-slate-800/80 bg-slate-50/60 dark:bg-slate-900/40 text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              <th class="py-3.5 px-4 pl-6">Technician</th>
              <th class="py-3.5 px-4">Contact</th>
              <th class="py-3.5 px-4">Workload Queue</th>
              <th class="py-3.5 px-4">Total Earnings</th>
              <th class="py-3.5 px-4">Total Paid</th>
              <th class="py-3.5 px-4">Payable Balance</th>
              <th class="py-3.5 px-4">Status</th>
              <th class="py-3.5 px-4 pr-6 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100 dark:divide-slate-800/60 text-sm">
            <tr v-if="loading">
              <td colspan="8" class="text-center py-12 text-slate-400 text-xs">
                <div class="inline-block animate-spin w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full mb-2"></div>
                <div>Loading technicians & workload...</div>
              </td>
            </tr>
            <tr v-else-if="filteredTechnicians.length === 0">
              <td colspan="8" class="text-center py-12 text-slate-400 dark:text-slate-500 text-xs">
                No technicians found matching criteria.
              </td>
            </tr>
            <tr
              v-for="t in paginatedTechnicians"
              :key="t.id"
              class="hover:bg-slate-50/70 dark:hover:bg-slate-800/40 transition group"
            >
              <!-- Technician Info -->
              <td class="py-3.5 px-4 pl-6 whitespace-nowrap">
                <div class="flex items-center gap-3">
                  <div class="w-9 h-9 rounded-xl bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 font-black flex items-center justify-center text-xs border border-indigo-200/60 dark:border-indigo-800/60 shrink-0">
                    {{ t.name?.charAt(0)?.toUpperCase() || 'T' }}
                  </div>
                  <div>
                    <router-link
                      :to="`/technicians/${t.id}`"
                      class="font-bold text-slate-900 dark:text-white hover:text-indigo-600 dark:hover:text-indigo-400 transition"
                    >
                      {{ t.name }}
                    </router-link>
                    <p class="text-[11px] text-slate-400 flex items-center gap-1.5 flex-wrap">
                      <span>{{ t.specialization || 'General Specialist' }}</span>
                      <span v-if="t.created_at">• 📅 {{ formatDate(t.created_at) }}</span>
                    </p>
                  </div>
                </div>
              </td>

              <!-- Contact & WhatsApp -->
              <td class="py-3.5 px-4 whitespace-nowrap">
                <div class="flex items-center gap-2">
                  <span class="font-mono text-xs font-semibold text-slate-700 dark:text-slate-300">
                    {{ t.mobile || t.phone || '-' }}
                  </span>
                  <a
                    v-if="getCleanMobile(t)"
                    :href="`https://wa.me/91${getCleanMobile(t)}?text=Hello%20${encodeURIComponent(t.name)},%20regarding%20repair%20orders%20at%20MyRepairHub.`"
                    target="_blank"
                    class="p-1 rounded-md bg-emerald-50 hover:bg-emerald-100 dark:bg-emerald-950/50 dark:hover:bg-emerald-900/50 text-emerald-600 dark:text-emerald-400 border border-emerald-200/60 dark:border-emerald-800/60 transition inline-flex items-center justify-center"
                    title="Message on WhatsApp"
                  >
                    <WhatsAppIcon sizeClass="w-3.5 h-3.5" />
                  </a>
                </div>
              </td>

              <!-- Workload Queue -->
              <td class="py-3.5 px-4 whitespace-nowrap">
                <div class="flex items-center gap-1.5 text-[10px] font-bold">
                  <span
                    class="px-2 py-0.5 rounded-md bg-indigo-50 dark:bg-indigo-950/50 text-indigo-700 dark:text-indigo-300 border border-indigo-200/60 dark:border-indigo-800/60"
                    title="Repairs in progress"
                  >
                    {{ t.workload?.in_progress_jobs || 0 }} Active
                  </span>
                  <span
                    class="px-2 py-0.5 rounded-md bg-amber-50 dark:bg-amber-950/50 text-amber-700 dark:text-amber-300 border border-amber-200/60 dark:border-amber-800/60"
                    title="Pending approval / queue"
                  >
                    {{ t.workload?.pending_jobs || 0 }} Queue
                  </span>
                  <span
                    class="px-2 py-0.5 rounded-md bg-emerald-50 dark:bg-emerald-950/50 text-emerald-700 dark:text-emerald-300 border border-emerald-200/60 dark:border-emerald-800/60"
                    title="Completed repairs"
                  >
                    {{ t.workload?.completed_jobs || 0 }} Done
                  </span>
                </div>
              </td>

              <!-- Total Earnings -->
              <td class="py-3.5 px-4 font-black text-slate-900 dark:text-white tabular-nums text-xs whitespace-nowrap">
                ₹{{ formatAmount(t.workload?.total_earnings || 0) }}
              </td>

              <!-- Total Paid -->
              <td class="py-3.5 px-4 font-bold text-emerald-600 dark:text-emerald-400 tabular-nums text-xs whitespace-nowrap">
                ₹{{ formatAmount(t.workload?.total_paid || 0) }}
              </td>

              <!-- Tech Payable (Dues) -->
              <td class="py-3.5 px-4 whitespace-nowrap">
                <span
                  v-if="Number(t.workload?.total_payable) > 0"
                  class="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[11px] font-black bg-amber-50 dark:bg-amber-950/40 text-amber-600 dark:text-amber-400 border border-amber-500/20 tabular-nums"
                >
                  ₹{{ formatAmount(t.workload.total_payable) }} Due
                </span>
                <span
                  v-else
                  class="inline-flex items-center px-2 py-0.5 rounded-md text-[10px] font-bold bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20"
                >
                  Settled ✓
                </span>
              </td>

              <!-- Status -->
              <td class="py-3.5 px-4 whitespace-nowrap">
                <span
                  :class="t.is_active !== false
                    ? 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-900/40'
                    : 'bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-900/40'"
                  class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold"
                >
                  {{ t.is_active !== false ? 'Active' : 'Inactive' }}
                </span>
              </td>

              <!-- Actions (Pay, View Details, Edit, Delete) -->
              <td class="py-3.5 px-4 pr-6 text-right whitespace-nowrap">
                <div class="flex items-center justify-end gap-1.5">
                  <!-- Quick Pay Button -->
                  <button
                    @click="openQuickPayModal(t)"
                    type="button"
                    class="px-2.5 py-1 rounded-lg text-xs font-bold bg-emerald-50 hover:bg-emerald-100 dark:bg-emerald-950/50 dark:hover:bg-emerald-900/50 text-emerald-700 dark:text-emerald-300 border border-emerald-200/80 dark:border-emerald-800/80 transition cursor-pointer flex items-center gap-1"
                    title="Record Payout to Technician"
                  >
                    <span>₹</span>
                    <span>Pay</span>
                  </button>

                  <!-- View Details -->
                  <router-link
                    :to="`/technicians/${t.id}`"
                    class="p-1.5 rounded-lg text-slate-500 hover:text-indigo-600 hover:bg-indigo-50 dark:hover:bg-slate-800 transition"
                    title="View Workload & Payout Ledger"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                  </router-link>

                  <!-- Edit -->
                  <button
                    @click="openEditModal(t)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-500 hover:text-amber-600 hover:bg-amber-50 dark:hover:bg-slate-800 transition cursor-pointer"
                    title="Edit Specialist"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
                  </button>

                  <!-- Delete -->
                  <button
                    @click="confirmDeleteTechnician(t)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/40 transition cursor-pointer"
                    title="Delete Specialist"
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
        :total="filteredTechnicians.length"
        :per-page="perPage"
        @page-change="onPageChange"
      />
    </div>

    <!-- MODAL 1: ADD / EDIT TECHNICIAN -->
    <div
      v-if="showModal"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 overflow-y-auto p-4 flex min-h-full items-center justify-center py-6 sm:py-10"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-3xl w-full max-w-md shadow-2xl my-auto max-h-[calc(100vh-3rem)] flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        <div class="px-6 py-4 border-b border-slate-100 dark:border-slate-800/80 flex justify-between items-center bg-slate-50/50 dark:bg-slate-900/30 shrink-0">
          <div>
            <h3 class="font-bold text-slate-900 dark:text-white">
              {{ isEditing ? 'Edit Technician' : 'Add Technician Specialist' }}
            </h3>
            <p class="text-xs text-slate-400">
              {{ isEditing ? 'Update profile and status' : 'Register repair specialist for job assignments' }}
            </p>
          </div>
          <button @click="showModal = false" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 cursor-pointer">✕</button>
        </div>

        <form @submit.prevent="saveTechnician" class="p-6 space-y-4 overflow-y-auto custom-scroll flex-1">
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Full Name <span class="text-rose-500">*</span>
            </label>
            <input
              v-model="form.name"
              type="text"
              class="w-full px-3.5 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 font-bold"
              placeholder="e.g. Ramesh Patel"
              required
            />
          </div>

          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Mobile Number
            </label>
            <input
              v-model="form.mobile"
              type="tel"
              class="w-full px-3.5 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 font-semibold"
              placeholder="10-digit mobile"
            />
          </div>

          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Specialization
            </label>
            <input
              v-model="form.specialization"
              type="text"
              class="w-full px-3.5 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 font-semibold"
              placeholder="e.g. Display & Touch, Motherboard IC, Charging Port"
            />
          </div>

          <div class="flex items-center gap-2 pt-1">
            <input
              v-model="form.is_active"
              id="tech_active_checkbox"
              type="checkbox"
              class="w-4 h-4 rounded text-indigo-600 focus:ring-indigo-500 border-slate-300 dark:border-slate-700"
            />
            <label for="tech_active_checkbox" class="text-xs font-bold text-slate-700 dark:text-slate-300 cursor-pointer">
              Active Specialist (Can be assigned repair job cards)
            </label>
          </div>

          <div class="flex justify-end gap-2 pt-3 border-t border-slate-100 dark:border-slate-800/80 shrink-0">
            <button
              type="button"
              @click="showModal = false"
              class="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-xl transition cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="saving"
              class="px-4 py-2 text-xs font-bold bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl shadow-md shadow-indigo-600/20 disabled:opacity-50 transition cursor-pointer"
            >
              {{ saving ? 'Saving...' : (isEditing ? 'Update Technician' : 'Add Technician') }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- MODAL 2: QUICK PAY TECHNICIAN (Record Payout) -->
    <div
      v-if="showQuickPayModal"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-3 sm:p-5"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-3xl w-full max-w-md shadow-2xl max-h-[85vh] flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        <!-- Modal Header -->
        <div class="px-6 py-4 border-b border-slate-100 dark:border-slate-800/80 flex justify-between items-center bg-slate-50/50 dark:bg-slate-900/30 shrink-0">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-xl bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center font-bold">
              ₹
            </div>
            <div>
              <h3 class="font-bold text-slate-900 dark:text-white">Pay {{ targetTech?.name }}</h3>
              <p class="text-[11px] text-slate-400">Record commission or salary payout</p>
            </div>
          </div>
          <button @click="showQuickPayModal = false" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 cursor-pointer">✕</button>
        </div>

        <form @submit.prevent="submitQuickPayout" class="flex flex-col flex-1 overflow-hidden min-h-0">
          <!-- Scrollable Body with bottom padding for dropdowns -->
          <div class="p-6 space-y-4 overflow-y-auto custom-scroll flex-1">
            <!-- Payable Highlight Card -->
            <div class="p-3.5 rounded-xl bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-800/40 flex items-center justify-between shrink-0">
              <div>
                <p class="text-[11px] font-bold uppercase tracking-wider text-amber-700 dark:text-amber-400">Outstanding Payable</p>
                <p class="text-xs text-slate-500 dark:text-slate-400">Remaining due balance</p>
              </div>
              <div class="text-right">
                <span class="text-xl font-black text-amber-600 dark:text-amber-400 tabular-nums">
                  ₹{{ formatAmount(targetTech?.workload?.total_payable || 0) }}
                </span>
              </div>
            </div>

            <!-- Payout Amount -->
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Payout Amount (₹) <span class="text-rose-500">*</span>
              </label>
              <div class="relative">
                <span class="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 font-bold">₹</span>
                <input
                  v-model.number="quickPayForm.amount"
                  type="number"
                  step="0.01"
                  min="1"
                  class="w-full pl-8 pr-4 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-emerald-500 text-slate-900 dark:text-slate-100 font-bold"
                  placeholder="Enter amount"
                  required
                />
              </div>
            </div>

            <!-- Payment Date -->
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Payment Date <span class="text-rose-500">*</span>
              </label>
              <DatePicker v-model="quickPayForm.payment_date" required />
            </div>

            <!-- Payment Method -->
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Payment Mode <span class="text-rose-500">*</span>
              </label>
              <SearchableSelect
                v-model="quickPayForm.payment_method"
                :options="paymentMethodOptions"
                placeholder="Select Payment Method"
                minWidth="100%"
              />
            </div>

            <!-- Notes -->
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Notes (Optional)
              </label>
              <input
                v-model="quickPayForm.notes"
                type="text"
                class="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-emerald-500 text-slate-900 dark:text-slate-100"
                placeholder="e.g. Weekly settlement, Advance pay"
              />
            </div>
          </div>

          <!-- Pinned Footer -->
          <div class="px-6 py-3.5 border-t border-slate-100 dark:border-slate-800/80 bg-slate-50/50 dark:bg-slate-900/30 flex justify-end gap-2 shrink-0">
            <button
              type="button"
              @click="showQuickPayModal = false"
              class="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-xl transition cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="submittingQuickPay"
              class="px-4 py-2 text-xs font-bold bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl shadow-md shadow-emerald-600/20 disabled:opacity-50 transition cursor-pointer"
            >
              {{ submittingQuickPay ? 'Recording...' : 'Confirm Payout' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch, onMounted } from 'vue';
import { technicianApi } from '@/api/endpoints';
import { useToastStore } from '@/stores/toast';
import PaginationBar from '@/components/common/PaginationBar.vue';
import SearchableSelect from '@/components/common/SearchableSelect.vue';
import WhatsAppIcon from '@/components/common/WhatsAppIcon.vue';
import DatePicker from '@/components/common/DatePicker.vue';
import { formatDate, toInputDate } from '@/utils/date';

const toast = useToastStore();

const technicians = ref([]);
const loading = ref(false);
const search = ref('');
const selectedStatus = ref('all');
const sortBy = ref('newest');
const sortOptions = [
  { value: 'newest', label: 'Newest First (Recent)' },
  { value: 'oldest', label: 'Oldest First' },
  { value: 'name_asc', label: 'Name (A to Z)' },
  { value: 'name_desc', label: 'Name (Z to A)' },
];
const currentPage = ref(1);
const perPage = ref(10);

const summary = reactive({
  total_technicians: 0,
  active_technicians: 0,
  in_progress_jobs: 0,
  pending_jobs: 0,
  completed_jobs: 0,
});

// Modals
const showModal = ref(false);
const isEditing = ref(false);
const editingTechId = ref(null);
const saving = ref(false);
const form = reactive({
  name: '',
  mobile: '',
  specialization: '',
  is_active: true,
});

const showQuickPayModal = ref(false);
const targetTech = ref(null);
const submittingQuickPay = ref(false);
const quickPayForm = reactive({
  amount: 0,
  payment_date: toInputDate(new Date()),
  payment_method: 'cash',
  notes: '',
});

const statusFilterOptions = [
  { value: 'all', label: 'All Specialists' },
  { value: 'active', label: 'Active Only' },
  { value: 'inactive', label: 'Inactive Only' },
];

const paymentMethodOptions = [
  { value: 'cash', label: 'Cash', icon: '💵' },
  { value: 'upi', label: 'UPI / PhonePe / GPay', icon: '⚡' },
  { value: 'bank_transfer', label: 'Bank Transfer', icon: '🏦' },
  { value: 'card', label: 'Debit / Credit Card', icon: '💳' },
  { value: 'other', label: 'Other', icon: '📋' },
];

function formatAmount(amt) {
  return (Number(amt) || 0).toLocaleString('en-IN');
}

function getCleanMobile(t) {
  const p = t.mobile || t.phone;
  if (!p) return '';
  return String(p).replace(/[^0-9]/g, '').slice(-10);
}

const activeCount = computed(() => {
  return technicians.value.filter(t => t.is_active !== false).length;
});

const totalEarningsSum = computed(() => {
  return technicians.value.reduce((acc, t) => acc + (Number(t.workload?.total_earnings) || 0), 0);
});

const totalPaidSum = computed(() => {
  return technicians.value.reduce((acc, t) => acc + (Number(t.workload?.total_paid) || 0), 0);
});

const totalPayableSum = computed(() => {
  return technicians.value.reduce((acc, t) => acc + (Number(t.workload?.total_payable) || 0), 0);
});

const filteredTechnicians = computed(() => {
  let list = technicians.value;

  if (selectedStatus.value === 'active') {
    list = list.filter(t => t.is_active !== false);
  } else if (selectedStatus.value === 'inactive') {
    list = list.filter(t => t.is_active === false);
  }

  if (search.value) {
    const q = search.value.toLowerCase().trim();
    list = list.filter(t =>
      (t.name && t.name.toLowerCase().includes(q)) ||
      (t.mobile && t.mobile.toLowerCase().includes(q)) ||
      (t.phone && t.phone.toLowerCase().includes(q)) ||
      (t.specialization && t.specialization.toLowerCase().includes(q))
    );
  }
  return list;
});

const totalPages = computed(() => Math.max(1, Math.ceil(filteredTechnicians.value.length / perPage.value)));

const paginatedTechnicians = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredTechnicians.value.slice(start, start + perPage.value);
});

watch([search, selectedStatus, sortBy], () => {
  currentPage.value = 1;
  fetchTechnicians();
});

function onPageChange(page) {
  currentPage.value = page;
}

function resetFilters() {
  search.value = '';
  selectedStatus.value = 'all';
  sortBy.value = 'newest';
  currentPage.value = 1;
  fetchTechnicians();
}

async function fetchTechnicians() {
  loading.value = true;
  try {
    const res = await technicianApi.list({ sort: sortBy.value || 'newest' });
    const data = res.data?.data || res.data || [];
    technicians.value = Array.isArray(data) ? data : (data.data || []);
    if (res.data?.summary) {
      Object.assign(summary, res.data.summary);
    }
  } catch (err) {
    console.error('Failed to load technicians:', err);
    toast.error('Could not load technicians.');
  } finally {
    loading.value = false;
  }
}

function openAddModal() {
  isEditing.value = false;
  editingTechId.value = null;
  Object.assign(form, {
    name: '',
    mobile: '',
    specialization: '',
    is_active: true,
  });
  showModal.value = true;
}

function openEditModal(t) {
  isEditing.value = true;
  editingTechId.value = t.id;
  Object.assign(form, {
    name: t.name || '',
    mobile: t.mobile || t.phone || '',
    specialization: t.specialization || '',
    is_active: t.is_active !== false,
  });
  showModal.value = true;
}

async function saveTechnician() {
  if (!form.name?.trim()) {
    toast.warning('Please enter technician full name.');
    return;
  }
  saving.value = true;
  try {
    if (isEditing.value && editingTechId.value) {
      await technicianApi.update(editingTechId.value, form);
      toast.success(`Technician "${form.name}" updated successfully!`);
    } else {
      await technicianApi.create(form);
      toast.success(`Technician "${form.name}" added successfully!`);
    }
    showModal.value = false;
    fetchTechnicians();
  } catch (err) {
    console.error('Failed to save technician:', err);
    toast.error(err.response?.data?.message || 'Failed to save technician.');
  } finally {
    saving.value = false;
  }
}

function openQuickPayModal(t) {
  targetTech.value = t;
  const payable = Number(t.workload?.total_payable) || 0;
  Object.assign(quickPayForm, {
    amount: payable > 0 ? payable : '',
    payment_date: toInputDate(new Date()),
    payment_method: 'cash',
    notes: '',
  });
  showQuickPayModal.value = true;
}

async function submitQuickPayout() {
  if (!quickPayForm.amount || Number(quickPayForm.amount) <= 0) {
    toast.warning('Please enter a valid payout amount.');
    return;
  }
  submittingQuickPay.value = true;
  try {
    await technicianApi.addPayment(targetTech.value.id, {
      technician_id: targetTech.value.id,
      amount: quickPayForm.amount,
      payment_date: quickPayForm.payment_date,
      payment_method: quickPayForm.payment_method,
      notes: quickPayForm.notes,
    });
    toast.success(`Recorded ₹${formatAmount(quickPayForm.amount)} payout to ${targetTech.value.name}!`);
    showQuickPayModal.value = false;
    fetchTechnicians();
  } catch (err) {
    console.error('Failed to record payout:', err);
    toast.error(err.response?.data?.message || 'Failed to record payout.');
  } finally {
    submittingQuickPay.value = false;
  }
}

async function confirmDeleteTechnician(t) {
  const confirmed = await toast.confirm(
    `Are you sure you want to delete technician "${t.name}"? This action cannot be undone.`
  );
  if (!confirmed) return;

  try {
    await technicianApi.delete(t.id);
    toast.success(`Technician "${t.name}" removed successfully.`);
    fetchTechnicians();
  } catch (err) {
    console.error('Failed to delete technician:', err);
    toast.error(err.response?.data?.message || 'Failed to delete technician.');
  }
}

onMounted(() => {
  fetchTechnicians();
});
</script>
