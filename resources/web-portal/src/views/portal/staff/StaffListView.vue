<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <div class="flex items-center gap-2">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 border border-indigo-200/60 dark:border-indigo-800/60">
            Access Control & Team
          </span>
          <span class="text-xs text-slate-400">Mobile App & Web Logins</span>
        </div>
        <h2 class="text-2xl font-bold tracking-tight text-slate-900 dark:text-white mt-1">Staff Directory & Logins</h2>
        <p class="text-sm text-slate-500 dark:text-slate-400">Manage team members, mobile app access permissions, salaries and login credentials</p>
      </div>
      <button
        @click="openAddModal"
        class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold shadow-md shadow-indigo-600/20 transition-all hover:scale-[1.02] active:scale-[0.98] cursor-pointer"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
        </svg>
        <span>+ Add Staff Member</span>
      </button>
    </div>

    <!-- Top Summary Metric Cards -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
      <!-- Total Staff -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-xs flex items-center gap-3.5">
        <div class="w-12 h-12 rounded-xl bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 flex items-center justify-center shrink-0 border border-indigo-100 dark:border-indigo-900/40">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
          </svg>
        </div>
        <div class="min-w-0">
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Total Staff</p>
          <h3 class="text-xl font-black text-slate-900 dark:text-white mt-0.5">{{ summaryStats.totalStaff }}</h3>
          <p class="text-[11px] text-slate-400 truncate">Registered team</p>
        </div>
      </div>

      <!-- Active Logins -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-xs flex items-center gap-3.5">
        <div class="w-12 h-12 rounded-xl bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center shrink-0 border border-emerald-100 dark:border-emerald-900/40">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
          </svg>
        </div>
        <div class="min-w-0">
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Active Logins</p>
          <div class="flex items-baseline gap-1 mt-0.5">
            <h3 class="text-xl font-black text-slate-900 dark:text-white">{{ summaryStats.activeLogins }}</h3>
            <span v-if="summaryStats.maxAllowed > 0" class="text-xs font-bold text-slate-400">/ {{ summaryStats.maxAllowed }}</span>
          </div>
          <p class="text-[11px] text-emerald-600 dark:text-emerald-400 font-semibold truncate">
            {{ summaryStats.maxAllowed > 0 ? `${summaryStats.maxAllowed - summaryStats.activeLogins} slots left` : 'App login enabled' }}
          </p>
        </div>
      </div>

      <!-- Inactive / Disabled -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-xs flex items-center gap-3.5">
        <div class="w-12 h-12 rounded-xl bg-amber-50 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 flex items-center justify-center shrink-0 border border-amber-100 dark:border-amber-900/40">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
          </svg>
        </div>
        <div class="min-w-0">
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Disabled Logins</p>
          <h3 class="text-xl font-black text-slate-900 dark:text-white mt-0.5">{{ summaryStats.inactiveStaff }}</h3>
          <p class="text-[11px] text-slate-400 truncate">Access blocked</p>
        </div>
      </div>

      <!-- Monthly Payroll -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-xs flex items-center gap-3.5">
        <div class="w-12 h-12 rounded-xl bg-purple-50 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400 flex items-center justify-center shrink-0 border border-purple-100 dark:border-purple-900/40">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z" />
          </svg>
        </div>
        <div class="min-w-0">
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Monthly Payroll</p>
          <h3 class="text-xl font-black text-slate-900 dark:text-white mt-0.5 truncate">₹{{ summaryStats.payroll.toLocaleString('en-IN') }}</h3>
          <p class="text-[11px] text-slate-400 truncate">Active staff salaries</p>
        </div>
      </div>
    </div>

    <!-- Filter & Search Bar -->
    <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-sm flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
      <!-- Search Input -->
      <div class="relative flex-1">
        <svg class="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
        <input
          v-model="search"
          type="text"
          placeholder="Search by name, mobile, or designation..."
          class="w-full pl-10 pr-4 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-slate-800 dark:text-slate-100 placeholder-slate-400"
        />
        <button
          v-if="search"
          @click="search = ''"
          class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 text-xs cursor-pointer"
        >
          ✕
        </button>
      </div>

      <!-- Status Filter -->
      <div class="w-full sm:w-56 shrink-0">
        <SearchableSelect
          v-model="statusFilter"
          :options="statusOptions"
          placeholder="Filter Status"
          :searchable="false"
          :fullWidth="true"
        />
      </div>
    </div>

    <!-- Staff Table Card -->
    <div class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800/80 shadow-sm overflow-hidden">
      <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="border-b border-slate-100 dark:border-slate-800/80 bg-slate-50/60 dark:bg-slate-900/40 text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              <th class="py-3.5 px-4 pl-6">Staff Member</th>
              <th class="py-3.5 px-4">Login & Password</th>
              <th class="py-3.5 px-4">Permitted Modules</th>
              <th class="py-3.5 px-4">Salary & Joining</th>
              <th class="py-3.5 px-4">Login Status</th>
              <th class="py-3.5 px-4 pr-6 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100 dark:divide-slate-800/60 text-sm">
            <tr v-if="loading">
              <td colspan="6" class="text-center py-16 text-slate-400">
                <div class="inline-block animate-spin w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full mb-2"></div>
                <div>Loading staff directory...</div>
              </td>
            </tr>
            <tr v-else-if="filteredStaff.length === 0">
              <td colspan="6" class="text-center py-16 text-slate-400 dark:text-slate-500">
                <div class="max-w-xs mx-auto text-center space-y-2">
                  <div class="w-12 h-12 rounded-2xl bg-slate-100 dark:bg-slate-800 flex items-center justify-center mx-auto text-slate-400">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                  </div>
                  <p class="font-bold text-slate-700 dark:text-slate-300">No staff members found</p>
                  <p class="text-xs text-slate-400">Add an employee account or adjust your filter query.</p>
                </div>
              </td>
            </tr>
            <tr
              v-for="s in paginatedStaff"
              :key="s.id"
              class="hover:bg-slate-50/70 dark:hover:bg-slate-800/40 transition group"
            >
              <!-- Staff Member Column -->
              <td class="py-3.5 px-4 pl-6">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 rounded-xl bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 font-bold flex items-center justify-center text-sm border border-indigo-200/60 dark:border-indigo-800/60 shrink-0">
                    {{ s.name?.charAt(0)?.toUpperCase() || 'S' }}
                  </div>
                  <div class="min-w-0">
                    <router-link
                      :to="`/staff/${s.id}`"
                      class="font-bold text-slate-900 dark:text-white hover:text-indigo-600 dark:hover:text-indigo-400 transition truncate block"
                    >
                      {{ s.name }}
                    </router-link>
                    <div class="flex items-center gap-1.5 mt-0.5">
                      <span class="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-semibold bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                        {{ s.designation || 'Staff' }}
                      </span>
                      <span v-if="s.email" class="text-[11px] text-slate-400 truncate max-w-[140px]">{{ s.email }}</span>
                    </div>
                  </div>
                </div>
              </td>

              <!-- Login & Password Credentials -->
              <td class="py-3.5 px-4">
                <div class="space-y-1">
                  <!-- Mobile + WhatsApp button -->
                  <div class="flex items-center gap-2">
                    <span class="font-mono text-xs font-semibold text-slate-700 dark:text-slate-200">
                      {{ s.mobile || s.phone || '—' }}
                    </span>
                    <button
                      v-if="s.mobile || s.phone"
                      type="button"
                      @click="shareOnWhatsApp(s)"
                      class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px] font-bold text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/60 hover:bg-emerald-100 dark:hover:bg-emerald-900/60 border border-emerald-200 dark:border-emerald-800 transition cursor-pointer"
                      title="Share credentials on WhatsApp"
                    >
                      <WhatsAppIcon sizeClass="w-3 h-3 text-emerald-600 dark:text-emerald-400" />
                      <span>Share</span>
                    </button>
                  </div>

                  <!-- Password with Reveal & Copy -->
                  <div v-if="s.login_password" class="flex items-center gap-1.5 text-xs">
                    <span class="text-[11px] text-slate-400">Pass:</span>
                    <span class="font-mono text-[11px] px-1.5 py-0.5 rounded bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300">
                      {{ revealedPasswords[s.id] ? s.login_password : '••••••••' }}
                    </span>
                    <button
                      type="button"
                      @click="toggleRevealPassword(s.id)"
                      class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition cursor-pointer"
                      :title="revealedPasswords[s.id] ? 'Hide password' : 'Show password'"
                    >
                      <svg v-if="!revealedPasswords[s.id]" class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                      </svg>
                      <svg v-else class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                      </svg>
                    </button>
                    <button
                      type="button"
                      @click="copyText(s.login_password, 'Password copied!')"
                      class="text-slate-400 hover:text-indigo-600 dark:hover:text-indigo-400 transition cursor-pointer"
                      title="Copy password"
                    >
                      <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                      </svg>
                    </button>
                  </div>
                  <div v-else class="text-[11px] text-slate-400 italic">
                    Password encrypted
                  </div>
                </div>
              </td>

              <!-- Permitted Modules Badges -->
              <td class="py-3.5 px-4">
                <div class="flex flex-wrap gap-1 max-w-[240px]">
                  <span
                    v-if="s.permissions?.sales"
                    class="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-semibold bg-emerald-50 dark:bg-emerald-950/50 text-emerald-700 dark:text-emerald-400 border border-emerald-200/60 dark:border-emerald-800/60"
                  >
                    🛒 Sales
                  </span>
                  <span
                    v-if="s.permissions?.repairs"
                    class="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-semibold bg-indigo-50 dark:bg-indigo-950/50 text-indigo-700 dark:text-indigo-400 border border-indigo-200/60 dark:border-indigo-800/60"
                  >
                    🔧 Repairs
                  </span>
                  <span
                    v-if="s.permissions?.purchases"
                    class="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-semibold bg-blue-50 dark:bg-blue-950/50 text-blue-700 dark:text-blue-400 border border-blue-200/60 dark:border-blue-800/60"
                  >
                    📦 Stock
                  </span>
                  <span
                    v-if="s.permissions?.expenses"
                    class="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-semibold bg-amber-50 dark:bg-amber-950/50 text-amber-700 dark:text-amber-400 border border-amber-200/60 dark:border-amber-800/60"
                  >
                    💰 Expenses
                  </span>
                  <span
                    v-if="s.permissions?.used_mobiles"
                    class="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-semibold bg-purple-50 dark:bg-purple-950/50 text-purple-700 dark:text-purple-400 border border-purple-200/60 dark:border-purple-800/60"
                  >
                    📱 Used
                  </span>
                  <span
                    v-if="!hasAnyPermission(s)"
                    class="text-[11px] text-slate-400 italic"
                  >
                    No modules
                  </span>
                </div>
              </td>

              <!-- Salary & Joining Date -->
              <td class="py-3.5 px-4">
                <div class="text-xs">
                  <div class="font-bold text-slate-800 dark:text-slate-200">
                    {{ s.salary ? `₹${Number(s.salary).toLocaleString('en-IN')}/mo` : '—' }}
                  </div>
                  <div class="text-[11px] text-slate-400 mt-0.5">
                    {{ s.joining_date ? `Joined: ${s.joining_date}` : 'Date not set' }}
                  </div>
                </div>
              </td>

              <!-- Login Status & Toggle -->
              <td class="py-3.5 px-4">
                <button
                  type="button"
                  @click="toggleStatus(s)"
                  :class="s.is_active
                    ? 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-400 border-emerald-200 dark:border-emerald-800 hover:bg-emerald-100'
                    : 'bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-400 border-rose-200 dark:border-rose-800 hover:bg-rose-100'"
                  class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold border transition cursor-pointer"
                  :title="s.is_active ? 'Click to disable login' : 'Click to activate login'"
                >
                  <span class="w-1.5 h-1.5 rounded-full" :class="s.is_active ? 'bg-emerald-500 animate-pulse' : 'bg-rose-500'"></span>
                  <span>{{ s.is_active ? 'Active' : 'Disabled' }}</span>
                </button>
              </td>

              <!-- Actions -->
              <td class="py-3.5 px-4 pr-6 text-right">
                <div class="flex items-center justify-end gap-1.5">
                  <router-link
                    :to="`/staff/${s.id}`"
                    class="p-1.5 rounded-lg text-slate-400 hover:text-indigo-600 hover:bg-indigo-50 dark:hover:bg-indigo-950/40 transition cursor-pointer"
                    title="View Full Profile"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                    </svg>
                  </router-link>
                  <button
                    @click="openEditModal(s)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-400 hover:text-amber-600 hover:bg-amber-50 dark:hover:bg-amber-950/40 transition cursor-pointer"
                    title="Edit Staff Member"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                    </svg>
                  </button>
                  <button
                    @click="confirmDeleteStaff(s)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/40 transition cursor-pointer"
                    title="Delete Staff Account"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                    </svg>
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
        :total="filteredStaff.length"
        :per-page="perPage"
        @page-change="onPageChange"
      />
    </div>

    <!-- Add / Edit Staff Modal -->
    <div
      v-if="showModal"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-3 sm:p-5"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-2xl w-full max-w-xl shadow-2xl max-h-[85vh] flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-200">
        <!-- Modal Header -->
        <div class="px-6 py-4 border-b border-slate-100 dark:border-slate-800/80 flex justify-between items-center bg-slate-50/50 dark:bg-slate-900/30 shrink-0">
          <div>
            <h3 class="font-bold text-slate-900 dark:text-white">
              {{ editingStaffId ? 'Edit Staff Member' : 'Add New Staff Member' }}
            </h3>
            <p class="text-xs text-slate-400">Configure profile, credentials & mobile app permissions</p>
          </div>
          <button @click="closeModal" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition cursor-pointer">✕</button>
        </div>

        <!-- Modal Form Body -->
        <form @submit.prevent="saveStaff" class="p-6 space-y-5 overflow-y-auto custom-scroll flex-1">
          <!-- Role Quick Presets (Only on create or optional switch) -->
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-2">
              Role Preset (Auto-fill Permissions)
            </label>
            <div class="grid grid-cols-2 sm:grid-cols-4 gap-2">
              <button
                type="button"
                v-for="preset in rolePresets"
                :key="preset.id"
                @click="applyRolePreset(preset)"
                :class="selectedPreset === preset.id
                  ? 'border-indigo-600 bg-indigo-50 dark:bg-indigo-950/50 text-indigo-700 dark:text-indigo-300 ring-1 ring-indigo-500'
                  : 'border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 hover:border-slate-300'"
                class="px-2.5 py-2 rounded-xl border text-xs font-semibold flex flex-col items-center justify-center gap-1 transition cursor-pointer text-center"
              >
                <span>{{ preset.icon }}</span>
                <span class="truncate w-full">{{ preset.name }}</span>
              </button>
            </div>
          </div>

          <!-- Basic Info (Name & Mobile) -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Full Name <span class="text-rose-500">*</span>
              </label>
              <input
                v-model="form.name"
                type="text"
                class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400"
                placeholder="e.g. Ramesh Patel"
                required
              />
            </div>
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Login Mobile <span class="text-rose-500">*</span>
              </label>
              <input
                v-model="form.mobile"
                type="tel"
                maxlength="10"
                class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400 font-mono"
                placeholder="10-digit mobile number"
                required
              />
            </div>
          </div>

          <!-- Login Password -->
          <div>
            <div class="flex items-center justify-between mb-1.5">
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
                Login Password <span v-if="!editingStaffId" class="text-rose-500">*</span>
              </label>
              <button
                type="button"
                @click="generateRandomPassword"
                class="text-xs font-bold text-indigo-600 dark:text-indigo-400 hover:underline cursor-pointer"
              >
                ⚡ Generate Random
              </button>
            </div>
            <div class="relative">
              <input
                v-model="form.password"
                :type="showPasswordInModal ? 'text' : 'password'"
                class="w-full pl-3 pr-10 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400 font-mono"
                :placeholder="editingStaffId ? 'Leave blank to keep unchanged' : 'At least 6 characters'"
                :required="!editingStaffId"
              />
              <button
                type="button"
                @click="showPasswordInModal = !showPasswordInModal"
                class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 cursor-pointer"
              >
                <svg v-if="!showPasswordInModal" class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                </svg>
                <svg v-else class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                </svg>
              </button>
            </div>
          </div>

          <!-- Designation & Email -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Designation / Title
              </label>
              <input
                v-model="form.designation"
                type="text"
                class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400"
                placeholder="e.g. Sales Executive, Cashier"
              />
            </div>
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Email Address (Optional)
              </label>
              <input
                v-model="form.email"
                type="email"
                class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400"
                placeholder="e.g. staff@shop.com"
              />
            </div>
          </div>

          <!-- Salary & Joining Date -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Monthly Salary (₹)
              </label>
              <input
                v-model="form.salary"
                type="number"
                min="0"
                step="500"
                class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400"
                placeholder="e.g. 15000"
              />
            </div>
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Joining Date
              </label>
              <input
                v-model="form.joining_date"
                type="date"
                class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100"
              />
            </div>
          </div>

          <!-- Module Permissions (5 Granular Toggles) -->
          <div>
            <div class="flex items-center justify-between mb-2">
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
                Mobile App Access Permissions
              </label>
              <span class="text-[11px] text-slate-400">Control features in staff app</span>
            </div>
            <div class="space-y-2 bg-slate-50/70 dark:bg-slate-900/40 p-3 rounded-2xl border border-slate-200/80 dark:border-slate-800/80">
              <!-- Sales -->
              <label class="flex items-center justify-between p-2 rounded-xl bg-white dark:bg-slate-800 border border-slate-200/60 dark:border-slate-700/60 cursor-pointer hover:border-emerald-300 transition">
                <div class="flex items-center gap-2.5">
                  <span class="text-base">🛒</span>
                  <div>
                    <p class="text-xs font-bold text-slate-800 dark:text-slate-100">Sales & Billing (POS)</p>
                    <p class="text-[10px] text-slate-400">Create invoices, manage sales & receipts</p>
                  </div>
                </div>
                <input
                  v-model="form.permissions.sales"
                  type="checkbox"
                  class="w-4 h-4 rounded text-indigo-600 focus:ring-indigo-500 border-slate-300 dark:border-slate-600"
                />
              </label>

              <!-- Repairs -->
              <label class="flex items-center justify-between p-2 rounded-xl bg-white dark:bg-slate-800 border border-slate-200/60 dark:border-slate-700/60 cursor-pointer hover:border-indigo-300 transition">
                <div class="flex items-center gap-2.5">
                  <span class="text-base">🔧</span>
                  <div>
                    <p class="text-xs font-bold text-slate-800 dark:text-slate-100">Repair Jobs & Diagnostics</p>
                    <p class="text-[10px] text-slate-400">Job cards, intake, diagnostic status & delivery</p>
                  </div>
                </div>
                <input
                  v-model="form.permissions.repairs"
                  type="checkbox"
                  class="w-4 h-4 rounded text-indigo-600 focus:ring-indigo-500 border-slate-300 dark:border-slate-600"
                />
              </label>

              <!-- Inventory -->
              <label class="flex items-center justify-between p-2 rounded-xl bg-white dark:bg-slate-800 border border-slate-200/60 dark:border-slate-700/60 cursor-pointer hover:border-blue-300 transition">
                <div class="flex items-center gap-2.5">
                  <span class="text-base">📦</span>
                  <div>
                    <p class="text-xs font-bold text-slate-800 dark:text-slate-100">Stock & Purchases</p>
                    <p class="text-[10px] text-slate-400">View products, inventory stock & supplier purchases</p>
                  </div>
                </div>
                <input
                  v-model="form.permissions.purchases"
                  type="checkbox"
                  class="w-4 h-4 rounded text-indigo-600 focus:ring-indigo-500 border-slate-300 dark:border-slate-600"
                />
              </label>

              <!-- Expenses -->
              <label class="flex items-center justify-between p-2 rounded-xl bg-white dark:bg-slate-800 border border-slate-200/60 dark:border-slate-700/60 cursor-pointer hover:border-amber-300 transition">
                <div class="flex items-center gap-2.5">
                  <span class="text-base">💰</span>
                  <div>
                    <p class="text-xs font-bold text-slate-800 dark:text-slate-100">Shop Expenses</p>
                    <p class="text-[10px] text-slate-400">Record petty cash, store expenses & daily overheads</p>
                  </div>
                </div>
                <input
                  v-model="form.permissions.expenses"
                  type="checkbox"
                  class="w-4 h-4 rounded text-indigo-600 focus:ring-indigo-500 border-slate-300 dark:border-slate-600"
                />
              </label>

              <!-- Used Mobiles -->
              <label class="flex items-center justify-between p-2 rounded-xl bg-white dark:bg-slate-800 border border-slate-200/60 dark:border-slate-700/60 cursor-pointer hover:border-purple-300 transition">
                <div class="flex items-center gap-2.5">
                  <span class="text-base">📱</span>
                  <div>
                    <p class="text-xs font-bold text-slate-800 dark:text-slate-100">Used Mobiles (Buy / Sell)</p>
                    <p class="text-[10px] text-slate-400">Second-hand phone intake, refurbishment & resale</p>
                  </div>
                </div>
                <input
                  v-model="form.permissions.used_mobiles"
                  type="checkbox"
                  class="w-4 h-4 rounded text-indigo-600 focus:ring-indigo-500 border-slate-300 dark:border-slate-600"
                />
              </label>
            </div>
          </div>

          <!-- Active Account Checkbox -->
          <div class="pt-1">
            <label class="flex items-center gap-2.5 cursor-pointer">
              <input
                v-model="form.is_active"
                type="checkbox"
                class="w-4 h-4 rounded text-indigo-600 focus:ring-indigo-500 border-slate-300 dark:border-slate-600"
              />
              <span class="text-xs font-semibold text-slate-700 dark:text-slate-300">
                Staff member is active and allowed to log in
              </span>
            </label>
          </div>

          <!-- Footer Actions -->
          <div class="flex justify-end gap-2 pt-4 border-t border-slate-100 dark:border-slate-800/80 shrink-0">
            <button
              type="button"
              @click="closeModal"
              class="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-xl transition cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="saving"
              class="px-5 py-2 text-xs font-semibold text-white bg-indigo-600 hover:bg-indigo-500 rounded-xl shadow-md shadow-indigo-600/20 disabled:opacity-50 transition cursor-pointer"
            >
              {{ saving ? 'Saving...' : (editingStaffId ? 'Update Staff Member' : 'Create Staff Login') }}
            </button>
          </div>
        </form>
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
        <h3 class="text-base font-bold text-slate-900 dark:text-white">Delete Staff Account?</h3>
        <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
          Are you sure you want to delete <span class="font-bold text-slate-700 dark:text-slate-300">{{ staffToDelete?.name }}</span>? Their app login will be immediately revoked.
        </p>
        <div class="flex items-center justify-center gap-2 mt-5">
          <button
            @click="deleteModalOpen = false"
            class="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition cursor-pointer"
          >
            Cancel
          </button>
          <button
            @click="executeDeleteStaff"
            :disabled="deleting"
            class="px-4 py-2 rounded-xl text-xs font-semibold bg-rose-600 hover:bg-rose-500 text-white shadow-md shadow-rose-600/20 disabled:opacity-50 transition cursor-pointer"
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
import { useToastStore } from '@/stores/toast';
import { staffApi } from '@/api/endpoints';
import PaginationBar from '@/components/common/PaginationBar.vue';
import SearchableSelect from '@/components/common/SearchableSelect.vue';
import WhatsAppIcon from '@/components/common/WhatsAppIcon.vue';

