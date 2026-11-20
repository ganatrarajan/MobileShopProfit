<template>
  <div class="relative w-full" ref="containerRef">
    <!-- Clickable Input Field Trigger -->
    <div
      @click="toggleDropdown"
      :class="[
        'w-full flex items-center justify-between px-3.5 py-2.5 text-xs font-semibold rounded-xl border transition cursor-pointer select-none',
        isOpen
          ? 'ring-2 ring-indigo-500/30 border-indigo-500 bg-white dark:bg-slate-900'
          : 'border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 hover:border-slate-300 dark:hover:border-slate-600',
        disabled ? 'opacity-50 cursor-not-allowed bg-slate-100 dark:bg-slate-800' : '',
        inputClass
      ]"
    >
      <div class="flex items-center gap-2 truncate">
        <!-- Calendar Icon Left (Optional) -->
        <svg class="w-4 h-4 text-slate-400 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
        </svg>

        <!-- Display Value -->
        <span v-if="displayFormattedValue" class="text-slate-900 dark:text-slate-100 font-bold truncate">
          {{ displayFormattedValue }}
        </span>
        <span v-else class="text-slate-400 font-normal">
          {{ placeholder || 'YYYY-MM-DD' }}
        </span>
      </div>

      <!-- Right Action Icons (Clear + Calendar/Dropdown Indicator) -->
      <div class="flex items-center gap-1.5 shrink-0 ml-2">
        <button
          v-if="modelValue && !required && !disabled"
          type="button"
          @click.stop="clearDate"
          class="p-0.5 rounded-full text-slate-400 hover:text-rose-500 hover:bg-slate-100 dark:hover:bg-slate-800 transition"
          title="Clear date"
        >
          <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>

        <svg
          :class="['w-4 h-4 text-slate-400 transition-transform duration-200', isOpen ? 'rotate-180 text-indigo-600' : '']"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
        </svg>
      </div>
    </div>

    <!-- Hidden Native Input for HTML5 form validation if required -->
    <input
      type="text"
      :value="modelValue || ''"
      :required="required"
      tabindex="-1"
      class="opacity-0 absolute pointer-events-none w-0 h-0"
    />

    <!-- Floating Calendar Dropdown Popup -->
    <transition
      enter-active-class="transition duration-150 ease-out"
      enter-from-class="transform scale-95 opacity-0 -translate-y-2"
      enter-to-class="transform scale-100 opacity-100 translate-y-0"
      leave-active-class="transition duration-100 ease-in"
      leave-from-class="transform scale-100 opacity-100 translate-y-0"
      leave-to-class="transform scale-95 opacity-0 -translate-y-2"
    >
      <div
        v-if="isOpen"
        class="absolute left-0 mt-2 z-50 w-72 sm:w-80 p-4 sm:p-4.5 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-3xl shadow-2xl shadow-slate-900/15 dark:shadow-black/60 select-none animate-in fade-in"
        :style="{ minWidth: '280px' }"
      >
        <!-- Top Caret Pointer Indicator (matching screenshot) -->
        <div class="absolute -top-1.5 left-6 w-3 h-3 bg-white dark:bg-slate-900 border-t border-l border-slate-200 dark:border-slate-800 rotate-45"></div>

        <!-- 1. Header: Chevron Left, Month ▾ Year, Chevron Right -->
        <div class="flex items-center justify-between mb-3 px-1">
          <!-- Prev Month Button (coral chevron in screenshot) -->
          <button
            type="button"
            @click.stop="prevMonth"
            class="w-8 h-8 flex items-center justify-center rounded-xl text-rose-500 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/40 transition cursor-pointer"
            title="Previous Month"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M15 19l-7-7 7-7" />
            </svg>
          </button>

          <!-- Month & Year Title with Selector Toggle -->
          <div class="flex items-center gap-1.5">
            <button
              type="button"
              @click.stop="showMonthPicker = !showMonthPicker; showYearPicker = false"
              class="flex items-center gap-1 text-sm sm:text-base font-bold text-slate-800 dark:text-slate-100 hover:text-indigo-600 dark:hover:text-indigo-400 px-2 py-1 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 transition cursor-pointer"
            >
              <span>{{ currentMonthName }}</span>
              <svg class="w-3.5 h-3.5 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M19 9l-7 7-7-7" />
              </svg>
            </button>

            <button
              type="button"
              @click.stop="showYearPicker = !showYearPicker; showMonthPicker = false"
              class="text-sm sm:text-base font-bold text-slate-800 dark:text-slate-100 hover:text-indigo-600 dark:hover:text-indigo-400 px-1.5 py-1 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 transition cursor-pointer"
            >
              {{ currentYear }}
            </button>
          </div>

          <!-- Next Month Button (chevron right in screenshot) -->
          <button
            type="button"
            @click.stop="nextMonth"
            class="w-8 h-8 flex items-center justify-center rounded-xl text-slate-400 hover:text-indigo-600 hover:bg-slate-100 dark:hover:bg-slate-800 transition cursor-pointer"
            title="Next Month"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M9 5l7 7-7 7" />
            </svg>
          </button>
        </div>

        <!-- 2. Month Selector Grid Popup Overlay -->
        <div v-if="showMonthPicker" class="grid grid-cols-3 gap-2 py-3 bg-white dark:bg-slate-900">
          <button
            v-for="(mName, idx) in monthsList"
            :key="idx"
            type="button"
            @click.stop="selectMonth(idx)"
            :class="[
              'py-2 px-2.5 rounded-xl text-xs font-bold transition text-center cursor-pointer',
              idx === currentMonth
                ? 'bg-indigo-600 text-white shadow-sm'
                : 'text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800'
            ]"
          >
            {{ mName }}
          </button>
        </div>

        <!-- 3. Year Selector Grid Popup Overlay -->
        <div v-else-if="showYearPicker" class="py-2 bg-white dark:bg-slate-900">
          <div class="flex items-center justify-between mb-2 px-1">
            <button
              type="button"
              @click.stop="yearOffset -= 12"
              class="p-1 rounded-lg text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800"
            >
              &laquo;
            </button>
            <span class="text-xs font-bold text-slate-500">{{ yearRangeStart }} - {{ yearRangeEnd }}</span>
            <button
              type="button"
              @click.stop="yearOffset += 12"
              class="p-1 rounded-lg text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800"
            >
              &raquo;
            </button>
          </div>
          <div class="grid grid-cols-4 gap-1.5">
            <button
              v-for="y in visibleYears"
              :key="y"
              type="button"
              @click.stop="selectYear(y)"
              :class="[
                'py-2 rounded-xl text-xs font-bold transition text-center cursor-pointer',
                y === currentYear
                  ? 'bg-indigo-600 text-white shadow-sm'
                  : 'text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800'
              ]"
            >
              {{ y }}
            </button>
          </div>
        </div>

        <!-- 4. Normal Calendar Days View -->
        <div v-else>
          <!-- Days of Week Header: Sun Mon Tue Wed Thu Fri Sat -->
          <div class="grid grid-cols-7 mb-1.5">
            <div
              v-for="dayName in ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']"
              :key="dayName"
              class="text-center text-[11px] font-bold text-slate-500 dark:text-slate-400 py-1"
            >
              {{ dayName }}
            </div>
          </div>

          <!-- Calendar Days Grid (6 Rows x 7 Columns) -->
          <div class="grid grid-cols-7 gap-1">
            <button
              v-for="(cell, cIdx) in calendarDays"
              :key="cIdx"
              type="button"
              @click.stop="selectDay(cell)"
              :disabled="isDayDisabled(cell)"
              :class="[
                'h-8 sm:h-9 w-full flex items-center justify-center text-xs font-semibold rounded-xl transition cursor-pointer select-none',
                // Other month padding days
                !cell.isCurrentMonth
                  ? 'text-slate-300 dark:text-slate-600 hover:text-slate-500'
                  : 'text-slate-700 dark:text-slate-200',
                // Selected Day (Solid indigo)
                cell.isSelected
                  ? 'bg-indigo-600 text-white font-bold shadow-md shadow-indigo-600/30 ring-2 ring-indigo-600'
                  : '',
                // Today (Rounded outline border box matching screenshot day 20)
                cell.isToday && !cell.isSelected
                  ? 'border-2 border-indigo-500 text-indigo-600 dark:text-indigo-400 font-bold bg-indigo-50/40 dark:bg-indigo-950/20'
                  : '',
                // Hover for non-selected
                !cell.isSelected && cell.isCurrentMonth
                  ? 'hover:bg-slate-100 dark:hover:bg-slate-800 hover:text-indigo-600 dark:hover:text-indigo-400'
                  : '',
                isDayDisabled(cell) ? 'opacity-30 cursor-not-allowed hover:bg-transparent' : ''
              ]"
            >
              {{ cell.dayNumber }}
            </button>
          </div>

          <!-- Quick Actions Footer: Today & Clear -->
          <div class="flex items-center justify-between pt-3 mt-3 border-t border-slate-100 dark:border-slate-800 text-xs">
            <button
              type="button"
              @click.stop="setToday"
              class="font-bold text-indigo-600 dark:text-indigo-400 hover:underline px-2 py-1 rounded cursor-pointer"
            >
              Today
            </button>

            <button
              v-if="!required"
              type="button"
              @click.stop="clearDate"
              class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-300 px-2 py-1 rounded cursor-pointer"
            >
              Clear
            </button>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';
