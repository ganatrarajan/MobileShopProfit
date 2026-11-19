<template>
  <div v-if="isOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4 overflow-y-auto">
    <!-- Backdrop -->
    <div @click="close" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm transition-opacity"></div>

    <!-- Modal Card -->
    <div class="relative w-full max-w-2xl bg-white dark:bg-[#111827] rounded-3xl border border-slate-200/80 dark:border-slate-800/80 shadow-2xl overflow-hidden z-10 my-8">
      <!-- Header -->
      <div class="p-6 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between">
        <div class="flex items-center gap-3">
          <div class="w-10 h-10 rounded-2xl bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 flex items-center justify-center shadow-xs">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"/></svg>
          </div>
          <div>
            <h3 class="text-base font-black text-slate-900 dark:text-white">
              {{ isEdit ? 'Edit Customer Device' : 'Register Customer Device' }}
            </h3>
            <p class="text-xs text-slate-400 mt-0.5">
              Customer: <span class="font-bold text-slate-700 dark:text-slate-300">{{ customerName }}</span>
              <span v-if="customerPhone" class="ml-1.5 font-mono">({{ customerPhone }})</span>
            </p>
          </div>
        </div>

        <button
          @click="close"
          type="button"
          class="p-2 rounded-xl text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition cursor-pointer"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
        </button>
      </div>

      <!-- Error Message Banner -->
      <div v-if="errorMessage" class="mx-6 mt-4 p-3.5 rounded-2xl bg-rose-500/10 border border-rose-500/20 text-rose-600 dark:text-rose-400 text-xs font-semibold flex items-center gap-2">
        <svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
        <span>{{ errorMessage }}</span>
      </div>

      <!-- Form Body -->
      <form @submit.prevent="handleSubmit" class="p-6 space-y-4 max-h-[75vh] overflow-y-auto">
        <!-- 1. Device Type -->
        <div>
          <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-2">
            Device Type <span class="text-rose-500">*</span>
          </label>
          <div class="grid grid-cols-4 gap-2">
            <button
              v-for="type in deviceTypes"
              :key="type"
              type="button"
              @click="form.device_type = type"
              :class="[
                'py-2 px-3 rounded-xl text-xs font-bold transition flex items-center justify-center gap-1.5 cursor-pointer border',
                form.device_type === type
                  ? 'bg-indigo-600 text-white border-indigo-600 shadow-sm shadow-indigo-600/20'
                  : 'bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800'
              ]"
            >
              <span>{{ getDeviceTypeIcon(type) }}</span>
              <span>{{ type }}</span>
            </button>
          </div>
        </div>

        <!-- 2. Brand & Model (2 Columns) -->
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <!-- Brand Searchable Select -->
          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
              Brand <span class="text-rose-500">*</span>
            </label>
            <SearchableSelect
              v-model="form.brand"
              :options="allBrandsCatalog"
              placeholder="Select or type brand..."
              searchPlaceholder="Search mobile brands from catalog..."
              :allowCustom="true"
              :clearable="true"
              :fullWidth="true"
              @change="onBrandSelected"
            />
          </div>

          <!-- Model Searchable Select -->
          <div>
            <div class="flex items-center justify-between mb-1.5">
              <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider">
                Model <span class="text-rose-500">*</span>
              </label>
              <span v-if="loadingModels" class="text-[10px] text-indigo-500 font-semibold animate-pulse">Loading models...</span>
              <span v-else-if="modelSuggestions.length" class="text-[10px] text-slate-400 font-medium">({{ modelSuggestions.length }} models)</span>
            </div>
            <SearchableSelect
              v-model="form.model"
              :options="modelSuggestions"
              :placeholder="modelSuggestions.length ? `Select or type model (${modelSuggestions.length} available)...` : 'Select or type model...'"
              searchPlaceholder="Search mobile models from catalog..."
              :allowCustom="true"
              :clearable="true"
              :fullWidth="true"
            />
          </div>
        </div>

        <!-- 4. RAM, Storage & Color (3 Columns) -->
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
              RAM (Optional)
            </label>
            <SearchableSelect
              v-model="form.ram"
              :options="ramOptions"
              placeholder="Select RAM"
              searchPlaceholder="Search or enter RAM..."
              :allowCustom="true"
              :clearable="true"
              :fullWidth="true"
              direction="down"
            />
          </div>

          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
              Storage (Optional)
            </label>
            <SearchableSelect
              v-model="form.storage"
              :options="storageOptions"
              placeholder="Select Storage"
              searchPlaceholder="Search or enter Storage..."
              :allowCustom="true"
              :clearable="true"
              :fullWidth="true"
              direction="down"
            />
          </div>

          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
              Color (Optional)
            </label>
            <input
              v-model="form.color"
              type="text"
              placeholder="e.g. Midnight Black, Deep Purple"
              class="w-full px-3.5 py-2.5 text-xs font-semibold bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 dark:focus:border-indigo-400 text-slate-900 dark:text-white"
            />
          </div>
        </div>

        <!-- 5. IMEI 1 & IMEI 2 (2 Columns with scanner options) -->
        <div>
          <div class="flex items-center justify-between mb-2">
            <span class="text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider flex items-center gap-1.5">
              <span>🏷️</span> Device Identifiers (IMEI & Serial)
            </span>
            <button
              type="button"
              @click="openScanner('box', 'Auto-Scan Phone Box Sticker', 'box')"
              class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-500 hover:to-purple-500 text-white text-[11px] font-bold shadow-xs transition cursor-pointer"
              title="Scan box sticker to automatically extract IMEI 1, IMEI 2, and Serial"
            >
              <span>⚡</span>
              <span>Auto-Scan Box Sticker</span>
            </button>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <!-- IMEI 1 -->
            <div>
              <div class="flex items-center justify-between mb-1.5">
                <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider">
                  IMEI 1 (Optional)
                </label>
                <div class="flex items-center gap-2">
                  <span
                    v-if="form.imei_1"
                    class="text-[10px] font-mono font-bold"
                    :class="form.imei_1.length === 15 ? 'text-emerald-500' : 'text-slate-400'"
                  >
                    {{ form.imei_1.length }}/15
                  </span>
                  <button
                    type="button"
                    @click="openScanner('imei_1', 'Scan Primary IMEI 1', 'camera')"
                    class="text-[11px] font-bold text-indigo-600 dark:text-indigo-400 hover:underline flex items-center gap-0.5 cursor-pointer"
                  >
                    <span>📷</span> Scan
                  </button>
                </div>
              </div>
              <div class="relative">
                <input
                  v-model="form.imei_1"
                  @input="cleanImei('imei_1')"
                  type="text"
                  maxlength="15"
                  placeholder="15-digit IMEI number"
                  class="w-full pl-3.5 pr-8 py-2.5 text-xs font-mono font-bold bg-slate-50 dark:bg-slate-900 border rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500/20 transition text-slate-900 dark:text-white"
                  :class="form.imei_1 && form.imei_1.length !== 15 ? 'border-amber-400' : 'border-slate-200 dark:border-slate-800 focus:border-indigo-500'"
                />
                <button
                  type="button"
                  @click="openScanner('imei_1', 'Scan Primary IMEI 1', 'camera')"
                  class="absolute inset-y-0 right-1 px-2 flex items-center text-slate-400 hover:text-indigo-600 cursor-pointer text-xs"
                  title="Scan IMEI 1"
                >
                  📷
                </button>
              </div>
            </div>

            <!-- IMEI 2 -->
            <div>
              <div class="flex items-center justify-between mb-1.5">
                <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider">
                  IMEI 2 (Optional)
                </label>
                <div class="flex items-center gap-2">
                  <span
                    v-if="form.imei_2"
                    class="text-[10px] font-mono font-bold"
                    :class="form.imei_2.length === 15 ? 'text-emerald-500' : 'text-slate-400'"
                  >
                    {{ form.imei_2.length }}/15
                  </span>
                  <button
                    type="button"
                    @click="openScanner('imei_2', 'Scan Secondary IMEI 2', 'camera')"
                    class="text-[11px] font-bold text-indigo-600 dark:text-indigo-400 hover:underline flex items-center gap-0.5 cursor-pointer"
                  >
                    <span>📷</span> Scan
                  </button>
                </div>
              </div>
              <div class="relative">
                <input
                  v-model="form.imei_2"
                  @input="cleanImei('imei_2')"
                  type="text"
                  maxlength="15"
                  placeholder="15-digit second IMEI"
                  class="w-full pl-3.5 pr-8 py-2.5 text-xs font-mono font-bold bg-slate-50 dark:bg-slate-900 border rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500/20 transition text-slate-900 dark:text-white"
                  :class="form.imei_2 && form.imei_2.length !== 15 ? 'border-amber-400' : 'border-slate-200 dark:border-slate-800 focus:border-indigo-500'"
                />
                <button
                  type="button"
                  @click="openScanner('imei_2', 'Scan Secondary IMEI 2', 'camera')"
                  class="absolute inset-y-0 right-1 px-2 flex items-center text-slate-400 hover:text-indigo-600 cursor-pointer text-xs"
                  title="Scan IMEI 2"
                >
                  📷
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- 6. Serial Number & Purchase Date (2 Columns with Serial Scan) -->
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <div class="flex items-center justify-between mb-1.5">
              <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider">
                Serial Number (Optional)
              </label>
              <button
                type="button"
                @click="openScanner('serial_number', 'Scan Serial Number', 'camera')"
                class="text-[11px] font-bold text-indigo-600 dark:text-indigo-400 hover:underline flex items-center gap-0.5 cursor-pointer"
              >
                <span>📷</span> Scan
              </button>
            </div>
            <div class="relative">
              <input
                v-model="form.serial_number"
                type="text"
                placeholder="e.g. SN12948274A"
                class="w-full pl-3.5 pr-8 py-2.5 text-xs font-mono bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 dark:focus:border-indigo-400 text-slate-900 dark:text-white"
              />
              <button
                type="button"
                @click="openScanner('serial_number', 'Scan Serial Number', 'camera')"
                class="absolute inset-y-0 right-1 px-2 flex items-center text-slate-400 hover:text-indigo-600 cursor-pointer text-xs"
                title="Scan Serial"
              >
                📷
              </button>
            </div>
          </div>

          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
              Purchase Date (Optional)
            </label>
            <input
              v-model="form.purchase_date"
              type="date"
              class="w-full px-3.5 py-2.5 text-xs font-semibold bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 dark:focus:border-indigo-400 text-slate-900 dark:text-white"
            />
          </div>
        </div>

        <!-- 7. Condition Notes / History -->
        <div>
          <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
            Device Notes / Known Issues (Optional)
          </label>
          <textarea
            v-model="form.notes"
            rows="2"
            placeholder="e.g. Minor scratches on back camera lens, previously repaired battery..."
            class="w-full px-3.5 py-2.5 text-xs font-medium bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 dark:focus:border-indigo-400 text-slate-900 dark:text-white resize-none"
          ></textarea>
        </div>

        <!-- Modal Footer Actions -->
        <div class="pt-4 border-t border-slate-100 dark:border-slate-800 flex items-center justify-end gap-3">
          <button
            @click="close"
            type="button"
            class="px-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-300 text-xs font-bold hover:bg-slate-50 dark:hover:bg-slate-800 transition cursor-pointer"
          >
            Cancel
          </button>
          <button
            type="submit"
            :disabled="submitting"
            class="px-5 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 text-white text-xs font-bold shadow-md shadow-indigo-600/20 transition flex items-center gap-2 cursor-pointer"
          >
            <svg v-if="submitting" class="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
            <span>{{ isEdit ? 'Update Device' : 'Save & Register Device' }}</span>
          </button>
        </div>
      </form>
    </div>

    <!-- Barcode & IMEI Scanner Modal -->
    <BarcodeScannerModal
      :is-open="scannerOpen"
      :title="scannerTitle"
      :initial-mode="scannerInitialMode"
      @close="scannerOpen = false"
      @scan="handleScanResult"
      @box-result="handleBoxResult"
    />
  </div>
