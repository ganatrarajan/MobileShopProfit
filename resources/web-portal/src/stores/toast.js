import { defineStore } from 'pinia';
import { ref } from 'vue';

export const useToastStore = defineStore('toast', () => {
  const toasts = ref([]);
  let nextId = 1;

  // Confirm modal state
  const confirmState = ref({
    isOpen: false,
    title: 'Confirm Action',
    message: 'Are you sure you want to proceed?',
    confirmText: 'Confirm',
    cancelText: 'Cancel',
    type: 'danger', // 'danger' | 'warning' | 'primary'
    resolve: null,
  });

  function addToast({ type = 'info', title = '', message = '', duration = 4000 }) {
    const id = nextId++;
    const defaultTitles = {
      success: 'Success',
      error: 'Action Failed',
      warning: 'Attention',
      info: 'Notice',
    };

    const toast = {
      id,
      type, // 'success' | 'error' | 'warning' | 'info'
      title: title || defaultTitles[type] || 'Notification',
      message: typeof message === 'string' ? message : JSON.stringify(message),
      duration,
      createdAt: Date.now(),
    };

    // Add to top of stack
    toasts.value.unshift(toast);

    // Keep max 5 visible toasts
    if (toasts.value.length > 5) {
      toasts.value.pop();
    }

    if (duration > 0) {
      setTimeout(() => {
        removeToast(id);
      }, duration);
    }

    return id;
  }

  function removeToast(id) {
    const idx = toasts.value.findIndex((t) => t.id === id);
    if (idx !== -1) {
      toasts.value.splice(idx, 1);
    }
  }

  function clearAll() {
    toasts.value = [];
  }

  function success(message, title = 'Success', duration = 3500) {
    return addToast({ type: 'success', title, message, duration });
  }

  function error(message, title = 'Action Failed', duration = 5000) {
    return addToast({ type: 'error', title, message, duration });
  }

  function warning(message, title = 'Attention', duration = 4000) {
    return addToast({ type: 'warning', title, message, duration });
  }

  function info(message, title = 'Information', duration = 3500) {
    return addToast({ type: 'info', title, message, duration });
  }

  function confirm({
    title = 'Confirm Action',
    message = 'Are you sure you want to perform this action?',
    confirmText = 'Yes, Proceed',
    cancelText = 'Cancel',
    type = 'danger',
  } = {}) {
    return new Promise((resolve) => {
      confirmState.value = {
        isOpen: true,
        title,
        message,
        confirmText,
        cancelText,
        type,
        resolve,
      };
    });
  }

  function handleConfirm(result) {
    if (confirmState.value.resolve) {
      confirmState.value.resolve(result);
    }
    confirmState.value.isOpen = false;
    confirmState.value.resolve = null;
  }

  return {
    toasts,
    confirmState,
    addToast,
    removeToast,
    clearAll,
    success,
    error,
    warning,
    info,
    confirm,
    handleConfirm,
  };
});
