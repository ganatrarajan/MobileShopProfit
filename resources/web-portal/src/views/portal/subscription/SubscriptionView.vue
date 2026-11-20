<template>
  <div class="max-w-4xl mx-auto space-y-6 font-['Outfit',sans-serif]">
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
        <p class="text-sm text-slate-500 dark:text-slate-400">View active SaaS plan, validity date, and contact admin to renew or upgrade your license</p>
      </div>

      <button
        type="button"
        @click="openContactAdminModal()"
        class="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold shadow-md shadow-emerald-600/20 transition cursor-pointer self-start sm:self-center"
      >
        <WhatsAppIcon sizeClass="w-4 h-4 text-white" />
        <span>Contact Admin to Renew</span>
      </button>
    </div>

    <!-- Current Plan Banner -->
    <div class="rounded-3xl p-6 sm:p-8 bg-gradient-to-r from-indigo-600 via-indigo-700 to-indigo-800 text-white shadow-xl shadow-indigo-600/20 flex flex-col md:flex-row items-start md:items-center justify-between gap-6 relative overflow-hidden">
      <!-- Decorative background circles -->
      <div class="absolute -right-12 -top-12 w-48 h-48 bg-white/10 rounded-full blur-2xl pointer-events-none"></div>
      <div class="absolute right-32 -bottom-16 w-40 h-40 bg-indigo-400/20 rounded-full blur-xl pointer-events-none"></div>

      <div class="relative z-10 space-y-2">
        <div class="flex items-center gap-2.5">
          <span class="text-[11px] uppercase tracking-wider bg-white/20 backdrop-blur-md px-3 py-1 rounded-full font-bold">
            Active Plan
          </span>
          <span
            :class="subscription.status === 'active' ? 'bg-emerald-500 text-white' : 'bg-amber-400 text-slate-900'"
            class="px-2.5 py-0.5 rounded-full text-[11px] font-bold uppercase shadow-xs"
          >
            {{ subscription.status || 'Active' }}
          </span>
        </div>
        <h3 class="text-2xl sm:text-3xl font-black tracking-tight">
          {{ subscription.plan?.name || subscription.plan_name || 'Free Trial' }}
        </h3>
        <p class="text-indigo-100 text-xs sm:text-sm flex items-center gap-1.5 font-medium">
          <span>Valid Until:</span>
          <span class="font-bold text-white font-mono bg-white/15 px-2.5 py-0.5 rounded-lg">
            {{ formatDate(subscription.expiry_date) }}
          </span>
          <span v-if="subscription.days_remaining !== undefined" class="text-indigo-200 text-xs">
            ({{ subscription.days_remaining }} days remaining)
          </span>
        </p>
      </div>

      <div class="relative z-10 flex flex-col sm:flex-row gap-2.5 w-full md:w-auto">
        <button
          type="button"
          @click="openContactAdminModal()"
          class="px-4 py-2.5 rounded-xl bg-white text-indigo-700 hover:bg-indigo-50 text-xs font-bold shadow-md transition flex items-center justify-center gap-2 cursor-pointer"
        >
          <WhatsAppIcon sizeClass="w-4 h-4 text-emerald-600" />
          <span>Renew / Extend Plan</span>
        </button>
      </div>
    </div>

    <!-- Admin Contact Details Card (As configured in Admin Panel) -->
    <div class="bg-white dark:bg-[#111827] rounded-3xl p-6 border border-slate-200/80 dark:border-slate-800/80 shadow-sm space-y-4">
      <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
        <div class="flex items-center gap-2.5">
          <div class="w-9 h-9 rounded-xl bg-emerald-50 dark:bg-emerald-950/50 text-emerald-600 dark:text-emerald-400 flex items-center justify-center font-bold">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 5.636l-3.536 3.536m0 5.656l3.536 3.536M9.172 9.172L5.636 5.636m3.536 9.192l-3.536 3.536M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-5 0a4 4 0 11-8 0 4 4 0 018 0z"/></svg>
          </div>
          <div>
            <h3 class="font-bold text-slate-900 dark:text-white text-sm">Official Admin & Renewal Support</h3>
            <p class="text-xs text-slate-400">Plans are activated and renewed directly by the system administrator</p>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 pt-1">
        <!-- WhatsApp Admin -->
        <a
          :href="getWhatsAppUrl(subscription.plan)"
          target="_blank"
          class="p-4 rounded-2xl bg-emerald-50/60 dark:bg-emerald-950/30 border border-emerald-200/70 dark:border-emerald-900/50 hover:border-emerald-400 transition flex items-center gap-3.5 group cursor-pointer"
        >
          <div class="w-10 h-10 rounded-xl bg-emerald-500 text-white flex items-center justify-center shrink-0 shadow-sm shadow-emerald-500/20 group-hover:scale-105 transition">
            <WhatsAppIcon sizeClass="w-5 h-5 text-white" />
          </div>
          <div class="min-w-0">
            <p class="text-[11px] font-bold uppercase tracking-wider text-emerald-700 dark:text-emerald-400">WhatsApp Admin</p>
            <p class="text-xs font-bold text-slate-800 dark:text-slate-100 font-mono truncate mt-0.5">
              {{ adminContact.whatsapp_number || adminContact.support_phone }}
            </p>
            <p class="text-[10px] text-emerald-600 dark:text-emerald-400 font-medium">Click to chat directly →</p>
          </div>
        </a>

        <!-- Phone Call -->
        <a
          :href="getPhoneCallUrl()"
          class="p-4 rounded-2xl bg-indigo-50/60 dark:bg-indigo-950/30 border border-indigo-200/70 dark:border-indigo-900/50 hover:border-indigo-400 transition flex items-center gap-3.5 group cursor-pointer"
        >
          <div class="w-10 h-10 rounded-xl bg-indigo-600 text-white flex items-center justify-center shrink-0 shadow-sm shadow-indigo-600/20 group-hover:scale-105 transition">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/></svg>
          </div>
          <div class="min-w-0">
            <p class="text-[11px] font-bold uppercase tracking-wider text-indigo-700 dark:text-indigo-400">Direct Phone Call</p>
            <p class="text-xs font-bold text-slate-800 dark:text-slate-100 font-mono truncate mt-0.5">
              {{ adminContact.support_phone }}
            </p>
            <p class="text-[10px] text-indigo-600 dark:text-indigo-400 font-medium">Click to call admin →</p>
          </div>
        </a>

        <!-- Support Email & Hours -->
        <a
          :href="getEmailUrl(subscription.plan)"
          class="p-4 rounded-2xl bg-slate-50 dark:bg-slate-900/50 border border-slate-200 dark:border-slate-800 hover:border-slate-400 transition flex items-center gap-3.5 group cursor-pointer"
        >
          <div class="w-10 h-10 rounded-xl bg-slate-700 text-white flex items-center justify-center shrink-0 shadow-sm group-hover:scale-105 transition">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/></svg>
          </div>
          <div class="min-w-0">
            <p class="text-[11px] font-bold uppercase tracking-wider text-slate-500">Official Email</p>
            <p class="text-xs font-bold text-slate-800 dark:text-slate-100 truncate mt-0.5">
              {{ adminContact.support_email }}
            </p>
            <p class="text-[10px] text-slate-400 truncate">{{ adminContact.support_hours }}</p>
          </div>
        </a>
      </div>
    </div>

    <!-- Contact Admin Renewal Modal -->
    <div
      v-if="contactModalOpen"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-3 sm:p-5"
      @wheel.stop
    >
      <div class="bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-3xl w-full max-w-md shadow-2xl flex flex-col max-h-[90vh] overflow-hidden animate-in fade-in zoom-in-95 my-auto">
        <!-- Pinned Header -->
        <div class="p-5 sm:p-6 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between shrink-0 bg-indigo-50/50 dark:bg-indigo-950/30">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-2xl bg-indigo-600 text-white flex items-center justify-center font-bold shadow-md shadow-indigo-600/20">
              <WhatsAppIcon sizeClass="w-5 h-5 text-white" />
            </div>
            <div>
              <h3 class="text-base font-bold text-slate-900 dark:text-white">Contact Admin to Renew</h3>
              <p class="text-xs text-slate-400">
                Shop: {{ shopName }} <span v-if="shopId">(#{{ shopId }})</span>
              </p>
            </div>
          </div>
          <button @click="contactModalOpen = false" class="text-slate-400 hover:text-slate-600 p-1.5 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 cursor-pointer">✕</button>
        </div>

        <!-- Body -->
        <div class="overflow-y-auto custom-scroll flex-1 p-5 sm:p-6 space-y-4">
          <!-- Current Plan Summary Card -->
          <div class="p-4 rounded-2xl bg-indigo-50/70 dark:bg-indigo-950/40 border border-indigo-200/80 dark:border-indigo-800">
            <span class="text-[10px] font-bold uppercase tracking-wider text-indigo-600 dark:text-indigo-400">Your Current Subscription:</span>
            <div class="flex items-center justify-between mt-1">
              <h4 class="font-black text-slate-900 dark:text-white text-base">{{ subscription.plan?.name || subscription.plan_name || 'Free Trial' }}</h4>
              <span class="font-bold text-[10px] bg-emerald-100 dark:bg-emerald-900/60 text-emerald-700 dark:text-emerald-300 px-2 py-0.5 rounded-md uppercase font-mono">
                {{ subscription.status || 'Active' }}
              </span>
            </div>
            <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
              Valid Until: <strong class="text-slate-800 dark:text-slate-200">{{ formatDate(subscription.expiry_date) }}</strong>
            </p>
          </div>

          <!-- Quick instructions -->
          <p class="text-xs text-slate-600 dark:text-slate-300 leading-relaxed">
            Please message or call the administrator directly to renew, extend, or update your shop account license:
          </p>

          <!-- Contact Actions -->
          <div class="space-y-2.5 pt-1">
            <!-- 1. WhatsApp Button -->
            <a
              :href="getWhatsAppUrl()"
              target="_blank"
              class="w-full py-3 px-4 rounded-2xl bg-[#25D366] hover:bg-[#20ba5a] text-white font-bold text-xs shadow-md shadow-emerald-500/20 transition flex items-center justify-center gap-2 cursor-pointer"
            >
              <WhatsAppIcon sizeClass="w-4 h-4 text-white" />
              <span>Message Admin on WhatsApp</span>
            </a>

            <!-- 2. Phone Call Button -->
            <a
              :href="getPhoneCallUrl()"
              class="w-full py-3 px-4 rounded-2xl bg-indigo-600 hover:bg-indigo-500 text-white font-bold text-xs shadow-md shadow-indigo-600/20 transition flex items-center justify-center gap-2 cursor-pointer"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/></svg>
              <span>Call Admin: {{ adminContact.support_phone }}</span>
            </a>

            <!-- 3. Email Button -->
            <a
              :href="getEmailUrl()"
              class="w-full py-2.5 px-4 rounded-2xl border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-200 font-semibold text-xs transition flex items-center justify-center gap-2 cursor-pointer"
            >
              <svg class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/></svg>
              <span>Email: {{ adminContact.support_email }}</span>
            </a>
          </div>

          <div class="pt-2 text-[11px] text-slate-400 text-center">
            🕒 Hours: {{ adminContact.support_hours }}
          </div>
        </div>

        <!-- Footer -->
        <div class="p-4 border-t border-slate-100 dark:border-slate-800 flex justify-end shrink-0 bg-slate-50/50 dark:bg-slate-900/50">
          <button
            type="button"
            @click="contactModalOpen = false"
            class="px-4 py-2 rounded-xl text-xs font-bold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition cursor-pointer"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue';
import { subscriptionApi, supportApi } from '@/api/endpoints';
import { formatDate } from '@/utils/date';
import { useAuthStore } from '@/stores/auth';
import WhatsAppIcon from '@/components/common/WhatsAppIcon.vue';

const authStore = useAuthStore();

const subscription = ref({});
const contactModalOpen = ref(false);

const shopName = computed(() => authStore.shopName || authStore.shop?.name || 'My Shop');
const shopId = computed(() => authStore.shop?.id || authStore.user?.shop_id || '');

const adminContact = reactive({
  support_phone: '+91 98765 43210',
  whatsapp_number: '+91 98765 43210',
  support_email: 'support@mobileprofits1.com',
  support_hours: 'Mon - Sat: 9:00 AM - 8:00 PM IST',
});

function openContactAdminModal() {
  contactModalOpen.value = true;
}

function getWhatsAppUrl() {
  const phone = adminContact.whatsapp_number || adminContact.support_phone || '919876543210';
  let cleanPhone = String(phone).replace(/\D/g, '');
  if (cleanPhone.length === 10) cleanPhone = '91' + cleanPhone;

  const sName = shopName.value;
  const sId = shopId.value;
  const planName = subscription.value?.plan?.name || subscription.value?.plan_name || 'Renewal Plan';

  const text = `Hello Admin 👋\n\nI want to renew / extend my shop subscription:\n• Shop: ${sName}${sId ? ` (ID: #${sId})` : ''}\n• Current Plan: ${planName}\n\nPlease share payment details / extend my plan. Thank you!`;

  return `https://wa.me/${cleanPhone}?text=${encodeURIComponent(text)}`;
}

function getPhoneCallUrl() {
  const phone = adminContact.support_phone || '+91 98765 43210';
  const clean = String(phone).replace(/[^0-9+]/g, '');
  return `tel:${clean}`;
}

function getEmailUrl() {
  const email = adminContact.support_email || 'support@mobileprofits1.com';
  const sName = shopName.value;
  const sId = shopId.value;
  const planName = subscription.value?.plan?.name || subscription.value?.plan_name || 'Renewal';

  const subject = `Subscription Renewal Request - ${sName} (#${sId})`;
  const body = `Hello Admin,\n\nI would like to renew or extend our shop subscription plan ("${planName}").\n\nShop Name: ${sName}\nShop ID: #${sId}\nOwner Name: ${authStore.user?.name || ''}\nOwner Mobile: ${authStore.user?.mobile || authStore.user?.phone || ''}\n\nPlease advise on the renewal process.\n\nThank you!`;

  return `mailto:${email}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
}

async function loadSubscription() {
  try {
    const [subRes, contactRes] = await Promise.all([
      subscriptionApi.status().catch(() => ({ data: { data: {} } })),
      supportApi.contactInfo().catch(() => ({ data: { data: {} } })),
    ]);

    subscription.value = subRes.data?.data || {};

    // Support contact info from API or status
    const contactData = contactRes.data?.data || subRes.data?.data?.admin_contact || {};
    if (contactData.support_phone) adminContact.support_phone = contactData.support_phone;
    if (contactData.whatsapp_number) adminContact.whatsapp_number = contactData.whatsapp_number;
    else if (contactData.whatsapp) adminContact.whatsapp_number = contactData.whatsapp;
    if (contactData.support_email) adminContact.support_email = contactData.support_email;
    if (contactData.support_hours) adminContact.support_hours = contactData.support_hours;
  } catch (err) {
    console.error('Failed to load subscription info:', err);
  }
}

function formatAmount(val) {
  if (val === undefined || val === null || isNaN(val)) return '0.00';
  return Number(val).toLocaleString('en-IN', { maximumFractionDigits: 2 });
}

onMounted(() => {
  loadSubscription();
});
</script>