const toast = useToastStore();

const staffList = ref([]);
const summaryData = ref({});
const loading = ref(false);
const showModal = ref(false);
const editingStaffId = ref(null);
const saving = ref(false);
const search = ref('');
const statusFilter = ref('all');
const showPasswordInModal = ref(false);
const selectedPreset = ref('');

const revealedPasswords = reactive({});

const deleteModalOpen = ref(false);
const staffToDelete = ref(null);
const deleting = ref(false);

const currentPage = ref(1);
const perPage = ref(10);

const statusOptions = [
  { value: 'all', label: 'All Statuses' },
  { value: 'active', label: 'Active Logins Only' },
  { value: 'inactive', label: 'Disabled Logins Only' },
];

const rolePresets = [
  {
    id: 'manager',
    name: 'Manager',
    icon: '👑',
    designation: 'Store Manager',
    permissions: { sales: true, repairs: true, purchases: true, expenses: true, used_mobiles: true }
  },
  {
    id: 'sales',
    name: 'Sales / Billing',
    icon: '🛒',
    designation: 'Sales Executive',
    permissions: { sales: true, repairs: false, purchases: false, expenses: false, used_mobiles: false }
  },
  {
    id: 'service',
    name: 'Service Advisor',
    icon: '🔧',
    designation: 'Service Advisor',
    permissions: { sales: false, repairs: true, purchases: false, expenses: false, used_mobiles: false }
  },
  {
    id: 'cashier',
    name: 'Cashier',
    icon: '💼',
    designation: 'Cashier & Accounts',
    permissions: { sales: true, repairs: false, purchases: false, expenses: true, used_mobiles: false }
  },
];

