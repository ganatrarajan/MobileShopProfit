<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="relative z-20 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <div class="flex items-center gap-2">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 border border-indigo-200/60 dark:border-indigo-800/60">
            Intelligence
          </span>
          <span class="text-xs text-slate-400">Financials & Operations</span>
        </div>
        <h2 class="text-2xl font-bold tracking-tight text-slate-900 dark:text-white mt-1">Reports & Analytics</h2>
        <p class="text-sm text-slate-500 dark:text-slate-400">Business overview, sales performance, repair margins, and receivables</p>
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
          alignRight
        />

        <button
          @click="printReport"
          class="inline-flex items-center justify-center gap-2 px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#111827] text-slate-700 dark:text-slate-200 text-xs font-semibold hover:bg-slate-50 dark:hover:bg-slate-800/60 transition shadow-sm cursor-pointer"
        >
          <svg class="w-4 h-4 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z" />
          </svg>
          Print / Export PDF
        </button>
      </div>
    </div>

    <!-- Outstanding Dues Hero Card -->
    <div class="bg-gradient-to-br from-rose-500/10 via-rose-500/5 to-transparent dark:from-rose-950/30 dark:via-rose-950/10 dark:to-transparent rounded-2xl p-6 border border-rose-200/80 dark:border-rose-900/40 shadow-sm relative overflow-hidden">
      <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div>
          <div class="flex items-center gap-2">
            <span class="w-2.5 h-2.5 rounded-full bg-rose-500 animate-pulse"></span>
            <p class="text-xs font-bold uppercase tracking-wider text-rose-700 dark:text-rose-400">Total Customer Pending Balance (Udhar / Outstanding)</p>
          </div>
          <p class="text-3xl font-extrabold text-rose-600 dark:text-rose-400 mt-2">₹{{ formatAmount(outstandingDues.total_due || 0) }}</p>
          <p class="text-xs text-rose-600/80 dark:text-rose-400/80 mt-1 font-medium">{{ outstandingDues.customers_count || 0 }} customers have active pending dues ledger</p>
        </div>
        <router-link
          to="/portal/customers"
          class="px-4 py-2 rounded-xl text-xs font-semibold bg-rose-600 hover:bg-rose-500 text-white shadow-md shadow-rose-600/20 transition"
        >
          View Customer Dues →
        </router-link>
      </div>
    </div>

    <!-- Reports Card -->
    <div class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800/80 shadow-sm overflow-hidden">
      <!-- Tabs -->
      <div class="border-b border-slate-100 dark:border-slate-800/80 px-6 flex gap-6 bg-slate-50/50 dark:bg-slate-900/30">
        <button
          @click="activeTab = 'sales'"
          :class="['py-3.5 border-b-2 font-semibold text-sm transition', activeTab === 'sales' ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400' : 'border-transparent text-slate-500 hover:text-slate-800 dark:text-slate-400 dark:hover:text-slate-200']"
        >
          Sales Summary
        </button>
        <button
          @click="activeTab = 'repairs'"
          :class="['py-3.5 border-b-2 font-semibold text-sm transition', activeTab === 'repairs' ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400' : 'border-transparent text-slate-500 hover:text-slate-800 dark:text-slate-400 dark:hover:text-slate-200']"
        >
          Repairs Summary
        </button>
        <button
          @click="activeTab = 'expenses'"
          :class="['py-3.5 border-b-2 font-semibold text-sm transition', activeTab === 'expenses' ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400' : 'border-transparent text-slate-500 hover:text-slate-800 dark:text-slate-400 dark:hover:text-slate-200']"
        >
          Expenses Breakdown
        </button>
      </div>

      <div class="p-6">
        <div v-if="loading" class="text-center py-12 text-slate-400">
          <div class="inline-block animate-spin w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full mb-2"></div>
          <div>Loading report metrics...</div>
        </div>
        <div v-else>
          <!-- Sales Tab Content -->
          <div v-if="activeTab === 'sales'" class="space-y-6">
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div class="p-5 rounded-2xl bg-slate-50 dark:bg-slate-900/50 border border-slate-200/70 dark:border-slate-800">
                <p class="text-xs font-bold uppercase tracking-wider text-slate-400">Total Sales Volume</p>
                <p class="text-2xl font-extrabold text-slate-900 dark:text-white mt-2">₹{{ formatAmount(salesReport.total_revenue || 0) }}</p>
                <p class="text-xs text-slate-400 mt-1">Gross sales billed across all invoices</p>
              </div>
              <div class="p-5 rounded-2xl bg-slate-50 dark:bg-slate-900/50 border border-slate-200/70 dark:border-slate-800">
                <p class="text-xs font-bold uppercase tracking-wider text-slate-400">Invoices Generated</p>
                <p class="text-2xl font-extrabold text-indigo-600 dark:text-indigo-400 mt-2">{{ salesReport.invoices_count || 0 }}</p>
                <p class="text-xs text-slate-400 mt-1">Receipts created in system</p>
              </div>
              <div class="p-5 rounded-2xl bg-slate-50 dark:bg-slate-900/50 border border-slate-200/70 dark:border-slate-800">
                <p class="text-xs font-bold uppercase tracking-wider text-slate-400">Collected Cash / UPI</p>
                <p class="text-2xl font-extrabold text-emerald-600 dark:text-emerald-400 mt-2">₹{{ formatAmount(salesReport.collected_amount || 0) }}</p>
                <p class="text-xs text-slate-400 mt-1">Actual settlements realized</p>
              </div>
            </div>
          </div>

          <!-- Repairs Tab Content -->
          <div v-if="activeTab === 'repairs'" class="space-y-6">
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div class="p-5 rounded-2xl bg-slate-50 dark:bg-slate-900/50 border border-slate-200/70 dark:border-slate-800">
                <p class="text-xs font-bold uppercase tracking-wider text-slate-400">Repairs Revenue</p>
                <p class="text-2xl font-extrabold text-slate-900 dark:text-white mt-2">₹{{ formatAmount(repairsReport.total_amount || 0) }}</p>
                <p class="text-xs text-slate-400 mt-1">Service charges + parts replaced</p>
              </div>
              <div class="p-5 rounded-2xl bg-slate-50 dark:bg-slate-900/50 border border-slate-200/70 dark:border-slate-800">
                <p class="text-xs font-bold uppercase tracking-wider text-slate-400">Devices Handled</p>
                <p class="text-2xl font-extrabold text-indigo-600 dark:text-indigo-400 mt-2">{{ repairsReport.total_repairs || 0 }}</p>
                <p class="text-xs text-slate-400 mt-1">Total repair job cards booked</p>
              </div>
              <div class="p-5 rounded-2xl bg-slate-50 dark:bg-slate-900/50 border border-slate-200/70 dark:border-slate-800">
                <p class="text-xs font-bold uppercase tracking-wider text-slate-400">Completed & Delivered</p>
                <p class="text-2xl font-extrabold text-emerald-600 dark:text-emerald-400 mt-2">{{ repairsReport.completed_repairs || 0 }}</p>
                <p class="text-xs text-slate-400 mt-1">Successfully fixed and handed over</p>
              </div>
            </div>
          </div>

          <!-- Expenses Tab Content -->
          <div v-if="activeTab === 'expenses'" class="space-y-6">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="p-5 rounded-2xl bg-slate-50 dark:bg-slate-900/50 border border-slate-200/70 dark:border-slate-800">
                <p class="text-xs font-bold uppercase tracking-wider text-slate-400">Total Overhead Spend</p>
                <p class="text-2xl font-extrabold text-rose-600 dark:text-rose-400 mt-2">₹{{ formatAmount(expensesReport.total_expenses || 0) }}</p>
                <p class="text-xs text-slate-400 mt-1">Rent, electricity, tea, tools, logistics</p>
              </div>
              <div class="p-5 rounded-2xl bg-slate-50 dark:bg-slate-900/50 border border-slate-200/70 dark:border-slate-800">
                <p class="text-xs font-bold uppercase tracking-wider text-slate-400">Expense Entries Count</p>
                <p class="text-2xl font-extrabold text-slate-900 dark:text-white mt-2">{{ expensesReport.count || 0 }}</p>
                <p class="text-xs text-slate-400 mt-1">Individual disbursements recorded</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useFilterStore } from '@/stores/filter';
