<template>
  <div class="space-y-6">
    <!-- Header Actions -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <div class="flex items-center gap-2">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 border border-indigo-200/60 dark:border-indigo-800/60">
            Stock Management
          </span>
          <span class="text-xs text-slate-400">Parts, Displays, ICs & Accessories</span>
        </div>
        <h1 class="text-2xl font-bold tracking-tight text-slate-900 dark:text-white mt-1">Inventory & Spare Parts Catalogue</h1>
        <p class="text-xs sm:text-sm text-slate-500 dark:text-slate-400">Track item stock levels, cost prices, selling margins, and low stock thresholds.</p>
      </div>
      <button
        @click="openCreateModal"
        type="button"
        class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold shadow-md shadow-indigo-600/20 transition-all hover:scale-[1.02] active:scale-[0.98]"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" d="M12 4v16m8-8H4"/></svg>
        + Add Item / Part
      </button>
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
          placeholder="Search by Item name, SKU, Barcode, category..."
        />
      </div>

      <div class="flex items-center gap-2">
        <SearchableSelect
          v-model="stockFilter"
          :options="stockFilterOptions"
          @change="fetchItems"
          placeholder="All Stock Levels"
          searchPlaceholder="Search stock levels..."
          minWidth="150px"
        />

        <button
          v-if="searchQuery || stockFilter"
          @click="searchQuery = ''; stockFilter = ''; fetchItems()"
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
              <th class="py-3.5 px-4 pl-6">Item / Part Details</th>
              <th class="py-3.5 px-4">SKU / Code</th>
              <th class="py-3.5 px-4">Stock Level</th>
              <th class="py-3.5 px-4">Purchase Cost</th>
              <th class="py-3.5 px-4">Selling Price</th>
              <th class="py-3.5 px-4 pr-6 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100 dark:divide-slate-800/60 text-sm">
            <tr v-if="loading">
              <td colspan="6" class="py-12 text-center text-xs text-slate-400">
                <div class="inline-block animate-spin w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full mb-2"></div>
                <div>Loading inventory items...</div>
              </td>
            </tr>
            <tr v-else-if="items.length === 0">
              <td colspan="6" class="py-12 text-center text-slate-400 dark:text-slate-500 text-xs">
                No inventory items found matching criteria.
              </td>
            </tr>
            <tr
              v-for="item in items"
              :key="item.id"
              class="hover:bg-slate-50/70 dark:hover:bg-slate-800/40 transition-colors group"
            >
              <td class="py-3.5 px-4 pl-6">
                <div class="font-bold text-slate-900 dark:text-white">{{ item.name }}</div>
                <div class="text-[11px] text-slate-400 mt-0.5">{{ item.category || 'General Spare Part' }}</div>
              </td>
              <td class="py-3.5 px-4">
                <span class="font-mono text-xs text-slate-600 dark:text-slate-400 bg-slate-100 dark:bg-slate-800 px-2 py-0.5 rounded border border-slate-200 dark:border-slate-700/60">
                  {{ item.sku || item.barcode || 'NO-SKU' }}
                </span>
              </td>
              <td class="py-3.5 px-4">
                <span :class="getStockBadgeClass(item)" class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold">
                  {{ item.stock_quantity ?? item.current_stock ?? 0 }} in stock
                </span>
              </td>
              <td class="py-3.5 px-4">
                <span class="font-bold text-slate-700 dark:text-slate-300 tabular-nums">
                  ₹{{ formatAmount(item.cost_price || item.purchase_price || 0) }}
                </span>
              </td>
              <td class="py-3.5 px-4">
                <span class="font-extrabold text-slate-900 dark:text-white tabular-nums">
                  ₹{{ formatAmount(item.selling_price || item.unit_price || 0) }}
                </span>
              </td>
              <td class="py-3.5 px-4 pr-6 text-right">
                <div class="flex items-center justify-end gap-1">
                  <!-- Edit -->
                  <button
                    @click="editItem(item)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-500 hover:text-amber-600 hover:bg-amber-50 dark:hover:bg-slate-800 transition cursor-pointer"
                    title="Edit Item"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
                  </button>

                  <!-- Delete -->
                  <button
                    @click="confirmDeleteItem(item)"
                    type="button"
                    class="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/40 transition cursor-pointer"
                    title="Delete Item"
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

    <!-- Add / Edit Item Modal -->
    <div
      v-if="modalOpen"
      class="fixed inset-0 z-50 overflow-y-auto flex min-h-full items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm py-6 sm:py-10"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-[#111827] w-full max-w-lg rounded-2xl shadow-2xl border border-slate-200/80 dark:border-slate-800/80 overflow-hidden my-auto max-h-[calc(100vh-3rem)] flex flex-col animate-in fade-in zoom-in-95">
        <div class="px-6 py-4 border-b border-slate-100 dark:border-slate-800/80 flex justify-between items-center bg-slate-50/50 dark:bg-slate-900/30 shrink-0">
          <div>
            <h3 class="text-sm font-bold text-slate-900 dark:text-white">{{ editingId ? 'Edit Inventory Item' : 'Add New Inventory Item' }}</h3>
            <p class="text-[11px] text-slate-400">Manage item stock details and pricing</p>
          </div>
          <button @click="modalOpen = false" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition cursor-pointer">✕</button>
        </div>
        <form @submit.prevent="saveItem" class="p-6 space-y-4 overflow-y-auto custom-scroll flex-1">
          <div class="grid grid-cols-2 gap-4">
            <div class="col-span-2">
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Item Name <span class="text-rose-500">*</span></label>
              <input v-model="form.name" type="text" required class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400" placeholder="e.g. iPhone 13 Display OLED" />
            </div>
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">SKU / Barcode</label>
              <input v-model="form.sku" type="text" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400" placeholder="e.g. DISP-IP13-01" />
            </div>
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Stock Quantity <span class="text-rose-500">*</span></label>
              <input v-model.number="form.stock_quantity" type="number" min="0" required class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100" />
            </div>
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Cost Price (₹)</label>
              <input v-model.number="form.cost_price" type="number" step="0.01" min="0" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100" />
            </div>
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Selling Price (₹) <span class="text-rose-500">*</span></label>
              <input v-model.number="form.selling_price" type="number" step="0.01" min="0" required class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100" />
            </div>
          </div>
          <div class="flex justify-end gap-2 pt-3 border-t border-slate-100 dark:border-slate-800/80 shrink-0">
            <button type="button" @click="modalOpen = false" class="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-xl transition cursor-pointer">Cancel</button>
            <button
              type="submit"
              class="px-4 py-2 text-xs font-semibold text-white bg-indigo-600 hover:bg-indigo-500 rounded-xl shadow-md shadow-indigo-600/20 transition cursor-pointer"
            >
              {{ editingId ? 'Update Item' : 'Add Item' }}
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
        <h3 class="text-base font-bold text-slate-900 dark:text-white">Delete Inventory Item?</h3>
        <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
          Are you sure you want to delete <span class="font-bold text-slate-700 dark:text-slate-300">{{ itemToDelete?.name }}</span>?
        </p>
        <div class="flex items-center justify-center gap-2 mt-5">
          <button
            @click="deleteModalOpen = false"
            class="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition"
          >
            Cancel
          </button>
          <button
            @click="executeDeleteItem"
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
import { useToastStore } from '@/stores/toast';
import { inventoryApi } from '@/api/endpoints';
import PaginationBar from '@/components/common/PaginationBar.vue';
import SearchableSelect from '@/components/common/SearchableSelect.vue';

const toast = useToastStore();

const stockFilterOptions = [
  { value: '', label: 'All Stock Levels' },
  { value: 'in_stock', label: 'In Stock Items' },
  { value: 'low_stock', label: 'Low Stock Warning' },
  { value: 'out_of_stock', label: 'Out of Stock' },
];

const items = ref([]);
const loading = ref(false);
const searchQuery = ref('');
const stockFilter = ref('');
const currentPage = ref(1);
const totalPages = ref(1);
const totalCount = ref(0);
const perPage = ref(10);
let searchTimer = null;

const modalOpen = ref(false);
const editingId = ref(null);

const deleteModalOpen = ref(false);
const itemToDelete = ref(null);
const deleting = ref(false);

const form = reactive({
  name: '',
  sku: '',
  stock_quantity: 0,
  cost_price: 0,
  selling_price: 0,
});

function debounceSearch() {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => {
    currentPage.value = 1;
    fetchItems();
  }, 350);
}