const form = reactive({
  name: '',
  mobile: '',
  password: '',
  email: '',
  designation: '',
  salary: '',
  joining_date: new Date().toISOString().split('T')[0],
  address: '',
  is_active: true,
  permissions: {
    sales: true,
    repairs: true,
    purchases: false,
    expenses: false,
    used_mobiles: false,
  },
});

async function fetchStaff() {
  loading.value = true;
  try {
    const res = await staffApi.list();
    if (res.data?.success) {
      staffList.value = res.data.data || [];
      summaryData.value = res.data.summary || {};
    } else {
      const payload = res.data?.data;
      staffList.value = payload?.data || (Array.isArray(payload) ? payload : []);
    }
  } catch (err) {
    console.error('Failed to load staff list:', err);
    toast.error('Failed to load staff list', 'Error');
  } finally {
    loading.value = false;
  }
}

const summaryStats = computed(() => {
  const totalStaff = summaryData.value?.total_staff ?? staffList.value.length;
  const activeLogins = summaryData.value?.staff_accounts_used ?? staffList.value.filter(s => s.is_active).length;
  const maxAllowed = summaryData.value?.max_staff_allowed ?? 0;
  const inactiveStaff = staffList.value.filter(s => !s.is_active).length;
  const payroll = staffList.value
    .filter(s => s.is_active && s.salary)
    .reduce((sum, s) => sum + Number(s.salary), 0);

  return { totalStaff, activeLogins, maxAllowed, inactiveStaff, payroll };
});