import { parseDate, formatDate } from '@/utils/date';

const props = defineProps({
  modelValue: {
    type: [String, Date, null],
    default: '',
  },
  placeholder: {
    type: String,
    default: 'Select date...',
  },
  required: {
    type: Boolean,
    default: false,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  minDate: {
    type: [String, Date, null],
    default: null,
  },
  maxDate: {
    type: [String, Date, null],
    default: null,
  },
  inputClass: {
    type: String,
    default: '',
  },
  displayFormat: {
    type: String,
    default: 'dd_month_yyyy', // 'dd_month_yyyy' or 'iso'
  },
});

const emit = defineEmits(['update:modelValue', 'change']);

const containerRef = ref(null);
const isOpen = ref(false);
const showMonthPicker = ref(false);
const showYearPicker = ref(false);
const yearOffset = ref(0);

const monthsList = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

// Internal calendar view date (year & month)
const viewDate = ref(new Date());

// Sync view date whenever modelValue changes or dropdown opens
function syncViewDate() {
  if (props.modelValue) {
    const d = parseDate(props.modelValue);
    if (d) {
      viewDate.value = new Date(d.getFullYear(), d.getMonth(), 1);
      return;
    }
  }
  const today = new Date();
  viewDate.value = new Date(today.getFullYear(), today.getMonth(), 1);
}

watch(() => props.modelValue, () => {
  if (!isOpen.value) syncViewDate();
}, { immediate: true });

function toggleDropdown() {
  if (props.disabled) return;
  if (!isOpen.value) {
    syncViewDate();
    showMonthPicker.value = false;
    showYearPicker.value = false;
  }
  isOpen.value = !isOpen.value;
}

function closeDropdown() {
  isOpen.value = false;
  showMonthPicker.value = false;
  showYearPicker.value = false;
}

// Close on outside click
function handleClickOutside(e) {
  if (containerRef.value && !containerRef.value.contains(e.target)) {
    closeDropdown();
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside);
});

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside);
});

