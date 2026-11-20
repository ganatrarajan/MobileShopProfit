<template>
  <div v-if="resolvedTotal > 0" class="px-6 py-4 border-t border-slate-100 dark:border-slate-800/80 bg-slate-50/50 dark:bg-slate-900/40 flex flex-col sm:flex-row items-center justify-between gap-3 transition-colors">
    <div class="text-xs font-medium text-slate-500 dark:text-slate-400">
      Showing <span class="font-bold text-slate-700 dark:text-slate-200">{{ fromItem }}</span> to
      <span class="font-bold text-slate-700 dark:text-slate-200">{{ toItem }}</span> of
      <span class="font-bold text-indigo-600 dark:text-indigo-400">{{ resolvedTotal }}</span> {{ label || 'records' }}
    </div>

    <div class="flex items-center gap-1.5 flex-wrap">
      <!-- Previous Button -->
      <button
        type="button"
        @click="goTo(resolvedCurrentPage - 1)"
        :disabled="resolvedCurrentPage <= 1"
        class="px-3 py-1.5 text-xs font-bold rounded-xl bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700/80 shadow-xs hover:bg-slate-100 dark:hover:bg-slate-700 disabled:opacity-30 disabled:cursor-not-allowed transition cursor-pointer flex items-center gap-1"
      >
        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" /></svg>
        Prev
      </button>

      <!-- Clickable Page Number Buttons -->
      <template v-for="page in visiblePages" :key="page">
        <span
          v-if="page === '...'"
          class="px-2 py-1 text-xs text-slate-400 select-none"
        >
          ...
        </span>
        <button
          v-else
          type="button"
          @click="goTo(page)"
          :class="[
            'min-w-8 h-8 px-2.5 text-xs font-bold rounded-xl transition flex items-center justify-center cursor-pointer',
            page === resolvedCurrentPage
              ? 'bg-indigo-600 text-white shadow-sm shadow-indigo-500/20'
              : 'bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700/80 hover:bg-slate-100 dark:hover:bg-slate-700'
          ]"
        >
          {{ page }}
        </button>
      </template>

      <!-- Next Button -->
      <button
        type="button"
        @click="goTo(resolvedCurrentPage + 1)"
        :disabled="resolvedCurrentPage >= effectiveLastPage"
        class="px-3 py-1.5 text-xs font-bold rounded-xl bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700/80 shadow-xs hover:bg-slate-100 dark:hover:bg-slate-700 disabled:opacity-30 disabled:cursor-not-allowed transition cursor-pointer flex items-center gap-1"
      >
        Next
        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" /></svg>
      </button>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue';

const props = defineProps({
  pagination: { type: Object, default: null },
  currentPage: { type: Number, default: 1 },
  lastPage: { type: Number, default: null },
  totalPages: { type: Number, default: null },
  total: { type: Number, default: 0 },
  perPage: { type: Number, default: 10 },
  label: { type: String, default: 'records' },
});

const emit = defineEmits(['change-page', 'page-change']);

const resolvedCurrentPage = computed(() => {
  if (props.pagination && props.pagination.current_page !== undefined) {
    return Number(props.pagination.current_page) || 1;
  }
  return Number(props.currentPage) || 1;
});

const resolvedTotal = computed(() => {
  if (props.pagination && props.pagination.total !== undefined) {
    return Number(props.pagination.total) || 0;
  }
  return Number(props.total) || 0;
});

const resolvedPerPage = computed(() => {
  if (props.pagination && props.pagination.per_page !== undefined) {
    return Math.max(1, Number(props.pagination.per_page) || 10);
  }
  return Math.max(1, Number(props.perPage) || 10);
});

// Accurately compute total pages from total and perPage, or explicit props
const effectiveLastPage = computed(() => {
  if (props.pagination && props.pagination.last_page !== undefined) {
    return Math.max(1, Number(props.pagination.last_page) || 1);
  }
  const tot = resolvedTotal.value;
  const pp = resolvedPerPage.value;
  const calculated = Math.ceil(tot / pp);

  const passedTotal = Number(props.totalPages);
  const passedLast = Number(props.lastPage);

  if (passedTotal && passedTotal > 1) return passedTotal;
  if (passedLast && passedLast > 1) return passedLast;
  return Math.max(1, calculated);
});

const fromItem = computed(() => {
  if (resolvedTotal.value === 0) return 0;
  const pp = resolvedPerPage.value;
  return (resolvedCurrentPage.value - 1) * pp + 1;
});

const toItem = computed(() => {
  const pp = resolvedPerPage.value;
  return Math.min(resolvedCurrentPage.value * pp, resolvedTotal.value);
});

// Generate smart visible page numbers: e.g. [1, 2, 3, 4] or [1, '...', 4, 5, '...', 10]
const visiblePages = computed(() => {
  const last = effectiveLastPage.value;
  const cur = resolvedCurrentPage.value;

  if (last <= 7) {
    return Array.from({ length: last }, (_, i) => i + 1);
  }

  const pages = [];
  pages.push(1);

  let start = Math.max(2, cur - 1);
  let end = Math.min(last - 1, cur + 1);

  if (cur <= 3) {
    end = 4;
  }
  if (cur >= last - 2) {
    start = last - 3;
  }

  if (start > 2) pages.push('...');
  for (let i = start; i <= end; i++) {
    pages.push(i);
  }
  if (end < last - 1) pages.push('...');

  pages.push(last);
  return pages;
});

function goTo(page) {
  const target = Number(page);
  if (target >= 1 && target <= effectiveLastPage.value && target !== resolvedCurrentPage.value) {
    emit('change-page', target);
    emit('page-change', target);
  }
}
</script>