function hasAnyPermission(s) {
  if (!s.permissions) return false;
  return Object.values(s.permissions).some(v => Boolean(v));
}

function toggleRevealPassword(id) {
  revealedPasswords[id] = !revealedPasswords[id];
}

function copyText(text, successMsg = 'Copied to clipboard!') {
  if (!text) return;
  navigator.clipboard.writeText(text).then(() => {
    toast.success(successMsg, 'Copied');
  }).catch(() => {
    toast.info(`Text: ${text}`, 'Copy Info');
  });
}

function shareOnWhatsApp(s) {
  const phone = (s.mobile || s.phone || '').replace(/\D/g, '');
  const passText = s.login_password ? `\n🔑 *Password:* ${s.login_password}` : '';
  const message = `Hello ${s.name} 👋,\n\nHere are your staff login credentials for our store mobile application:\n\n📱 *Mobile / Username:* ${s.mobile || s.phone}${passText}\n\nPlease keep this information secure.\n\nThank you!`;
  const url = `https://wa.me/91${phone}?text=${encodeURIComponent(message)}`;
  window.open(url, '_blank');
}

function generateRandomPassword() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789abcdefghijkmnpqrstuvwxyz';
  let pwd = '';
  for (let i = 0; i < 8; i++) {
    pwd += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  form.password = pwd;
  showPasswordInModal.value = true;
  toast.info(`Generated password: ${pwd}`, 'Password Created');
}

