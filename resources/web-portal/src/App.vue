<template>
  <router-view />
  <GlobalToastContainer />
  <GlobalConfirmModal />
</template>

<script setup>
import { onMounted } from 'vue';
import { useAuthStore } from '@/stores/auth';
import { useToastStore } from '@/stores/toast';
import GlobalToastContainer from '@/components/common/GlobalToastContainer.vue';
import GlobalConfirmModal from '@/components/common/GlobalConfirmModal.vue';

const authStore = useAuthStore();
const toastStore = useToastStore();

onMounted(() => {
  authStore.initAuth();

  // Global helpers
  window.$toast = toastStore;
  window.$confirm = toastStore.confirm;

  // Gracefully intercept any legacy window.alert calls into stylized toasts
  window.alert = (msg) => {
    const text = typeof msg === 'string' ? msg : JSON.stringify(msg);
    if (/fail|error|invalid|exceed/i.test(text)) {
      toastStore.error(text, 'Notice');
    } else if (/success|saved|created|updated/i.test(text)) {
      toastStore.success(text, 'Success');
    } else {
      toastStore.warning(text, 'Attention');
    }
  };
});
</script>