</template>

<script setup>
import { ref, reactive, watch, computed, onMounted } from 'vue';
import { deviceApi } from '@/api/endpoints';
import { useToastStore } from '@/stores/toast';
import SearchableSelect from '@/components/common/SearchableSelect.vue';
import BarcodeScannerModal from '@/components/common/BarcodeScannerModal.vue';
import { toInputDate } from '@/utils/date';

const props = defineProps({
  isOpen: { type: Boolean, default: false },
  customer: { type: Object, default: () => ({}) },
  deviceToEdit: { type: Object, default: null },
});

const emit = defineEmits(['close', 'saved']);

const toastStore = useToastStore();
const submitting = ref(false);
const errorMessage = ref('');

const isEdit = computed(() => !!props.deviceToEdit?.id);

const customerName = computed(() => props.customer?.name || 'Walk-in Customer');
const customerPhone = computed(() => props.customer?.mobile || props.customer?.phone || '');

const deviceTypes = ['Mobile', 'Tablet', 'Laptop', 'Other'];

const ramOptions = [
  '2 GB',
  '3 GB',
  '4 GB',
  '6 GB',
  '8 GB',
  '12 GB',
  '16 GB',
  '24 GB',
  '32 GB',
];

const storageOptions = [
  '16 GB',
  '32 GB',
  '64 GB',
  '128 GB',
  '256 GB',
  '512 GB',
  '1 TB',
];

