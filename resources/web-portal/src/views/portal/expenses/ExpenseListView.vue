<template>
  <div class="space-y-6">
    <!-- Header Actions -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <div class="flex items-center gap-2">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-rose-50 dark:bg-rose-950/60 text-rose-600 dark:text-rose-400 border border-rose-200/60 dark:border-rose-800/60">
            Overheads
          </span>
          <span class="text-xs text-slate-400">Rent, Electricity, Tea, Tools</span>
        </div>
        <h1 class="text-2xl font-bold tracking-tight text-slate-900 dark:text-white mt-1">Shop Expense Tracker</h1>
        <p class="text-xs sm:text-sm text-slate-500 dark:text-slate-400">Record daily shop running costs to calculate accurate net profit margins.</p>
      </div>
      <button
        @click="showModal = true"
        type="button"
        class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold shadow-md shadow-indigo-600/20 transition-all hover:scale-[1.02] active:scale-[0.98]"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" d="M12 4v16m8-8H4"/></svg>
        + Add Expense
      </button>
    </div>

    <!-- Search & Filter Bar -->
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
          placeholder="Search expenses by title or category..."
        />
      </div>

      <div class="flex items-center gap-2">
        <!-- Date Preset Filter (Synced globally with Dashboard) -->
        <SearchableSelect
          v-model="filterStore.selectedPeriod"
          :options="filterStore.periodOptions"
          @change="onPeriodChange"
          placeholder="Select Period"
          searchPlaceholder="Search period..."
          minWidth="140px"
        />

        <button
          v-if="searchQuery || filterStore.selectedPeriod !== 'this_month'"
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
              <th class="py-3.5 px-4 pl-6">Date</th>
              <th class="py-3.5 px-4">Category</th>
              <th class="py-3.5 px-4">Title / Note</th>
              <th class="py-3.5 px-4">Payment Mode</th>
              <th class="py-3.5 px-4">Amount</th>
              <th class="py-3.5 px-4 pr-6 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100 dark:divide-slate-800/60 text-sm">
            <tr v-if="loading">
              <td colspan="6" class="py-12 text-center text-xs text-slate-400">
                <div class="inline-block animate-spin w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full mb-2"></div>
                <div>Loading expense records...</div>
              </td>
            </tr>
            <tr v-else-if="expenses.length === 0">
              <td colspan="6" class="py-12 text-center text-slate-400 dark:text-slate-500 text-xs">No expenses found matching criteria.</td>
            </tr>
            <tr v-for="exp in expenses" :key="exp.id" class="hover:bg-slate-50/70 dark:hover:bg-slate-800/40 transition-colors group">
              <td class="py-3.5 px-4 pl-6 text-xs text-slate-400">{{ formatDate(exp.expense_date || exp.created_at) }}</td>
              <td class="py-3.5 px-4">
                <span class="inline-flex items-center px-2 py-0.5 rounded-md text-xs font-semibold bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700/50">
                  {{ exp.category?.name || exp.category_name || 'General Overheads' }}
                </span>
              </td>
              <td class="py-3.5 px-4">
                <div class="font-bold text-slate-900 dark:text-white">{{ exp.title || exp.name || 'Expense' }}</div>
                <div class="text-[11px] text-slate-400">{{ exp.description || '' }}</div>
              </td>
              <td class="py-3.5 px-4 text-xs font-bold uppercase tracking-wider text-slate-600 dark:text-slate-400">
                {{ exp.payment_mode || 'Cash' }}
              </td>
              <td class="py-3.5 px-4 font-extrabold text-rose-600 dark:text-rose-400 tabular-nums">
                ₹{{ formatAmount(exp.amount) }}
              </td>
              <td class="py-3.5 px-4 pr-6 text-right">
                <button
                  @click="confirmDeleteExpense(exp)"
                  type="button"
                  class="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/40 transition cursor-pointer"
                  title="Delete Expense"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                </button>
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

    <!-- Add Expense Modal -->
    <div
      v-if="showModal"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 overflow-y-auto flex min-h-full items-center justify-center p-4 py-6 sm:py-10"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-[#111827] w-full max-w-md rounded-2xl shadow-2xl border border-slate-200/80 dark:border-slate-800/80 overflow-hidden my-auto max-h-[calc(100vh-3rem)] flex flex-col animate-in fade-in zoom-in-95">
        <div class="px-6 py-4 border-b border-slate-100 dark:border-slate-800/80 flex justify-between items-center bg-slate-50/50 dark:bg-slate-900/30 shrink-0">
          <div>
            <h3 class="text-sm font-bold text-slate-900 dark:text-white">Record Shop Expense</h3>
            <p class="text-[11px] text-slate-400">Log overhead payment</p>
          </div>
          <button @click="showModal = false" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 text-sm font-bold cursor-pointer">✕</button>
        </div>
        <form @submit.prevent="saveExpense" class="p-6 space-y-4 overflow-y-auto custom-scroll flex-1">
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Expense Title <span class="text-rose-500">*</span></label>
            <input v-model="form.title" type="text" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400" placeholder="e.g. Shop Rent, Chai / Tea, Soldering Wire" required />
          </div>
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Amount (₹) <span class="text-rose-500">*</span></label>
            <input v-model.number="form.amount" type="number" step="0.01" min="1" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100" required />
          </div>
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Payment Mode</label>
            <SearchableSelect
              v-model="form.payment_mode"
              :options="expensePaymentModes"
              placeholder="Select Mode"
              minWidth="100%"
            />
          </div>
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Description / Note</label>
            <input v-model="form.description" type="text" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400" placeholder="Optional notes" />
          </div>
          <div class="flex justify-end gap-2 pt-3 border-t border-slate-100 dark:border-slate-800/80 shrink-0">
            <button type="button" @click="showModal = false" class="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-xl transition cursor-pointer">Cancel</button>
            <button type="submit" class="px-4 py-2 text-xs font-semibold text-white bg-indigo-600 hover:bg-indigo-500 rounded-xl shadow-md shadow-indigo-600/20 transition cursor-pointer">Record Expense</button>
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
        <h3 class="text-base font-bold text-slate-900 dark:text-white">Delete Expense Record?</h3>
        <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
          Are you sure you want to delete expense <span class="font-bold text-slate-700 dark:text-slate-300">{{ expenseToDelete?.title || expenseToDelete?.name }}</span>?
        </p>
        <div class="flex items-center justify-center gap-2 mt-5">
          <button
            @click="deleteModalOpen = false"
            class="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition"
          >
            Cancel
          </button>
          <button
            @click="executeDeleteExpense"
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
import { useFilterStore } from '@/stores/filter';
import { useToastStore } from '@/stores/toast';
import { expenseApi } from '@/api/endpoints';
import PaginationBar from '@/components/common/PaginationBar.vue';
import SearchableSelect from '@/components/common/SearchableSelect.vue';

