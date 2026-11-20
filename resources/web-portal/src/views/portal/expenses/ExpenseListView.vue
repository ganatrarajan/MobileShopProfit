<template>
  <div class="space-y-6">
    <!-- Header Actions -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <div class="flex items-center gap-2">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-rose-50 dark:bg-rose-950/60 text-rose-600 dark:text-rose-400 border border-rose-200/60 dark:border-rose-800/60">
            Overheads
          </span>
          <span class="text-xs text-slate-400">Rent, Electricity, Tea, Tools, Maintenance</span>
        </div>
        <h1 class="text-2xl font-black tracking-tight text-slate-900 dark:text-white mt-1">Shop Expense Tracker (Kharcha)</h1>
        <p class="text-xs sm:text-sm text-slate-500 dark:text-slate-400">Record and track daily shop running costs to calculate accurate net profit margins.</p>
      </div>
      <div class="flex items-center gap-2.5">
        <button
          @click="openCategoryModal"
          type="button"
          class="inline-flex items-center justify-center gap-2 px-3.5 py-2.5 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 hover:border-indigo-500 text-slate-700 dark:text-slate-200 text-xs font-bold shadow-xs transition-all cursor-pointer"
        >
          <svg class="w-4 h-4 text-indigo-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"/></svg>
          + Category
        </button>
        <button
          @click="openAddModal"
          type="button"
          class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold shadow-md shadow-indigo-600/20 transition-all hover:scale-[1.02] active:scale-[0.98] cursor-pointer"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" d="M12 4v16m8-8H4"/></svg>
          + Add Expense
        </button>
      </div>
    </div>

    <!-- 3 Summary Metrics Cards (Matching Mobile App Expenses Header) -->
    <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
      <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 shadow-xs">
        <div class="flex items-center justify-between">
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">Total Expenses ({{ filterStore.periodDisplayLabel }})</p>
          <div class="w-9 h-9 rounded-xl bg-rose-500/10 text-rose-600 dark:text-rose-400 flex items-center justify-center">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
          </div>
        </div>
        <p class="text-2xl sm:text-3xl font-black text-rose-600 dark:text-rose-400 mt-2 tabular-nums">
          ₹{{ formatAmount(totalExpensesSum) }}
        </p>
        <p class="text-[11px] text-slate-400 mt-1">Aggregated expenditure recorded</p>
      </div>

      <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 shadow-xs">
        <div class="flex items-center justify-between">
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">Total Entries</p>
          <div class="w-9 h-9 rounded-xl bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 flex items-center justify-center">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/></svg>
          </div>
        </div>
        <p class="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white mt-2 tabular-nums">
          {{ totalCount }}
        </p>
        <p class="text-[11px] text-slate-400 mt-1">Expense entries logged</p>
      </div>

      <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 shadow-xs">
        <div class="flex items-center justify-between">
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">Categories in Use</p>
          <div class="w-9 h-9 rounded-xl bg-purple-500/10 text-purple-600 dark:text-purple-400 flex items-center justify-center">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"/></svg>
          </div>
        </div>
        <p class="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white mt-2 tabular-nums">
          {{ categories.length }}
        </p>
        <p class="text-[11px] text-slate-400 mt-1">Available overhead categories</p>
      </div>
    </div>

    <!-- Search & Filter Bar -->
    <div class="relative z-20 bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-2xl p-4 shadow-sm flex flex-col lg:flex-row gap-3 items-stretch lg:items-center justify-between">
      <div class="relative flex-1">
        <span class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
        </span>
        <input
          v-model="searchQuery"
          @input="debounceSearch"
          type="text"
          class="w-full pl-10 pr-4 py-2 text-xs font-semibold bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 dark:focus:border-indigo-400 transition-all placeholder-slate-400 text-slate-800 dark:text-slate-100"
          placeholder="Search expenses by title, notes, or ref #..."
        />
      </div>

      <div class="flex flex-wrap items-center gap-2">
        <!-- Category Filter -->
        <SearchableSelect
          v-model="selectedCategory"
          :options="categoryFilterOptions"
          @change="onCategoryChange"
          placeholder="All Categories"
          searchPlaceholder="Search category..."
          minWidth="170px"
        />

        <!-- Date Preset Filter (Synced globally with Dashboard) -->
        <SearchableSelect
          v-model="filterStore.selectedPeriod"
          :options="filterStore.periodOptions"
          @change="onPeriodChange"
          placeholder="Select Period"
          searchPlaceholder="Search period..."
          minWidth="140px"
        />

        <!-- Sort Filter -->
        <SearchableSelect
          v-model="sortBy"
          :options="sortOptions"
          @change="onSortChange"
          placeholder="Sort Expenses"
          searchPlaceholder="Search sort..."
          minWidth="150px"
          prefixIcon="↕️"
        />

        <button
          v-if="searchQuery || selectedCategory !== 'all' || filterStore.selectedPeriod !== 'this_month' || sortBy !== 'newest'"
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
        <table class="w-full text-left border-collapse text-xs">
          <thead>
            <tr class="border-b border-slate-100 dark:border-slate-800/80 text-[11px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider bg-slate-50/60 dark:bg-slate-900/40">
              <th class="py-3.5 px-4 pl-6">Date</th>
              <th class="py-3.5 px-4">Category</th>
              <th class="py-3.5 px-4">Title / Note</th>
              <th class="py-3.5 px-4">Payment Mode</th>
              <th class="py-3.5 px-4 text-right">Amount (₹)</th>
              <th class="py-3.5 px-4 pr-6 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100 dark:divide-slate-800/60 font-medium">
            <tr v-if="loading">
              <td colspan="6" class="py-12 text-center text-xs text-slate-400">
                <div class="inline-block animate-spin w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full mb-2"></div>
                <div>Loading expense records...</div>
              </td>
            </tr>
            <tr v-else-if="expenses.length === 0">
              <td colspan="6" class="py-12 text-center text-slate-400 dark:text-slate-500 text-xs">
                No expenses found matching the criteria.
                <div class="mt-2">
                  <button @click="openAddModal" class="text-indigo-600 dark:text-indigo-400 font-bold hover:underline">Record first expense →</button>
                </div>
              </td>
            </tr>
            <tr v-for="exp in expenses" :key="exp.id" class="hover:bg-slate-50/70 dark:hover:bg-slate-800/40 transition-colors group">
              <!-- Date -->
              <td class="py-3.5 px-4 pl-6 text-slate-500 whitespace-nowrap">
                {{ formatDate(exp.expense_date || exp.created_at) }}
              </td>

              <!-- Category -->
              <td class="py-3.5 px-4">
                <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-bold bg-indigo-50 dark:bg-indigo-950/50 text-indigo-700 dark:text-indigo-300 border border-indigo-200/80 dark:border-indigo-900/50">
                  <span class="w-1.5 h-1.5 rounded-full bg-indigo-500"></span>
                  {{ exp.category?.name || 'General Overheads' }}
                </span>
              </td>

              <!-- Title / Note / Ref # -->
              <td class="py-3.5 px-4 max-w-xs">
                <div class="font-bold text-slate-900 dark:text-white flex items-center gap-2">
                  <span>{{ exp.title || 'Expense' }}</span>
                  <span
                    v-if="exp.is_recurring"
                    class="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-semibold bg-purple-50 text-purple-700 dark:bg-purple-950/50 dark:text-purple-300 border border-purple-200/80 dark:border-purple-900/50"
                  >
                    🔁 {{ exp.recurrence_type || 'Recurring' }}
                  </span>
                </div>
                <div v-if="exp.notes" class="text-[11px] text-slate-400 truncate mt-0.5">{{ exp.notes }}</div>
                <div v-if="exp.reference_number" class="text-[10px] font-mono text-slate-400 mt-0.5">Ref: #{{ exp.reference_number }}</div>
              </td>

              <!-- Payment Mode -->
              <td class="py-3.5 px-4 whitespace-nowrap">
                <span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-lg text-xs font-semibold bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300">
                  <span>{{ getPaymentMethodIcon(exp.payment_method) }}</span>
                  <span>{{ getPaymentMethodLabel(exp.payment_method) }}</span>
                </span>
              </td>

              <!-- Amount -->
              <td class="py-3.5 px-4 text-right font-mono font-black text-rose-600 dark:text-rose-400 tabular-nums">
                ₹{{ formatAmount(exp.amount) }}
              </td>

              <!-- Actions (Edit & Delete) -->
              <td class="py-3.5 px-4 pr-6 text-right whitespace-nowrap">
                <div class="inline-flex items-center gap-1">
                  <!-- Edit Button -->
                  <button
                    @click="openEditModal(exp)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-400 hover:text-indigo-600 hover:bg-indigo-50 dark:hover:bg-indigo-950/40 transition cursor-pointer"
                    title="Edit Expense"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
                  </button>

                  <!-- Delete Button -->
                  <button
                    @click="confirmDeleteExpense(exp)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/40 transition cursor-pointer"
                    title="Delete Expense"
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
    <!-- ADD / EDIT EXPENSE MODAL (Full parity with Flutter AddEditExpenseScreen)   -->
    <!-- ========================================================================= -->
    <div
      v-if="showModal"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 overflow-y-auto flex min-h-full items-center justify-center p-4 py-6 sm:py-10"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-[#111827] w-full max-w-lg rounded-2xl shadow-2xl border border-slate-200/80 dark:border-slate-800/80 overflow-hidden my-auto max-h-[calc(100vh-3rem)] flex flex-col animate-in fade-in zoom-in-95">
        <!-- Modal Header -->
        <div class="px-6 py-4 border-b border-slate-100 dark:border-slate-800/80 flex justify-between items-center bg-slate-50/50 dark:bg-slate-900/30 shrink-0">
          <div>
            <h3 class="text-sm font-bold text-slate-900 dark:text-white">
              {{ isEditing ? 'Edit Expense Record' : 'Record Shop Expense (Kharcha)' }}
            </h3>
            <p class="text-[11px] text-slate-400">
              {{ isEditing ? 'Update overhead details and cost' : 'Log overhead payment into shop financial book' }}
            </p>
          </div>
          <button @click="showModal = false" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 text-sm font-bold cursor-pointer">✕</button>
        </div>

        <!-- Modal Form Body -->
        <form @submit.prevent="submitExpense" class="p-6 space-y-4 overflow-y-auto custom-scroll flex-1">
          <!-- Category Selection with Quick Add Category Link -->
          <div>
            <div class="flex items-center justify-between mb-1.5">
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
                Expense Category <span class="text-rose-500">*</span>
              </label>
              <button
                @click="openCategoryModal"
                type="button"
                class="text-xs font-bold text-indigo-600 dark:text-indigo-400 hover:underline cursor-pointer"
              >
                + Add Custom Category
              </button>
            </div>
            <SearchableSelect
              v-model="form.category_id"
              :options="formCategoryOptions"
              placeholder="Select Category"
              searchPlaceholder="Search category (e.g. Rent, Salary, Tea)..."
              minWidth="100%"
            />
          </div>

          <!-- Expense Title -->
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Expense Title <span class="text-rose-500">*</span>
            </label>
            <input
              v-model="form.title"
              type="text"
              class="w-full px-3 py-2 text-xs font-medium bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400"
              placeholder="e.g. Shop Rent Nov, Chai / Tea, Soldering Wire, Electricity Bill"
              required
            />
          </div>

          <!-- Amount & Expense Date Row -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Amount (₹) <span class="text-rose-500">*</span>
              </label>
              <input
                v-model.number="form.amount"
                type="number"
                step="0.01"
                min="0.01"
                class="w-full px-3 py-2 text-xs font-bold bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400"
                placeholder="0.00"
                required
              />
            </div>
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Expense Date <span class="text-rose-500">*</span>
              </label>
              <DatePicker v-model="form.expense_date" required />
            </div>
          </div>

          <!-- Payment Method & Reference Number Row -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Payment Method
              </label>
              <SearchableSelect
                v-model="form.payment_method"
                :options="paymentMethodOptions"
                placeholder="Select Payment Method"
                minWidth="100%"
              />
            </div>
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Reference / Txn # (Optional)
              </label>
              <input
                v-model="form.reference_number"
                type="text"
                class="w-full px-3 py-2 text-xs font-medium bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400"
                placeholder="e.g. UTR-12849, Chq #0023"
              />
            </div>
          </div>

          <!-- Recurring Expense Checkbox -->
          <div class="p-3 rounded-xl bg-slate-50 dark:bg-slate-900/50 border border-slate-200/60 dark:border-slate-800/60 space-y-2">
            <label class="flex items-center gap-2 cursor-pointer">
              <input
                v-model="form.is_recurring"
                type="checkbox"
                class="w-4 h-4 rounded text-indigo-600 focus:ring-indigo-500 border-slate-300 dark:border-slate-700"
              />
              <span class="text-xs font-bold text-slate-700 dark:text-slate-200">
                🔁 Recurring Expense (Monthly / Yearly)
              </span>
            </label>
            <div v-if="form.is_recurring" class="pl-6 pt-1">
              <label class="block text-[11px] font-semibold text-slate-400 mb-1">Recurrence Cycle</label>
              <select
                v-model="form.recurrence_type"
                class="px-3 py-1.5 text-xs bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-lg text-slate-800 dark:text-slate-200"
              >
                <option value="monthly">Monthly (Rent, Electricity, Internet)</option>
                <option value="yearly">Yearly (License, Domain, Insurance)</option>
              </select>
            </div>
          </div>

          <!-- Notes / Description -->
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Description / Notes (Optional)
            </label>
            <textarea
              v-model="form.notes"
              rows="2"
              class="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400"
              placeholder="Add optional notes, payee details, or specifics..."
            ></textarea>
          </div>

          <!-- Submit Buttons -->
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
              class="px-4 py-2 text-xs font-semibold text-white bg-indigo-600 hover:bg-indigo-500 rounded-xl shadow-md shadow-indigo-600/20 disabled:opacity-50 transition cursor-pointer"
            >
              {{ saving ? (isEditing ? 'Updating...' : 'Recording...') : (isEditing ? 'Update Expense' : 'Record Expense') }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- ========================================================================= -->
    <!-- QUICK ADD CUSTOM CATEGORY MODAL (Matching Mobile App Category Modal)       -->
    <!-- ========================================================================= -->
    <div
      v-if="showCategoryModal"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 overflow-y-auto flex min-h-full items-center justify-center p-4 py-6"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-2xl w-full max-w-sm shadow-2xl p-6 animate-in fade-in zoom-in-95">
        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-2">
            <span class="w-8 h-8 rounded-xl bg-indigo-500/10 text-indigo-600 flex items-center justify-center">
              🏷️
            </span>
            <h3 class="text-sm font-bold text-slate-900 dark:text-white">Add Custom Category</h3>
          </div>
          <button @click="showCategoryModal = false" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 text-sm font-bold cursor-pointer">✕</button>
        </div>

        <form @submit.prevent="submitCategory" class="space-y-4">
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Category Name <span class="text-rose-500">*</span>
            </label>
            <input
              v-model="newCategoryName"
              type="text"
              class="w-full px-3 py-2 text-xs font-medium bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400"
              placeholder="e.g. Tea & Snacks, Courier, Packaging"
              required
              autofocus
            />
          </div>

          <div class="flex items-center justify-end gap-2 pt-2">
            <button
              @click="showCategoryModal = false"
              type="button"
              class="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="savingCategory"
              class="px-4 py-2 rounded-xl text-xs font-semibold bg-indigo-600 hover:bg-indigo-500 text-white shadow-md shadow-indigo-600/20 disabled:opacity-50 transition cursor-pointer"
            >
              {{ savingCategory ? 'Adding...' : 'Add Category' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- ========================================================================= -->
    <!-- DELETE CONFIRMATION MODAL                                                 -->
    <!-- ========================================================================= -->
    <div
      v-if="deleteModalOpen"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 overflow-y-auto flex min-h-full items-center justify-center p-4 py-6"
      @wheel.stop
    >
      <div class="bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-2xl w-full max-w-sm shadow-2xl p-6 text-center animate-in fade-in zoom-in-95">
        <div class="w-12 h-12 rounded-full bg-rose-50 dark:bg-rose-950/60 text-rose-600 dark:text-rose-400 flex items-center justify-center mx-auto mb-3">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
        </div>
        <h3 class="text-base font-bold text-slate-900 dark:text-white">Delete Expense Record?</h3>
        <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
          Are you sure you want to delete expense <span class="font-bold text-slate-700 dark:text-slate-300">"{{ expenseToDelete?.title }}"</span> of ₹{{ formatAmount(expenseToDelete?.amount) }}?
        </p>
        <div class="flex items-center justify-center gap-2 mt-5">
          <button
            @click="deleteModalOpen = false"
            class="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition cursor-pointer"
          >
            Cancel
          </button>
          <button
            @click="executeDeleteExpense"
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
import { useFilterStore } from '@/stores/filter';
import { useToastStore } from '@/stores/toast';
import { expenseApi, expenseCategoryApi } from '@/api/endpoints';
import PaginationBar from '@/components/common/PaginationBar.vue';
import SearchableSelect from '@/components/common/SearchableSelect.vue';
import DatePicker from '@/components/common/DatePicker.vue';
import { formatDate, toInputDate } from '@/utils/date';

const filterStore = useFilterStore();
const toast = useToastStore();

// Payment Methods matching mobile app
const paymentMethodOptions = [
  { value: 'cash', label: 'Cash', icon: '💵' },
  { value: 'upi', label: 'UPI / GPay / PhonePe', icon: '⚡' },
  { value: 'bank_transfer', label: 'Bank Transfer (NEFT/RTGS)', icon: '🏦' },
  { value: 'card', label: 'Debit / Credit Card', icon: '💳' },
  { value: 'other', label: 'Other', icon: '📝' },
];

function getPaymentMethodLabel(method) {
  const map = {
    cash: 'Cash',
    upi: 'UPI',
    bank_transfer: 'Bank Transfer',
    card: 'Card',
    other: 'Other',
  };
  return map[method] || method || 'Cash';
}

function getPaymentMethodIcon(method) {
  const map = {
    cash: '💵',
    upi: '⚡',
    bank_transfer: '🏦',
    card: '💳',
    other: '📝',
  };
  return map[method] || '💵';
}

const expenses = ref([]);
const categories = ref([]);
const loading = ref(false);
const saving = ref(false);
const searchQuery = ref('');
const selectedCategory = ref('all');
const sortBy = ref('newest');
const sortOptions = [
  { value: 'newest', label: 'Newest First (Recent)' },
  { value: 'oldest', label: 'Oldest First' },
  { value: 'amount_high', label: 'Amount (High to Low)' },
  { value: 'amount_low', label: 'Amount (Low to High)' },
];

const totalExpensesSum = ref(0);
const totalCount = ref(0);
const currentPage = ref(1);
const totalPages = ref(1);
const perPage = ref(15);
let searchTimer = null;

// Modal States
const showModal = ref(false);
const isEditing = ref(false);
const editingId = ref(null);

const showCategoryModal = ref(false);
const newCategoryName = ref('');
const savingCategory = ref(false);

const deleteModalOpen = ref(false);
const expenseToDelete = ref(null);
const deleting = ref(false);

// Form State (Matching Flutter AddEditExpenseScreen model)
const form = reactive({
  category_id: null,
  title: '',
  amount: null,
  expense_date: toInputDate(new Date()),
  payment_method: 'cash',
  reference_number: '',
  notes: '',
  is_recurring: false,
  recurrence_type: 'monthly',
});

// Category Filter Options
const categoryFilterOptions = computed(() => {
  return [
    { value: 'all', label: 'All Categories' },
    ...categories.value.map((c) => ({
      value: String(c.id),
      label: c.name + (c.is_system_default ? '' : ' (Custom)'),
    })),
  ];
});

// Form Category Options
const formCategoryOptions = computed(() => {
  return categories.value.map((c) => ({
    value: c.id,
    label: c.name + (c.is_system_default ? '' : ' (Custom)'),
  }));
});

function debounceSearch() {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => {
    currentPage.value = 1;
    fetchExpenses();
  }, 350);
}

function onCategoryChange() {
  currentPage.value = 1;
  fetchExpenses();
}

function onSortChange() {
  currentPage.value = 1;
  fetchExpenses();
}

function onPeriodChange() {
  filterStore.setPeriod(filterStore.selectedPeriod);
  currentPage.value = 1;
  fetchExpenses();
}

function resetFilters() {
  searchQuery.value = '';
  selectedCategory.value = 'all';
  sortBy.value = 'newest';
  filterStore.setPeriod('this_month');
  currentPage.value = 1;
  fetchExpenses();
}

// Fetch Categories
async function fetchCategories() {
  try {
    const res = await expenseCategoryApi.list();
    const data = res.data?.data || res.data || [];
    categories.value = Array.isArray(data) ? data : [];
  } catch (err) {
    console.error('Failed to load expense categories:', err);
  }
}

// Fetch Expenses
async function fetchExpenses() {
  loading.value = true;
  try {
    const periodVal = filterStore.selectedPeriod;
    const params = {
      page: currentPage.value,
      per_page: perPage.value,
      search: searchQuery.value || undefined,
      category_id: selectedCategory.value !== 'all' ? selectedCategory.value : undefined,
      period: periodVal !== 'all_time' ? periodVal : undefined,
      sort: sortBy.value || 'newest',
    };

    const res = await expenseApi.list(params);
    const payload = res.data?.data;

    if (payload?.data) {
      expenses.value = payload.data;
      currentPage.value = payload.current_page || 1;
      totalCount.value = payload.total || payload.data.length;
      totalPages.value = payload.last_page || Math.max(1, Math.ceil(totalCount.value / perPage.value));
      if (payload.per_page) perPage.value = payload.per_page;
    } else if (res.data?.meta) {
      expenses.value = Array.isArray(payload) ? payload : [];
      currentPage.value = res.data.meta.current_page || 1;
      totalCount.value = res.data.meta.total || expenses.value.length;
      totalPages.value = res.data.meta.last_page || Math.max(1, Math.ceil(totalCount.value / perPage.value));
      if (res.data.meta.per_page) perPage.value = res.data.meta.per_page;
    } else {
      expenses.value = Array.isArray(payload) ? payload : [];
      totalCount.value = expenses.value.length;
      totalPages.value = Math.max(1, Math.ceil(expenses.value.length / perPage.value));
    }

    if (res.data?.metrics) {
      totalExpensesSum.value = Number(res.data.metrics.total_expenses_sum) || 0;
      totalCount.value = Number(res.data.metrics.total_count) || expenses.value.length;
    } else {
      totalExpensesSum.value = expenses.value.reduce((acc, it) => acc + (Number(it.amount) || 0), 0);
    }
  } catch (err) {
    console.error('Failed to load expenses:', err);
  } finally {
    loading.value = false;
  }
}

function changePage(p) {
  currentPage.value = p;
  fetchExpenses();
}

function formatAmount(amt) {
  return (Number(amt) || 0).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}


// Open Add Modal
function openAddModal() {
  isEditing.value = false;
  editingId.value = null;
  form.category_id = categories.value.length > 0 ? categories.value[0].id : null;
  form.title = '';
  form.amount = null;
  form.expense_date = toInputDate(new Date());
  form.payment_method = 'cash';
  form.reference_number = '';
  form.notes = '';
  form.is_recurring = false;
  form.recurrence_type = 'monthly';
  showModal.value = true;
}

// Open Edit Modal
function openEditModal(exp) {
  isEditing.value = true;
  editingId.value = exp.id;
  form.category_id = exp.category_id || (exp.category?.id ?? (categories.value[0]?.id || null));
  form.title = exp.title || '';
  form.amount = exp.amount ? Number(exp.amount) : null;
  form.expense_date = toInputDate(exp.expense_date || exp.created_at, true);
  form.payment_method = exp.payment_method || 'cash';
  form.reference_number = exp.reference_number || '';
  form.notes = exp.notes || '';
  form.is_recurring = Boolean(exp.is_recurring);
  form.recurrence_type = exp.recurrence_type || 'monthly';
  showModal.value = true;
}

// Submit Expense (Create or Update)
async function submitExpense() {
  if (!form.category_id) {
    toast.error('Please select an expense category.', 'Validation Error');
    return;
  }
  if (!form.title.trim()) {
    toast.error('Please enter an expense title.', 'Validation Error');
    return;
  }
  if (!form.amount || Number(form.amount) <= 0) {
    toast.error('Please enter a valid amount greater than 0.', 'Validation Error');
    return;
  }

  saving.value = true;
  try {
    const payload = {
      category_id: form.category_id,
      title: form.title.trim(),
      amount: Number(form.amount),
      expense_date: form.expense_date,
      payment_method: form.payment_method || 'cash',
      reference_number: form.reference_number?.trim() || null,
      notes: form.notes?.trim() || null,
      is_recurring: form.is_recurring,
      recurrence_type: form.is_recurring ? form.recurrence_type : null,
    };

    if (isEditing.value && editingId.value) {
      await expenseApi.update(editingId.value, payload);
      toast.success(`Expense "${form.title}" updated successfully!`, 'Expense Updated');
    } else {
      await expenseApi.create(payload);
      toast.success(`Expense "${form.title}" of ₹${formatAmount(form.amount)} recorded!`, 'Expense Recorded');
    }

    showModal.value = false;
    fetchExpenses();
  } catch (err) {
    const msg = err.response?.data?.message || (err.response?.data?.errors ? Object.values(err.response.data.errors).flat().join(' ') : 'Failed to save expense');
    toast.error(msg, 'Save Expense Failed');
  } finally {
    saving.value = false;
  }
}

// Quick Add Category Modal
function openCategoryModal() {
  newCategoryName.value = '';
  showCategoryModal.value = true;
}

async function submitCategory() {
  const name = newCategoryName.value.trim();
  if (!name) return;

  savingCategory.value = true;
  try {
    const res = await expenseCategoryApi.create({ name });
    const createdCat = res.data?.data || res.data;
    await fetchCategories();

    if (createdCat?.id) {
      form.category_id = createdCat.id;
    }

    showCategoryModal.value = false;
    newCategoryName.value = '';
    toast.success(`Category "${name}" added successfully!`, 'Category Created');
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to create category';
    toast.error(msg, 'Category Error');
  } finally {
    savingCategory.value = false;
  }
}

// Delete Expense
function confirmDeleteExpense(exp) {
  expenseToDelete.value = exp;
  deleteModalOpen.value = true;
}

async function executeDeleteExpense() {
  if (!expenseToDelete.value) return;
  deleting.value = true;
  try {
    const expTitle = expenseToDelete.value.title;
    await expenseApi.delete(expenseToDelete.value.id);
    deleteModalOpen.value = false;
    expenseToDelete.value = null;
    toast.success(`Expense "${expTitle}" deleted successfully.`, 'Expense Deleted');
    fetchExpenses();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to delete expense';
    toast.error(msg, 'Delete Expense Failed');
  } finally {
    deleting.value = false;
  }
}

onMounted(async () => {
  await fetchCategories();
  fetchExpenses();
});
</script>