const allBrandsCatalog = ref([]);
const modelSuggestions = ref([]);
const loadingModels = ref(false);

// Barcode & IMEI Scanner State
const scannerOpen = ref(false);
const scannerTitle = ref('Scan Barcode or IMEI');
const scannerInitialMode = ref('camera');
const scannerTarget = ref('imei_1');

const form = reactive({
  device_type: 'Mobile',
  brand: '',
  model: '',
  ram: '',
  storage: '',
  variant: '',
  color: '',
  imei_1: '',
  imei_2: '',
  serial_number: '',
  purchase_date: '',
  notes: '',
});

function openScanner(target, title = 'Scan Barcode or IMEI', mode = 'camera') {
  scannerTarget.value = target;
  scannerTitle.value = title;
  scannerInitialMode.value = mode;
  scannerOpen.value = true;
}

function cleanScannedCode(raw) {
  if (!raw) return '';
  return raw.replace(/^(s\/n|sn|serial|imei1|imei2|imei|p\/n|pn)[:\s-]+/i, '').trim();
}

function handleScanResult(code) {
  if (!code) return;
  const clean = cleanScannedCode(code);
  switch (scannerTarget.value) {
    case 'imei_1':
      form.imei_1 = clean.replace(/\D/g, '').slice(0, 15);
      toastStore.success(`Scanned Primary IMEI 1: ${form.imei_1}`);
      break;
    case 'imei_2':
      form.imei_2 = clean.replace(/\D/g, '').slice(0, 15);
      toastStore.success(`Scanned Secondary IMEI 2: ${form.imei_2}`);
      break;
    case 'serial_number':
      form.serial_number = clean;
      toastStore.success(`Scanned Serial Number: ${clean}`);
      break;
  }
  scannerOpen.value = false;
}