function applyRolePreset(preset) {
  selectedPreset.value = preset.id;
  form.designation = preset.designation;
  form.permissions = { ...preset.permissions };
}

function openAddModal() {
  editingStaffId.value = null;
  selectedPreset.value = '';
  showPasswordInModal.value = false;
  Object.assign(form, {
    name: '',
    mobile: '',
    password: '',
    email: '',
    designation: '',
    salary: '',
    joining_date: new Date().toISOString().split('T')[0],
    address: '',
    is_active: true,
    permissions: {
      sales: true,
      repairs: true,
      purchases: false,
      expenses: false,
      used_mobiles: false,
    },
  });
  showModal.value = true;
}

function openEditModal(s) {
  editingStaffId.value = s.id;
  selectedPreset.value = '';
  showPasswordInModal.value = false;
  Object.assign(form, {
    name: s.name || '',
    mobile: s.mobile || s.phone || '',
    password: '',
    email: s.email || '',
    designation: s.designation || '',
    salary: s.salary || '',
    joining_date: s.joining_date || new Date().toISOString().split('T')[0],
    address: s.address || '',
    is_active: s.is_active ?? true,
    permissions: {
      sales: s.permissions?.sales ?? true,
      repairs: s.permissions?.repairs ?? true,
      purchases: s.permissions?.purchases ?? false,
      expenses: s.permissions?.expenses ?? false,
      used_mobiles: s.permissions?.used_mobiles ?? false,
    },
  });
  showModal.value = true;
}

