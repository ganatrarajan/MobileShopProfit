<template>
  <div class="min-h-screen flex items-center justify-center bg-slate-100 dark:bg-slate-950 p-4 sm:p-6 transition-colors duration-250 relative font-sans selection:bg-indigo-600 selection:text-white">
    <!-- Background subtle gradient aura matching ERP -->
    <div class="absolute inset-0 bg-gradient-to-tr from-indigo-500/5 via-transparent to-purple-500/5 dark:from-indigo-500/10 dark:via-transparent dark:to-cyan-500/10 pointer-events-none"></div>

    <!-- Top Floating Actions (Dark/Light mode & Google Play link) -->
    <div class="absolute top-4 sm:top-6 right-4 sm:right-6 z-20 flex items-center gap-3">
      <!-- Google Play Pill -->
      <a
        href="https://play.google.com/store/apps/details?id=com.repairehub"
        target="_blank"
        class="hidden sm:inline-flex items-center gap-2 px-3 py-1.5 rounded-xl bg-white/80 dark:bg-slate-900/80 border border-slate-200 dark:border-slate-800 text-xs font-semibold text-slate-700 dark:text-slate-300 hover:text-indigo-600 dark:hover:text-indigo-400 shadow-sm backdrop-blur-md transition-all"
        title="Download MyRepairHub on Google Play"
      >
        <svg class="w-4 h-4 text-emerald-500" viewBox="0 0 24 24" fill="currentColor">
          <path d="M3.609 1.814L13.793 12 3.61 22.186c-.378-.363-.61-.88-.61-1.464V3.278c0-.584.232-1.101.61-1.464zM15.207 13.414l2.122 2.121-12.72 7.344 10.598-9.465zm0-2.828L4.609 1.121l12.72 7.344-2.122 2.121zm1.414 1.414l3.535 2.042c.884.511.884 1.346 0 1.856l-3.535 2.042-2.122-2.119z" />
        </svg>
        <span>Google Play</span>
      </a>

      <!-- Light / Dark Mode Toggle Button (Same as ERP AppLayout) -->
      <button
        @click="toggleTheme"
        type="button"
        class="p-2 text-slate-500 dark:text-slate-400 hover:text-indigo-600 dark:hover:text-amber-400 rounded-xl bg-white/80 dark:bg-slate-900/80 border border-slate-200 dark:border-slate-800 shadow-sm backdrop-blur-md transition-colors cursor-pointer"
        title="Toggle Light/Dark Theme"
      >
        <!-- Sun Icon (if dark mode active) -->
        <svg v-if="isDark" class="w-5 h-5 text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 9H3m15.364-6.364l-.707.707M6.343 17.657l-.707.707m0-12.728l.707.707m12.728 12.728l.707-.707M12 8a4 4 0 100 8 4 4 0 000-8z"></path>
        </svg>
        <!-- Moon Icon (if light mode active) -->
        <svg v-else class="w-5 h-5 text-indigo-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"></path>
        </svg>
      </button>
    </div>

    <!-- Login Card (Exact ERP Card Structure & Styling) -->
    <div class="w-full max-w-md bg-white/95 dark:bg-slate-900/75 backdrop-blur-md border border-slate-200 dark:border-slate-800/80 p-6 sm:p-8 rounded-2xl shadow-2xl transition-all relative z-10">
      <!-- Header / Logo -->
      <div class="flex flex-col items-center mb-7">
        <div class="w-16 h-16 rounded-2xl bg-indigo-600 flex items-center justify-center text-white text-3xl font-extrabold shadow-lg shadow-indigo-500/25 mb-3 transition-transform hover:scale-105">
          <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
          </svg>
        </div>
        <h2 class="text-2xl font-bold tracking-tight text-slate-900 dark:text-white flex items-center gap-2">
          MyRepairHub
          <span class="text-[10px] font-extrabold uppercase tracking-widest px-2 py-0.5 rounded-md bg-indigo-50 text-indigo-700 dark:bg-indigo-900/50 dark:text-indigo-400 border border-indigo-200 dark:border-indigo-800">
            Web
          </span>
        </h2>
        <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">Smart Mobile Shop & Repair Management</p>
      </div>

      <!-- Welcome Back Subhead -->
      <h3 class="text-lg font-bold text-slate-800 dark:text-white text-center mb-5">Welcome Back</h3>

      <!-- Error Alert (Exact ERP Style: Rose border + icon + text) -->
      <div
        v-if="error"
        class="mb-5 p-3.5 bg-rose-500/10 border border-rose-500/25 text-rose-600 dark:text-rose-400 rounded-xl text-xs font-semibold flex items-start gap-2.5 transition-all"
      >
        <svg class="w-4 h-4 flex-shrink-0 mt-0.5 text-rose-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path>
        </svg>
        <div class="flex-1 leading-relaxed break-words">{{ error }}</div>
        <button
          type="button"
          @click="error = ''"
          class="text-rose-400 hover:text-rose-600 dark:hover:text-rose-200 font-bold ml-1"
          title="Dismiss"
        >
          ✕
        </button>
      </div>

      <!-- Form (ERP Inputs with Left Icons & Border Styling) -->
      <form @submit.prevent="handleLogin" class="space-y-4">
        <!-- Mobile / Email Field -->
        <div>
          <label class="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-2">
            Mobile Number / Email
          </label>
          <div class="relative">
            <span class="absolute inset-y-0 left-0 pl-3.5 flex items-center text-slate-400 dark:text-slate-500">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 12a4 4 0 10-8 0 4 4 0 008 0zm0 0v1.5a2.5 2.5 0 005 0V12a9 9 0 10-9 9m4.5-1.206a8.959 8.959 0 01-4.5 1.207"></path>
              </svg>
            </span>
            <input
              type="text"
              v-model="form.login"
              required
              autofocus
              placeholder="e.g. 7405989816 or owner@email.com"
              class="w-full pl-10 pr-4 py-2.5 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl text-sm text-slate-900 dark:text-white placeholder-slate-400 dark:placeholder-slate-600 focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all font-medium"
            />
          </div>
        </div>

        <!-- Password Field -->
        <div>
          <div class="flex justify-between items-center mb-2">
            <label class="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              Password
            </label>
            <span class="text-[11px] text-slate-400 dark:text-slate-500 font-medium">Owner Login</span>
          </div>
          <div class="relative">
            <span class="absolute inset-y-0 left-0 pl-3.5 flex items-center text-slate-400 dark:text-slate-500">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path>
              </svg>
            </span>
            <input
              :type="showPassword ? 'text' : 'password'"
              v-model="form.password"
              required
              placeholder="••••••••"
              class="w-full pl-10 pr-11 py-2.5 bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl text-sm text-slate-900 dark:text-white placeholder-slate-400 dark:placeholder-slate-600 focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all"
            />
            <button
              type="button"
              @click="showPassword = !showPassword"
              class="absolute inset-y-0 right-0 pr-3.5 flex items-center text-slate-400 hover:text-slate-600 dark:hover:text-slate-300 transition-colors"
            >
              <svg v-if="!showPassword" class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
              </svg>
              <svg v-else class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
              </svg>
            </button>
          </div>
        </div>

        <!-- Remember Me Checkbox -->
        <div class="flex items-center pt-1">
          <input
            type="checkbox"
            id="remember"
            v-model="form.remember"
            class="h-4 w-4 rounded border-slate-300 dark:border-slate-800 bg-slate-50 dark:bg-slate-950 text-indigo-600 focus:ring-indigo-500/25"
          />
          <label for="remember" class="ml-2.5 block text-xs text-slate-500 dark:text-slate-400 font-medium select-none cursor-pointer">
            Remember my credentials
          </label>
        </div>

        <!-- Submit Button (Exact ERP indigo styling) -->
        <button
          type="submit"
          :disabled="loading"
          class="w-full py-2.5 px-4 bg-indigo-600 hover:bg-indigo-500 active:scale-[0.98] text-white font-bold text-sm rounded-xl shadow-lg shadow-indigo-600/20 transition-all flex items-center justify-center gap-2 disabled:opacity-50 disabled:pointer-events-none mt-2 cursor-pointer"
        >
          <svg v-if="loading" class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <span v-if="loading">Signing in...</span>
          <span v-else>Sign In</span>
        </button>
      </form>

      <!-- App Download / Google Play Box (Matching ERP card) -->
      <div class="mt-6 pt-5 border-t border-slate-200/80 dark:border-slate-800/80">
        <div class="p-3.5 rounded-xl bg-slate-50 dark:bg-slate-950/70 border border-slate-200 dark:border-slate-800 flex items-center justify-between gap-3">
          <div class="flex items-center gap-2.5 min-w-0">
            <div class="w-8 h-8 rounded-lg bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-center justify-center flex-shrink-0">
              <svg class="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
                <path d="M3.609 1.814L13.793 12 3.61 22.186c-.378-.363-.61-.88-.61-1.464V3.278c0-.584.232-1.101.61-1.464zM15.207 13.414l2.122 2.121-12.72 7.344 10.598-9.465zm0-2.828L4.609 1.121l12.72 7.344-2.122 2.121zm1.414 1.414l3.535 2.042c.884.511.884 1.346 0 1.856l-3.535 2.042-2.122-2.119z" />
              </svg>
            </div>
            <div class="min-w-0">
              <p class="text-xs font-bold text-slate-800 dark:text-white truncate">Android Mobile App</p>
              <p class="text-[11px] text-slate-500 dark:text-slate-400 truncate">Staff & Technicians use mobile app</p>
            </div>
          </div>
          <a
            href="https://play.google.com/store/apps/details?id=com.repairehub"
            target="_blank"
            class="px-2.5 py-1.5 rounded-lg bg-indigo-600 hover:bg-indigo-500 text-white text-[11px] font-bold transition-colors whitespace-nowrap flex-shrink-0"
          >
            Get App →
          </a>
        </div>

        <p class="text-[11px] text-center text-slate-400 dark:text-slate-500 mt-4 leading-relaxed">
          Web portal access is reserved for <strong class="text-slate-600 dark:text-slate-300 font-semibold">Shop Owners</strong> with active web access enabled by admin.
        </p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useAuthStore } from '@/stores/auth';