const filterStore = useFilterStore();
const toast = useToastStore();

const expensePaymentModes = [
  { value: 'Cash', label: 'Cash', icon: '💵' },
  { value: 'UPI', label: 'UPI / GPay / Paytm', icon: '⚡' },
  { value: 'Bank', label: 'Bank Transfer', icon: '🏦' },
];

const expenses = ref([]);
const loading = ref(false);
const searchQuery = ref('');
const currentPage = ref(1);
const totalPages = ref(1);
const totalCount = ref(0);
const perPage = ref(10);
let searchTimer = null;

const showModal = ref(false);
const deleteModalOpen = ref(false);
const expenseToDelete = ref(null);
const deleting = ref(false);

const form = reactive({
  title: '',
  amount: 0,
  payment_mode: 'Cash',
  description: '',
});

function debounceSearch() {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => {
    currentPage.value = 1;
    fetchExpenses();
  }, 350);
}

function onPeriodChange() {
  filterStore.setPeriod(filterStore.selectedPeriod);
  currentPage.value = 1;
  fetchExpenses();
}

function resetFilters() {
  searchQuery.value = '';
  filterStore.setPeriod('this_month');
  currentPage.value = 1;
  fetchExpenses();
}

async function fetchExpenses() {
  loading.value = true;
  try {
    const periodVal = filterStore.selectedPeriod;
    const res = await expenseApi.list({
      page: currentPage.value,
      per_page: perPage.value,
      search: searchQuery.value || undefined,
      period: periodVal !== 'all_time' ? periodVal : undefined,
    });
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
  return (Number(amt) || 0).toLocaleString('en-IN');
}

function formatDate(d) {
  if (!d) return '-';
  const date = new Date(d);
  return date.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
}

async function saveExpense() {
  try {
    const title = form.title;
    const amt = form.amount;
    await expenseApi.create({
      title: form.title,
      name: form.title,
      amount: form.amount,
      payment_mode: form.payment_mode,
      description: form.description,
    });
    showModal.value = false;
    form.title = '';
    form.amount = 0;
    form.description = '';
    toast.success(`Expense "${title}" of ₹${Number(amt).toLocaleString('en-IN')} recorded!`, 'Expense Saved');
    fetchExpenses();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to save expense';
    toast.error(msg, 'Save Expense Failed');
  }
}

function confirmDeleteExpense(exp) {
  expenseToDelete.value = exp;
  deleteModalOpen.value = true;
}

async function executeDeleteExpense() {
  if (!expenseToDelete.value) return;
  deleting.value = true;
  try {
    const expTitle = expenseToDelete.value.title || expenseToDelete.value.name;
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

onMounted(() => {
  fetchExpenses();
});
</script>
