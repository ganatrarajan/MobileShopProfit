<template>
  <div class="max-w-5xl mx-auto space-y-6 pb-16 font-['Outfit',sans-serif]">
    <!-- Top Action Bar -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div class="flex items-center gap-3">
        <router-link
          to="/sales"
          class="inline-flex items-center gap-1.5 px-3 py-2 text-xs font-semibold rounded-xl bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-200 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 shadow-sm transition"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/></svg>
          Back to Sales
        </router-link>
        <div>
          <h1 class="text-2xl font-bold text-slate-900 dark:text-white">New Sale / POS Counter</h1>
          <p class="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
            Bill accessories, devices, or inventory parts with real-time stock deduction and invoice generation
          </p>
        </div>
      </div>

      <div class="flex items-center gap-2">
        <router-link to="/sales" class="px-4 py-2 text-xs font-semibold rounded-xl border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 hover:bg-slate-50">
          Cancel
        </router-link>
        <button
          type="button"
          @click="submitSale"
          :disabled="submitting"
          class="px-5 py-2 text-xs font-bold rounded-xl bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-white shadow-md shadow-emerald-500/20 transition flex items-center gap-1.5"
        >
          <svg v-if="submitting" class="w-3.5 h-3.5 animate-spin" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path></svg>
          {{ submitting ? 'Processing...' : 'Complete & Generate Invoice' }}
        </button>
      </div>
    </div>

    <!-- Alert Banner -->
    <div v-if="errorMsg" class="p-4 bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-800 rounded-2xl text-xs font-semibold text-red-700 dark:text-red-300 flex items-center justify-between">
      <div class="flex items-center gap-2">
        <svg class="w-4 h-4 text-red-500 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
        <span>{{ errorMsg }}</span>
      </div>
      <button @click="errorMsg = ''" class="text-red-400 hover:text-red-600">✕</button>
    </div>

    <form @submit.prevent="submitSale" class="space-y-6">
      <!-- 1. Customer Selection (Dropdown & Quick Add) -->
      <div class="bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200/80 dark:border-slate-700/80 shadow-sm space-y-4">
        <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-lg bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 flex items-center justify-center font-bold">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
            </div>
            <div>
              <h3 class="font-bold text-slate-900 dark:text-white text-sm">Customer Profile</h3>
              <p class="text-[11px] text-slate-400">Select registered customer or enter walk-in customer details</p>
            </div>
          </div>

          <button
            type="button"
            @click="showQuickCustomerModal = true"
            class="text-xs font-bold text-emerald-600 hover:text-emerald-700 flex items-center gap-1 bg-emerald-50 dark:bg-emerald-950/40 px-3 py-1.5 rounded-xl border border-emerald-200 dark:border-emerald-800"
          >
            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
            + Add Customer
          </button>
        </div>

        <!-- Selected Customer Card -->
        <div v-if="selectedCustomer" class="p-4 bg-emerald-50/60 dark:bg-emerald-950/30 rounded-2xl border border-emerald-100 dark:border-emerald-900/40 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-xl bg-emerald-600 text-white flex items-center justify-center font-extrabold text-base shadow-sm">
              {{ (selectedCustomer.name || 'C')[0] }}
            </div>
            <div>
              <div class="flex items-center gap-2">
                <h4 class="font-bold text-slate-900 dark:text-white text-sm">{{ selectedCustomer.name }}</h4>
                <span class="text-[10px] font-bold text-emerald-700 dark:text-emerald-300 bg-white dark:bg-slate-800 px-2 py-0.5 rounded-full border border-emerald-200 dark:border-emerald-800">
                  Customer #{{ selectedCustomer.id }}
                </span>
              </div>
              <div class="flex items-center gap-3 text-xs text-slate-500 dark:text-slate-400 mt-0.5 font-mono">
                <span>📞 {{ selectedCustomer.phone || selectedCustomer.mobile || 'No mobile' }}</span>
                <span v-if="selectedCustomer.city" class="font-sans">📍 {{ selectedCustomer.city }}</span>
              </div>
            </div>
          </div>

          <button
            type="button"
            @click="clearCustomerSelection"
            class="text-xs font-bold text-emerald-600 dark:text-emerald-400 hover:underline self-start sm:self-center"
          >
            Change / Walk-in
          </button>
        </div>

        <!-- Customer Search & Walk-in Input -->
        <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
              Search Registered Customer
            </label>
            <div class="relative" ref="customerSearchContainer">
              <input
                v-model="customerSearchQuery"
                @focus="showCustomerDropdown = true"
                type="text"
                placeholder="Type customer name or mobile..."
                class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-semibold focus:ring-2 focus:ring-emerald-500"
              />
              <!-- Invisible Backdrop to close dropdown on click outside -->
              <div
                v-if="showCustomerDropdown"
                @click="showCustomerDropdown = false"
                class="fixed inset-0 z-20"
              ></div>

              <div
                v-if="showCustomerDropdown && filteredCustomers.length > 0"
                class="absolute left-0 right-0 top-full mt-1 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl shadow-xl max-h-52 overflow-y-auto z-30 divide-y divide-slate-100 dark:divide-slate-700"
              >
                <div
                  v-for="c in filteredCustomers"
                  :key="c.id"
                  @click="selectCustomer(c)"
                  class="p-2.5 hover:bg-emerald-50 dark:hover:bg-emerald-950/40 cursor-pointer flex items-center justify-between text-xs"
                >
                  <div>
                    <p class="font-bold text-slate-800 dark:text-slate-200">{{ c.name }}</p>
                    <p class="text-slate-400 font-mono text-[11px]">{{ c.phone || c.mobile }}</p>
                  </div>
                  <span class="text-[10px] font-bold text-emerald-600 bg-white dark:bg-slate-700 px-2 py-0.5 rounded">Select</span>
                </div>
              </div>
            </div>
          </div>

          <div>
            <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
              Or Walk-in Customer Name
            </label>
            <input
              v-model="form.customer_name"
              type="text"
              placeholder="e.g. Walk-in Customer, Amit, etc."
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-semibold"
            />
          </div>
        </div>
      </div>

      <!-- 2. Product Items & Inventory Selector Table -->
      <div class="bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200/80 dark:border-slate-700/80 shadow-sm space-y-4">
        <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-lg bg-indigo-50 dark:bg-indigo-950/40 text-indigo-600 dark:text-indigo-400 flex items-center justify-center font-bold">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"/></svg>
            </div>
            <div>
              <h3 class="font-bold text-slate-900 dark:text-white text-sm">Line Items & Products</h3>
              <p class="text-[11px] text-slate-400">Pick from shop inventory stock or type custom line item</p>
            </div>
          </div>

          <button
            type="button"
            @click="addItemRow"
            class="text-xs font-bold text-indigo-600 hover:text-indigo-700 flex items-center gap-1 bg-indigo-50 dark:bg-indigo-950/40 px-3 py-1.5 rounded-xl border border-indigo-200 dark:border-indigo-800"
          >
            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
            + Add Row
          </button>
        </div>

        <!-- Items Table -->
        <div class="overflow-x-auto">
          <table class="w-full text-xs">
            <thead>
              <tr class="text-slate-400 uppercase font-semibold border-b border-slate-200 dark:border-slate-700 text-left">
                <th class="py-2.5 w-1/3">Item Description / Inventory Picker</th>
                <th class="py-2.5 w-24 text-center">Qty</th>
                <th class="py-2.5 w-32 text-right">Unit Rate (₹)</th>
                <th class="py-2.5 w-32 text-right">Line Total (₹)</th>
                <th class="py-2.5 w-12 text-center"></th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100 dark:divide-slate-700/60 font-medium">
              <tr v-for="(item, idx) in form.items" :key="idx">
                <td class="py-3 pr-2">
                  <div class="space-y-1.5">
                    <!-- Searchable Dropdown to pick from inventory -->
                    <SearchableSelect
                      v-model="item.inventory_item_id"
                      :options="inventoryOptions"
                      @change="(val) => onInventoryOptionChange(item, val)"
                      placeholder="-- Pick from Shop Inventory (Optional) --"
                      searchPlaceholder="Search product by name, brand, SKU..."
                      minWidth="100%"
                      popoverMinWidth="100%"
                      popoverMaxWidth="500px"
                      :fullWidth="true"
                    />

                    <!-- Item Name input -->
                    <input
                      v-model="item.item_name"
                      type="text"
                      placeholder="e.g. 65W SuperVOOC Charger, Tempered Glass"
                      required
                      class="w-full px-3.5 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-xs font-semibold"
                    />
                  </div>
                </td>

                <td class="py-3 px-2 text-center align-top">
                  <input
                    v-model.number="item.quantity"
                    type="number"
                    min="1"
                    required
                    class="w-20 px-2.5 py-2 text-center rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-xs font-bold"
                  />
                </td>

                <td class="py-3 px-2 text-right align-top">
                  <input
                    v-model.number="item.unit_price"
                    type="number"
                    step="0.01"
                    min="0"
                    required
                    class="w-28 px-2.5 py-2 text-right rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-xs font-bold font-mono"
                  />
                </td>

                <td class="py-3 px-2 text-right align-top pt-4">
                  <span class="font-bold text-slate-900 dark:text-white font-mono text-sm">
                    ₹{{ formatAmount(Number(item.quantity || 1) * Number(item.unit_price || 0)) }}
                  </span>
                </td>

                <td class="py-3 pl-2 text-center align-top pt-4">
                  <button
                    v-if="form.items.length > 1"
                    type="button"
                    @click="removeItemRow(idx)"
                    class="text-rose-500 hover:text-rose-700 p-1 rounded hover:bg-rose-50"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- 3. Billing, Discount & Settlement Summary -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Payment Method & Notes -->
        <div class="bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200/80 dark:border-slate-700/80 shadow-sm space-y-4">
          <h3 class="font-bold text-slate-900 dark:text-white text-sm border-b border-slate-100 dark:border-slate-700 pb-2">
            Payment & Settlement
          </h3>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">Payment Method</label>
              <SearchableSelect
                v-model="form.payment_method"
                :options="salePaymentOptions"
                placeholder="Select Method"
                minWidth="100%"
              />
            </div>

            <div>
              <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
                Amount Paid Now (₹)
              </label>
              <input
                v-model.number="form.payment_amount"
                type="number"
                step="0.01"
                min="0"
                class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-bold text-emerald-600 font-mono"
              />
            </div>
          </div>

          <div>
            <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">Invoice Remarks / Customer Note</label>
            <input
              v-model="form.notes"
              type="text"
              placeholder="e.g. 6 Months warranty on display. No return on opened box."
              class="w-full px-3.5 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs"
            />
          </div>
        </div>

        <!-- Order Summary Card -->
        <div class="bg-slate-50 dark:bg-slate-900 rounded-2xl p-5 border border-slate-200 dark:border-slate-800 space-y-3 flex flex-col justify-between">
          <div>
            <h3 class="font-bold text-slate-900 dark:text-white text-sm border-b border-slate-200 dark:border-slate-700 pb-2 mb-3">
              Invoice Ledger Summary
            </h3>

            <div class="space-y-2 text-xs">
              <div class="flex justify-between text-slate-500">
                <span>Subtotal:</span>
                <span class="font-semibold text-slate-800 dark:text-slate-200 font-mono">₹{{ formatAmount(subtotal) }}</span>
              </div>
              <div class="flex justify-between items-center text-slate-500">
                <span>Special Discount (₹):</span>
                <input
                  v-model.number="form.discount"
                  type="number"
                  min="0"
                  class="w-24 px-2 py-1 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg text-right font-mono font-bold text-xs"
                />
              </div>
              <div class="flex justify-between font-extrabold text-base text-slate-900 dark:text-white pt-2 border-t border-slate-200 dark:border-slate-700">
                <span>Grand Total:</span>
                <span class="text-indigo-600 dark:text-indigo-400 font-mono">₹{{ formatAmount(grandTotal) }}</span>
              </div>
              <div class="flex justify-between text-emerald-600 font-semibold pt-1">
                <span>Amount Paid:</span>
                <span class="font-mono">₹{{ formatAmount(form.payment_amount) }}</span>
              </div>
              <div class="flex justify-between font-bold text-sm pt-2 border-t border-slate-200 dark:border-slate-700">
                <span>Balance Due:</span>
                <span :class="dueAmount > 0 ? 'text-rose-600' : 'text-emerald-600'" class="font-mono">
                  ₹{{ formatAmount(dueAmount) }}
                </span>
              </div>
            </div>
          </div>

          <button
            type="submit"
            :disabled="submitting"
            class="w-full py-3 rounded-xl bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-white font-bold text-xs shadow-lg shadow-emerald-500/20 transition"
          >
            {{ submitting ? 'Generating Invoice...' : 'Complete & Generate Tax Invoice' }}
          </button>
        </div>
      </div>
    </form>

    <!-- Quick Add Customer Modal -->
    <div
      v-if="showQuickCustomerModal"
      class="fixed inset-0 z-50 overflow-y-auto flex min-h-full items-center justify-center p-4 py-6 sm:py-10 bg-black/60 backdrop-blur-sm animate-fade-in"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-slate-800 rounded-3xl max-w-md w-full p-6 shadow-2xl border border-slate-200 dark:border-slate-700 space-y-4 my-auto max-h-[calc(100vh-3rem)] flex flex-col overflow-hidden">
        <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3">
          <h3 class="font-bold text-slate-900 dark:text-white text-base">+ Quick Add Customer</h3>
          <button @click="showQuickCustomerModal = false" class="text-slate-400 hover:text-slate-600">✕</button>
        </div>

        <form @submit.prevent="submitQuickCustomer" class="space-y-4 text-xs">
          <div>
            <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">
              Customer Name <span class="text-rose-500">*</span>
            </label>
            <input
              v-model="quickCustomerForm.name"
              type="text"
              required
              placeholder="e.g. Ramesh Patel"
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-semibold"
            />
          </div>
          <div>
            <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">
              Mobile Number <span class="text-rose-500">*</span>
            </label>
            <input
              v-model="quickCustomerForm.phone"
              type="tel"
              required
              placeholder="10-digit mobile"
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-mono font-semibold"
            />
          </div>
          <div>
            <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">City / Area</label>
            <input
              v-model="quickCustomerForm.city"
              type="text"
              placeholder="e.g. Surat, Mumbai"
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs"
            />
          </div>
          <div class="flex items-center justify-end gap-2 pt-2">
            <button
              type="button"
              @click="showQuickCustomerModal = false"
              class="px-4 py-2 rounded-xl border border-slate-200 text-slate-600 font-semibold"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="quickCustomerSubmitting"
              class="px-5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold"
            >
              {{ quickCustomerSubmitting ? 'Saving...' : 'Save & Select' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { useToastStore } from '@/stores/toast';
import { saleApi, customerApi, inventoryApi } from '@/api/endpoints';
import SearchableSelect from '@/components/common/SearchableSelect.vue';

const router = useRouter();
const toast = useToastStore();

const customerSearchContainer = ref(null);

function handleClickOutside(event) {
  if (customerSearchContainer.value && !customerSearchContainer.value.contains(event.target)) {
    showCustomerDropdown.value = false;
  }
}

const salePaymentOptions = [
  { value: 'cash', label: 'Cash', icon: '💵' },
  { value: 'upi', label: 'UPI / Scanner', icon: '⚡' },
  { value: 'card', label: 'Card / POS', icon: '💳' },
  { value: 'bank_transfer', label: 'Bank Transfer', icon: '🏦' },
  { value: 'credit', label: 'On Credit (Due / Udhar)', icon: '⏳' },
];
const submitting = ref(false);
const errorMsg = ref('');

// Lists
const customers = ref([]);
const inventoryList = ref([]);

// Customer selection
const customerSearchQuery = ref('');
const showCustomerDropdown = ref(false);
const selectedCustomer = ref(null);

// Quick Customer Modal
const showQuickCustomerModal = ref(false);
const quickCustomerSubmitting = ref(false);
const quickCustomerForm = reactive({
  name: '',
  phone: '',
  city: '',
});

// Main Form
const form = reactive({
  customer_id: null,
  customer_name: '',
  customer_phone: '',
  payment_method: 'cash',
  discount: 0,
  payment_amount: 0,
  notes: '',
  items: [
    { inventory_item_id: null, item_name: '', quantity: 1, unit_price: 0 },
  ],
});

const filteredCustomers = computed(() => {
  const q = customerSearchQuery.value.trim().toLowerCase();
  if (!q) return customers.value.slice(0, 10);
  return customers.value.filter(c =>
    (c.name && c.name.toLowerCase().includes(q)) ||
    (c.phone && c.phone.includes(q)) ||
    (c.mobile && c.mobile.includes(q))
  ).slice(0, 15);
});

const subtotal = computed(() => {
  return form.items.reduce((sum, item) => sum + ((Number(item.quantity) || 0) * (Number(item.unit_price) || 0)), 0);
});

const grandTotal = computed(() => {
  const tot = subtotal.value - (Number(form.discount) || 0);
  return tot > 0 ? tot : 0;
});

const dueAmount = computed(() => {
  const due = grandTotal.value - (Number(form.payment_amount) || 0);
  return due > 0 ? due : 0;
});

function addItemRow() {
  form.items.push({ inventory_item_id: null, item_name: '', quantity: 1, unit_price: 0 });
}

function removeItemRow(index) {
  form.items.splice(index, 1);
}

const inventoryOptions = computed(() => {
  return [
    {
      value: null,
      label: '-- Custom Item / Manual Entry --',
      icon: '✍️',
    },
    ...inventoryList.value.map(inv => ({
      value: inv.id,
      label: inv.name,
      stock: Number(inv.current_stock ?? 0),
      price: Number(inv.selling_price || 0),
      brand: inv.brand || '',
      sku: inv.sku || '',
      item: inv,
    }))
  ];
});

function onInventoryOptionChange(item, selectedId) {
  item.inventory_item_id = selectedId;
  if (!selectedId) {
    return;
  }
  const found = inventoryList.value.find(i => i.id === selectedId);
  if (found) {
    item.item_name = found.name;
    item.unit_price = Number(found.selling_price || 0);
  }
}

function onInventoryItemSelected(item) {
  const found = inventoryList.value.find(i => i.id === item.inventory_item_id);
  if (found) {
    item.item_name = found.name;
    item.unit_price = Number(found.selling_price || 0);
  }
}

function selectCustomer(c) {
  selectedCustomer.value = c;
  form.customer_id = c.id;
  form.customer_name = c.name;
  form.customer_phone = c.phone || c.mobile || '';
  showCustomerDropdown.value = false;
}

function clearCustomerSelection() {
  selectedCustomer.value = null;
  form.customer_id = null;
  form.customer_name = '';
  form.customer_phone = '';
  customerSearchQuery.value = '';
}

async function submitQuickCustomer() {
  quickCustomerSubmitting.value = true;
  try {
    const res = await customerApi.create(quickCustomerForm);
    const created = res.data?.data || res.data;
    if (created) {
      customers.value.unshift(created);
      selectCustomer(created);
      showQuickCustomerModal.value = false;
      toast.success(`Customer "${created.name}" created and selected!`, 'Customer Added');
      quickCustomerForm.name = '';
      quickCustomerForm.phone = '';
      quickCustomerForm.city = '';
    }
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to create customer.';
    toast.error(msg, 'Customer Failed');
  } finally {
    quickCustomerSubmitting.value = false;
  }
}

async function loadData() {
  try {
    const [custRes, invRes] = await Promise.all([
      customerApi.list({ per_page: 200 }),
      inventoryApi.list({ per_page: 200 }),
    ]);
    customers.value = custRes.data?.data?.data || custRes.data?.data || [];
    inventoryList.value = invRes.data?.data?.data || invRes.data?.data || [];
  } catch (err) {
    console.error('Failed to load customers or inventory:', err);
  }
}

async function submitSale() {
  submitting.value = true;
  errorMsg.value = '';

  if (form.items.length === 0 || !form.items[0].item_name) {
    const msg = 'Please add at least one line item with a product name and price.';
    errorMsg.value = msg;
    toast.warning(msg, 'Incomplete Items');
    submitting.value = false;
    return;
  }

  try {
    const payload = {
      customer_id: form.customer_id || null,
      customer_name: form.customer_name || 'Walk-in Customer',
      customer_mobile: form.customer_phone || null,
      sale_type: form.customer_id ? 'regular' : 'quick',
      discount: Number(form.discount || 0),
      payment_amount: Number(form.payment_amount || grandTotal.value),
      payment_method: form.payment_method === 'credit' ? 'other' : (form.payment_method || 'cash'),
      notes: form.notes || null,
      items: form.items.map(it => ({
        inventory_item_id: it.inventory_item_id || null,
        product_name: it.item_name,
        item_name: it.item_name,
        quantity: Number(it.quantity || 1),
        unit_price: Number(it.unit_price || 0),
      })),
    };

    const res = await saleApi.create(payload);
    const saleId = res.data?.data?.id || res.data?.id;
    const invNo = res.data?.data?.invoice_number || res.data?.invoice_number || ('INV-' + saleId);
    toast.success(`Sale invoice #${invNo} generated successfully!`, 'Invoice Created');
    if (saleId) {
      router.push(`/sales/${saleId}`);
    } else {
      router.push('/sales');
    }
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to complete sale. Check inputs.';
    errorMsg.value = msg;
    toast.error(msg, 'Sale Generation Failed');
  } finally {
    submitting.value = false;
  }
}

function formatAmount(amt) {
  return (Number(amt) || 0).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

onMounted(() => {
  loadData();
  document.addEventListener('click', handleClickOutside);
});

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside);
});
</script>