async function fetchItems() {
  loading.value = true;
  try {
    const res = await inventoryApi.list({
      page: currentPage.value,
      per_page: perPage.value,
      search: searchQuery.value,
      filter: stockFilter.value,
    });
    const payload = res.data?.data;
    if (payload?.data) {
      items.value = payload.data;
      currentPage.value = payload.current_page || 1;
      totalCount.value = payload.total || payload.data.length;
      totalPages.value = payload.last_page || Math.max(1, Math.ceil(totalCount.value / perPage.value));
      if (payload.per_page) perPage.value = payload.per_page;
    } else if (res.data?.meta) {
      items.value = Array.isArray(payload) ? payload : [];
      currentPage.value = res.data.meta.current_page || 1;
      totalCount.value = res.data.meta.total || items.value.length;
      totalPages.value = res.data.meta.last_page || Math.max(1, Math.ceil(totalCount.value / perPage.value));
      if (res.data.meta.per_page) perPage.value = res.data.meta.per_page;
    } else {
      items.value = Array.isArray(payload) ? payload : [];
      totalCount.value = items.value.length;
      totalPages.value = Math.max(1, Math.ceil(items.value.length / perPage.value));
    }
  } catch (err) {
    console.error('Failed to load inventory items:', err);
  } finally {
    loading.value = false;
  }
}

