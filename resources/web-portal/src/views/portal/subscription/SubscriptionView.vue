<template>
  <div class="max-w-4xl mx-auto space-y-6">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <div class="flex items-center gap-2">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 border border-indigo-200/60 dark:border-indigo-800/60">
            Billing
          </span>
          <span class="text-xs text-slate-400">Shop License & Tier</span>
        </div>
        <h2 class="text-2xl font-bold tracking-tight text-slate-900 dark:text-white mt-1">Subscription & Billing</h2>
        <p class="text-sm text-slate-500 dark:text-slate-400">View active SaaS plan, expiry dates, and renew subscription</p>
      </div>
    </div>

    <!-- Current Plan Banner -->
    <div class="rounded-2xl p-6 bg-gradient-to-r from-indigo-600 to-indigo-800 text-white shadow-xl shadow-indigo-600/20 flex flex-col md:flex-row items-start md:items-center justify-between gap-6 relative overflow-hidden">
      <div class="relative z-10">
        <span class="text-xs uppercase tracking-wider bg-white/20 backdrop-blur-md px-3 py-1 rounded-full font-bold">Active Plan</span>
        <h3 class="text-2xl font-black mt-3">{{ subscription.plan_name || 'Free Trial' }}</h3>
        <p class="text-indigo-100 text-sm mt-1">
          Valid Until: <span class="font-bold text-white">{{ formatDate(subscription.expiry_date) }}</span>
        </p>
      </div>
      <div class="relative z-10">
        <span :class="subscription.status === 'active' ? 'bg-emerald-500/90 text-white' : 'bg-amber-400 text-slate-900'" class="px-3.5 py-1.5 rounded-full text-xs font-bold uppercase shadow-sm">
          {{ subscription.status || 'Trial' }}
        </span>
      </div>
    </div>

    <!-- Available Plans -->
    <div class="space-y-4">
      <h3 class="text-lg font-bold text-slate-900 dark:text-white">Available Upgrade Plans</h3>
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div
          v-for="plan in plans"
          :key="plan.id"
          class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800/80 p-6 shadow-sm hover:border-indigo-500 dark:hover:border-indigo-500 transition-all flex flex-col justify-between group"
        >
          <div>
            <h4 class="font-bold text-slate-900 dark:text-white text-lg group-hover:text-indigo-600 dark:group-hover:text-indigo-400 transition">{{ plan.name }}</h4>
            <p class="text-xs text-slate-400 mt-1">{{ plan.duration_days }} Days Access</p>
            <div class="my-4">
              <span class="text-3xl font-extrabold text-slate-900 dark:text-white">₹{{ plan.price }}</span>
              <span class="text-xs text-slate-400"> / {{ plan.duration_days }} days</span>
            </div>
            <ul class="space-y-2.5 text-xs text-slate-600 dark:text-slate-300 mb-6">
              <li class="flex items-center gap-2"><span class="text-indigo-600 dark:text-indigo-400 font-bold">✓</span> Unlimited Repairs & Sales</li>
              <li class="flex items-center gap-2"><span class="text-indigo-600 dark:text-indigo-400 font-bold">✓</span> Inventory & Dues Ledger</li>
              <li class="flex items-center gap-2"><span class="text-indigo-600 dark:text-indigo-400 font-bold">✓</span> Thermal Bill & A4 Invoices</li>
              <li class="flex items-center gap-2"><span class="text-indigo-600 dark:text-indigo-400 font-bold">✓</span> Mobile App & Web Portal Sync</li>
            </ul>
          </div>
          <div>
            <a
              href="https://play.google.com/store/apps/details?id=com.repairehub"
              target="_blank"
              class="w-full inline-flex items-center justify-center px-4 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-semibold shadow-md shadow-indigo-600/20 transition text-center"
            >
              Upgrade via Google Play App
            </a>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { subscriptionApi } from '@/api/endpoints';

const subscription = ref({});
const plans = ref([]);

async function loadSubscription() {
  try {
    const [subRes, plansRes] = await Promise.all([
      subscriptionApi.status().catch(() => ({ data: { data: {} } })),
      subscriptionApi.plans().catch(() => ({ data: { data: [] } })),
    ]);
    subscription.value = subRes.data?.data || {};
    plans.value = plansRes.data?.data || [];
  } catch (err) {
    console.error('Failed to load subscription info:', err);
  }
}

function formatDate(d) {
  if (!d) return 'Lifetime';
  const date = new Date(d);
  return date.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
}

onMounted(() => {
  loadSubscription();
});
</script>