const router = useRouter();
const route = useRoute();
const authStore = useAuthStore();

const form = reactive({
  login: localStorage.getItem('saved_login') || '',
  password: '',
  remember: Boolean(localStorage.getItem('saved_login')),
});

const showPassword = ref(false);
const error = ref('');
const loading = ref(false);
const isDark = ref(false);

onMounted(() => {
  // Sync Dark/Light state with documentElement class
  isDark.value = document.documentElement.classList.contains('dark');
});

function toggleTheme() {
  if (isDark.value) {
    document.documentElement.classList.remove('dark');
    localStorage.setItem('theme', 'light');
    isDark.value = false;
  } else {
    document.documentElement.classList.add('dark');
    localStorage.setItem('theme', 'dark');
    isDark.value = true;
  }
}

async function handleLogin() {
  error.value = '';
  loading.value = true;

  const inputVal = form.login.trim();
  const isEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(inputVal);
  let cleanLogin = inputVal;

  if (!isEmail) {
    const cleanDigits = inputVal.replace(/\D/g, '');
    if (cleanDigits.length < 10) {
      error.value = 'Please enter a valid 10-digit mobile number or email address';
      loading.value = false;
      return;
    }
    cleanLogin = cleanDigits.slice(-10);
  }

  if (!form.password || form.password.length < 4) {
    error.value = 'Password must be at least 4 characters';
    loading.value = false;
    return;
  }

  try {
    await authStore.login(cleanLogin, form.password);

    if (form.remember) {
      localStorage.setItem('saved_login', cleanLogin);
    } else {
      localStorage.removeItem('saved_login');
    }

    const redirect = route.query.redirect || '/';
    router.push(redirect);
  } catch (err) {
    error.value = err.response?.data?.message || err.message || 'Login failed. Please check your credentials.';
  } finally {
    loading.value = false;
  }
}
</script>