function handleBoxResult(res) {
  if (res.imei1) form.imei_1 = res.imei1.replace(/\D/g, '').slice(0, 15);
  if (res.imei2) form.imei_2 = res.imei2.replace(/\D/g, '').slice(0, 15);
  if (res.serialNumber) form.serial_number = res.serialNumber;
  toastStore.success('Extracted IMEIs and Serial from box sticker!', 'Auto-Scan Success');
  scannerOpen.value = false;
}

function getDeviceTypeIcon(type) {
  switch (type) {
    case 'Mobile': return '📱';
    case 'Tablet': return '📟';
    case 'Laptop': return '💻';
    default: return '⚙️';
  }
}

const filteredBrandSuggestions = computed(() => {
  if (!form.brand) return allBrandsCatalog.value.slice(0, 15);
  const q = form.brand.toLowerCase();
  return allBrandsCatalog.value.filter((b) => b.toLowerCase().includes(q)).slice(0, 15);
});

function cleanImei(field) {
  if (form[field]) {
    form[field] = String(form[field]).replace(/[^0-9]/g, '').slice(0, 15);
  }
}

async function loadBrandsCatalog() {
  try {
    const res = await deviceApi.brands();
    allBrandsCatalog.value = res.data?.data || res.data || [];
  } catch (err) {
    console.error('Failed to load brands catalog:', err);
  }
}

async function fetchModelsForBrand(brand) {
  if (!brand || brand.trim().length < 2) {
    modelSuggestions.value = [];
    return;
  }
  loadingModels.value = true;
  try {
    const res = await deviceApi.models({ brand: brand.trim() });
    modelSuggestions.value = res.data?.data || res.data || [];
  } catch {
    modelSuggestions.value = [];
  } finally {
    loadingModels.value = false;
  }
}

function selectBrand(brand) {
  form.brand = brand;
  fetchModelsForBrand(brand);
}

function onBrandSelected(brand) {
  fetchModelsForBrand(brand || form.brand);
}

let brandTimer = null;
function onBrandInput() {
  clearTimeout(brandTimer);
  brandTimer = setTimeout(() => {
    fetchModelsForBrand(form.brand);
  }, 400);
}

function resetForm() {
  form.device_type = 'Mobile';
  form.brand = '';
  form.model = '';
  form.ram = '';
  form.storage = '';
  form.variant = '';
  form.color = '';
  form.imei_1 = '';
  form.imei_2 = '';
  form.serial_number = '';
  form.purchase_date = '';
  form.notes = '';
  errorMessage.value = '';
}

