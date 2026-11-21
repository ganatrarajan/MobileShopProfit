<template>
  <div class="max-w-4xl mx-auto space-y-6">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <div class="flex items-center gap-2">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 border border-indigo-200/60 dark:border-indigo-800/60">
            Store Identity
          </span>
          <span class="text-xs text-slate-400">Configuration</span>
        </div>
        <h2 class="text-2xl font-bold tracking-tight text-slate-900 dark:text-white mt-1">Shop Profile & Settings</h2>
        <p class="text-sm text-slate-500 dark:text-slate-400">Manage business information, invoice branding, and address</p>
      </div>
    </div>

    <!-- Alert Banners -->
    <div v-if="successMsg" class="p-4 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-900/50 text-sm text-emerald-700 dark:text-emerald-300 flex items-center gap-2">
      <svg class="w-5 h-5 text-emerald-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
      {{ successMsg }}
    </div>
    <div v-if="errorMsg" class="p-4 rounded-xl bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-900/50 text-sm text-rose-700 dark:text-rose-300 flex items-center gap-2">
      <svg class="w-5 h-5 text-rose-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
      {{ errorMsg }}
    </div>

    <form @submit.prevent="saveShop" class="space-y-6">
      <!-- Business Identity Card -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800/80 p-6 shadow-sm space-y-4">
        <h3 class="font-bold text-slate-900 dark:text-white border-b border-slate-100 dark:border-slate-800/80 pb-3">Business Identity</h3>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Shop Name <span class="text-rose-500">*</span></label>
            <input v-model="form.name" type="text" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100" required />
          </div>
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Owner Name <span class="text-rose-500">*</span></label>
            <input v-model="form.owner_name" type="text" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100" required />
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Shop Contact Number (Bills, Card & WhatsApp) <span class="text-rose-500">*</span>
            </label>
            <input v-model="form.phone" type="tel" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100" required placeholder="Shop public phone" />
            <p class="text-[10px] text-slate-400 mt-1">Printed on all customer invoices, digital visiting card & WhatsApp. No OTP needed.</p>
          </div>
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Owner Login Mobile
            </label>
            <input v-model="form.owner_mobile" type="tel" disabled class="w-full px-3 py-2 text-sm bg-slate-100 dark:bg-slate-800/80 border border-slate-200 dark:border-slate-700 rounded-xl text-slate-500 dark:text-slate-400 cursor-not-allowed" />
            <p class="text-[10px] text-slate-400 mt-1">Used strictly for account login authentication and security OTP verification.</p>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Email Address</label>
            <input v-model="form.email" type="email" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100" />
          </div>
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">GSTIN / Tax ID</label>
            <input v-model="form.gst_number" type="text" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400" placeholder="Optional GST" />
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">UPI ID for Payments</label>
            <input v-model="form.upi_id" type="text" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400" placeholder="e.g. shop@okaxis" />
          </div>
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Tagline / Motto</label>
            <input v-model="form.tagline" type="text" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400" placeholder="Fast & Reliable Mobile Repairs" />
          </div>
        </div>
      </div>

      <!-- Address Details Card -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800/80 p-6 shadow-sm space-y-4">
        <h3 class="font-bold text-slate-900 dark:text-white border-b border-slate-100 dark:border-slate-800/80 pb-3">Location & Address</h3>
        <div>
          <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Shop Address</label>
          <input v-model="form.address" type="text" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400" placeholder="Shop No, Complex, Street" />
        </div>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">City</label>
            <input v-model="form.city" type="text" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100" />
          </div>
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">State</label>
            <input v-model="form.state" type="text" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100" />
          </div>
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Pincode</label>
            <input v-model="form.pincode" type="text" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100" />
          </div>
        </div>
      </div>

      <!-- Invoice Terms & Conditions Card -->
      <div class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800/80 p-6 shadow-sm space-y-4">
        <h3 class="font-bold text-slate-900 dark:text-white border-b border-slate-100 dark:border-slate-800/80 pb-3">Invoice Terms & Conditions</h3>
        <div>
          <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
            Bill Terms (Printed on PDF Invoices)
          </label>
          <textarea
            v-model="form.terms_and_conditions"
            rows="4"
            class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400 font-mono text-xs"
            placeholder="1. Goods once sold will be covered strictly as per warranty terms.&#10;2. Physical damage or liquid exposure voids warranty.&#10;3. Please present this bill for any warranty claims."
          ></textarea>
          <p class="text-[10px] text-slate-400 mt-1">These custom warranty and repair terms are printed at the bottom of all customer bills.</p>
        </div>
      </div>

      <div class="flex justify-end">
        <button
          type="submit"
          :disabled="saving"
          class="px-6 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-semibold text-sm shadow-md shadow-indigo-600/20 disabled:opacity-50 transition cursor-pointer"
        >
          {{ saving ? 'Saving Changes...' : 'Save Settings' }}
        </button>
      </div>
    </form>

    <!-- Official Support & Helpline Details (from Admin Panel SystemSetting) -->
    <div class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800/80 p-6 shadow-sm space-y-4">
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 border-b border-slate-100 dark:border-slate-800 pb-3">
        <div>
          <span class="inline-flex items-center px-2 py-0.5 rounded-md text-[10px] font-bold uppercase tracking-wider bg-indigo-50 text-indigo-700 dark:bg-indigo-950/60 dark:text-indigo-400 border border-indigo-200/60 dark:border-indigo-800/60">
            Official Care & Helpline
          </span>
          <h3 class="font-bold text-slate-900 dark:text-white mt-1">Platform Admin Support Information</h3>
        </div>
        <span class="text-xs text-slate-500 dark:text-slate-400 font-medium">
          ⏱️ {{ adminContact.support_hours }}
        </span>
      </div>

      <p class="text-xs text-slate-500 dark:text-slate-400">
        For plan renewal, shop license expansion, or assistance, reach out directly to the official admin support team:
      </p>

      <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <!-- WhatsApp -->
        <a
          :href="`https://wa.me/${cleanPhone(adminContact.whatsapp_number)}?text=${encodeURIComponent('Hello Admin, I need support with my shop account on MyRepairHub')}`"
          target="_blank"
          class="flex items-center gap-3 p-3.5 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200/80 dark:border-slate-800 hover:border-emerald-500/50 dark:hover:border-emerald-500/50 hover:bg-emerald-50/20 transition group"
        >
          <div class="w-10 h-10 rounded-xl bg-emerald-50 dark:bg-emerald-950/50 text-emerald-600 dark:text-emerald-400 flex items-center justify-center font-bold">
            <WhatsAppIcon sizeClass="w-5 h-5 text-emerald-600" />
          </div>
          <div class="min-w-0">
            <p class="text-[10px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-wider">Official WhatsApp</p>
            <p class="text-xs font-bold text-slate-800 dark:text-slate-200 group-hover:text-emerald-600 transition truncate">{{ adminContact.whatsapp_number }}</p>
          </div>
        </a>

        <!-- Phone Helpline -->
        <a
          :href="`tel:${cleanPhone(adminContact.support_phone)}`"
          class="flex items-center gap-3 p-3.5 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200/80 dark:border-slate-800 hover:border-indigo-500/50 dark:hover:border-indigo-500/50 hover:bg-indigo-50/20 transition group"
        >
          <div class="w-10 h-10 rounded-xl bg-indigo-50 dark:bg-indigo-950/50 text-indigo-600 dark:text-indigo-400 flex items-center justify-center font-bold">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/></svg>
          </div>
          <div class="min-w-0">
            <p class="text-[10px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-wider">Help Helpline</p>
            <p class="text-xs font-bold text-slate-800 dark:text-slate-200 group-hover:text-indigo-600 transition truncate">{{ adminContact.support_phone }}</p>
          </div>
        </a>

        <!-- Support Email -->
        <a
          :href="`mailto:${adminContact.support_email}`"
          class="flex items-center gap-3 p-3.5 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200/80 dark:border-slate-800 hover:border-purple-500/50 dark:hover:border-purple-500/50 hover:bg-purple-50/20 transition group"
        >
          <div class="w-10 h-10 rounded-xl bg-purple-50 dark:bg-purple-950/50 text-purple-600 dark:text-purple-400 flex items-center justify-center font-bold">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/></svg>
          </div>
          <div class="min-w-0">
            <p class="text-[10px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-wider">Email Address</p>
            <p class="text-xs font-bold text-slate-800 dark:text-slate-200 group-hover:text-purple-600 transition truncate">{{ adminContact.support_email }}</p>
          </div>
        </a>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue';