function closeModal() {
  showModal.value = false;
  editingStaffId.value = null;
}

async function saveStaff() {
  saving.value = true;
  try {
    const payload = {
      name: form.name,
      mobile: form.mobile,
      phone: form.mobile,
      email: form.email || null,
      designation: form.designation || null,
      salary: form.salary ? Number(form.salary) : null,
      joining_date: form.joining_date || null,
      address: form.address || null,
      is_active: form.is_active,
      permissions: form.permissions,
    };
    if (form.password) {
      payload.password = form.password;
    }

    if (editingStaffId.value) {
      await staffApi.update(editingStaffId.value, payload);
      toast.success(`Staff member "${form.name}" updated successfully!`, 'Staff Updated');
    } else {
      await staffApi.create(payload);
      toast.success(`Staff member "${form.name}" created successfully!`, 'Staff Created');
    }

    closeModal();
    fetchStaff();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to save staff account';
    toast.error(msg, 'Save Failed');
  } finally {
    saving.value = false;
  }
}

async function toggleStatus(s) {
  try {
    await staffApi.toggleStatus(s.id);
    toast.success(`Status for "${s.name}" updated!`, 'Status Changed');
    fetchStaff();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to update staff status';
    toast.error(msg, 'Status Update Failed');
  }
}

function confirmDeleteStaff(s) {
  staffToDelete.value = s;
  deleteModalOpen.value = true;
}

