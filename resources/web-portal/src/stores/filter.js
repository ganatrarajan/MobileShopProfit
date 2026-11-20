import { defineStore } from 'pinia';
import { ref, computed } from 'vue';

export const useFilterStore = defineStore('filter', () => {
  // Global persisted period filter across all pages in the portal
  const storedPeriod = localStorage.getItem('portal_selected_period');
  const selectedPeriod = ref(storedPeriod || 'this_month');

  const periodOptions = [
    { value: 'today', label: 'Today' },
    { value: 'yesterday', label: 'Yesterday' },
    { value: 'this_week', label: 'This Week' },
    { value: 'this_month', label: 'This Month' },
    { value: 'last_month', label: 'Last Month' },
    { value: 'this_year', label: 'This Year' },
    { value: 'all_time', label: 'All Time' },
  ];

  const repairStatusOptions = [
    { value: '', label: 'All Repair Statuses' },
    { value: 'received', label: 'Received' },
    { value: 'diagnosing', label: 'Diagnosing' },
    { value: 'waiting_customer', label: 'Waiting Customer' },
    { value: 'waiting_parts', label: 'Waiting Parts' },
    { value: 'repairing', label: 'Repairing' },
    { value: 'ready', label: 'Ready for Pickup' },
    { value: 'delivered', label: 'Delivered' },
    { value: 'cancelled', label: 'Cancelled' },
  ];

  function setPeriod(period) {
    if (!period) return;
    selectedPeriod.value = period;
    try {
      localStorage.setItem('portal_selected_period', period);
    } catch {
      // ignore storage quota issues
    }
  }

  const periodDisplayLabel = computed(() => {
    switch (selectedPeriod.value) {
      case 'today': return "Today's";
      case 'yesterday': return "Yesterday's";
      case 'this_week': return 'This Week';
      case 'last_month': return 'Last Month';
      case 'this_year': return 'This Year';
      case 'all_time': return 'All Time';
      case 'this_month':
      default:
        return 'This Month';
    }
  });

  return {
    selectedPeriod,
    periodOptions,
    repairStatusOptions,
    setPeriod,
    periodDisplayLabel,
  };
});
