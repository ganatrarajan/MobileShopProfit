<template>
  <div class="space-y-6">
    <!-- Header Actions -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <div class="flex items-center gap-2">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 border border-indigo-200/60 dark:border-indigo-800/60">
            Procurement
          </span>
          <span class="text-xs text-slate-400">Vendor Bills & Stock Inward</span>
        </div>
        <h1 class="text-2xl font-bold tracking-tight text-slate-900 dark:text-white mt-1">Stock Purchases (Vendor Orders)</h1>
        <p class="text-xs sm:text-sm text-slate-500 dark:text-slate-400">Record wholesale mobile phone purchases, spare part bulk orders, and supplier payments.</p>
      </div>
      <button
        @click="showCreateModal = true"
        type="button"
        class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold shadow-md shadow-indigo-600/20 transition-all hover:scale-[1.02] active:scale-[0.98]"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" d="M12 4v16m8-8H4"/></svg>
        + Record Purchase
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
          placeholder="Search purchases by Bill #, Supplier name..."
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
              <th class="py-3.5 px-4 pl-6">Purchase Bill #</th>
              <th class="py-3.5 px-4">Supplier / Vendor</th>
              <th class="py-3.5 px-4">Total Amount</th>
              <th class="py-3.5 px-4">Payment Status</th>
              <th class="py-3.5 px-4">Remarks</th>
              <th class="py-3.5 px-4 pr-6 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100 dark:divide-slate-800/60 text-sm">
            <tr v-if="loading">
              <td colspan="6" class="py-12 text-center text-xs text-slate-400">
                <div class="inline-block animate-spin w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full mb-2"></div>
                <div>Loading purchase orders...</div>
              </td>
            </tr>
            <tr v-else-if="purchases.length === 0">
              <td colspan="6" class="py-12 text-center text-slate-400 dark:text-slate-500 text-xs">No vendor purchases found matching criteria.</td>
            </tr>
            <tr v-for="p in purchases" :key="p.id" class="hover:bg-slate-50/70 dark:hover:bg-slate-800/40 transition-colors group">
              <td class="py-3.5 px-4 pl-6">
                <div class="font-bold font-mono text-indigo-600 dark:text-indigo-400">#{{ p.purchase_number || p.bill_number || p.id }}</div>
                <div class="text-[11px] text-slate-400 mt-0.5">{{ formatDate(p.purchase_date || p.created_at) }}</div>
              </td>
              <td class="py-3.5 px-4">
                <div class="font-bold text-slate-900 dark:text-slate-100">{{ p.vendor_name || p.vendor?.name || 'Direct Supplier' }}</div>
                <div class="text-[11px] text-slate-400 font-mono mt-0.5">{{ p.vendor?.phone || '-' }}</div>
              </td>
              <td class="py-3.5 px-4">
                <div class="font-extrabold text-slate-900 dark:text-white tabular-nums">₹{{ formatAmount(p.total_amount || p.grand_total || 0) }}</div>
              </td>
              <td class="py-3.5 px-4">
                <span v-if="p.due_amount > 0 || p.outstanding_amount > 0" class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-900/40">
                  Due: ₹{{ formatAmount(p.due_amount || p.outstanding_amount) }}
                </span>
                <span v-else class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-900/40">
                  Fully Paid
                </span>
              </td>
              <td class="py-3.5 px-4 text-xs text-slate-500 dark:text-slate-400 max-w-xs truncate">
                {{ p.notes || p.remarks || '-' }}
              </td>
              <td class="py-3.5 px-4 pr-6 text-right">
                <button
                  @click="confirmDeletePurchase(p)"
                  type="button"
                  class="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/40 transition cursor-pointer"
                  title="Delete Purchase"
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

    <!-- Record Purchase Modal -->
    <div
      v-if="showCreateModal"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 overflow-y-auto flex min-h-full items-center justify-center p-4 py-6 sm:py-10"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-[#111827] w-full max-w-md rounded-2xl shadow-2xl border border-slate-200/80 dark:border-slate-800/80 overflow-hidden my-auto max-h-[calc(100vh-3rem)] flex flex-col animate-in fade-in zoom-in-95">
        <div class="px-6 py-4 border-b border-slate-100 dark:border-slate-800/80 flex justify-between items-center bg-slate-50/50 dark:bg-slate-900/30 shrink-0">
          <div>
            <h3 class="text-sm font-bold text-slate-900 dark:text-white">Record Vendor Purchase</h3>
            <p class="text-[11px] text-slate-400">Log wholesale inventory inward</p>
          </div>
          <button @click="showCreateModal = false" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 text-sm font-bold cursor-pointer">✕</button>
        </div>
        <form @submit.prevent="savePurchase" class="p-6 space-y-4 overflow-y-auto custom-scroll flex-1">
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Supplier / Vendor Name <span class="text-rose-500">*</span></label>
            <input v-model="form.vendor_name" type="text" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400" placeholder="e.g. Metro Mobile Wholesale" required />
          </div>
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Bill / Invoice Number</label>
            <input v-model="form.bill_number" type="text" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400" placeholder="Supplier Bill Ref" />
          </div>
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Total Amount (₹) <span class="text-rose-500">*</span></label>
            <input v-model.number="form.total_amount" type="number" step="0.01" min="1" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100" required />
          </div>
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Notes / Items Included</label>
            <textarea v-model="form.notes" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400" rows="2" placeholder="e.g. 5x OLED displays, 10x batteries"></textarea>
          </div>
          <div class="flex justify-end gap-2 pt-3 border-t border-slate-100 dark:border-slate-800/80 shrink-0">
            <button type="button" @click="showCreateModal = false" class="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-xl transition cursor-pointer">Cancel</button>
            <button type="submit" class="px-4 py-2 text-xs font-semibold text-white bg-indigo-600 hover:bg-indigo-500 rounded-xl shadow-md shadow-indigo-600/20 transition cursor-pointer">Save Purchase</button>
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
        <h3 class="text-base font-bold text-slate-900 dark:text-white">Delete Purchase Record?</h3>
        <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
          Are you sure you want to delete purchase <span class="font-mono font-bold text-slate-700 dark:text-slate-300">#{{ purchaseToDelete?.purchase_number || purchaseToDelete?.bill_number || purchaseToDelete?.id }}</span>?
        </p>
        <div class="flex items-center justify-center gap-2 mt-5">
          <button
            @click="deleteModalOpen = false"
            class="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition"
          >
            Cancel
          </button>
          <button
            @click="executeDeletePurchase"
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
import { purchaseApi } from '@/api/endpoints';
import PaginationBar from '@/components/common/PaginationBar.vue';
import SearchableSelect from '@/components/common/SearchableSelect.vue';

