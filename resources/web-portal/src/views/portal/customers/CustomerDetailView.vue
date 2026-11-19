<template>
  <div class="max-w-6xl mx-auto space-y-6 pb-12 font-['Outfit',sans-serif]">
    <!-- Top Bar -->
    <div class="flex items-center justify-between">
      <router-link
        to="/customers"
        class="inline-flex items-center gap-1.5 px-3 py-2 text-xs font-semibold rounded-xl bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-200 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-700/60 shadow-sm transition cursor-pointer"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/></svg>
        Back to Customers Directory
      </router-link>
      <span class="text-xs font-mono font-bold text-slate-400">Customer ID #{{ customer.id }}</span>
    </div>

    <!-- Customer Profile Hero Card -->
    <div class="bg-white dark:bg-[#111827] rounded-3xl p-6 border border-slate-200/80 dark:border-slate-800/80 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-6">
      <div class="flex items-start sm:items-center gap-4">
        <div class="w-16 h-16 rounded-2xl bg-indigo-600 text-white flex items-center justify-center font-extrabold text-2xl shadow-lg shadow-indigo-500/20 shrink-0">
          {{ (customer.name || 'C')[0]?.toUpperCase() }}
        </div>
        <div>
          <div class="flex flex-wrap items-center gap-2">
            <h1 class="text-2xl font-black text-slate-900 dark:text-white">{{ customer.name }}</h1>
            <span
              v-if="Number(customer.total_due) > 0"
              class="px-2.5 py-0.5 rounded-full text-xs font-bold text-rose-600 dark:text-rose-400 bg-rose-50 dark:bg-rose-950/50 border border-rose-200/80 dark:border-rose-900/40"
            >
              Pending Due: ₹{{ formatAmount(customer.total_due) }}
            </span>
            <span
              v-else
              class="px-2.5 py-0.5 rounded-full text-xs font-semibold text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/50 border border-emerald-200/80 dark:border-emerald-900/40"
            >
              All Dues Cleared
            </span>
          </div>

          <div class="flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-slate-500 dark:text-slate-400 mt-1.5">
            <span class="font-mono font-bold text-slate-700 dark:text-slate-300">📱 {{ customer.mobile || customer.phone || 'No mobile' }}</span>
            <span v-if="customer.alternate_mobile" class="font-mono text-slate-400">Alt: {{ customer.alternate_mobile }}</span>
            <span v-if="customer.email">✉️ {{ customer.email }}</span>
            <span v-if="customer.city">📍 {{ customer.city }}</span>
          </div>
          <p v-if="customer.address" class="text-xs text-slate-400 mt-1">{{ customer.address }}</p>
          <p v-if="customer.notes" class="text-xs italic text-indigo-600 dark:text-indigo-400 mt-1 bg-indigo-50/50 dark:bg-indigo-950/30 px-2.5 py-1 rounded-lg inline-block">
            Note: {{ customer.notes }}
          </p>
        </div>
      </div>

      <div class="flex flex-wrap items-center gap-2 shrink-0">
        <!-- Add Device Shortcut in Hero -->
        <button
          @click="openAddDeviceModal"
          type="button"
          class="inline-flex items-center gap-1.5 px-3.5 py-2.5 text-xs font-bold rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white shadow-md shadow-indigo-600/20 transition cursor-pointer"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" d="M12 4v16m8-8H4"/></svg>
          + Add Device
        </button>

        <a
          v-if="customer.mobile || customer.phone"
          :href="`https://wa.me/91${String(customer.mobile || customer.phone).replace(/[^0-9]/g, '').slice(-10)}`"
          target="_blank"
          class="inline-flex items-center gap-1.5 px-3.5 py-2.5 text-xs font-bold rounded-xl bg-[#25D366] text-white hover:bg-[#20ba5a] shadow-sm transition shadow-green-500/20 cursor-pointer"
        >
          <svg class="w-4 h-4 fill-current" viewBox="0 0 24 24">
            <path d="M12.031 6.172c-3.181 0-5.767 2.586-5.768 5.766-.001 1.298.38 2.27 1.019 3.287l-.711 2.598 2.664-.698c.969.584 1.761.948 2.796.949h.005c3.18 0 5.767-2.586 5.768-5.766 0-3.18-2.588-5.766-5.773-5.766zm8.411 5.766c0 4.655-3.784 8.439-8.439 8.439-1.42 0-2.755-.355-3.928-.973l-4.345 1.139 1.161-4.237c-.694-1.222-1.07-2.628-1.07-4.108 0-4.656 3.784-8.44 8.439-8.44 4.655 0 8.439 3.784 8.439 8.44z"/>
          </svg>
          WhatsApp
        </a>

        <a
          v-if="customer.mobile || customer.phone"
          :href="`tel:${customer.mobile || customer.phone}`"
          class="inline-flex items-center gap-1.5 px-3.5 py-2.5 text-xs font-semibold rounded-xl bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-200 hover:bg-slate-200 dark:hover:bg-slate-700 transition"
        >
          📞 Call
        </a>
      </div>
    </div>

    <!-- 4 Stats Overview Cards -->
    <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-xs">
        <p class="text-[11px] text-slate-400 font-bold uppercase tracking-wider">Total Repairs</p>
        <p class="text-2xl font-black text-indigo-600 dark:text-indigo-400 mt-1 tabular-nums">
          {{ customer.repairs_count ?? (customer.repairs?.length || 0) }}
        </p>
      </div>

      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-xs">
        <p class="text-[11px] text-slate-400 font-bold uppercase tracking-wider">Total Invoices (Sales)</p>
        <p class="text-2xl font-black text-emerald-600 dark:text-emerald-400 mt-1 tabular-nums">
          {{ customer.sales_count ?? (customer.sales?.length || 0) }}
        </p>
      </div>

      <!-- Device Count Card with Quick Add -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-xs flex items-center justify-between">
        <div>
          <p class="text-[11px] text-slate-400 font-bold uppercase tracking-wider">Registered Devices</p>
          <p class="text-2xl font-black text-purple-600 dark:text-purple-400 mt-1 tabular-nums">
            {{ customer.devices_count ?? (customer.devices?.length || 0) }}
          </p>
        </div>
        <button
          @click="openAddDeviceModal"
          type="button"
          class="p-2 rounded-xl bg-purple-50 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400 hover:bg-purple-100 transition cursor-pointer"
          title="Add Device"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 4v16m8-8H4"/></svg>
        </button>
      </div>

      <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-xs">
        <p class="text-[11px] text-slate-400 font-bold uppercase tracking-wider">Khata Pending Due</p>
        <p class="text-2xl font-black text-rose-600 dark:text-rose-400 mt-1 tabular-nums">
          ₹{{ formatAmount(customer.total_due) }}
        </p>
      </div>
    </div>

    <!-- Tabbed History: Repairs, Sales, Devices -->
    <div class="bg-white dark:bg-[#111827] rounded-3xl border border-slate-200/80 dark:border-slate-800/80 shadow-sm overflow-hidden">
      <div class="border-b border-slate-100 dark:border-slate-800 px-6 flex items-center justify-between overflow-x-auto">
        <div class="flex gap-6">
          <button
            @click="activeTab = 'repairs'"
            :class="['py-3.5 border-b-2 font-bold text-xs transition uppercase tracking-wider cursor-pointer whitespace-nowrap', activeTab === 'repairs' ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400' : 'border-transparent text-slate-400 hover:text-slate-600']"
          >
            Repair Orders ({{ customer.repairs?.length || 0 }})
          </button>
          <button
            @click="activeTab = 'sales'"
            :class="['py-3.5 border-b-2 font-bold text-xs transition uppercase tracking-wider cursor-pointer whitespace-nowrap', activeTab === 'sales' ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400' : 'border-transparent text-slate-400 hover:text-slate-600']"
          >
            Sales Invoices ({{ customer.sales?.length || 0 }})
          </button>
          <button
            @click="activeTab = 'devices'"
            :class="['py-3.5 border-b-2 font-bold text-xs transition uppercase tracking-wider cursor-pointer whitespace-nowrap flex items-center gap-1.5', activeTab === 'devices' ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400' : 'border-transparent text-slate-400 hover:text-slate-600']"
          >
            <span>Registered Devices</span>
            <span class="px-2 py-0.5 rounded-full text-[10px] font-extrabold bg-purple-100 dark:bg-purple-950/60 text-purple-700 dark:text-purple-300">
              {{ customer.devices?.length || 0 }}
            </span>
          </button>
        </div>

        <!-- Add Device CTA button on Tab Bar -->
        <button
          v-if="activeTab === 'devices'"
          @click="openAddDeviceModal"
          type="button"
          class="inline-flex items-center gap-1 px-3 py-1.5 rounded-xl bg-purple-600 hover:bg-purple-500 text-white text-xs font-bold transition shadow-xs cursor-pointer"
        >
          <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 4v16m8-8H4"/></svg>
          Add Device
        </button>
      </div>

      <!-- Repairs Tab -->
      <div v-if="activeTab === 'repairs'" class="p-6">
        <div v-if="!customer.repairs || customer.repairs.length === 0" class="text-center py-10 text-slate-400 text-xs">
          No repair jobs recorded for this customer yet.
        </div>
        <div v-else class="space-y-3">
          <div
            v-for="rep in customer.repairs"
            :key="rep.id"
            class="p-4 border border-slate-100 dark:border-slate-800/80 rounded-2xl flex flex-col sm:flex-row sm:items-center justify-between gap-3 hover:bg-slate-50 dark:hover:bg-slate-900/40 transition"
          >
            <div>
              <div class="flex items-center gap-2">
                <span class="font-mono font-bold text-indigo-600 dark:text-indigo-400 text-xs">
                  {{ rep.job_number || ('JOB-' + rep.id) }}
                </span>
                <span class="px-2 py-0.5 rounded text-[10px] font-bold uppercase bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300">
                  {{ rep.repair_status || 'Received' }}
                </span>
              </div>
              <p class="text-xs font-bold text-slate-900 dark:text-white mt-1">{{ rep.problem_description || 'General inspection / service' }}</p>
              <p class="text-[11px] text-slate-400 mt-0.5">Date: {{ formatDate(rep.date_received || rep.created_at) }}</p>
            </div>
            <div class="flex items-center justify-between sm:justify-end gap-4">
              <div class="text-right">
                <p class="font-mono font-bold text-slate-900 dark:text-white text-xs">₹{{ formatAmount(rep.final_cost || rep.estimated_cost) }}</p>
                <p v-if="Number(rep.amount_due) > 0" class="text-[11px] font-mono text-rose-600 dark:text-rose-400 font-bold">Due: ₹{{ formatAmount(rep.amount_due) }}</p>
                <p v-else class="text-[11px] text-emerald-600 dark:text-emerald-400 font-semibold">Paid Full</p>
              </div>
              <router-link
                :to="`/repairs/${rep.id}`"
                class="px-3 py-1.5 rounded-xl bg-indigo-50 dark:bg-indigo-950/40 text-indigo-600 dark:text-indigo-400 text-xs font-bold hover:bg-indigo-100 transition shrink-0"
              >
                View Job →
              </router-link>
            </div>
          </div>
        </div>
      </div>

      <!-- Sales Tab -->
      <div v-if="activeTab === 'sales'" class="p-6">
        <div v-if="!customer.sales || customer.sales.length === 0" class="text-center py-10 text-slate-400 text-xs">
          No sales invoices recorded for this customer yet.
        </div>
        <div v-else class="space-y-3">
          <div
            v-for="s in customer.sales"
            :key="s.id"
            class="p-4 border border-slate-100 dark:border-slate-800/80 rounded-2xl flex flex-col sm:flex-row sm:items-center justify-between gap-3 hover:bg-slate-50 dark:hover:bg-slate-900/40 transition"
          >
            <div>
              <div class="flex items-center gap-2">
                <span class="font-mono font-bold text-indigo-600 dark:text-indigo-400 text-xs">
                  #{{ s.invoice_number || s.invoice_no || ('INV-' + s.id) }}
                </span>
                <span
                  class="px-2 py-0.5 rounded text-[10px] font-bold uppercase"
                  :class="s.payment_status === 'paid' ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/50 dark:text-emerald-400' : 'bg-rose-50 text-rose-700 dark:bg-rose-950/50 dark:text-rose-400'"
                >
                  {{ s.payment_status || 'Paid' }}
                </span>
              </div>
              <p class="text-[11px] text-slate-400 mt-1">{{ formatDate(s.sale_date || s.created_at) }}</p>
            </div>
            <div class="flex items-center justify-between sm:justify-end gap-4">
              <div class="text-right">
                <p class="font-mono font-bold text-slate-900 dark:text-white text-xs">₹{{ formatAmount(s.grand_total || s.total_amount) }}</p>
                <p v-if="Number(s.amount_due) > 0" class="text-[11px] font-mono text-rose-600 dark:text-rose-400 font-bold">Due: ₹{{ formatAmount(s.amount_due) }}</p>
                <p v-else class="text-[11px] text-emerald-600 dark:text-emerald-400 font-semibold">Paid Full</p>
              </div>
              <router-link
                :to="`/sales/${s.id}`"
                class="px-3 py-1.5 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 text-xs font-bold hover:bg-emerald-100 transition shrink-0"
              >
                View Bill →
              </router-link>
            </div>
          </div>
        </div>
      </div>

      <!-- Devices Tab (Full Parity with Mobile App) -->
      <div v-if="activeTab === 'devices'" class="p-6">
        <!-- Empty State matching mobile app -->
        <div
          v-if="!customer.devices || customer.devices.length === 0"
          class="p-8 text-center border-2 border-dashed border-slate-200 dark:border-slate-800 rounded-2xl flex flex-col items-center justify-center"
        >
          <div class="w-12 h-12 rounded-2xl bg-purple-50 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400 flex items-center justify-center text-xl mb-3">
            📱
          </div>
          <h4 class="text-sm font-bold text-slate-900 dark:text-white">No registered devices yet</h4>
          <p class="text-xs text-slate-400 mt-1 max-w-sm">
            Register this customer's phones, tablets, or laptops to track warranty, device histories, and book instant repairs.
          </p>
          <button
            @click="openAddDeviceModal"
            type="button"
            class="mt-4 px-4 py-2 rounded-xl bg-purple-600 hover:bg-purple-500 text-white text-xs font-bold shadow-md shadow-purple-600/20 transition cursor-pointer flex items-center gap-1.5"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 4v16m8-8H4"/></svg>
            <span>+ Add Device</span>
          </button>
        </div>

        <!-- Devices Grid -->
        <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div
            v-for="d in customer.devices"
            :key="d.id"
            class="p-5 border border-slate-200/80 dark:border-slate-800 rounded-2xl bg-slate-50/70 dark:bg-slate-900/50 hover:border-purple-300 dark:hover:border-purple-800 transition flex flex-col justify-between"
          >
            <div>
              <!-- Top Row: Icon + Title + Device Type -->
              <div class="flex items-start justify-between gap-3">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 rounded-xl bg-purple-100 dark:bg-purple-950/80 text-purple-600 dark:text-purple-400 flex items-center justify-center text-lg shrink-0">
                    {{ getDeviceIcon(d.device_type) }}
                  </div>
                  <div>
                    <h4 class="font-bold text-slate-900 dark:text-white text-sm">
                      {{ d.brand }} {{ d.model }}
                    </h4>
                    <div class="flex flex-wrap items-center gap-1.5 mt-0.5">
                      <span class="px-2 py-0.5 rounded text-[10px] font-bold uppercase bg-slate-200 dark:bg-slate-800 text-slate-700 dark:text-slate-300">
                        {{ d.device_type || 'Mobile' }}
                      </span>
                      <span v-if="d.variant" class="px-2 py-0.5 rounded text-[10px] font-semibold bg-purple-50 dark:bg-purple-950/50 text-purple-700 dark:text-purple-300">
                        {{ d.variant }}
                      </span>
                      <span v-if="d.color" class="px-2 py-0.5 rounded text-[10px] font-semibold bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400">
                        {{ d.color }}
                      </span>
                    </div>
                  </div>
                </div>

                <!-- Edit & Delete Action Menu -->
                <div class="flex items-center gap-1">
                  <button
                    @click="openEditDeviceModal(d)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-400 hover:text-indigo-600 hover:bg-indigo-50 dark:hover:bg-slate-800 transition cursor-pointer"
                    title="Edit Device Details"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"/></svg>
                  </button>
                  <button
                    @click="handleDeleteDevice(d)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-slate-800 transition cursor-pointer"
                    title="Delete Device"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                  </button>
                </div>
              </div>

              <!-- Identifiers: IMEI & Serial -->
              <div class="mt-3.5 pt-3 border-t border-slate-200/60 dark:border-slate-800/80 space-y-1.5 text-xs font-mono">
                <div v-if="d.imei_1 || d.imei1" class="flex items-center justify-between text-slate-600 dark:text-slate-400">
                  <span>IMEI 1:</span>
                  <span class="font-bold text-slate-800 dark:text-slate-200">{{ d.imei_1 || d.imei1 }}</span>
                </div>
                <div v-if="d.imei_2 || d.imei2" class="flex items-center justify-between text-slate-600 dark:text-slate-400">
                  <span>IMEI 2:</span>
                  <span class="font-bold text-slate-800 dark:text-slate-200">{{ d.imei_2 || d.imei2 }}</span>
                </div>
                <div v-if="d.serial_number" class="flex items-center justify-between text-slate-600 dark:text-slate-400">
                  <span>Serial:</span>
                  <span class="font-bold text-slate-800 dark:text-slate-200">{{ d.serial_number }}</span>
                </div>
                <div v-if="d.purchase_date" class="flex items-center justify-between text-slate-600 dark:text-slate-400">
                  <span class="font-sans">Purchased:</span>
                  <span class="font-sans font-medium text-slate-700 dark:text-slate-300">{{ formatDate(d.purchase_date) }}</span>
                </div>
                <p v-if="d.notes" class="text-[11px] font-sans italic text-slate-500 mt-2 bg-white/70 dark:bg-slate-900/60 p-2 rounded-lg">
                  {{ d.notes }}
                </p>
              </div>
            </div>

            <!-- Card Bottom: Instant New Repair Booking Action -->
            <div class="mt-4 pt-3 border-t border-slate-200/60 dark:border-slate-800/80 flex items-center justify-between">
              <span class="text-[10px] text-slate-400">ID #{{ d.id }}</span>
              <router-link
                :to="`/repairs/new?customer_id=${customer.id}&device_id=${d.id}`"
                class="inline-flex items-center gap-1 px-3 py-1.5 rounded-xl bg-amber-500/10 text-amber-600 dark:text-amber-400 hover:bg-amber-500 hover:text-white text-xs font-bold transition shadow-xs cursor-pointer"
              >
                <span>🔧 Book Repair</span>
                <span>→</span>
              </router-link>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Reusable Customer Device Modal -->
    <CustomerDeviceModal
      :is-open="deviceModalOpen"
      :customer="customer"
      :device-to-edit="deviceToEdit"
      @close="deviceModalOpen = false"
      @saved="loadCustomer"
    />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { customerApi, deviceApi } from '@/api/endpoints';
