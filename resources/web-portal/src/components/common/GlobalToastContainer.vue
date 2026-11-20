<template>
  <div class="fixed top-5 right-5 z-[99999] flex flex-col gap-3 max-w-sm w-full pointer-events-none px-4 sm:px-0">
    <TransitionGroup
      name="toast"
      tag="div"
      class="flex flex-col gap-2.5 w-full"
    >
      <div
        v-for="toast in toastStore.toasts"
        :key="toast.id"
        class="pointer-events-auto relative overflow-hidden rounded-2xl p-4 shadow-2xl border backdrop-blur-md transition-all duration-300 flex items-start gap-3 group"
        :class="getToastCardClasses(toast.type)"
      >
        <!-- Left Color Accent Glow Bar -->
        <div
          class="absolute left-0 top-0 bottom-0 w-1.5"
          :class="getAccentBarClass(toast.type)"
        ></div>

        <!-- Status Icon -->
        <div
          class="w-8 h-8 rounded-xl shrink-0 flex items-center justify-center shadow-xs text-sm"
          :class="getIconBadgeClass(toast.type)"
        >
          <!-- Success: Check -->
          <svg v-if="toast.type === 'success'" class="w-4 h-4 text-emerald-600 dark:text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7" />
          </svg>

          <!-- Error: Exclamation/Cross -->
          <svg v-else-if="toast.type === 'error'" class="w-4 h-4 text-rose-600 dark:text-rose-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>

          <!-- Warning: Exclamation Triangle -->
          <svg v-else-if="toast.type === 'warning'" class="w-4 h-4 text-amber-600 dark:text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>

          <!-- Info: Information Circle -->
          <svg v-else class="w-4 h-4 text-indigo-600 dark:text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>

        <!-- Content (Title & Message) -->
        <div class="flex-1 min-w-0 pr-1">
          <h4 class="text-xs font-bold text-slate-900 dark:text-white leading-tight">
            {{ toast.title }}
          </h4>
          <p class="text-[12px] text-slate-600 dark:text-slate-300 mt-0.5 leading-snug break-words">
            {{ toast.message }}
          </p>
        </div>

        <!-- Close Button -->
        <button
          type="button"
          @click="toastStore.removeToast(toast.id)"
          class="shrink-0 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 p-1 rounded-lg transition hover:bg-slate-100 dark:hover:bg-slate-800 cursor-pointer"
          aria-label="Dismiss notification"
        >
          <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>

        <!-- Dynamic Animated Progress Bar for Auto-Dismiss -->
        <div
          v-if="toast.duration > 0"
          class="absolute bottom-0 left-0 right-0 h-0.5 overflow-hidden"
          :class="getProgressBgClass(toast.type)"
        >
          <div
            class="h-full w-full origin-left animate-toast-progress"
            :style="{ animationDuration: `${toast.duration}ms` }"
            :class="getProgressBarClass(toast.type)"
          ></div>
        </div>
      </div>
    </TransitionGroup>
  </div>
</template>

<script setup>
import { useToastStore } from '@/stores/toast';

const toastStore = useToastStore();

function getToastCardClasses(type) {
  switch (type) {
    case 'success':
      return 'bg-white/95 dark:bg-slate-900/95 border-emerald-500/30 dark:border-emerald-500/40 shadow-emerald-500/10';
    case 'error':
      return 'bg-white/95 dark:bg-slate-900/95 border-rose-500/30 dark:border-rose-500/40 shadow-rose-500/10';
    case 'warning':
      return 'bg-white/95 dark:bg-slate-900/95 border-amber-500/30 dark:border-amber-500/40 shadow-amber-500/10';
    default:
      return 'bg-white/95 dark:bg-slate-900/95 border-indigo-500/30 dark:border-indigo-500/40 shadow-indigo-500/10';
  }
}

function getAccentBarClass(type) {
  switch (type) {
    case 'success':
      return 'bg-emerald-500';
    case 'error':
      return 'bg-rose-500';
    case 'warning':
      return 'bg-amber-500';
    default:
      return 'bg-indigo-500';
  }
}

function getIconBadgeClass(type) {
  switch (type) {
    case 'success':
      return 'bg-emerald-50 dark:bg-emerald-950/60 border border-emerald-200 dark:border-emerald-800';
    case 'error':
      return 'bg-rose-50 dark:bg-rose-950/60 border border-rose-200 dark:border-rose-800';
    case 'warning':
      return 'bg-amber-50 dark:bg-amber-950/60 border border-amber-200 dark:border-amber-800';
    default:
      return 'bg-indigo-50 dark:bg-indigo-950/60 border border-indigo-200 dark:border-indigo-800';
  }
}

function getProgressBgClass(type) {
  switch (type) {
    case 'success':
      return 'bg-emerald-100 dark:bg-emerald-950/40';
    case 'error':
      return 'bg-rose-100 dark:bg-rose-950/40';
    case 'warning':
      return 'bg-amber-100 dark:bg-amber-950/40';
    default:
      return 'bg-indigo-100 dark:bg-indigo-950/40';
  }
}

function getProgressBarClass(type) {
  switch (type) {
    case 'success':
      return 'bg-emerald-500';
    case 'error':
      return 'bg-rose-500';
    case 'warning':
      return 'bg-amber-500';
    default:
      return 'bg-indigo-500';
  }
}
</script>

<style scoped>
.toast-enter-active,
.toast-leave-active {
  transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}
.toast-enter-from {
  opacity: 0;
  transform: translateX(40px) scale(0.95);
}
.toast-leave-to {
  opacity: 0;
  transform: translateX(40px) scale(0.95);
}

@keyframes toastProgress {
  from {
    transform: scaleX(1);
  }
  to {
    transform: scaleX(0);
  }
}

.animate-toast-progress {
  animation: toastProgress linear forwards;
}
</style>