import { shopApi, supportApi } from '@/api/endpoints';
import { useAuthStore } from '@/stores/auth';
import { useToastStore } from '@/stores/toast';
import WhatsAppIcon from '@/components/common/WhatsAppIcon.vue';

const authStore = useAuthStore();
const toast = useToastStore();
const saving = ref(false);
const successMsg = ref('');
const errorMsg = ref('');

const adminContact = reactive({
  support_phone: '+91 98765 43210',
  whatsapp_number: '+91 98765 43210',
  support_email: 'support@mobileprofits1.com',
  support_hours: 'Mon - Sat: 9:00 AM - 8:00 PM IST',
});

function cleanPhone(phone) {
  if (!phone) return '919876543210';
  const digits = String(phone).replace(/\D/g, '');
  if (digits.length === 10) return `91${digits}`;
  return digits;
}

const form = reactive({
  name: '',
  owner_name: '',
  phone: '',
  owner_mobile: '',
  email: '',
  gst_number: '',
  upi_id: '',
  tagline: '',
  address: '',
  city: '',
  state: '',
  pincode: '',
  terms_and_conditions: '',
});

async function loadAdminContact() {
  try {
    const res = await supportApi.contactInfo();
    const info = res.data?.data;
    if (info) {
      if (info.support_phone) adminContact.support_phone = info.support_phone;
      if (info.whatsapp_number) adminContact.whatsapp_number = info.whatsapp_number;
      if (info.support_email) adminContact.support_email = info.support_email;
      if (info.support_hours) adminContact.support_hours = info.support_hours;
    }
  } catch (err) {
    console.error('Failed to load support contact info:', err);
  }
}