// Current view year & month
const currentYear = computed(() => viewDate.value.getFullYear());
const currentMonth = computed(() => viewDate.value.getMonth());
const currentMonthName = computed(() => monthsList[currentMonth.value]);

// Navigation
function prevMonth() {
  viewDate.value = new Date(currentYear.value, currentMonth.value - 1, 1);
}

function nextMonth() {
  viewDate.value = new Date(currentYear.value, currentMonth.value + 1, 1);
}

function selectMonth(mIdx) {
  viewDate.value = new Date(currentYear.value, mIdx, 1);
  showMonthPicker.value = false;
}

function selectYear(y) {
  viewDate.value = new Date(y, currentMonth.value, 1);
  showYearPicker.value = false;
}

// Year Range for Year Picker
const yearRangeStart = computed(() => Math.floor(currentYear.value / 12) * 12 + yearOffset.value);
const yearRangeEnd = computed(() => yearRangeStart.value + 11);
const visibleYears = computed(() => {
  const start = yearRangeStart.value;
  return Array.from({ length: 12 }, (_, i) => start + i);
});

// Calendar grid calculation (42 cells: prev month padding + current month + next month padding)
const calendarDays = computed(() => {
  const year = currentYear.value;
  const month = currentMonth.value;

  const firstDayOfWeek = new Date(year, month, 1).getDay(); // 0 = Sun, 1 = Mon ...
  const daysInCurrentMonth = new Date(year, month + 1, 0).getDate();
  const daysInPrevMonth = new Date(year, month, 0).getDate();

  const selectedDate = props.modelValue ? parseDate(props.modelValue) : null;
  const today = new Date();

  const cells = [];

  // Previous month trailing days
  for (let i = firstDayOfWeek - 1; i >= 0; i--) {
    const day = daysInPrevMonth - i;
    const dateObj = new Date(year, month - 1, day);
    cells.push({
      dayNumber: day,
      date: dateObj,
      isCurrentMonth: false,
      isToday: isSameDay(dateObj, today),
      isSelected: selectedDate ? isSameDay(dateObj, selectedDate) : false,
    });
  }

  // Current month days
  for (let d = 1; d <= daysInCurrentMonth; d++) {
    const dateObj = new Date(year, month, d);
    cells.push({
      dayNumber: d,
      date: dateObj,
      isCurrentMonth: true,
      isToday: isSameDay(dateObj, today),
      isSelected: selectedDate ? isSameDay(dateObj, selectedDate) : false,
    });
  }

  // Next month leading days (fill total to 42 cells)
  const remaining = 42 - cells.length;
  for (let nextD = 1; nextD <= remaining; nextD++) {
    const dateObj = new Date(year, month + 1, nextD);
    cells.push({
      dayNumber: nextD,
      date: dateObj,
      isCurrentMonth: false,
      isToday: isSameDay(dateObj, today),
      isSelected: selectedDate ? isSameDay(dateObj, selectedDate) : false,
    });
  }

  return cells;
});