import { useToastStore } from '@/stores/toast';
import { formatDate } from '@/utils/date';
import CustomerDeviceModal from '@/components/customers/CustomerDeviceModal.vue';

const route = useRoute();
const toastStore = useToastStore();
const customer = ref({});
const activeTab = ref('repairs');

// Device Modal State
const deviceModalOpen = ref(false);
const deviceToEdit = ref(null);

function openAddDeviceModal() {
  deviceToEdit.value = null;
  deviceModalOpen.value = true;
}

function openEditDeviceModal(device) {
  deviceToEdit.value = device;
  deviceModalOpen.value = true;
}

function getDeviceIcon(type) {
  switch (type) {
    case 'Mobile': return '📱';
    case 'Tablet': return '📟';
    case 'Laptop': return '💻';
    default: return '⚙️';
  }
}

async function handleDeleteDevice(device) {
  const confirmed = await toastStore.confirm({
    title: 'Delete Registered Device?',
    message: `Are you sure you want to remove ${device.brand} ${device.model} from ${customer.value.name}'s account? This action cannot be undone.`,
    confirmText: 'Delete Device',
    type: 'danger',
  });

  if (confirmed) {
    try {
      await deviceApi.delete(device.id);
      toastStore.success(`Device ${device.brand} ${device.model} removed`);
      await loadCustomer();
    } catch (err) {
      console.error('Failed to delete device:', err);
      toastStore.error('Could not delete device. It may be linked to active repair orders.');
    }
  }
}

async function loadCustomer() {
  try {
    const res = await customerApi.get(route.params.id);
    customer.value = res.data?.data || res.data || {};
  } catch (err) {
    console.error('Failed to load customer:', err);
  }
}

function formatAmount(amt) {
  if (amt === undefined || amt === null || isNaN(amt)) return '0.00';
  return Number(amt).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

onMounted(() => {
  loadCustomer();
});
</script>
