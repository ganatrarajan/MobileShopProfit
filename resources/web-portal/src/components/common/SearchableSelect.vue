<template>
  <div
    ref="containerRef"
    class="relative text-left"
    :class="[ isFullWidth ? 'w-full block' : 'inline-block' ]"
  >
    <!-- Trigger Button -->
    <button
      type="button"
      @click="toggleDropdown"
      :disabled="disabled"
      class="group flex items-center justify-between gap-2.5 px-3.5 py-2.5 text-xs font-semibold rounded-xl border transition-all select-none cursor-pointer"
      :class="[
        isFullWidth ? 'w-full' : 'inline-flex',
        isOpen
          ? 'border-indigo-500 ring-2 ring-indigo-500/20 bg-white dark:bg-slate-900 text-indigo-700 dark:text-indigo-300'
          : 'border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 text-slate-700 dark:text-slate-200 hover:border-slate-300 dark:hover:border-slate-700 hover:bg-slate-50/70 dark:hover:bg-slate-800/60 shadow-xs',
        disabled ? 'opacity-50 cursor-not-allowed' : ''
      ]"
      :style="{ minWidth: isFullWidth ? '100%' : minWidth }"
    >
      <div class="flex items-center gap-2 truncate">
        <!-- Optional Prefix Icon / Custom Icon or Selected Option's Icon -->
        <span v-if="selectedOption?.icon || prefixIcon" class="shrink-0 text-sm">
          <slot name="icon">
            <span>{{ selectedOption?.icon || prefixIcon }}</span>
          </slot>
        </span>

        <!-- Selected Label / Placeholder -->
        <span
          class="truncate"
          :class="selectedLabel ? 'font-semibold text-slate-800 dark:text-slate-100' : 'font-normal text-slate-400 dark:text-slate-500'"
        >
          {{ selectedLabel || placeholder }}
        </span>
      </div>

      <div class="flex items-center gap-1.5 shrink-0">
        <!-- Clear button (if clearable) -->
        <button
          v-if="clearable && modelValue"
          @click.stop="clearSelection"
          type="button"
          class="p-0.5 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 rounded-md shrink-0 cursor-pointer"
          title="Clear selection"
        >
          <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>

        <!-- Chevron Icon with 180deg flip -->
        <svg
          class="w-3.5 h-3.5 text-slate-400 group-hover:text-slate-600 dark:group-hover:text-slate-300 transition-transform duration-200 shrink-0"
          :class="{ 'rotate-180 text-indigo-600 dark:text-indigo-400': isOpen }"
          fill="none" stroke="currentColor" viewBox="0 0 24 24"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
        </svg>
      </div>
    </button>

    <!-- Dropdown Popover Menu -->
    <div
      v-if="isOpen"
      class="absolute z-50 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-2xl shadow-slate-900/20 dark:shadow-slate-950/50 p-2 space-y-1.5 animate-in fade-in zoom-in-95 duration-100"
      :class="[
        isFullWidth ? 'w-full left-0 right-0' : (shouldAlignRight ? 'right-0 left-auto' : 'left-0'),
        openUpwards ? 'bottom-full mb-1.5' : 'top-full mt-1.5'
      ]"
      :style="{
        width: isFullWidth ? '100%' : 'auto',
        minWidth: isFullWidth ? '100%' : (popoverMinWidth || '200px'),
        maxWidth: popoverMaxWidth || (isFullWidth ? '100%' : '380px')
      }"
      @wheel.stop
    >
      <!-- Search Input (if searchable) -->
      <div v-if="isSearchable" class="relative px-0.5 pt-0.5 pb-1">
        <svg
          class="w-3.5 h-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none"
          fill="none" stroke="currentColor" viewBox="0 0 24 24"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
        <input
          ref="searchInputRef"
          v-model="searchQuery"
          type="text"
          :placeholder="searchPlaceholder || 'Search options...'"
          class="w-full pl-9 pr-7 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-950 text-xs font-medium text-slate-800 dark:text-slate-100 placeholder-slate-400 focus:outline-none focus:ring-1 focus:ring-indigo-500"
          @keydown.esc="closeDropdown"
          @keydown.enter.prevent="handleEnterKey"
          @click.stop
        />
        <button
          v-if="searchQuery"
          @click.stop="searchQuery = ''"
          type="button"
          class="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 text-xs cursor-pointer p-0.5"
        >
          ✕
        </button>
      </div>

      <!-- Custom Value Quick Option (if allowCustom is enabled and user typed something not matching an exact option) -->
      <div
        v-if="allowCustom && searchQuery.trim() && !hasExactMatch"
        @click="selectCustomOption(searchQuery.trim())"
        class="px-3 py-2 rounded-xl text-xs font-semibold cursor-pointer transition flex items-center justify-between gap-2 border border-dashed border-indigo-300 dark:border-indigo-700 bg-indigo-50/80 dark:bg-indigo-950/50 text-indigo-700 dark:text-indigo-300 hover:bg-indigo-100 dark:hover:bg-indigo-900/60"
      >
        <div class="flex items-center gap-2 truncate">
          <svg class="w-3.5 h-3.5 text-indigo-600 dark:text-indigo-400 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 4v16m8-8H4" />
          </svg>
          <span class="truncate">Use "<strong>{{ searchQuery.trim() }}</strong>"</span>
        </div>
        <span class="text-[10px] uppercase font-bold tracking-wider px-1.5 py-0.5 rounded bg-indigo-200/60 dark:bg-indigo-800/60 text-indigo-800 dark:text-indigo-200 shrink-0">Custom</span>
      </div>

      <!-- Options List with Adaptive Dynamic Height -->
      <div
        class="overflow-y-auto space-y-1 pr-1 custom-scroll"
        :style="optionsMaxHeightStyle"
        @wheel.stop
      >
        <div
          v-for="opt in filteredOptions"
          :key="getOptionValue(opt)"
          @click="selectOption(opt)"
          class="w-full px-3 py-2 rounded-xl text-xs font-semibold cursor-pointer transition flex items-center justify-between gap-2 select-none"
          :class="[
            isSelected(opt)
              ? 'bg-indigo-600 text-white font-bold shadow-xs'
              : 'text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800/70'
          ]"
        >
          <!-- Rich option layout (if stock or price provided) -->
          <div v-if="opt.stock !== undefined || opt.price !== undefined" class="flex items-center justify-between gap-2 w-full truncate">
            <div class="flex items-center gap-2 truncate">
              <span v-if="opt.icon" class="text-sm shrink-0">{{ opt.icon }}</span>
              <span class="truncate font-medium">{{ getOptionLabel(opt) }}</span>
            </div>
            <div class="flex items-center gap-1.5 shrink-0">
              <span
                v-if="opt.stock !== undefined"
                class="px-2 py-0.5 rounded-lg text-[10px] font-bold"
                :class="[
                  isSelected(opt)
                    ? 'bg-white/20 text-white'
                    : (opt.stock <= 0
                        ? 'bg-rose-100 dark:bg-rose-950/60 text-rose-700 dark:text-rose-400 border border-rose-200/60 dark:border-rose-800/60'
                        : (opt.stock <= 5
                            ? 'bg-amber-100 dark:bg-amber-950/60 text-amber-700 dark:text-amber-400 border border-amber-200/60 dark:border-amber-800/60'
                            : 'bg-emerald-100 dark:bg-emerald-950/60 text-emerald-700 dark:text-emerald-400 border border-emerald-200/60 dark:border-emerald-800/60'))
                ]"
              >
                {{ opt.stock <= 0 ? 'Out of Stock' : (opt.stock <= 5 ? `Low: ${opt.stock}` : `Stock: ${opt.stock}`) }}
              </span>
              <span
                v-if="opt.price !== undefined && opt.price > 0"
                class="font-mono font-bold text-xs"
                :class="isSelected(opt) ? 'text-white' : 'text-slate-900 dark:text-slate-100'"
              >
                ₹{{ Number(opt.price || 0).toLocaleString('en-IN') }}
              </span>
            </div>
          </div>

          <!-- Standard simple label -->
          <div v-else class="flex items-center gap-2 truncate">
            <span v-if="opt.icon" class="text-sm shrink-0">{{ opt.icon }}</span>
            <span class="truncate">{{ getOptionLabel(opt) }}</span>
          </div>

          <!-- White Checkmark for active selection -->
          <svg
            v-if="isSelected(opt)"
            class="w-4 h-4 text-white shrink-0 ml-1"
            fill="none" stroke="currentColor" viewBox="0 0 24 24"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7" />
          </svg>
        </div>

        <!-- Empty Results with Manual Add Prompt -->
        <div
          v-if="filteredOptions.length === 0"
          class="py-4 px-3 text-center space-y-2.5"
        >
          <div class="text-xs text-slate-400 dark:text-slate-500">
            <span v-if="searchQuery.trim()">No options matching "<strong>{{ searchQuery.trim() }}</strong>"</span>
            <span v-else>No options available.</span>
          </div>

          <button
            v-if="allowCustom && searchQuery.trim()"
            type="button"
            @click.stop="selectCustomOption(searchQuery.trim())"
            class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-bold text-xs shadow-md shadow-indigo-600/20 transition cursor-pointer"
          >
            <span>➕</span>
            <span>Use "{{ searchQuery.trim() }}" Manually</span>
          </button>
        </div>
      </div>

      <!-- Dedicated Manual Entry Footer / Bar -->
      <div
        v-if="allowCustom"
        class="pt-2 px-1 border-t border-slate-100 dark:border-slate-800/80"
        @click.stop
      >
        <!-- State 1: Collapsed Button -->
        <div
          v-if="!isManualInputActive"
          @click="startManualEntry"
          class="px-2 py-1.5 rounded-xl flex items-center justify-between text-xs text-indigo-600 dark:text-indigo-400 font-semibold hover:bg-indigo-50 dark:hover:bg-indigo-950/40 cursor-pointer transition select-none"
        >
          <div class="flex items-center gap-1.5 truncate">
            <span>✏️</span>
            <span class="truncate">Not in list? Enter manually</span>
          </div>
          <span class="text-[10px] uppercase font-bold tracking-wider px-1.5 py-0.5 rounded bg-indigo-100 dark:bg-indigo-900/50 shrink-0">
            + Manual
          </span>
        </div>

        <!-- State 2: Expanded Inline Input -->
        <div
          v-else
          class="p-2 bg-indigo-50/70 dark:bg-indigo-950/40 rounded-xl border border-indigo-200 dark:border-indigo-800/60 space-y-2 animate-in fade-in"
        >
          <div class="flex items-center justify-between">
            <label class="text-[10px] font-bold uppercase tracking-wider text-indigo-700 dark:text-indigo-300">
              Enter Custom / Manual Value
            </label>
            <button
              type="button"
              @click="isManualInputActive = false"
              class="text-[10px] font-bold text-slate-400 hover:text-slate-600 cursor-pointer"
            >
              ✕ Cancel
            </button>
          </div>
          <div class="flex items-center gap-1.5">
            <input
              ref="manualInputFieldRef"
              v-model="manualInputValue"
              type="text"
              placeholder="Type custom name/spec..."
              class="w-full px-2.5 py-1.5 text-xs font-semibold rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 text-slate-900 dark:text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              @keydown.enter.prevent="submitManualInput"
            />
            <button
              type="button"
              @click="submitManualInput"
              :disabled="!manualInputValue.trim()"
              class="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 text-white font-bold text-xs rounded-lg transition shadow-xs cursor-pointer shrink-0"
            >
              Add
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, nextTick, onMounted, onUnmounted } from 'vue';

