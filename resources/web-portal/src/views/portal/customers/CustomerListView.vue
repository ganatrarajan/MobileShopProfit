<template>
  <div class="space-y-6">
    <!-- Header Actions -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <div class="flex items-center gap-2">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 border border-indigo-200/60 dark:border-indigo-800/60">
            Clientele
          </span>
          <span class="text-xs text-slate-400">Profiles, Dues & Repair Records</span>
        </div>
        <h1 class="text-2xl font-bold tracking-tight text-slate-900 dark:text-white mt-1">Customer Accounts Directory</h1>
        <p class="text-xs sm:text-sm text-slate-500 dark:text-slate-400">View customer profiles, contact directories, repair histories, and outstanding dues.</p>
      </div>
      <button
        @click="openCreateModal"
        type="button"
        class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold shadow-md shadow-indigo-600/20 transition-all hover:scale-[1.02] active:scale-[0.98] cursor-pointer"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" d="M12 4v16m8-8H4"/></svg>
        + Add Customer
      </button>
    </div>

    <!-- 3 Summary Metrics Cards (Matching Mobile App Customer Directory) -->
    <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
      <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 shadow-xs">
        <div class="flex items-center justify-between">
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">Total Registered Customers</p>
          <div class="w-9 h-9 rounded-xl bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 flex items-center justify-center">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
          </div>
        </div>
        <p class="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white mt-2 tabular-nums">
          {{ totalCount }}
        </p>
        <p class="text-[11px] text-slate-400 mt-1">Verified shop client accounts</p>
      </div>

      <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 shadow-xs">
        <div class="flex items-center justify-between">
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">Total Pending Dues (Udhar)</p>
          <div class="w-9 h-9 rounded-xl bg-rose-500/10 text-rose-600 dark:text-rose-400 flex items-center justify-center">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
          </div>
        </div>
        <p class="text-2xl sm:text-3xl font-black text-rose-600 dark:text-rose-400 mt-2 tabular-nums">
          ₹{{ formatAmount(totalPendingDues) }}
        </p>
        <p class="text-[11px] text-slate-400 mt-1">Total outstanding across all accounts</p>
      </div>

      <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 shadow-xs">
        <div class="flex items-center justify-between">
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">Total Jobs & Orders</p>
          <div class="w-9 h-9 rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/></svg>
          </div>
        </div>
        <p class="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white mt-2 tabular-nums">
          {{ totalCompletedJobs }}
        </p>
        <p class="text-[11px] text-slate-400 mt-1">Service repairs and sales billed</p>
      </div>
    </div>

    <!-- Search & Filter Bar -->
    <div class="bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-2xl p-4 shadow-sm flex flex-col md:flex-row gap-3 items-stretch md:items-center justify-between">
      <div class="relative flex-1">
        <span class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
        </span>
        <input
          v-model="searchQuery"
          @input="debounceSearch"
          type="text"
          class="w-full pl-10 pr-4 py-2 text-xs font-semibold bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 dark:focus:border-indigo-400 transition-all placeholder-slate-400 text-slate-800 dark:text-slate-100"
          placeholder="Search customer by name, mobile, city, address..."
        />
      </div>

      <div class="flex items-center gap-2">
        <SearchableSelect
          v-model="sortBy"
          :options="sortOptions"
          @change="currentPage = 1; fetchCustomers()"
          placeholder="Sort By"
          minWidth="180px"
          :searchable="false"
        />

        <button
          v-if="searchQuery || sortBy !== 'newest'"
          @click="searchQuery = ''; sortBy = 'newest'; currentPage = 1; fetchCustomers()"
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
        <table class="w-full text-left border-collapse text-xs">
          <thead>
            <tr class="border-b border-slate-100 dark:border-slate-800/80 text-[11px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider bg-slate-50/60 dark:bg-slate-900/40">
              <th class="py-3.5 px-4 pl-6">Customer</th>
              <th class="py-3.5 px-4">Contact</th>
              <th class="py-3.5 px-4">Address / City</th>
              <th class="py-3.5 px-4">Created Date</th>
              <th class="py-3.5 px-4 text-center">Total Jobs</th>
              <th class="py-3.5 px-4 text-right">Khata / Due</th>
              <th class="py-3.5 px-4 pr-6 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100 dark:divide-slate-800/60 font-medium">
            <tr v-if="loading">
              <td colspan="7" class="py-12 text-center text-xs text-slate-400">
                <div class="inline-block animate-spin w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full mb-2"></div>
                <div>Loading customer profiles...</div>
              </td>
            </tr>
            <tr v-else-if="customers.length === 0">
              <td colspan="7" class="py-12 text-center text-slate-400 dark:text-slate-500 text-xs">
                No customers found. Click "+ Add Customer" to create one.
              </td>
            </tr>
            <tr
              v-for="c in customers"
              :key="c.id"
              class="hover:bg-slate-50/70 dark:hover:bg-slate-800/40 transition-colors group"
            >
              <!-- Customer Column -->
              <td class="py-3.5 px-4 pl-6">
                <div class="flex items-center gap-3">
                  <div class="w-9 h-9 rounded-xl bg-indigo-50 dark:bg-indigo-950/50 border border-indigo-200/80 dark:border-indigo-800 text-indigo-700 dark:text-indigo-400 font-extrabold text-xs flex items-center justify-center flex-shrink-0">
                    {{ (c.name || 'C').substring(0, 1).toUpperCase() }}
                  </div>
                  <div>
                    <router-link
                      :to="`/customers/${c.id}`"
                      class="font-bold text-slate-900 dark:text-white hover:text-indigo-600 dark:hover:text-indigo-400 transition"
                    >
                      {{ c.name }}
                    </router-link>
                    <div class="text-[10px] text-slate-400 font-mono">ID #{{ c.id }}</div>
                  </div>
                </div>
              </td>

              <!-- Contact Column -->
              <td class="py-3.5 px-4">
                <div class="font-semibold text-slate-800 dark:text-slate-200 font-mono flex items-center gap-1.5">
                  <span>{{ c.mobile || c.phone || '-' }}</span>
                  <a
                    v-if="c.mobile || c.phone"
                    :href="`https://wa.me/91${String(c.mobile || c.phone).replace(/[^0-9]/g, '').slice(-10)}`"
                    target="_blank"
                    class="p-1 rounded-md bg-emerald-50 hover:bg-emerald-100 dark:bg-emerald-950/50 dark:hover:bg-emerald-900/50 text-emerald-600 dark:text-emerald-400 border border-emerald-200/60 dark:border-emerald-800/60 transition inline-flex items-center justify-center cursor-pointer"
                    title="Chat on WhatsApp"
                  >
                    <WhatsAppIcon sizeClass="w-3.5 h-3.5" />
                  </a>
                </div>
                <div v-if="c.alternate_mobile" class="text-[11px] text-slate-400 font-mono">Alt: {{ c.alternate_mobile }}</div>
                <div v-if="c.email" class="text-[11px] text-slate-400 truncate max-w-[180px]">{{ c.email }}</div>
              </td>

              <!-- Address / City Column -->
              <td class="py-3.5 px-4">
                <div class="font-bold text-slate-800 dark:text-slate-200">{{ c.city || 'Local' }}</div>
                <div v-if="c.address" class="text-[11px] text-slate-400 truncate max-w-xs">{{ c.address }}</div>
              </td>

              <!-- Created Date Column -->
              <td class="py-3.5 px-4 whitespace-nowrap text-slate-600 dark:text-slate-400">
                <span class="font-medium text-xs">📅 {{ formatDate(c.created_at) }}</span>
              </td>

              <!-- Total Jobs Column (Actual live counts) -->
              <td class="py-3.5 px-4 text-center">
                <div class="inline-flex flex-col items-center">
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-extrabold bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700/60">
                    {{ (c.repairs_count || 0) + (c.sales_count || 0) }} Jobs
                  </span>
                  <span class="text-[10px] text-slate-400 mt-0.5 font-medium">
                    {{ c.repairs_count || 0 }} Repairs • {{ c.sales_count || 0 }} Sales
                  </span>
                </div>
              </td>

              <!-- Khata / Balance Column -->
              <td class="py-3.5 px-4 text-right font-mono">
                <span
                  v-if="Number(c.total_due) > 0"
                  class="inline-block px-2 py-0.5 rounded-md text-[11px] font-bold text-rose-600 dark:text-rose-400 bg-rose-50 dark:bg-rose-950/50 border border-rose-200/80 dark:border-rose-900/40"
                >
                  Due: ₹{{ formatAmount(c.total_due) }}
                </span>
                <span
                  v-else
                  class="inline-block px-2 py-0.5 rounded-md text-[11px] font-semibold text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/50"
                >
                  All Clear
                </span>
              </td>

              <!-- Actions Column -->
              <td class="py-3.5 px-4 pr-6 text-right whitespace-nowrap">
                <div class="flex items-center justify-end gap-1">
                  <!-- Quick Add Device for this customer -->
                  <button
                    @click="openAddDeviceForCustomer(c)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-500 hover:text-purple-600 hover:bg-purple-50 dark:hover:bg-slate-800 transition cursor-pointer"
                    title="Register / Add Customer Device"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 9v6m3-3H9"/></svg>
                  </button>

                  <!-- Ledger / View Details -->
                  <router-link
                    :to="`/customers/${c.id}`"
                    class="p-1.5 rounded-lg text-slate-500 hover:text-indigo-600 hover:bg-indigo-50 dark:hover:bg-slate-800 transition"
                    title="View Customer Ledger & History"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                  </router-link>

                  <!-- Edit Profile -->
                  <button
                    @click="editCustomer(c)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-500 hover:text-amber-600 hover:bg-amber-50 dark:hover:bg-slate-800 transition cursor-pointer"
                    title="Edit Customer Profile"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
                  </button>

                  <!-- Delete Profile -->
                  <button
                    @click="confirmDeleteCustomer(c)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/40 transition cursor-pointer"
                    title="Delete Customer Profile"
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

    <!-- ========================================================================= -->
    <!-- ADD / EDIT CUSTOMER MODAL (Full parity with Flutter AddCustomerScreen)    -->
    <!-- ========================================================================= -->
    <div
      v-if="modalOpen"
      class="fixed inset-0 z-50 overflow-y-auto flex min-h-full items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm py-6 sm:py-10"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-[#111827] w-full max-w-lg rounded-2xl shadow-2xl border border-slate-200/80 dark:border-slate-800/80 overflow-hidden my-auto max-h-[calc(100vh-3rem)] flex flex-col animate-in fade-in zoom-in-95">
        <div class="px-6 py-4 border-b border-slate-100 dark:border-slate-800/80 flex justify-between items-center bg-slate-50/50 dark:bg-slate-900/30 shrink-0">
          <div>
            <h3 class="text-sm font-bold text-slate-900 dark:text-white">{{ editingId ? 'Edit Customer Profile' : 'Add New Customer Profile' }}</h3>
            <p class="text-[11px] text-slate-400">Save client details for invoices, repairs, khata ledger, and device tracking</p>
          </div>
          <button @click="modalOpen = false" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition cursor-pointer">✕</button>
        </div>

        <form @submit.prevent="saveCustomer" class="p-6 space-y-4 overflow-y-auto custom-scroll flex-1">
          <!-- Full Name -->
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Full Name <span class="text-rose-500">*</span></label>
            <input v-model="form.name" type="text" required class="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400" placeholder="e.g. Rahul Sharma" />
          </div>

          <!-- Primary Mobile & Alternate Mobile Row -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Primary Mobile <span class="text-rose-500">*</span></label>
              <input
                v-model="form.mobile"
                type="tel"
                maxlength="10"
                required
                class="w-full px-3 py-2 text-xs font-mono bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400"
                placeholder="10-digit number"
              />
            </div>
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Alternate Mobile / WhatsApp</label>
              <input
                v-model="form.alternate_mobile"
                type="tel"
                maxlength="10"
                class="w-full px-3 py-2 text-xs font-mono bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400"
                placeholder="Optional 10-digit"
              />
            </div>
          </div>

          <!-- Email & City Row -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Email Address</label>
              <input v-model="form.email" type="email" class="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400" placeholder="customer@gmail.com" />
            </div>
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">City / Town</label>
              <input v-model="form.city" type="text" class="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400" placeholder="e.g. Rajkot, Ahmedabad" />
            </div>
          </div>

          <!-- Address -->
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Street / Shop Address</label>
            <input v-model="form.address" type="text" class="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400" placeholder="Building, Street, Area" />
          </div>

          <!-- Customer Notes -->
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Customer Notes / Preferences</label>
            <textarea
              v-model="form.notes"
              rows="2"
              class="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400"
              placeholder="e.g. Regular VIP client, prefers WhatsApp updates..."
            ></textarea>
          </div>

          <!-- Submit Buttons -->
          <div class="flex justify-end gap-2 pt-3 border-t border-slate-100 dark:border-slate-800/80 shrink-0">
            <button type="button" @click="modalOpen = false" class="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-xl transition cursor-pointer">Cancel</button>
            <button
              type="submit"
              :disabled="saving"
              class="px-4 py-2 text-xs font-semibold text-white bg-indigo-600 hover:bg-indigo-500 rounded-xl shadow-md shadow-indigo-600/20 disabled:opacity-50 transition cursor-pointer"
            >
              {{ saving ? 'Saving...' : (editingId ? 'Update Customer' : 'Save Customer') }}
            </button>
          </div>
        </form>
      </div>
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
        <h3 class="text-base font-bold text-slate-900 dark:text-white">Delete Customer Profile?</h3>
        <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
          Are you sure you want to delete <span class="font-bold text-slate-700 dark:text-slate-300">{{ customerToDelete?.name }}</span>?
        </p>
        <div class="flex items-center justify-center gap-2 mt-5">
          <button
            @click="deleteModalOpen = false"
            class="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition cursor-pointer"
          >
            Cancel
          </button>
          <button
            @click="executeDeleteCustomer"
            :disabled="deleting"
            class="px-4 py-2 rounded-xl text-xs font-semibold bg-rose-600 hover:bg-rose-500 text-white shadow-md shadow-rose-600/20 disabled:opacity-50 transition cursor-pointer"
          >
            {{ deleting ? 'Deleting...' : 'Yes, Delete' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Customer Device Modal (Matching Mobile App) -->
    <CustomerDeviceModal
      :is-open="deviceModalOpen"
      :customer="selectedCustomerForDevice"
      @close="deviceModalOpen = false"
      @saved="fetchCustomers"
    />
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue';
import { useToastStore } from '@/stores/toast';
import { customerApi } from '@/api/endpoints';
import PaginationBar from '@/components/common/PaginationBar.vue';
import WhatsAppIcon from '@/components/common/WhatsAppIcon.vue';
import CustomerDeviceModal from '@/components/customers/CustomerDeviceModal.vue';
import SearchableSelect from '@/components/common/SearchableSelect.vue';
import { formatDate } from '@/utils/date';

const toast = useToastStore();

const customers = ref([]);
const loading = ref(false);
const searchQuery = ref('');
const sortBy = ref('newest');
const currentPage = ref(1);
const totalPages = ref(1);
const totalCount = ref(0);
const perPage = ref(15);
let searchTimer = null;

const sortOptions = [
  { value: 'newest', label: 'Newest First (Recent)' },
  { value: 'oldest', label: 'Oldest First' },
  { value: 'name_asc', label: 'Name (A to Z)' },
  { value: 'name_desc', label: 'Name (Z to A)' },
];

// Add Device Modal State
const deviceModalOpen = ref(false);
const selectedCustomerForDevice = ref(null);

function openAddDeviceForCustomer(c) {
  selectedCustomerForDevice.value = c;
  deviceModalOpen.value = true;
}

const modalOpen = ref(false);
const editingId = ref(null);
const saving = ref(false);

const deleteModalOpen = ref(false);
const customerToDelete = ref(null);
const deleting = ref(false);

const form = reactive({
  name: '',
  mobile: '',
  alternate_mobile: '',
  email: '',
  city: '',
  address: '',
  notes: '',
});

// Computed Metrics across loaded customers
const totalPendingDues = computed(() => {
  return customers.value.reduce((acc, c) => acc + (Number(c.total_due) || 0), 0);
});

const totalCompletedJobs = computed(() => {
  return customers.value.reduce((acc, c) => acc + ((Number(c.repairs_count) || 0) + (Number(c.sales_count) || 0)), 0);
});

function debounceSearch() {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => {
    currentPage.value = 1;
    fetchCustomers();
  }, 350);
}

async function fetchCustomers() {
  loading.value = true;
  try {
    const res = await customerApi.list({
      page: currentPage.value,
      per_page: perPage.value,
      search: searchQuery.value || undefined,
      sort: sortBy.value,
    });
    const payload = res.data?.data;
    if (payload?.data) {
      customers.value = payload.data;
      currentPage.value = payload.current_page || 1;
      totalCount.value = payload.total || payload.data.length;
      totalPages.value = payload.last_page || Math.max(1, Math.ceil(totalCount.value / perPage.value));
      if (payload.per_page) perPage.value = payload.per_page;
    } else if (res.data?.meta) {
      customers.value = Array.isArray(payload) ? payload : [];
      currentPage.value = res.data.meta.current_page || 1;
      totalCount.value = res.data.meta.total || customers.value.length;
      totalPages.value = res.data.meta.last_page || Math.max(1, Math.ceil(totalCount.value / perPage.value));
      if (res.data.meta.per_page) perPage.value = res.data.meta.per_page;
    } else {
      customers.value = Array.isArray(payload) ? payload : [];
      totalCount.value = customers.value.length;
      totalPages.value = Math.max(1, Math.ceil(customers.value.length / perPage.value));
    }
  } catch (err) {
    console.error('Failed to load customers:', err);
  } finally {
    loading.value = false;
  }
}

function changePage(p) {
  currentPage.value = p;
  fetchCustomers();
}

function formatAmount(amt) {
  return (Number(amt) || 0).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function openCreateModal() {
  editingId.value = null;
  Object.assign(form, {
    name: '',
    mobile: '',
    alternate_mobile: '',
    email: '',
    city: '',
    address: '',
    notes: '',
  });
  modalOpen.value = true;
}

function editCustomer(c) {
  editingId.value = c.id;
  Object.assign(form, {
    name: c.name || '',
    mobile: c.mobile || c.phone || '',
    alternate_mobile: c.alternate_mobile || '',
    email: c.email || '',
    city: c.city || '',
    address: c.address || '',
    notes: c.notes || '',
  });
  modalOpen.value = true;
}

async function saveCustomer() {
  if (!form.name.trim()) {
    toast.error('Please enter customer full name.', 'Validation Error');
    return;
  }
  const cleanMobile = form.mobile.trim().replace(/\D/g, '');
  if (cleanMobile.length !== 10) {
    toast.error('Please enter a valid 10-digit Indian mobile number.', 'Validation Error');
    return;
  }

  saving.value = true;
  try {
    const payload = {
      name: form.name.trim(),
      mobile: cleanMobile,
      alternate_mobile: form.alternate_mobile?.trim() || null,
      email: form.email?.trim() || null,
      city: form.city?.trim() || null,
      address: form.address?.trim() || null,
      notes: form.notes?.trim() || null,
    };

    if (editingId.value) {
      await customerApi.update(editingId.value, payload);
      toast.success(`Customer "${form.name}" updated successfully!`, 'Customer Updated');
    } else {
      await customerApi.create(payload);
      toast.success(`Customer "${form.name}" added successfully!`, 'Customer Added');
    }
    modalOpen.value = false;
    fetchCustomers();
  } catch (err) {
    if (err.response?.status === 409) {
      toast.error('A customer with this mobile number already exists in your shop.', 'Duplicate Customer');
    } else {
      const msg = err.response?.data?.message || (err.response?.data?.errors ? Object.values(err.response.data.errors).flat().join(' ') : 'Failed to save customer');
      toast.error(msg, 'Save Customer Failed');
    }
  } finally {
    saving.value = false;
  }
}

function confirmDeleteCustomer(c) {
  customerToDelete.value = c;
  deleteModalOpen.value = true;
}

async function executeDeleteCustomer() {
  if (!customerToDelete.value) return;
  deleting.value = true;
  try {
    const deletedName = customerToDelete.value.name;
    await customerApi.delete(customerToDelete.value.id);
    deleteModalOpen.value = false;
    customerToDelete.value = null;
    toast.success(`Customer "${deletedName}" deleted successfully.`, 'Customer Deleted');
    fetchCustomers();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to delete customer';
    toast.error(msg, 'Delete Customer Failed');
  } finally {
    deleting.value = false;
  }
}

onMounted(() => {
  fetchCustomers();
});
</script>
