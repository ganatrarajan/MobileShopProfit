<template>
  <div
    v-if="toastStore.confirmState.isOpen"
    class="fixed inset-0 z-[999999] overflow-y-auto flex items-center justify-center p-4 bg-slate-950/70 backdrop-blur-xs animate-in fade-in duration-150"
    @click.self="cancel"
    @keydown.esc="cancel"
    @wheel.stop
  >
    <div
      class="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-3xl p-6 max-w-sm w-full shadow-2xl space-y-4 animate-in zoom-in-95 duration-150"
    >
      <div class="flex items-start gap-3.5">
        <!-- Icon badge -->
        <div
          class="w-10 h-10 rounded-2xl shrink-0 flex items-center justify-center text-lg shadow-xs"
          :class="getIconBadgeClasses()"
        >
          <svg
            v-if="toastStore.confirmState.type === 'danger'"
            class="w-5 h-5 text-rose-600 dark:text-rose-400"
            fill="none" stroke="currentColor" viewBox="0 0 24 24"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
          </svg>
          <svg
            v-else-if="toastStore.confirmState.type === 'warning'"
            class="w-5 h-5 text-amber-600 dark:text-amber-400"
            fill="none" stroke="currentColor" viewBox="0 0 24 24"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
          <svg
            v-else
            class="w-5 h-5 text-indigo-600 dark:text-indigo-400"
            fill="none" stroke="currentColor" viewBox="0 0 24 24"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>

        <div>
          <h3 class="text-base font-bold text-slate-900 dark:text-white">
            {{ toastStore.confirmState.title }}
          </h3>
          <p class="text-xs text-slate-500 dark:text-slate-400 mt-1 leading-relaxed">
            {{ toastStore.confirmState.message }}
          </p>
        </div>
      </div>

      <div class="flex items-center justify-end gap-2.5 pt-2">
        <button
          type="button"
          @click="cancel"
          class="px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-xs font-semibold text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-700 transition cursor-pointer"
        >
          {{ toastStore.confirmState.cancelText }}
        </button>
        <button
          type="button"
          @click="confirm"
          class="px-4 py-2 rounded-xl text-xs font-bold text-white shadow-xs transition cursor-pointer"
          :class="getConfirmButtonClasses()"
        >
          {{ toastStore.confirmState.confirmText }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useToastStore } from '@/stores/toast';

const toastStore = useToastStore();

function cancel() {
  toastStore.handleConfirm(false);
}

function confirm() {
  toastStore.handleConfirm(true);
}

function getIconBadgeClasses() {
  switch (toastStore.confirmState.type) {
    case 'danger':
      return 'bg-rose-50 dark:bg-rose-950/60 border border-rose-200 dark:border-rose-800';
    case 'warning':
      return 'bg-amber-50 dark:bg-amber-950/60 border border-amber-200 dark:border-amber-800';
    default:
      return 'bg-indigo-50 dark:bg-indigo-950/60 border border-indigo-200 dark:border-indigo-800';
  }
}

function getConfirmButtonClasses() {
  switch (toastStore.confirmState.type) {
    case 'danger':
      return 'bg-rose-600 hover:bg-rose-700 shadow-rose-600/20';
    case 'warning':
      return 'bg-amber-600 hover:bg-amber-700 shadow-amber-600/20';
    default:
      return 'bg-indigo-600 hover:bg-indigo-700 shadow-indigo-600/20';
  }
}
</script>