function isSameDay(d1, d2) {
  if (!d1 || !d2) return false;
  return (
    d1.getFullYear() === d2.getFullYear() &&
    d1.getMonth() === d2.getMonth() &&
    d1.getDate() === d2.getDate()
  );
}

function isDayDisabled(cell) {
  if (props.minDate) {
    const min = parseDate(props.minDate);
    if (min && cell.date < new Date(min.getFullYear(), min.getMonth(), min.getDate())) return true;
  }
  if (props.maxDate) {
    const max = parseDate(props.maxDate);
    if (max && cell.date > new Date(max.getFullYear(), max.getMonth(), max.getDate(), 23, 59, 59)) return true;
  }
  return false;
}

// Select a day
function selectDay(cell) {
  if (isDayDisabled(cell)) return;
  const isoStr = toIsoDate(cell.date);
  emit('update:modelValue', isoStr);
  emit('change', isoStr);
  closeDropdown();
}

function setToday() {
  const today = new Date();
  const isoStr = toIsoDate(today);
  emit('update:modelValue', isoStr);
  emit('change', isoStr);
  syncViewDate();
  closeDropdown();
}

function clearDate() {
  emit('update:modelValue', '');
  emit('change', '');
  closeDropdown();
}

function toIsoDate(d) {
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

// Display Formatted Value in input
const displayFormattedValue = computed(() => {
  if (!props.modelValue) return '';
  const parsed = parseDate(props.modelValue);
  if (!parsed) return String(props.modelValue);
  if (props.displayFormat === 'iso') {
    return toIsoDate(parsed);
  }
  // Standard portal format: DD Month YYYY (e.g. 20 Nov 2026)
  return formatDate(parsed);
});
</script>