async function executeDeleteStaff() {
  if (!staffToDelete.value) return;
  deleting.value = true;
  try {
    const staffName = staffToDelete.value.name;
    await staffApi.delete(staffToDelete.value.id);
    deleteModalOpen.value = false;
    staffToDelete.value = null;
    toast.success(`Staff account "${staffName}" removed.`, 'Staff Deleted');
    fetchStaff();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to delete staff account';
    toast.error(msg, 'Delete Failed');
  } finally {
    deleting.value = false;
  }
}

const filteredStaff = computed(() => {
  let list = staffList.value;

  if (statusFilter.value === 'active') {
    list = list.filter(s => s.is_active);
  } else if (statusFilter.value === 'inactive') {
    list = list.filter(s => !s.is_active);
  }

  if (search.value) {
    const q = search.value.toLowerCase();
    list = list.filter(s =>
      (s.name && s.name.toLowerCase().includes(q)) ||
      (s.phone && s.phone.includes(q)) ||
      (s.mobile && s.mobile.includes(q)) ||
      (s.email && s.email.toLowerCase().includes(q)) ||
      (s.designation && s.designation.toLowerCase().includes(q))
    );
  }
  return list;
});

const totalPages = computed(() => Math.max(1, Math.ceil(filteredStaff.value.length / perPage.value)));

const paginatedStaff = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredStaff.value.slice(start, start + perPage.value);
});

function onPageChange(page) {
  currentPage.value = page;
}

onMounted(() => {
  fetchStaff();
});
</script>