watch(
  () => props.isOpen,
  (val) => {
    if (val) {
      if (props.deviceToEdit) {
        form.device_type = props.deviceToEdit.device_type || 'Mobile';
        form.brand = props.deviceToEdit.brand || '';
        form.model = props.deviceToEdit.model || '';
        form.color = props.deviceToEdit.color || '';
        form.imei_1 = props.deviceToEdit.imei_1 || props.deviceToEdit.imei1 || '';
        form.imei_2 = props.deviceToEdit.imei_2 || props.deviceToEdit.imei2 || '';
        form.serial_number = props.deviceToEdit.serial_number || '';
        form.purchase_date = props.deviceToEdit.purchase_date ? toInputDate(props.deviceToEdit.purchase_date) : '';
        form.notes = props.deviceToEdit.notes || '';

        // Parse RAM and Storage from variant string
        const v = props.deviceToEdit.variant || '';
        let initialRam = '';
        let initialStorage = '';
        const ramMatch = v.match(/([0-9]+\s*GB)\s*RAM/i) || v.match(/RAM:\s*([0-9]+\s*GB)/i) || v.match(/([0-9]+\s*GB)\s*\//i);
        if (ramMatch) initialRam = ramMatch[1];
        const storageMatch = v.match(/\/\s*([0-9]+\s*(?:GB|TB))/i) || v.match(/Storage:\s*([0-9]+\s*(?:GB|TB))/i) || v.match(/([0-9]+\s*(?:GB|TB))\s*$/i);
        if (storageMatch) initialStorage = storageMatch[1];

        if (!initialStorage && !initialRam) {
          const directMatch = v.match(/([0-9]+\s*(?:GB|TB))/i);
          if (directMatch) {
            const val = directMatch[1];
            if (storageOptions.includes(val) || parseInt(val) >= 32) {
              initialStorage = val;
            } else {
              initialRam = val;
            }
          }
        }

        form.ram = initialRam;
        form.storage = initialStorage;
        form.variant = v;

        if (form.brand) fetchModelsForBrand(form.brand);
      } else {
        resetForm();
      }
    }
  }
);

function close() {
  emit('close');
}

async function handleSubmit() {
  errorMessage.value = '';
  if (!form.brand?.trim()) {
    errorMessage.value = 'Please specify the device brand.';
    return;
  }
  if (!form.model?.trim()) {
    errorMessage.value = 'Please specify the device model.';
    return;
  }
  if (form.imei_1 && form.imei_1.length !== 15) {
    errorMessage.value = 'IMEI 1 must be exactly 15 numeric digits.';
    return;
  }
  if (form.imei_2 && form.imei_2.length !== 15) {
    errorMessage.value = 'IMEI 2 must be exactly 15 numeric digits.';
    return;
  }

  let composedVariant = '';
  if (form.ram && form.storage) {
    composedVariant = `${form.ram.trim()} / ${form.storage.trim()}`;
  } else if (form.storage) {
    composedVariant = form.storage.trim();
  } else if (form.ram) {
    composedVariant = form.ram.trim();
  } else if (form.variant) {
    composedVariant = form.variant.trim();
  }

  const payload = {
    device_type: form.device_type,
    brand: form.brand.trim(),
    model: form.model.trim(),
    variant: composedVariant || null,
    color: form.color ? form.color.trim() : null,
    imei_1: form.imei_1 || null,
    imei_2: form.imei_2 || null,
    serial_number: form.serial_number ? form.serial_number.trim() : null,
    purchase_date: form.purchase_date || null,
    notes: form.notes ? form.notes.trim() : null,
  };

  submitting.value = true;
  try {
    if (isEdit.value) {
      await deviceApi.update(props.deviceToEdit.id, payload);
      toastStore.success(`Device ${payload.brand} ${payload.model} updated successfully`);
    } else {
      const customerId = props.customer?.id;
      if (!customerId) {
        throw new Error('Customer ID missing.');
      }
      await deviceApi.createForCustomer(customerId, payload);
      toastStore.success(`Device ${payload.brand} ${payload.model} registered to customer`);
    }
    emit('saved');
    close();
  } catch (err) {
    console.error('Device save error:', err);
    if (err.response?.status === 409) {
      errorMessage.value = err.response.data?.message || 'A device with this IMEI already exists in your shop.';
    } else if (err.response?.data?.message) {
      errorMessage.value = err.response.data.message;
    } else {
      errorMessage.value = 'Failed to save device. Please check input values.';
    }
  } finally {
    submitting.value = false;
  }
}

onMounted(() => {
  loadBrandsCatalog();
});
</script>