const props = defineProps({
  modelValue: {
    type: [String, Number, Boolean, null],
    default: '',
  },
  options: {
    type: Array,
    default: () => [],
  },
  placeholder: {
    type: String,
    default: 'Select Option',
  },
  searchPlaceholder: {
    type: String,
    default: 'Search...',
  },
  prefixIcon: {
    type: String,
    default: '',
  },
  minWidth: {
    type: String,
    default: '140px',
  },
  popoverMinWidth: {
    type: String,
    default: '210px',
  },
  popoverMaxWidth: {
    type: String,
    default: '',
  },
  alignRight: {
    type: Boolean,
    default: false,
  },
  searchable: {
    type: Boolean,
    default: null, // auto-detect: if options >= 3, enable search
  },
  fullWidth: {
    type: Boolean,
    default: false,
  },
  allowCustom: {
    type: Boolean,
    default: true,
  },
  clearable: {
    type: Boolean,
    default: false,
  },
  direction: {
    type: String,
    default: 'down', // 'down' | 'up' | 'auto'
  },
  disabled: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update:modelValue', 'change']);

const isOpen = ref(false);
const searchQuery = ref('');
const searchInputRef = ref(null);
const containerRef = ref(null);
const openUpwards = ref(false);
const availableSpaceAbove = ref(300);
const availableSpaceBelow = ref(300);

// Manual Entry Inline State
const isManualInputActive = ref(false);
const manualInputValue = ref('');
const manualInputFieldRef = ref(null);

function startManualEntry() {
  isManualInputActive.value = true;
  manualInputValue.value = searchQuery.value || '';
  nextTick(() => {
    manualInputFieldRef.value?.focus();
  });
}

function submitManualInput() {
  const val = manualInputValue.value.trim();
  if (!val) return;
  selectCustomOption(val);
  isManualInputActive.value = false;
  manualInputValue.value = '';
}

const isFullWidth = computed(() => {
  return props.fullWidth || props.minWidth === '100%' || props.minWidth === 'w-full';
});

const isSearchable = computed(() => {
  if (props.searchable !== null) return props.searchable;
  return props.options.length >= 3;
});

function getOptionValue(opt) {
  if (opt !== null && typeof opt === 'object') {
    return opt.value !== undefined ? opt.value : opt.id;
  }
  return opt;
}

function getOptionLabel(opt) {
  if (opt !== null && typeof opt === 'object') {
    return opt.label !== undefined ? opt.label : opt.name || opt.title || String(opt.value);
  }
  return String(opt);
}

function isSelected(opt) {
  return String(getOptionValue(opt)) === String(props.modelValue);
}

const selectedOption = computed(() => {
  return props.options.find((opt) => isSelected(opt)) || null;
});

const selectedLabel = computed(() => {
  if (selectedOption.value) return getOptionLabel(selectedOption.value);
  if (props.allowCustom && props.modelValue) return String(props.modelValue);
  return '';
});

const hasExactMatch = computed(() => {
  const q = searchQuery.value.trim().toLowerCase();
  if (!q) return false;
  return props.options.some((opt) => getOptionLabel(opt).trim().toLowerCase() === q);
});

const filteredOptions = computed(() => {
  let list = props.options;
  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase().trim();
    list = list.filter((opt) => {
      const label = getOptionLabel(opt).toLowerCase();
      const extra = (opt.brand || opt.sku || opt.category || (opt.price ? String(opt.price) : '')).toLowerCase();
      return label.includes(q) || extra.includes(q);
    });
  }
  return list.slice(0, 100);
});

const isNearRightEdge = ref(false);

const shouldAlignRight = computed(() => {
  return props.alignRight || isNearRightEdge.value;
});

function calculatePlacement() {
  if (!containerRef.value) return;
  const rect = containerRef.value.getBoundingClientRect();
  isNearRightEdge.value = (window.innerWidth - rect.right) < 260;

  if (props.direction === 'down') {
    openUpwards.value = false;
    return;
  }
  if (props.direction === 'up') {
    openUpwards.value = true;
    return;
  }

  // If 'auto', only open upwards if very close to screen bottom and more room above
  const viewportBelow = window.innerHeight - rect.bottom;
  const viewportAbove = rect.top;

  if (viewportBelow < 160 && viewportAbove > 200) {
    openUpwards.value = true;
  } else {
    openUpwards.value = false;
  }
}

const optionsMaxHeightStyle = computed(() => {
  return {
    maxHeight: '260px'
  };
});

function toggleDropdown() {
  if (props.disabled) return;
  if (!isOpen.value) {
    calculatePlacement();
  }
  isOpen.value = !isOpen.value;
  if (isOpen.value) {
    searchQuery.value = '';
    if (isSearchable.value) {
      nextTick(() => {
        searchInputRef.value?.focus();
      });
    }
  }
}

function closeDropdown() {
  isOpen.value = false;
  searchQuery.value = '';
  isManualInputActive.value = false;
  manualInputValue.value = '';
}

function selectOption(opt) {
  const val = getOptionValue(opt);
  emit('update:modelValue', val);
  emit('change', val);
  closeDropdown();
}

function selectCustomOption(val) {
  emit('update:modelValue', val);
  emit('change', val);
  closeDropdown();
}

function clearSelection() {
  emit('update:modelValue', '');
  emit('change', '');
}

function handleEnterKey() {
  const q = searchQuery.value.trim();
  if (!q) return;

  const exact = props.options.find(
    (opt) => getOptionLabel(opt).trim().toLowerCase() === q.toLowerCase()
  );
  if (exact) {
    selectOption(exact);
    return;
  }

  if (filteredOptions.value.length === 1) {
    selectOption(filteredOptions.value[0]);
    return;
  }

  if (props.allowCustom) {
    selectCustomOption(q);
    return;
  }

  if (filteredOptions.value.length > 0) {
    selectOption(filteredOptions.value[0]);
  }
}

function handleDocumentClick(e) {
  if (isOpen.value && containerRef.value && !containerRef.value.contains(e.target)) {
    closeDropdown();
  }
}

function handleKeydown(e) {
  if (isOpen.value && e.key === 'Escape') {
    closeDropdown();
  }
}

onMounted(() => {
  document.addEventListener('pointerdown', handleDocumentClick);
  window.addEventListener('keydown', handleKeydown);
});

onUnmounted(() => {
  document.removeEventListener('pointerdown', handleDocumentClick);
  window.removeEventListener('keydown', handleKeydown);
});
</script>

<style scoped>
.custom-scroll::-webkit-scrollbar {
  width: 4px;
}
.custom-scroll::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scroll::-webkit-scrollbar-thumb {
  background: rgba(148, 163, 184, 0.4);
  border-radius: 9999px;
}
.custom-scroll::-webkit-scrollbar-thumb:hover {
  background: rgba(100, 116, 139, 0.6);
}
</style>
