<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <div class="flex items-center gap-2">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 border border-indigo-200/60 dark:border-indigo-800/60">
            Assurance
          </span>
          <span class="text-xs text-slate-400">Device & Spare Protection</span>
        </div>
        <h2 class="text-2xl font-bold tracking-tight text-slate-900 dark:text-white mt-1">Warranties & Guarantees</h2>
        <p class="text-sm text-slate-500 dark:text-slate-400">Track device and spare part warranties provided to customers</p>
      </div>
    </div>

    <!-- Filter & Search Bar -->
    <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-sm flex flex-col md:flex-row items-stretch md:items-center gap-3">
      <div class="relative flex-1">
        <svg class="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
        <input
          v-model="search"
          type="text"
          placeholder="Search by code, customer name, device or IMEI..."
          class="w-full pl-10 pr-4 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-slate-800 dark:text-slate-100 placeholder-slate-400"
        />
      </div>
      <div class="flex items-center gap-2">
        <SearchableSelect
          v-model="statusFilter"
          :options="warrantyStatusOptions"
          placeholder="All Statuses"
          searchPlaceholder="Search statuses..."
          minWidth="130px"
        />
        <button
          v-if="search || statusFilter"
          @click="search = ''; statusFilter = ''"
          class="px-3 py-2 text-xs font-medium text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200"
        >
          Clear
        </button>
      </div>
    </div>

    <!-- Table Card -->
    <div class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800/80 shadow-sm overflow-hidden">
      <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="border-b border-slate-100 dark:border-slate-800/80 bg-slate-50/60 dark:bg-slate-900/40 text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              <th class="py-3.5 px-4">Warranty Code</th>
              <th class="py-3.5 px-4">Customer</th>
              <th class="py-3.5 px-4">Device / Item</th>
              <th class="py-3.5 px-4">Period & Validity</th>
              <th class="py-3.5 px-4">Status</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100 dark:divide-slate-800/60 text-sm">
            <tr v-if="loading">
              <td colspan="5" class="text-center py-12 text-slate-400">
                <div class="inline-block animate-spin w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full mb-2"></div>
                <div>Loading warranties...</div>
              </td>
            </tr>
            <tr v-else-if="filteredWarranties.length === 0">
              <td colspan="5" class="text-center py-12 text-slate-400 dark:text-slate-500">
                No warranties match your criteria.
              </td>
            </tr>
            <tr
              v-for="w in paginatedWarranties"
              :key="w.id"
              class="hover:bg-slate-50/70 dark:hover:bg-slate-800/40 transition group"
            >
              <td class="py-3.5 px-4">
                <span class="font-mono font-semibold text-indigo-600 dark:text-indigo-400">#{{ w.warranty_code || w.id }}</span>
              </td>
              <td class="py-3.5 px-4">
                <div class="font-medium text-slate-900 dark:text-slate-100">{{ w.customer?.name || w.customer_name || 'Customer' }}</div>
                <div class="text-xs text-slate-400">{{ w.customer?.phone || '-' }}</div>
              </td>
              <td class="py-3.5 px-4">
                <div class="font-medium text-slate-800 dark:text-slate-200">{{ w.item_name || w.product_name || 'Repaired Device' }}</div>
                <div class="text-xs text-slate-400">{{ w.imei || '' }}</div>
              </td>
              <td class="py-3.5 px-4">
                <div class="text-sm font-medium text-slate-900 dark:text-slate-100">{{ w.duration_days ? w.duration_days + ' Days' : (w.period || '30 Days') }}</div>
                <div class="text-xs text-slate-500 dark:text-slate-400">Valid until: {{ formatDate(w.expiry_date) }}</div>
              </td>
              <td class="py-3.5 px-4">
                <span
                  :class="isExpired(w.expiry_date)
                    ? 'bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-900/40'
                    : 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-900/40'"
                  class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold capitalize"
                >
                  {{ isExpired(w.expiry_date) ? 'Expired' : 'Active' }}
                </span>
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
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { warrantyApi } from '@/api/endpoints';
import PaginationBar from '@/components/common/PaginationBar.vue';
import SearchableSelect from '@/components/common/SearchableSelect.vue';

const warrantyStatusOptions = [
  { value: '', label: 'All Statuses' },
  { value: 'active', label: 'Active Only' },
  { value: 'expired', label: 'Expired Only' },
];

const warranties = ref([]);
const loading = ref(false);
const search = ref('');
const statusFilter = ref('');

const currentPage = ref(1);
const perPage = ref(10);

async function fetchWarranties() {
  loading.value = true;
  try {
    const res = await warrantyApi.list();
    const payload = res.data?.data;
    warranties.value = payload?.data || (Array.isArray(payload) ? payload : []);
  } catch (err) {
    console.error('Failed to load warranties:', err);
  } finally {
    loading.value = false;
  }
}

function isExpired(d) {
  if (!d) return false;
  return new Date(d) < new Date();
}

function formatDate(d) {
  if (!d) return '-';
  const date = new Date(d);
  return date.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
}

const filteredWarranties = computed(() => {
  let list = warranties.value;
  if (statusFilter.value === 'active') {
    list = list.filter(w => !isExpired(w.expiry_date));
  } else if (statusFilter.value === 'expired') {
    list = list.filter(w => isExpired(w.expiry_date));
  }
  if (search.value) {
    const q = search.value.toLowerCase();
    list = list.filter(w =>
      (w.warranty_code && String(w.warranty_code).toLowerCase().includes(q)) ||
      (w.customer?.name && w.customer.name.toLowerCase().includes(q)) ||
      (w.customer_name && w.customer_name.toLowerCase().includes(q)) ||
      (w.item_name && w.item_name.toLowerCase().includes(q)) ||
      (w.imei && String(w.imei).includes(q))
    );
  }
  return list;
});

const totalPages = computed(() => Math.max(1, Math.ceil(filteredWarranties.value.length / perPage.value)));

const paginatedWarranties = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredWarranties.value.slice(start, start + perPage.value);
});

function onPageChange(page) {
  currentPage.value = page;
}

onMounted(() => {
  fetchWarranties();
});
</script>