import { reportApi } from '@/api/endpoints';
import SearchableSelect from '@/components/common/SearchableSelect.vue';

const filterStore = useFilterStore();

const activeTab = ref('sales');
const loading = ref(false);

const outstandingDues = ref({});
const salesReport = ref({});
const repairsReport = ref({});
const expensesReport = ref({});

function onPeriodChange() {
  filterStore.setPeriod(filterStore.selectedPeriod);
  loadReports();
}

async function loadReports() {
  loading.value = true;
  try {
    const periodVal = filterStore.selectedPeriod;
    const params = { period: periodVal };
    const [outRes, salesRes, repairsRes, expRes] = await Promise.all([
      reportApi.outstanding(params).catch(() => ({ data: { data: {} } })),
      reportApi.sales(params).catch(() => ({ data: { data: {} } })),
      reportApi.repairs(params).catch(() => ({ data: { data: {} } })),
      reportApi.expenses(params).catch(() => ({ data: { data: {} } })),
    ]);
    outstandingDues.value = outRes.data?.data || {};
    salesReport.value = salesRes.data?.data || {};
    repairsReport.value = repairsRes.data?.data || {};
    expensesReport.value = expRes.data?.data || {};
  } catch (err) {
    console.error('Failed to load reports:', err);
  } finally {
    loading.value = false;
  }
}

function printReport() {
  window.print();
}

function formatAmount(amt) {
  return (Number(amt) || 0).toLocaleString('en-IN');
}

onMounted(() => {
  loadReports();
});
</script>