async function loadShop() {
  try {
    const res = await shopApi.get();
    const data = res.data?.data;
    if (data) {
      Object.assign(form, {
        name: data.name || '',
        owner_name: data.owner_name || '',
        phone: data.phone || data.shop_phone || data.mobile || '',
        owner_mobile: data.owner_mobile || data.user?.mobile || '',
        email: data.email || '',
        gst_number: data.gst_number || '',
        upi_id: data.upi_id || '',
        tagline: data.tagline || '',
        address: data.address || '',
        city: data.city || '',
        state: data.state || '',
        pincode: data.pincode || '',
        terms_and_conditions: data.terms_and_conditions || '',
      });
    }
  } catch (err) {
    console.error('Failed to load shop settings:', err);
  }
}

async function saveShop() {
  saving.value = true;
  successMsg.value = '';
  errorMsg.value = '';
  try {
    await shopApi.update(form);
    successMsg.value = 'Shop settings saved successfully!';
    toast.success('Shop identity and business profile saved!', 'Settings Saved');
    authStore.fetchProfile();
    setTimeout(() => { successMsg.value = ''; }, 3000);
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to save shop settings';
    errorMsg.value = msg;
    toast.error(msg, 'Save Settings Failed');
  } finally {
    saving.value = false;
  }
}

onMounted(() => {
  loadShop();
  loadAdminContact();
});
</script>
