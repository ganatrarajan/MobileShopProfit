<template>
  <div class="max-w-5xl mx-auto space-y-6 pb-12 font-['Outfit',sans-serif]">
    <!-- Top Bar -->
    <div class="flex items-center justify-between">
      <router-link
        to="/customers"
        class="inline-flex items-center gap-1.5 px-3 py-2 text-xs font-semibold rounded-xl bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-200 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 shadow-sm transition"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/></svg>
        Back to Customers
      </router-link>
      <span class="text-xs font-mono font-bold text-slate-400">Customer ID #{{ customer.id }}</span>
    </div>

    <!-- Customer Profile Hero Card -->
    <div class="bg-white dark:bg-slate-800 rounded-3xl p-6 border border-slate-200/80 dark:border-slate-700/80 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-6">
      <div class="flex items-center gap-4">
        <div class="w-14 h-14 rounded-2xl bg-indigo-600 text-white flex items-center justify-center font-extrabold text-2xl shadow-lg shadow-indigo-500/20">
          {{ (customer.name || 'C')[0] }}
        </div>
        <div>
          <h1 class="text-2xl font-bold text-slate-900 dark:text-white">{{ customer.name }}</h1>
          <div class="flex flex-wrap items-center gap-3 text-xs text-slate-500 dark:text-slate-400 mt-1">
            <span class="font-mono">📞 {{ customer.phone || customer.mobile || 'No phone recorded' }}</span>
            <span v-if="customer.email">✉️ {{ customer.email }}</span>
            <span v-if="customer.city">📍 {{ customer.city }}</span>
          </div>
          <p v-if="customer.address" class="text-xs text-slate-400 mt-0.5">{{ customer.address }}</p>
        </div>
      </div>

      <div class="flex flex-wrap items-center gap-2">
        <a
          v-if="customer.phone || customer.mobile"
          :href="`https://wa.me/${formatPhoneForWhatsApp(customer.phone || customer.mobile)}`"
          target="_blank"
          class="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold rounded-xl bg-[#25D366] text-white hover:bg-[#20ba5a] shadow-sm transition shadow-green-500/20"
        >
          <svg class="w-4 h-4 fill-current" viewBox="0 0 24 24">
            <path d="M12.031 6.172c-3.181 0-5.767 2.586-5.768 5.766-.001 1.298.38 2.27 1.019 3.287l-.711 2.598 2.664-.698c.969.584 1.761.948 2.796.949h.005c3.18 0 5.767-2.586 5.768-5.766 0-3.18-2.588-5.766-5.773-5.766zm8.411 5.766c0 4.655-3.784 8.439-8.439 8.439-1.42 0-2.755-.355-3.928-.973l-4.345 1.139 1.161-4.237c-.694-1.222-1.07-2.628-1.07-4.108 0-4.656 3.784-8.44 8.439-8.44 4.655 0 8.439 3.784 8.439 8.44z"/>
          </svg>
          Chat WhatsApp
        </a>
        <a
          v-if="customer.phone || customer.mobile"
          :href="`tel:${customer.phone || customer.mobile}`"
          class="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-semibold rounded-xl bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-200 hover:bg-slate-200 transition"
        >
          Call Customer
        </a>
      </div>
    </div>

    <!-- Stats Overview Cards -->
    <div class="grid grid-cols-2 sm:grid-cols-3 gap-4">
      <div class="bg-white dark:bg-slate-800 rounded-2xl p-4 border border-slate-200/80 dark:border-slate-700/80 shadow-sm">
        <p class="text-xs text-slate-400 font-semibold uppercase">Total Repairs</p>
        <p class="text-2xl font-extrabold text-indigo-600 dark:text-indigo-400 mt-1">
          {{ customer.repairs?.length || 0 }}
        </p>
      </div>
      <div class="bg-white dark:bg-slate-800 rounded-2xl p-4 border border-slate-200/80 dark:border-slate-700/80 shadow-sm">
        <p class="text-xs text-slate-400 font-semibold uppercase">Total Sales</p>
        <p class="text-2xl font-extrabold text-emerald-600 dark:text-emerald-400 mt-1">
          {{ customer.sales?.length || 0 }}
        </p>
      </div>
      <div class="bg-white dark:bg-slate-800 rounded-2xl p-4 border border-slate-200/80 dark:border-slate-700/80 shadow-sm col-span-2 sm:col-span-1">
        <p class="text-xs text-slate-400 font-semibold uppercase">Registered Devices</p>
        <p class="text-2xl font-extrabold text-purple-600 dark:text-purple-400 mt-1">
          {{ customer.devices?.length || 0 }}
        </p>
      </div>
    </div>

    <!-- Tabbed History: Repairs, Sales, Devices -->
    <div class="bg-white dark:bg-slate-800 rounded-3xl border border-slate-200/80 dark:border-slate-700/80 shadow-sm overflow-hidden">
      <div class="border-b border-slate-100 dark:border-slate-700 px-6 flex gap-6">
        <button
          @click="activeTab = 'repairs'"
          :class="['py-3.5 border-b-2 font-bold text-xs transition uppercase tracking-wider', activeTab === 'repairs' ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400' : 'border-transparent text-slate-400 hover:text-slate-600']"
        >
          Repair Orders ({{ customer.repairs?.length || 0 }})
        </button>
        <button
          @click="activeTab = 'sales'"
          :class="['py-3.5 border-b-2 font-bold text-xs transition uppercase tracking-wider', activeTab === 'sales' ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400' : 'border-transparent text-slate-400 hover:text-slate-600']"
        >
          Sales Invoices ({{ customer.sales?.length || 0 }})
        </button>
        <button
          @click="activeTab = 'devices'"
          :class="['py-3.5 border-b-2 font-bold text-xs transition uppercase tracking-wider', activeTab === 'devices' ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400' : 'border-transparent text-slate-400 hover:text-slate-600']"
        >
          Registered Devices ({{ customer.devices?.length || 0 }})
        </button>
      </div>

      <!-- Repairs Tab -->
      <div v-if="activeTab === 'repairs'" class="p-6">
        <div v-if="!customer.repairs || customer.repairs.length === 0" class="text-center py-8 text-slate-400 text-xs">
          No repairs recorded for this customer.
        </div>
        <div v-else class="space-y-3">
          <div
            v-for="rep in customer.repairs"
            :key="rep.id"
            class="p-4 border border-slate-100 dark:border-slate-700/80 rounded-2xl flex flex-col sm:flex-row sm:items-center justify-between gap-3 hover:bg-slate-50 dark:hover:bg-slate-900/40 transition"
          >
            <div>
              <div class="flex items-center gap-2">
                <span class="font-extrabold text-slate-900 dark:text-white text-sm">
                  {{ rep.job_number || ('#JOB-' + rep.id) }}
                </span>
                <span class="text-xs font-semibold text-slate-600 dark:text-slate-300">
                  {{ rep.device_brand || rep.device?.brand || '' }} {{ rep.device_model || rep.device?.model || '' }}
                </span>
              </div>
              <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">{{ rep.problem_description || 'General inspection' }}</p>
              <p class="text-[11px] text-slate-400 mt-0.5">Date: {{ formatDate(rep.date_received || rep.created_at) }}</p>
            </div>
            <div class="flex items-center justify-between sm:justify-end gap-4">
              <span class="font-bold text-slate-900 dark:text-white text-sm">
                ₹{{ formatAmount(rep.final_cost || rep.estimated_cost) }}
              </span>
              <router-link
                :to="`/repairs/${rep.id}`"
                class="px-3 py-1.5 rounded-xl bg-indigo-50 dark:bg-indigo-950/40 text-indigo-600 dark:text-indigo-400 text-xs font-bold hover:bg-indigo-100 transition"
              >
                View Job →
              </router-link>
            </div>
          </div>
        </div>
      </div>

      <!-- Sales Tab -->
      <div v-if="activeTab === 'sales'" class="p-6">
        <div v-if="!customer.sales || customer.sales.length === 0" class="text-center py-8 text-slate-400 text-xs">
          No sales recorded for this customer.
        </div>
        <div v-else class="space-y-3">
          <div
            v-for="s in customer.sales"
            :key="s.id"
            class="p-4 border border-slate-100 dark:border-slate-700/80 rounded-2xl flex flex-col sm:flex-row sm:items-center justify-between gap-3 hover:bg-slate-50 dark:hover:bg-slate-900/40 transition"
          >
            <div>
              <span class="font-extrabold text-slate-900 dark:text-white text-sm font-mono">
                #{{ s.invoice_no || ('INV-' + s.id) }}
              </span>
              <p class="text-[11px] text-slate-400 mt-1">{{ formatDate(s.created_at) }}</p>
            </div>
            <div class="flex items-center justify-between sm:justify-end gap-4">
              <span class="font-bold text-slate-900 dark:text-white text-sm">₹{{ formatAmount(s.total_amount) }}</span>
              <router-link
                :to="`/sales/${s.id}`"
                class="px-3 py-1.5 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 text-xs font-bold hover:bg-emerald-100 transition"
              >
                View Bill →
              </router-link>
            </div>
          </div>
        </div>
      </div>

      <!-- Devices Tab -->
      <div v-if="activeTab === 'devices'" class="p-6">
        <div v-if="!customer.devices || customer.devices.length === 0" class="text-center py-8 text-slate-400 text-xs">
          No devices recorded for this customer.
        </div>
        <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div
            v-for="d in customer.devices"
            :key="d.id"
            class="p-4 border border-slate-100 dark:border-slate-700/80 rounded-2xl bg-slate-50 dark:bg-slate-900/40"
          >
            <h4 class="font-bold text-slate-900 dark:text-white text-sm">{{ d.brand }} {{ d.model }}</h4>
            <p v-if="d.imei1" class="text-xs font-mono text-slate-500 mt-1">IMEI 1: {{ d.imei1 }}</p>
            <p v-if="d.imei2" class="text-xs font-mono text-slate-500">IMEI 2: {{ d.imei2 }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { customerApi } from '@/api/endpoints';

const route = useRoute();
const customer = ref({});
const activeTab = ref('repairs');

async function loadCustomer() {
  try {
    const res = await customerApi.get(route.params.id);
    customer.value = res.data?.data || res.data || {};
  } catch (err) {
    console.error('Failed to load customer:', err);
  }
}

function formatPhoneForWhatsApp(phone) {
  if (!phone) return '';
  const cleaned = String(phone).replace(/\D/g, '');
  if (cleaned.length === 10) return '91' + cleaned;
  return cleaned;
}

function formatAmount(amt) {
  if (amt === undefined || amt === null || isNaN(amt)) return '0.00';
  return Number(amt).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function formatDate(val) {
  if (!val) return '-';
  try {
    const d = new Date(val);
    if (isNaN(d.getTime())) return String(val).substring(0, 10);
    return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
  } catch {
    return String(val).substring(0, 10);
  }
}

onMounted(() => {
  loadCustomer();
});
</script>