const filterStore = useFilterStore();
const toast = useToastStore();

const purchases = ref([]);
const loading = ref(false);
const searchQuery = ref('');
const currentPage = ref(1);
const totalPages = ref(1);
const totalCount = ref(0);
const perPage = ref(10);
let searchTimer = null;

const showCreateModal = ref(false);
const deleteModalOpen = ref(false);
const purchaseToDelete = ref(null);
const deleting = ref(false);

const form = reactive({
  vendor_name: '',
  bill_number: '',
  total_amount: 0,
  notes: '',
});

function debounceSearch() {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => {
    currentPage.value = 1;
    fetchPurchases();
  }, 350);
}

function onPeriodChange() {
  filterStore.setPeriod(filterStore.selectedPeriod);
  currentPage.value = 1;
  fetchPurchases();
}

function resetFilters() {
  searchQuery.value = '';
  filterStore.setPeriod('this_month');
  currentPage.value = 1;
  fetchPurchases();
}

async function fetchPurchases() {
  loading.value = true;
  try {
    const periodVal = filterStore.selectedPeriod;
    const res = await purchaseApi.list({
      page: currentPage.value,
      per_page: perPage.value,
      search: searchQuery.value || undefined,
      period: periodVal !== 'all_time' ? periodVal : undefined,
    });
    const payload = res.data?.data;
    if (payload?.data) {
      purchases.value = payload.data;
      currentPage.value = payload.current_page || 1;
      totalCount.value = payload.total || payload.data.length;
      totalPages.value = payload.last_page || Math.max(1, Math.ceil(totalCount.value / perPage.value));
      if (payload.per_page) perPage.value = payload.per_page;
    } else if (res.data?.meta) {
      purchases.value = Array.isArray(payload) ? payload : [];
      currentPage.value = res.data.meta.current_page || 1;
      totalCount.value = res.data.meta.total || purchases.value.length;
      totalPages.value = res.data.meta.last_page || Math.max(1, Math.ceil(totalCount.value / perPage.value));
      if (res.data.meta.per_page) perPage.value = res.data.meta.per_page;
    } else {
      purchases.value = Array.isArray(payload) ? payload : [];
      totalCount.value = purchases.value.length;
      totalPages.value = Math.max(1, Math.ceil(purchases.value.length / perPage.value));
    }
  } catch (err) {
    console.error('Failed to load purchases:', err);
  } finally {
    loading.value = false;
  }
}

function changePage(p) {
  currentPage.value = p;
  fetchPurchases();
}

function formatAmount(amt) {
  return (Number(amt) || 0).toLocaleString('en-IN');
}

function formatDate(d) {
  if (!d) return '-';
  const date = new Date(d);
  return date.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
}

async function savePurchase() {
  try {
    const vendor = form.vendor_name;
    const total = form.total_amount;
    await purchaseApi.create(form);
    showCreateModal.value = false;
    form.vendor_name = '';
    form.bill_number = '';
    form.total_amount = 0;
    form.notes = '';
    toast.success(`Purchase from "${vendor}" for ₹${Number(total).toLocaleString('en-IN')} recorded!`, 'Purchase Saved');
    fetchPurchases();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to save purchase';
    toast.error(msg, 'Save Purchase Failed');
  }
}

function confirmDeletePurchase(p) {
  purchaseToDelete.value = p;
  deleteModalOpen.value = true;
}

async function executeDeletePurchase() {
  if (!purchaseToDelete.value) return;
  deleting.value = true;
  try {
    const vendor = purchaseToDelete.value.vendor_name || purchaseToDelete.value.supplier_name || 'Vendor';
    await purchaseApi.delete(purchaseToDelete.value.id);
    deleteModalOpen.value = false;
    purchaseToDelete.value = null;
    toast.success(`Purchase record from "${vendor}" deleted successfully.`, 'Purchase Deleted');
    fetchPurchases();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to delete purchase';
    toast.error(msg, 'Delete Purchase Failed');
  } finally {
    deleting.value = false;
  }
}

onMounted(() => {
  fetchPurchases();
});
</script>
