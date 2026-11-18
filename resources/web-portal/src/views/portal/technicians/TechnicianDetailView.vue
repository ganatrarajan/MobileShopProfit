<template>
  <div class="space-y-6 pb-12">
    <!-- Back & Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div class="flex items-center gap-3">
        <router-link
          to="/technicians"
          class="p-2 rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#111827] text-slate-600 dark:text-slate-300 hover:text-indigo-600 dark:hover:text-indigo-400 hover:border-indigo-500/30 transition shadow-2xs"
          title="Back to Technicians"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
        </router-link>

        <div>
          <div class="flex items-center gap-2">
            <span class="inline-flex items-center px-2 py-0.5 rounded-md text-[10px] font-black uppercase tracking-wider bg-indigo-50 dark:bg-indigo-950/60 text-indigo-700 dark:text-indigo-300 border border-indigo-200/60 dark:border-indigo-800/60">
              Technician Profile
            </span>
            <span
              :class="tech.is_active !== false
                ? 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-900/40'
                : 'bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-900/40'"
              class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold"
            >
              {{ tech.is_active !== false ? 'Active Specialist' : 'Inactive' }}
            </span>
          </div>
          <h1 class="text-2xl font-black tracking-tight text-slate-900 dark:text-white mt-1 flex items-center gap-2">
            {{ tech.name || 'Technician Specialist' }}
          </h1>
          <p class="text-xs text-slate-500 dark:text-slate-400 mt-0.5 flex items-center gap-3">
            <span v-if="tech.mobile" class="font-mono flex items-center gap-1">
              📞 {{ tech.mobile }}
            </span>
            <span v-if="tech.specialization" class="flex items-center gap-1">
              🔧 {{ tech.specialization }}
            </span>
          </p>
        </div>
      </div>

      <!-- Action Buttons -->
      <div class="flex flex-wrap items-center gap-2.5">
        <a
          v-if="cleanedPhone"
          :href="`https://wa.me/91${cleanedPhone}?text=Hello%20${encodeURIComponent(tech.name)},%20regarding%20repair%20jobs%20and%20settlements%20at%20MyRepairHub.`"
          target="_blank"
          class="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold bg-emerald-50 hover:bg-emerald-100 dark:bg-emerald-950/50 dark:hover:bg-emerald-900/50 text-emerald-700 dark:text-emerald-300 border border-emerald-200/80 dark:border-emerald-800/80 transition"
        >
          <WhatsAppIcon sizeClass="w-4 h-4" />
          <span>WhatsApp</span>
        </a>

        <button
          @click="openEditModal"
          class="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-200 transition cursor-pointer"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
          <span>Edit Profile</span>
        </button>

        <button
          @click="openPayModal"
          class="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-bold bg-emerald-600 hover:bg-emerald-500 text-white shadow-md shadow-emerald-600/20 transition cursor-pointer active:scale-95"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
          <span>Pay Technician</span>
        </button>
      </div>
    </div>

    <!-- 1. FINANCIAL SUMMARY CARDS (Matching Mobile App Technician Screen) -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      <!-- Total Earnings -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-sm flex items-center justify-between">
        <div>
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Total Tech Earnings</p>
          <p class="text-2xl font-black text-slate-900 dark:text-white mt-1 tabular-nums">
            ₹{{ formatAmount(workload.total_earnings || 0) }}
          </p>
          <p class="text-[10px] text-slate-400 mt-0.5">Calculated across all assigned jobs</p>
        </div>
        <div class="w-11 h-11 rounded-2xl bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 flex items-center justify-center shrink-0">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
        </div>
      </div>

      <!-- Total Paid / Settled -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-sm flex items-center justify-between">
        <div>
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Total Paid Out</p>
          <p class="text-2xl font-black text-emerald-600 dark:text-emerald-400 mt-1 tabular-nums">
            ₹{{ formatAmount(workload.total_paid || 0) }}
          </p>
          <p class="text-[10px] text-slate-400 mt-0.5">Recorded settlement payouts</p>
        </div>
        <div class="w-11 h-11 rounded-2xl bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center shrink-0">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
        </div>
      </div>

      <!-- Outstanding Payable / Balance -->
      <div
        class="bg-white dark:bg-[#111827] rounded-2xl p-4 border shadow-sm flex items-center justify-between"
        :class="Number(workload.total_payable) > 0 ? 'border-amber-500/40 bg-amber-500/5' : 'border-slate-200/80 dark:border-slate-800/80'"
      >
        <div>
          <div class="flex items-center gap-1.5">
            <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Current Payable Due</p>
            <span
              v-if="Number(workload.total_payable) > 0"
              class="px-1.5 py-0.2 rounded text-[9px] font-black bg-amber-500/10 text-amber-600 dark:text-amber-400 border border-amber-500/20"
            >
              Pending
            </span>
            <span
              v-else
              class="px-1.5 py-0.2 rounded text-[9px] font-black bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20"
            >
              Settled ✓
            </span>
          </div>
          <p
            class="text-2xl font-black mt-1 tabular-nums"
            :class="Number(workload.total_payable) > 0 ? 'text-amber-600 dark:text-amber-400' : 'text-slate-900 dark:text-white'"
          >
            ₹{{ formatAmount(workload.total_payable || 0) }}
          </p>
          <p class="text-[10px] text-slate-400 mt-0.5">Earnings remaining to pay</p>
        </div>
        <div
          class="w-11 h-11 rounded-2xl flex items-center justify-center shrink-0"
          :class="Number(workload.total_payable) > 0 ? 'bg-amber-100 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400' : 'bg-slate-100 dark:bg-slate-800 text-slate-400'"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
        </div>
      </div>

      <!-- Workload Jobs Breakdown -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-sm flex items-center justify-between">
        <div>
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Total Work Orders</p>
          <p class="text-2xl font-black text-slate-900 dark:text-white mt-1 tabular-nums">
            {{ workload.total_jobs || recentJobs.length || 0 }} Jobs
          </p>
          <div class="flex items-center gap-1.5 text-[10px] font-bold mt-1">
            <span class="text-indigo-600 dark:text-indigo-400">{{ workload.in_progress_jobs || 0 }} Active</span>
            <span class="text-slate-300">•</span>
            <span class="text-amber-600 dark:text-amber-400">{{ workload.pending_jobs || 0 }} Queue</span>
            <span class="text-slate-300">•</span>
            <span class="text-emerald-600 dark:text-emerald-400">{{ workload.completed_jobs || 0 }} Done</span>
          </div>
        </div>
        <div class="w-11 h-11 rounded-2xl bg-sky-50 dark:bg-sky-950/60 text-sky-600 dark:text-sky-400 flex items-center justify-center shrink-0">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/></svg>
        </div>
      </div>
    </div>

    <!-- 2. TAB CONTROLS (Assigned Jobs vs Settlement History) -->
    <div class="border-b border-slate-200 dark:border-slate-800 flex items-center gap-6">
      <button
        @click="activeTab = 'jobs'"
        type="button"
        class="pb-3 text-sm font-bold border-b-2 transition cursor-pointer flex items-center gap-2"
        :class="activeTab === 'jobs' ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400' : 'border-transparent text-slate-500 hover:text-slate-700 dark:hover:text-slate-300'"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/></svg>
        <span>Assigned Repair Jobs ({{ recentJobs.length }})</span>
      </button>

      <button
        @click="activeTab = 'payments'"
        type="button"
        class="pb-3 text-sm font-bold border-b-2 transition cursor-pointer flex items-center gap-2"
        :class="activeTab === 'payments' ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400' : 'border-transparent text-slate-500 hover:text-slate-700 dark:hover:text-slate-300'"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
        <span>Payouts & Settlements Ledger ({{ payments.length }})</span>
      </button>
    </div>

    <!-- TAB 1: ASSIGNED REPAIR JOBS -->
    <div v-if="activeTab === 'jobs'" class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800/80 shadow-sm overflow-hidden">
      <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="border-b border-slate-100 dark:border-slate-800/80 bg-slate-50/60 dark:bg-slate-900/40 text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              <th class="py-3.5 px-4 pl-6">Job Info</th>
              <th class="py-3.5 px-4">Customer</th>
              <th class="py-3.5 px-4">Device & Problem</th>
              <th class="py-3.5 px-4">Status</th>
              <th class="py-3.5 px-4">Job Billed</th>
              <th class="py-3.5 px-4">Tech Pay / Fee</th>
              <th class="py-3.5 px-4 pr-6 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100 dark:divide-slate-800/60 text-sm">
            <tr v-if="loadingJobs">
              <td colspan="7" class="py-12 text-center text-xs text-slate-400">
                <div class="inline-block animate-spin w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full mb-2"></div>
                <div>Loading assigned repair jobs...</div>
              </td>
            </tr>
            <tr v-else-if="recentJobs.length === 0">
              <td colspan="7" class="py-12 text-center text-slate-400 dark:text-slate-500 text-xs">
                No repair jobs currently assigned to {{ tech.name }}.
              </td>
            </tr>
            <tr
              v-for="job in recentJobs"
              :key="job.id"
              class="hover:bg-slate-50/70 dark:hover:bg-slate-800/40 transition"
            >
              <!-- Job Info -->
              <td class="py-3.5 px-4 pl-6">
                <div class="font-bold font-mono text-indigo-600 dark:text-indigo-400">
                  {{ job.job_number || ('#JOB-' + String(job.id).padStart(6, '0')) }}
                </div>
                <div class="text-[11px] text-slate-400 mt-0.5">
                  {{ formatDate(job.date_received || job.created_at) }}
                </div>
              </td>

              <!-- Customer -->
              <td class="py-3.5 px-4">
                <div class="font-bold text-slate-900 dark:text-white text-xs">
                  {{ job.customer?.name || job.customer_name || 'Walk-in' }}
                </div>
                <div class="text-[11px] text-slate-400 font-mono mt-0.5">
                  {{ job.customer?.mobile || '-' }}
                </div>
              </td>

              <!-- Device & Problem -->
              <td class="py-3.5 px-4">
                <div class="font-semibold text-slate-800 dark:text-slate-200 text-xs">
                  {{ getDeviceName(job) }}
                </div>
                <div class="text-[11px] text-slate-400 truncate max-w-xs mt-0.5">
                  {{ job.problem_description || 'General repair' }}
                </div>
              </td>

              <!-- Status -->
              <td class="py-3.5 px-4">
                <span
                  :class="getStatusBadgeClass(job.repair_status || job.status)"
                  class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold uppercase"
                >
                  {{ job.repair_status || job.status || 'Received' }}
                </span>
              </td>

              <!-- Job Billed -->
              <td class="py-3.5 px-4 font-bold text-slate-900 dark:text-white tabular-nums">
                ₹{{ formatAmount(job.final_cost || job.estimated_cost || 0) }}
              </td>

              <!-- Tech Pay -->
              <td class="py-3.5 px-4">
                <span class="font-black text-indigo-600 dark:text-indigo-400 tabular-nums">
                  ₹{{ formatAmount(job.technician_earning || 0) }}
                </span>
              </td>

              <!-- Action -->
              <td class="py-3.5 px-4 pr-6 text-right">
                <router-link
                  :to="`/repairs/${job.id}`"
                  class="px-2.5 py-1 rounded-lg text-xs font-bold text-indigo-600 dark:text-indigo-400 bg-indigo-50 hover:bg-indigo-100 dark:bg-indigo-950/60 dark:hover:bg-indigo-900/60 transition"
                >
                  View Job →
                </router-link>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- TAB 2: PAYOUTS & SETTLEMENTS LEDGER -->
    <div v-if="activeTab === 'payments'" class="space-y-4">
      <div class="flex items-center justify-between">
        <div>
          <h3 class="font-bold text-slate-900 dark:text-white text-sm">Payout History & Settlements</h3>
          <p class="text-xs text-slate-400">Log of all payments disbursed to {{ tech.name }}</p>
        </div>
        <button
          @click="openPayModal"
          class="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold bg-emerald-600 hover:bg-emerald-500 text-white shadow-xs transition cursor-pointer"
        >
          + Record Payout
        </button>
      </div>

      <div class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800/80 shadow-sm overflow-hidden">
        <div class="overflow-x-auto">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="border-b border-slate-100 dark:border-slate-800/80 bg-slate-50/60 dark:bg-slate-900/40 text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
                <th class="py-3.5 px-4 pl-6">Payment Date</th>
                <th class="py-3.5 px-4">Amount Paid</th>
                <th class="py-3.5 px-4">Payment Method</th>
                <th class="py-3.5 px-4">Linked Job #</th>
                <th class="py-3.5 px-4">Notes</th>
                <th class="py-3.5 px-4 pr-6 text-right">Action</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100 dark:divide-slate-800/60 text-sm">
              <tr v-if="loadingPayments">
                <td colspan="6" class="py-12 text-center text-xs text-slate-400">
                  <div class="inline-block animate-spin w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full mb-2"></div>
                  <div>Loading payment history...</div>
                </td>
              </tr>
              <tr v-else-if="payments.length === 0">
                <td colspan="6" class="py-12 text-center text-slate-400 dark:text-slate-500 text-xs">
                  No payout records found for {{ tech.name }}.
                </td>
              </tr>
              <tr
                v-for="p in payments"
                :key="p.id"
                class="hover:bg-slate-50/70 dark:hover:bg-slate-800/40 transition"
              >
                <!-- Date -->
                <td class="py-3.5 px-4 pl-6 font-semibold text-slate-900 dark:text-white text-xs">
                  {{ formatDate(p.payment_date || p.created_at) }}
                </td>

                <!-- Amount -->
                <td class="py-3.5 px-4 font-black text-emerald-600 dark:text-emerald-400 text-sm tabular-nums">
                  ₹{{ formatAmount(p.amount) }}
                </td>

                <!-- Payment Method -->
                <td class="py-3.5 px-4">
                  <span class="inline-flex items-center px-2 py-0.5 rounded-md text-[10px] font-bold uppercase bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700">
                    {{ p.payment_method || 'Cash' }}
                  </span>
                </td>

                <!-- Linked Job -->
                <td class="py-3.5 px-4">
                  <span v-if="p.repair?.job_number || p.repair_job_number" class="font-mono text-xs text-indigo-600 dark:text-indigo-400 font-bold">
                    {{ p.repair?.job_number || p.repair_job_number }}
                  </span>
                  <span v-else class="text-xs text-slate-400 italic">General Settlement</span>
                </td>

                <!-- Notes -->
                <td class="py-3.5 px-4 text-xs text-slate-500 dark:text-slate-400 max-w-xs truncate">
                  {{ p.notes || '-' }}
                </td>

                <!-- Delete Action -->
                <td class="py-3.5 px-4 pr-6 text-right">
                  <button
                    @click="deletePayout(p)"
                    type="button"
                    class="p-1 rounded-lg text-slate-400 hover:text-rose-600 transition cursor-pointer"
                    title="Delete Payment"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- MODAL 1: PAY TECHNICIAN (Record Payout) -->
    <div
      v-if="showPayModal"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-3 sm:p-5"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-3xl w-full max-w-md shadow-2xl max-h-[85vh] flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        <div class="px-6 py-4 border-b border-slate-100 dark:border-slate-800/80 flex justify-between items-center bg-slate-50/50 dark:bg-slate-900/30 shrink-0">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-xl bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center font-bold">
              ₹
            </div>
            <div>
              <h3 class="font-bold text-slate-900 dark:text-white">Pay {{ tech.name }}</h3>
              <p class="text-[11px] text-slate-400">Record technician commission / salary payout</p>
            </div>
          </div>
          <button @click="showPayModal = false" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 cursor-pointer">✕</button>
        </div>

        <form @submit.prevent="submitPayout" class="flex flex-col flex-1 overflow-hidden min-h-0">
          <div class="p-6 space-y-4 overflow-y-auto custom-scroll flex-1">
            <!-- Payable Highlight Card -->
            <div class="p-3.5 rounded-xl bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-800/40 flex items-center justify-between shrink-0">
              <div>
                <p class="text-[11px] font-bold uppercase tracking-wider text-amber-700 dark:text-amber-400">Total Payable Balance</p>
                <p class="text-xs text-slate-500 dark:text-slate-400">Outstanding fee due</p>
              </div>
              <div class="text-right">
                <span class="text-xl font-black text-amber-600 dark:text-amber-400 tabular-nums">
                  ₹{{ formatAmount(workload.total_payable || 0) }}
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
                  v-model.number="payForm.amount"
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
              <input
                v-model="payForm.payment_date"
                type="date"
                class="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-emerald-500 text-slate-900 dark:text-slate-100 font-semibold"
                required
              />
            </div>

            <!-- Payment Method -->
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Payment Mode <span class="text-rose-500">*</span>
              </label>
              <SearchableSelect
                v-model="payForm.payment_method"
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
                v-model="payForm.notes"
                type="text"
                class="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-emerald-500 text-slate-900 dark:text-slate-100"
                placeholder="e.g. Weekly settlement, Diwali advance"
              />
            </div>
          </div>

          <!-- Pinned Footer -->
          <div class="px-6 py-3.5 border-t border-slate-100 dark:border-slate-800/80 bg-slate-50/50 dark:bg-slate-900/30 flex justify-end gap-2 shrink-0">
            <button
              type="button"
              @click="showPayModal = false"
              class="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-xl transition cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="submittingPay"
              class="px-4 py-2 text-xs font-bold bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl shadow-md shadow-emerald-600/20 disabled:opacity-50 transition cursor-pointer"
            >
              {{ submittingPay ? 'Recording...' : 'Confirm Payout' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- MODAL 2: EDIT TECHNICIAN -->
    <div
      v-if="showEditModal"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-3 sm:p-5"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-3xl w-full max-w-md shadow-2xl max-h-[85vh] flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        <div class="px-6 py-4 border-b border-slate-100 dark:border-slate-800/80 flex justify-between items-center bg-slate-50/50 dark:bg-slate-900/30 shrink-0">
          <div>
            <h3 class="font-bold text-slate-900 dark:text-white">Edit Technician</h3>
            <p class="text-xs text-slate-400">Update specialist details</p>
          </div>
          <button @click="showEditModal = false" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 cursor-pointer">✕</button>
        </div>

        <form @submit.prevent="submitEdit" class="p-6 space-y-4 overflow-y-auto custom-scroll flex-1">
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Full Name <span class="text-rose-500">*</span>
            </label>
            <input
              v-model="editForm.name"
              type="text"
              class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100"
              required
            />
          </div>

          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Mobile Number
            </label>
            <input
              v-model="editForm.mobile"
              type="tel"
              class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100"
              placeholder="10-digit phone"
            />
          </div>

          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Specialization
            </label>
            <input
              v-model="editForm.specialization"
              type="text"
              class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100"
              placeholder="e.g. Glass Replacement, Motherboard IC, Flashing"
            />
          </div>

          <div class="flex items-center gap-2 pt-1">
            <input
              v-model="editForm.is_active"
              id="edit_is_active"
              type="checkbox"
              class="w-4 h-4 rounded text-indigo-600 focus:ring-indigo-500 border-slate-300 dark:border-slate-700"
            />
            <label for="edit_is_active" class="text-xs font-bold text-slate-700 dark:text-slate-300 cursor-pointer">
              Active Specialist (Can be assigned new repair orders)
            </label>
          </div>

          <div class="flex justify-end gap-2 pt-3 border-t border-slate-100 dark:border-slate-800/80 shrink-0">
            <button
              type="button"
              @click="showEditModal = false"
              class="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-xl transition cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="savingEdit"
              class="px-4 py-2 text-xs font-bold bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl shadow-md shadow-indigo-600/20 disabled:opacity-50 transition cursor-pointer"
            >
              {{ savingEdit ? 'Saving...' : 'Save Changes' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { technicianApi } from '@/api/endpoints';
import { useToastStore } from '@/stores/toast';
import SearchableSelect from '@/components/common/SearchableSelect.vue';
import WhatsAppIcon from '@/components/common/WhatsAppIcon.vue';

const route = useRoute();
const toast = useToastStore();

const tech = ref({});
const workload = ref({});
const recentJobs = ref([]);
const payments = ref([]);

const loadingJobs = ref(false);
const loadingPayments = ref(false);
const activeTab = ref('jobs');

const showPayModal = ref(false);
const submittingPay = ref(false);
const payForm = ref({
  amount: 0,
  payment_date: new Date().toISOString().split('T')[0],
  payment_method: 'cash',
  notes: '',
});

const showEditModal = ref(false);
const savingEdit = ref(false);
const editForm = ref({
  name: '',
  mobile: '',
  specialization: '',
  is_active: true,
});

const paymentMethodOptions = [
  { value: 'cash', label: 'Cash', icon: '💵' },
  { value: 'upi', label: 'UPI / PhonePe / GPay', icon: '⚡' },
  { value: 'bank_transfer', label: 'Bank Transfer', icon: '🏦' },
  { value: 'card', label: 'Debit / Credit Card', icon: '💳' },
  { value: 'other', label: 'Other', icon: '📋' },
];

const cleanedPhone = computed(() => {
  const p = tech.value.mobile || tech.value.phone;
  if (!p) return '';
  return String(p).replace(/[^0-9]/g, '').slice(-10);
});

function formatAmount(amt) {
  return (Number(amt) || 0).toLocaleString('en-IN');
}

function formatDate(d) {
  if (!d) return '-';
  const date = new Date(d);
  if (isNaN(date.getTime())) return '-';
  return date.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
}

function getDeviceName(job) {
  if (job.device?.brand || job.device?.model) {
    return `${job.device.brand || ''} ${job.device.model || ''}`.trim();
  }
  return job.device_brand || job.device_model || 'Device Repair';
}

function getStatusBadgeClass(status) {
  const s = String(status || '').toLowerCase();
  if (s.includes('delivered') || s.includes('completed')) {
    return 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-900/40';
  }
  if (s.includes('ready')) {
    return 'bg-teal-50 dark:bg-teal-950/40 text-teal-600 dark:text-teal-400 border border-teal-200 dark:border-teal-900/40';
  }
  if (s.includes('repairing') || s.includes('progress')) {
    return 'bg-indigo-50 dark:bg-indigo-950/40 text-indigo-600 dark:text-indigo-400 border border-indigo-200 dark:border-indigo-900/40';
  }
  if (s.includes('waiting')) {
    return 'bg-amber-50 dark:bg-amber-950/40 text-amber-600 dark:text-amber-400 border border-amber-200 dark:border-amber-900/40';
  }
  return 'bg-blue-50 dark:bg-blue-950/40 text-blue-600 dark:text-blue-400 border border-blue-200 dark:border-blue-900/40';
}

async function fetchDetails() {
  loadingJobs.value = true;
  try {
    const res = await technicianApi.get(route.params.id);
    const data = res.data?.data || res.data || {};
    tech.value = data;
    workload.value = data.workload || {};
    recentJobs.value = data.recent_jobs || [];
  } catch (err) {
    console.error('Failed to load technician details:', err);
    toast.error('Could not load technician details.');
  } finally {
    loadingJobs.value = false;
  }
}

async function fetchPayments() {
  loadingPayments.value = true;
  try {
    const res = await technicianApi.payments(route.params.id);
    const data = res.data?.data;
    if (data?.data && Array.isArray(data.data)) {
      payments.value = data.data;
    } else if (Array.isArray(data)) {
      payments.value = data;
    } else {
      payments.value = [];
    }
    if (res.data?.summary) {
      workload.value = { ...workload.value, ...res.data.summary };
    }
  } catch (err) {
    console.error('Failed to load technician payments:', err);
  } finally {
    loadingPayments.value = false;
  }
}

function openPayModal() {
  payForm.value = {
    amount: Number(workload.value.total_payable) > 0 ? Number(workload.value.total_payable) : '',
    payment_date: new Date().toISOString().split('T')[0],
    payment_method: 'cash',
    notes: '',
  };
  showPayModal.value = true;
}

async function submitPayout() {
  if (!payForm.value.amount || Number(payForm.value.amount) <= 0) {
    toast.warning('Please enter a valid payout amount.');
    return;
  }
  submittingPay.value = true;
  try {
    await technicianApi.addPayment(tech.value.id, {
      technician_id: tech.value.id,
      amount: payForm.value.amount,
      payment_date: payForm.value.payment_date,
      payment_method: payForm.value.payment_method,
      notes: payForm.value.notes,
    });
    toast.success(`Recorded ₹${formatAmount(payForm.value.amount)} payout to ${tech.value.name}!`);
    showPayModal.value = false;
    await Promise.all([fetchDetails(), fetchPayments()]);
  } catch (err) {
    console.error('Failed to record payout:', err);
    toast.error(err.response?.data?.message || 'Failed to record payout.');
  } finally {
    submittingPay.value = false;
  }
}

async function deletePayout(p) {
  const confirmed = await toast.confirm(
    `Are you sure you want to delete this payout of ₹${formatAmount(p.amount)} recorded on ${formatDate(p.payment_date)}?`
  );
  if (!confirmed) return;

  try {
    await technicianApi.deletePayment(tech.value.id, p.id);
    toast.success('Payout record deleted.');
    await Promise.all([fetchDetails(), fetchPayments()]);
  } catch (err) {
    console.error('Failed to delete payment:', err);
    toast.error(err.response?.data?.message || 'Failed to delete payment.');
  }
}

function openEditModal() {
  editForm.value = {
    name: tech.value.name || '',
    mobile: tech.value.mobile || tech.value.phone || '',
    specialization: tech.value.specialization || '',
    is_active: tech.value.is_active !== false,
  };
  showEditModal.value = true;
}

async function submitEdit() {
  if (!editForm.value.name?.trim()) {
    toast.warning('Please enter technician name.');
    return;
  }
  savingEdit.value = true;
  try {
    await technicianApi.update(tech.value.id, editForm.value);
    toast.success('Technician profile updated successfully!');
    showEditModal.value = false;
    fetchDetails();
  } catch (err) {
    console.error('Failed to update technician:', err);
    toast.error(err.response?.data?.message || 'Failed to update technician.');
  } finally {
    savingEdit.value = false;
  }
}

onMounted(() => {
  fetchDetails();
  fetchPayments();
});
</script>