function changePage(p) {
  currentPage.value = p;
  fetchItems();
}

function formatAmount(amt) {
  return (Number(amt) || 0).toLocaleString('en-IN');
}

function getStockBadgeClass(item) {
  const qty = Number(item.stock_quantity ?? item.current_stock ?? 0);
  if (qty <= 0) {
    return 'bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-900/40';
  }
  if (qty <= (item.low_stock_threshold || 3)) {
    return 'bg-amber-50 dark:bg-amber-950/40 text-amber-600 dark:text-amber-400 border border-amber-200 dark:border-amber-900/40';
  }
  return 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-900/40';
}

function openCreateModal() {
  editingId.value = null;
  form.name = '';
  form.sku = '';
  form.stock_quantity = 0;
  form.cost_price = 0;
  form.selling_price = 0;
  modalOpen.value = true;
}

function editItem(item) {
  editingId.value = item.id;
  form.name = item.name;
  form.sku = item.sku || item.barcode || '';
  form.stock_quantity = item.stock_quantity ?? item.current_stock ?? 0;
  form.cost_price = item.cost_price || item.purchase_price || 0;
  form.selling_price = item.selling_price || item.unit_price || 0;
  modalOpen.value = true;
}

async function saveItem() {
  try {
    const itemName = form.name;
    if (editingId.value) {
      await inventoryApi.update(editingId.value, form);
      toast.success(`Inventory item "${itemName}" updated successfully!`, 'Item Updated');
    } else {
      await inventoryApi.create(form);
      toast.success(`Item "${itemName}" added to inventory!`, 'Item Created');
    }
    modalOpen.value = false;
    fetchItems();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to save item';
    toast.error(msg, 'Save Item Failed');
  }
}

function confirmDeleteItem(item) {
  itemToDelete.value = item;
  deleteModalOpen.value = true;
}

async function executeDeleteItem() {
  if (!itemToDelete.value) return;
  deleting.value = true;
  try {
    const itemName = itemToDelete.value.name;
    await inventoryApi.delete(itemToDelete.value.id);
    deleteModalOpen.value = false;
    itemToDelete.value = null;
    toast.success(`Item "${itemName}" deleted from inventory.`, 'Item Deleted');
    fetchItems();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to delete item';
    toast.error(msg, 'Delete Item Failed');
  } finally {
    deleting.value = false;
  }
}

onMounted(() => {
  fetchItems();
});
</script>
