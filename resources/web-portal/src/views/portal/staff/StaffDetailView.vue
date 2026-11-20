<template>
  <div class="space-y-6 max-w-7xl mx-auto pb-12">
    <!-- Top Header Breadcrumb & Actions -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div class="flex items-center gap-3">
        <router-link
          to="/staff"
          class="w-10 h-10 rounded-xl bg-white dark:bg-slate-800 border border-slate-200/80 dark:border-slate-700/80 flex items-center justify-center text-slate-500 hover:text-indigo-600 hover:border-indigo-200 transition shadow-xs"
          title="Back to Staff Directory"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
        </router-link>
        <div>
          <div class="flex items-center gap-2">
            <span class="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider bg-indigo-50 dark:bg-indigo-950/60 text-indigo-700 dark:text-indigo-300 border border-indigo-200 dark:border-indigo-800">
              Staff Member Profile
            </span>
            <span class="font-mono text-xs text-slate-400">#{{ staff?.id }}</span>
          </div>
          <h2 class="text-2xl font-black text-slate-900 dark:text-white tracking-tight mt-0.5">
            {{ staff?.name || 'Staff Member' }}
          </h2>
        </div>
      </div>

      <!-- Action Buttons -->
      <div class="flex flex-wrap items-center gap-2.5">
        <button
          v-if="staff"
          type="button"
          @click="shareOnWhatsApp"
          class="inline-flex items-center gap-2 px-3.5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold shadow-md shadow-emerald-600/20 transition cursor-pointer"
        >
          <WhatsAppIcon sizeClass="w-4 h-4 text-white" />
          <span>Share Login on WhatsApp</span>
        </button>

        <button
          v-if="staff"
          type="button"
          @click="openEditModal"
          class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-white dark:bg-slate-800 border border-slate-200/80 dark:border-slate-700 text-slate-700 dark:text-slate-200 hover:text-indigo-600 hover:border-indigo-300 text-xs font-bold shadow-xs transition cursor-pointer"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
          </svg>
          <span>Edit Profile</span>
        </button>

        <button
          v-if="staff"
          type="button"
          @click="toggleStatus"
          :class="staff.is_active
            ? 'bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 border-rose-200 dark:border-rose-800 hover:bg-rose-100'
            : 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 border-emerald-200 dark:border-emerald-800 hover:bg-emerald-100'"
          class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl border text-xs font-bold shadow-xs transition cursor-pointer"
        >
          <span class="w-2 h-2 rounded-full" :class="staff.is_active ? 'bg-rose-500' : 'bg-emerald-500'"></span>
          <span>{{ staff.is_active ? 'Deactivate Login' : 'Activate Login' }}</span>
        </button>

        <button
          v-if="staff"
          type="button"
          @click="confirmDelete"
          class="p-2 rounded-xl text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/30 transition cursor-pointer"
          title="Delete Staff"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
          </svg>
        </button>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="py-20 text-center">
      <div class="inline-block animate-spin w-8 h-8 border-3 border-indigo-600 border-t-transparent rounded-full mb-3"></div>
      <p class="text-sm font-semibold text-slate-500 dark:text-slate-400">Loading staff details...</p>
    </div>

    <template v-else-if="staff">
      <!-- Top Profile Overview Card -->
      <div class="bg-white dark:bg-[#111827] rounded-3xl p-6 border border-slate-200/80 dark:border-slate-800/80 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div class="flex items-center gap-4">
          <div class="w-16 h-16 rounded-2xl bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 font-black text-2xl flex items-center justify-center border border-indigo-200/60 dark:border-indigo-800/60 shadow-xs shrink-0">
            {{ staff.name?.charAt(0)?.toUpperCase() || 'S' }}
          </div>
          <div>
            <div class="flex items-center gap-2.5 flex-wrap">
              <h1 class="text-xl font-black text-slate-900 dark:text-white">{{ staff.name }}</h1>
              <span class="px-2.5 py-0.5 rounded-md text-xs font-bold bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-200 border border-slate-200 dark:border-slate-700">
                {{ staff.designation || 'Staff Member' }}
              </span>
              <span
                :class="staff.is_active
                  ? 'bg-emerald-50 dark:bg-emerald-950/50 text-emerald-700 dark:text-emerald-400 border-emerald-200 dark:border-emerald-800'
                  : 'bg-rose-50 dark:bg-rose-950/50 text-rose-700 dark:text-rose-400 border-rose-200 dark:border-rose-800'"
                class="px-2.5 py-0.5 rounded-full text-xs font-bold border inline-flex items-center gap-1.5"
              >
                <span class="w-1.5 h-1.5 rounded-full" :class="staff.is_active ? 'bg-emerald-500' : 'bg-rose-500'"></span>
                {{ staff.is_active ? 'App Login Active' : 'App Login Disabled' }}
              </span>
            </div>
            <p class="text-xs text-slate-400 mt-1 flex items-center gap-2">
              <span>Mobile: <strong class="text-slate-700 dark:text-slate-300 font-mono">{{ staff.mobile || staff.phone }}</strong></span>
              <span v-if="staff.email" class="text-slate-300 dark:text-slate-700">•</span>
              <span v-if="staff.email">Email: <strong class="text-slate-700 dark:text-slate-300">{{ staff.email }}</strong></span>
            </p>
          </div>
        </div>

        <!-- 4 Mini Metrics inside Top Card -->
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <div class="p-3 rounded-2xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200/60 dark:border-slate-800/60">
            <span class="text-[10px] font-bold uppercase tracking-wider text-slate-400 block">Designation</span>
            <span class="text-xs font-bold text-slate-900 dark:text-white truncate block mt-0.5">{{ staff.designation || 'Staff' }}</span>
          </div>
          <div class="p-3 rounded-2xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200/60 dark:border-slate-800/60">
            <span class="text-[10px] font-bold uppercase tracking-wider text-slate-400 block">Monthly Salary</span>
            <span class="text-xs font-black text-slate-900 dark:text-white block mt-0.5">
              {{ staff.salary ? `₹${formatAmount(staff.salary)}` : 'Not Set' }}
            </span>
          </div>
          <div class="p-3 rounded-2xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200/60 dark:border-slate-800/60">
            <span class="text-[10px] font-bold uppercase tracking-wider text-slate-400 block">App Login Slot</span>
            <span class="text-xs font-bold block mt-0.5" :class="staff.is_active ? 'text-emerald-600 dark:text-emerald-400' : 'text-slate-400'">
              {{ staff.is_active ? 'Active Slot' : 'Inactive' }}
            </span>
          </div>
          <div class="p-3 rounded-2xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200/60 dark:border-slate-800/60">
            <span class="text-[10px] font-bold uppercase tracking-wider text-slate-400 block">Modules</span>
            <span class="text-xs font-bold text-indigo-600 dark:text-indigo-400 block mt-0.5">
              {{ activePermissionsCount }} of 5 Active
            </span>
          </div>
        </div>
      </div>

      <!-- Main 3-Column Content Layout -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Column 1: Mobile App Login Credentials Card -->
        <div class="bg-white dark:bg-[#111827] rounded-3xl p-6 border border-slate-200/80 dark:border-slate-800/80 shadow-sm space-y-5">
          <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
            <div class="flex items-center gap-2">
              <div class="w-8 h-8 rounded-xl bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 flex items-center justify-center font-bold">
                🔑
              </div>
              <div>
                <h3 class="font-bold text-slate-900 dark:text-white text-sm">App Login Credentials</h3>
                <p class="text-[11px] text-slate-400">Mobile app sign-in details</p>
              </div>
            </div>
            <button
              @click="shareOnWhatsApp"
              class="p-1.5 rounded-lg bg-emerald-50 hover:bg-emerald-100 dark:bg-emerald-950/50 text-emerald-600 dark:text-emerald-400 border border-emerald-200/60 dark:border-emerald-800/60 transition cursor-pointer"
              title="Send via WhatsApp"
            >
              <WhatsAppIcon sizeClass="w-4 h-4" />
            </button>
          </div>

          <!-- Login Username / Mobile -->
          <div class="space-y-1.5">
            <label class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Login Mobile / Username</label>
            <div class="flex items-center justify-between p-3 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200/60 dark:border-slate-800/60">
              <span class="font-mono text-sm font-bold text-slate-800 dark:text-slate-100">
                {{ staff.mobile || staff.phone }}
              </span>
              <button
                @click="copyText(staff.mobile || staff.phone, 'Mobile')"
                type="button"
                class="p-1 rounded text-slate-400 hover:text-indigo-600 transition cursor-pointer"
                title="Copy Mobile"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"/></svg>
              </button>
            </div>
          </div>

          <!-- Login Password -->
          <div class="space-y-1.5">
            <label class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Account Password</label>
            <div class="flex items-center justify-between p-3 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200/60 dark:border-slate-800/60">
              <span class="font-mono text-sm font-bold text-slate-800 dark:text-slate-100">
                <template v-if="staff.login_password">
                  {{ showPassword ? staff.login_password : '••••••••' }}
                </template>
                <template v-else>
                  <span class="text-xs text-slate-400 italic">Protected (Owner Only)</span>
                </template>
              </span>
              <div class="flex items-center gap-1" v-if="staff.login_password">
                <button
                  @click="showPassword = !showPassword"
                  type="button"
                  class="p-1 rounded text-slate-400 hover:text-indigo-600 transition cursor-pointer"
                  :title="showPassword ? 'Hide Password' : 'Show Password'"
                >
                  <svg v-if="showPassword" class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l18 18"/></svg>
                  <svg v-else class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                </button>
                <button
                  @click="copyText(staff.login_password, 'Password')"
                  type="button"
                  class="p-1 rounded text-slate-400 hover:text-indigo-600 transition cursor-pointer"
                  title="Copy Password"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"/></svg>
                </button>
              </div>
            </div>
          </div>

          <!-- Login Instructions Notice -->
          <div class="p-3.5 rounded-2xl bg-indigo-50/60 dark:bg-indigo-950/30 border border-indigo-100 dark:border-indigo-900/40 text-xs text-indigo-900 dark:text-indigo-300 space-y-1.5">
            <div class="font-bold flex items-center gap-1.5">
              <span>💡 How to sign in</span>
            </div>
            <p class="text-[11px] leading-relaxed text-indigo-800/80 dark:text-indigo-300/80">
              Staff opens the <strong>Mobile Shop Profit</strong> app on Android, enters their mobile number and password, and logs in directly.
            </p>
          </div>
        </div>

        <!-- Column 2: Module Permissions Card -->
        <div class="bg-white dark:bg-[#111827] rounded-3xl p-6 border border-slate-200/80 dark:border-slate-800/80 shadow-sm space-y-4">
          <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
            <div class="flex items-center gap-2">
              <div class="w-8 h-8 rounded-xl bg-purple-50 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400 flex items-center justify-center font-bold">
                🛡️
              </div>
              <div>
                <h3 class="font-bold text-slate-900 dark:text-white text-sm">Permitted Modules</h3>
                <p class="text-[11px] text-slate-400">Granular access control in app</p>
              </div>
            </div>
            <button
              @click="openEditModal"
              class="text-xs font-bold text-indigo-600 dark:text-indigo-400 hover:underline cursor-pointer"
            >
              Modify
            </button>
          </div>

          <!-- Permissions List -->
          <div class="space-y-2.5">
            <div
              v-for="mod in moduleDefinitions"
              :key="mod.key"
              class="flex items-center justify-between p-3 rounded-2xl border transition"
              :class="isModuleAllowed(mod.key)
                ? 'bg-slate-50/70 dark:bg-slate-900/50 border-slate-200/70 dark:border-slate-800'
                : 'bg-slate-50/30 dark:bg-slate-900/20 border-slate-100 dark:border-slate-800/40 opacity-60'"
            >
              <div class="flex items-center gap-3">
                <span class="text-xl">{{ mod.icon }}</span>
                <div>
                  <h4 class="text-xs font-bold text-slate-800 dark:text-slate-200">{{ mod.label }}</h4>
                  <p class="text-[10px] text-slate-400">{{ mod.desc }}</p>
                </div>
              </div>

              <!-- Permission Active Pill -->
              <span
                class="px-2.5 py-1 rounded-lg text-[10px] font-bold uppercase inline-flex items-center gap-1"
                :class="isModuleAllowed(mod.key)
                  ? 'bg-emerald-50 dark:bg-emerald-950/60 text-emerald-700 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-800'
                  : 'bg-slate-100 dark:bg-slate-800 text-slate-400 border border-slate-200 dark:border-slate-700'"
              >
                <svg v-if="isModuleAllowed(mod.key)" class="w-3 h-3 text-emerald-600 dark:text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"/></svg>
                <span v-else class="text-xs leading-none">✕</span>
                {{ isModuleAllowed(mod.key) ? 'Allowed' : 'Disabled' }}
              </span>
            </div>
          </div>
        </div>

        <!-- Column 3: Employment Details & Information -->
        <div class="bg-white dark:bg-[#111827] rounded-3xl p-6 border border-slate-200/80 dark:border-slate-800/80 shadow-sm space-y-4">
          <div class="flex items-center gap-2 border-b border-slate-100 dark:border-slate-800 pb-3">
            <div class="w-8 h-8 rounded-xl bg-amber-50 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 flex items-center justify-center font-bold">
              📋
            </div>
            <div>
              <h3 class="font-bold text-slate-900 dark:text-white text-sm">Employment Profile</h3>
              <p class="text-[11px] text-slate-400">HR and contract details</p>
            </div>
          </div>

          <div class="divide-y divide-slate-100 dark:divide-slate-800/60 text-xs">
            <div class="py-2.5 flex justify-between items-center">
              <span class="text-slate-400 font-medium">Designation / Role</span>
              <span class="font-bold text-slate-800 dark:text-slate-200">{{ staff.designation || 'Staff' }}</span>
            </div>
            <div class="py-2.5 flex justify-between items-center">
              <span class="text-slate-400 font-medium">Monthly Salary</span>
              <span class="font-bold text-slate-900 dark:text-white font-mono">
                {{ staff.salary ? `₹${formatAmount(staff.salary)}` : 'Not specified' }}
              </span>
            </div>
            <div class="py-2.5 flex justify-between items-center">
              <span class="text-slate-400 font-medium">Joining Date</span>
              <span class="font-bold text-slate-800 dark:text-slate-200">{{ formatDate(staff.joining_date) }}</span>
            </div>
            <div class="py-2.5 flex justify-between items-center">
              <span class="text-slate-400 font-medium">Email Address</span>
              <span class="font-semibold text-slate-700 dark:text-slate-300">{{ staff.email || '-' }}</span>
            </div>
            <div class="py-2.5 flex justify-between items-center">
              <span class="text-slate-400 font-medium">Address / City</span>
              <span class="font-semibold text-slate-700 dark:text-slate-300 text-right max-w-xs truncate">{{ staff.address || '-' }}</span>
            </div>
            <div class="py-2.5 flex justify-between items-center">
              <span class="text-slate-400 font-medium">Registered On</span>
              <span class="font-semibold text-slate-500 dark:text-slate-400">{{ formatDate(staff.created_at) }}</span>
            </div>
          </div>

          <!-- Notes section if present -->
          <div v-if="staff.notes" class="pt-2">
            <span class="text-[11px] font-bold uppercase tracking-wider text-slate-400 block mb-1">Notes</span>
            <p class="p-3 rounded-xl bg-slate-50 dark:bg-slate-900/60 text-xs text-slate-600 dark:text-slate-300 italic border border-slate-200/60 dark:border-slate-800/60">
              {{ staff.notes }}
            </p>
          </div>
        </div>
      </div>
    </template>

    <!-- EDIT STAFF MODAL -->
    <div
      v-if="showEditModal"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-3 sm:p-5"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-3xl w-full max-w-lg shadow-2xl max-h-[85vh] flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        <!-- Header -->
        <div class="px-6 py-4 border-b border-slate-100 dark:border-slate-800/80 flex justify-between items-center bg-slate-50/50 dark:bg-slate-900/30 shrink-0">
          <div>
            <h3 class="font-bold text-slate-900 dark:text-white">Edit Staff Member</h3>
            <p class="text-xs text-slate-400">Update account credentials and module permissions</p>
          </div>
          <button @click="showEditModal = false" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 cursor-pointer">✕</button>
        </div>

        <form @submit.prevent="submitEdit" class="p-6 space-y-4 overflow-y-auto custom-scroll flex-1">
          <!-- Role Presets -->
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Role Presets (Quick Permission Setup)
            </label>
            <div class="grid grid-cols-2 sm:grid-cols-4 gap-2">
              <button
                v-for="preset in rolePresets"
                :key="preset.title"
                type="button"
                @click="applyPreset(preset)"
                class="px-2.5 py-2 rounded-xl text-xs font-bold border transition text-center cursor-pointer flex flex-col items-center gap-1"
                :class="editForm.designation === preset.title
                  ? 'bg-indigo-600 text-white border-indigo-600 shadow-xs'
                  : 'bg-slate-50 dark:bg-slate-900/60 border-slate-200 dark:border-slate-800 text-slate-700 dark:text-slate-300 hover:border-indigo-300'"
              >
                <span class="text-sm">{{ preset.icon }}</span>
                <span class="truncate w-full">{{ preset.title }}</span>
              </button>
            </div>
          </div>

          <!-- Name & Mobile -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Full Name <span class="text-rose-500">*</span>
              </label>
              <input
                v-model="editForm.name"
                type="text"
                class="w-full px-3.5 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 font-bold"
                required
              />
            </div>
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Login Mobile <span class="text-rose-500">*</span>
              </label>
              <input
                v-model="editForm.mobile"
                type="tel"
                class="w-full px-3.5 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 font-mono font-bold"
                required
              />
            </div>
          </div>

          <!-- Password (Optional update) -->
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Change Password (Leave blank to keep existing)
            </label>
            <div class="relative">
              <input
                v-model="editForm.password"
                :type="editShowPassword ? 'text' : 'password'"
                class="w-full pl-3.5 pr-10 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100"
                placeholder="Enter new password (min 6 chars)"
              />
              <button
                type="button"
                @click="editShowPassword = !editShowPassword"
                class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 cursor-pointer"
              >
                {{ editShowPassword ? 'Hide' : 'Show' }}
              </button>
            </div>
          </div>

          <!-- Designation & Salary -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Designation
              </label>
              <input
                v-model="editForm.designation"
                type="text"
                class="w-full px-3.5 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100"
                placeholder="e.g. Sales Executive"
              />
            </div>
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Monthly Salary (₹)
              </label>
              <input
                v-model.number="editForm.salary"
                type="number"
                step="100"
                min="0"
                class="w-full px-3.5 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 font-mono font-bold"
                placeholder="e.g. 15000"
              />
            </div>
          </div>

          <!-- Joining Date & Email -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Joining Date
              </label>
              <DatePicker v-model="editForm.joining_date" />
            </div>
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Email Address
              </label>
              <input
                v-model="editForm.email"
                type="email"
                class="w-full px-3.5 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100"
                placeholder="staff@gmail.com"
              />
            </div>
          </div>

          <!-- Permissions Checkboxes -->
          <div>
            <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-2">
              Granular Module Permissions
            </label>
            <div class="space-y-2">
              <label
                v-for="mod in moduleDefinitions"
                :key="mod.key"
                class="flex items-center justify-between p-2.5 rounded-xl border border-slate-200/70 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-900/50 cursor-pointer select-none transition"
              >
                <div class="flex items-center gap-2.5">
                  <span class="text-lg">{{ mod.icon }}</span>
                  <div>
                    <span class="text-xs font-bold text-slate-800 dark:text-slate-200 block">{{ mod.label }}</span>
                    <span class="text-[10px] text-slate-400 block">{{ mod.desc }}</span>
                  </div>
                </div>
                <input
                  v-model="editForm.permissions[mod.key]"
                  type="checkbox"
                  class="w-4 h-4 rounded text-indigo-600 focus:ring-indigo-500 border-slate-300 dark:border-slate-700"
                />
              </label>
            </div>
          </div>

          <!-- Active Toggle -->
          <div class="flex items-center gap-2 pt-1">
            <input
              v-model="editForm.is_active"
              id="edit_staff_active"
              type="checkbox"
              class="w-4 h-4 rounded text-indigo-600 focus:ring-indigo-500 border-slate-300 dark:border-slate-700"
            />
            <label for="edit_staff_active" class="text-xs font-bold text-slate-700 dark:text-slate-300 cursor-pointer">
              Active App Login (Uses 1 active login slot)
            </label>
          </div>

          <!-- Footer -->
          <div class="flex justify-end gap-2 pt-3 border-t border-slate-100 dark:border-slate-800/80 shrink-0">
            <button
              type="button"
              @click="showEditModal = false"
              class="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-xl transition cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="savingEdit"
              class="px-4 py-2 text-xs font-bold bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl shadow-md shadow-indigo-600/20 disabled:opacity-50 transition cursor-pointer"
            >
              {{ savingEdit ? 'Saving...' : 'Save Changes' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { staffApi } from '@/api/endpoints';
import { formatDate } from '@/utils/date';
import { useToastStore } from '@/stores/toast';
import { useAuthStore } from '@/stores/auth';
import WhatsAppIcon from '@/components/common/WhatsAppIcon.vue';
import DatePicker from '@/components/common/DatePicker.vue';

const route = useRoute();
const router = useRouter();
const toast = useToastStore();
const authStore = useAuthStore();

const staff = ref(null);
const loading = ref(true);
const showPassword = ref(false);
const showEditModal = ref(false);
const editShowPassword = ref(false);
const savingEdit = ref(false);

const moduleDefinitions = [
  { key: 'sales', label: 'Sales & Billing (POS)', icon: '🛒', desc: 'Create invoices, bills and counter sales' },
  { key: 'repairs', label: 'Repair Job Cards', icon: '🔧', desc: 'Take in devices, update statuses, assign technicians' },
  { key: 'purchases', label: 'Stock & Purchases', icon: '📦', desc: 'Manage inventory inward and vendor bills' },
  { key: 'expenses', label: 'Shop Expenses', icon: '💰', desc: 'Record daily expenses, chai, rent and utilities' },
  { key: 'used_mobiles', label: 'Used Mobiles (Buy/Sell)', icon: '📱', desc: 'Second-hand intake, resale and IMEI tracking' },
];

const rolePresets = [
  { title: 'Manager', icon: '👑', perms: { sales: true, repairs: true, purchases: true, expenses: true, used_mobiles: true } },
  { title: 'Sales & Billing', icon: '🛒', perms: { sales: true, repairs: false, purchases: false, expenses: false, used_mobiles: true } },
  { title: 'Cashier', icon: '💳', perms: { sales: true, repairs: false, purchases: false, expenses: true, used_mobiles: false } },
  { title: 'Service Advisor', icon: '🔧', perms: { sales: true, repairs: true, purchases: false, expenses: false, used_mobiles: false } },
];

const editForm = reactive({
  name: '',
  mobile: '',
  password: '',
  designation: '',
  salary: null,
  joining_date: '',
  email: '',
  address: '',
  is_active: true,
  permissions: {
    sales: true,
    repairs: true,
    purchases: false,
    expenses: false,
    used_mobiles: false,
  },
});

const activePermissionsCount = computed(() => {
  if (!staff.value?.permissions) return 0;
  return Object.values(staff.value.permissions).filter(Boolean).length;
});

function isModuleAllowed(key) {
  if (!staff.value?.permissions) return false;
  return !!staff.value.permissions[key];
}

function formatAmount(val) {
  if (!val && val !== 0) return '0.00';
  return Number(val).toLocaleString('en-IN', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
}

function copyText(val, label = 'Text') {
  if (!val) return;
  navigator.clipboard.writeText(String(val));
  toast.success(`${label} copied to clipboard!`);
}

function shareOnWhatsApp() {
  if (!staff.value) return;
  const shopName = authStore.shopName || 'Our Mobile Shop';
  const activeModules = [];
  if (staff.value.permissions?.sales) activeModules.push('🛒 Sales & Billing');
  if (staff.value.permissions?.repairs) activeModules.push('🔧 Repairs & Intake');
  if (staff.value.permissions?.purchases) activeModules.push('📦 Stock & Purchases');
  if (staff.value.permissions?.expenses) activeModules.push('💰 Expenses');
  if (staff.value.permissions?.used_mobiles) activeModules.push('📱 Used Mobiles');

  const lines = [
    `👋 Hello *${staff.value.name}*,`,
    `Your staff account (*${staff.value.designation || 'Staff'}*) for *${shopName}* is active on the *Mobile Shop Profit* app!\n`,
    `🔑 *Your Login Credentials:*`,
    `📱 *Mobile / Username:* ${staff.value.mobile || staff.value.phone}`,
  ];

  if (staff.value.login_password) {
    lines.push(`🔒 *Password:* ${staff.value.login_password}`);
  }

  if (activeModules.length > 0) {
    lines.push('\n🛡️ *Permitted Modules:*');
    activeModules.forEach(m => lines.push(` • ${m}`));
  }

  lines.push('\nPlease open the app and login to continue:');
  lines.push('https://play.google.com/store/apps/details?id=com.repairehub');

  const shareText = lines.join('\n');
  const cleanPhone = (staff.value.mobile || staff.value.phone || '').replace(/[^0-9]/g, '');
  const formattedPhone = cleanPhone.length === 10 ? `91${cleanPhone}` : cleanPhone;
  window.open(`https://wa.me/${formattedPhone}?text=${encodeURIComponent(shareText)}`, '_blank');
}

async function loadStaffDetails() {
  loading.value = true;
  try {
    const res = await staffApi.get(route.params.id);
    const data = res.data?.data || res.data;
    if (data) {
      staff.value = data;
    } else {
      toast.error('Staff account not found.');
      router.push('/staff');
    }
  } catch (err) {
    console.error('Failed to load staff details', err);
    toast.error(err.response?.data?.message || 'Failed to load staff details.');
  } finally {
    loading.value = false;
  }
}

function openEditModal() {
  if (!staff.value) return;
  editForm.name = staff.value.name || '';
  editForm.mobile = staff.value.mobile || staff.value.phone || '';
  editForm.password = '';
  editForm.designation = staff.value.designation || 'Staff';
  editForm.salary = staff.value.salary || null;
  editForm.joining_date = staff.value.joining_date || '';
  editForm.email = staff.value.email || '';
  editForm.address = staff.value.address || '';
  editForm.is_active = !!staff.value.is_active;
  editForm.permissions = {
    sales: !!staff.value.permissions?.sales,
    repairs: !!staff.value.permissions?.repairs,
    purchases: !!staff.value.permissions?.purchases,
    expenses: !!staff.value.permissions?.expenses,
    used_mobiles: !!staff.value.permissions?.used_mobiles,
  };
  showEditModal.value = true;
}

function applyPreset(preset) {
  editForm.designation = preset.title;
  if (preset.perms) {
    editForm.permissions = { ...preset.perms };
  }
}

async function submitEdit() {
  if (!editForm.name || !editForm.mobile) {
    toast.error('Name and mobile number are required.');
    return;
  }
  savingEdit.value = true;
  try {
    const payload = {
      name: editForm.name,
      mobile: editForm.mobile,
      designation: editForm.designation,
      salary: editForm.salary || null,
      joining_date: editForm.joining_date || null,
      email: editForm.email || null,
      address: editForm.address || null,
      is_active: editForm.is_active,
      permissions: editForm.permissions,
    };
    if (editForm.password) {
      payload.password = editForm.password;
    }
    const res = await staffApi.update(staff.value.id, payload);
    toast.success('Staff profile updated successfully!');
    showEditModal.value = false;
    loadStaffDetails();
  } catch (err) {
    console.error('Update failed', err);
    toast.error(err.response?.data?.message || 'Failed to update staff profile.');
  } finally {
    savingEdit.value = false;
  }
}

async function toggleStatus() {
  if (!staff.value) return;
  const willActivate = !staff.value.is_active;
  const confirmed = await toast.confirm({
    title: willActivate ? 'Activate Staff Login?' : 'Deactivate Staff Login?',
    message: willActivate
      ? `Are you sure you want to activate app login for ${staff.value.name}? This will consume 1 active staff slot.`
      : `Are you sure you want to deactivate app login for ${staff.value.name}? Staff will not be able to sign in until re-activated.`,
    confirmText: willActivate ? 'Yes, Activate' : 'Yes, Deactivate',
    type: willActivate ? 'info' : 'warning',
  });
  if (!confirmed) return;

  try {
    const res = await staffApi.toggleStatus(staff.value.id);
    toast.success(res.data?.message || `Staff login ${willActivate ? 'activated' : 'deactivated'} successfully!`);
    loadStaffDetails();
  } catch (err) {
    console.error('Toggle status failed', err);
    toast.error(err.response?.data?.message || 'Failed to update staff status.');
  }
}

async function confirmDelete() {
  if (!staff.value) return;
  const confirmed = await toast.confirm({
    title: 'Delete Staff Member?',
    message: `Are you sure you want to permanently delete ${staff.value.name}? Their login credentials will be revoked immediately.`,
    confirmText: 'Delete Staff',
    type: 'danger',
  });
  if (!confirmed) return;

  try {
    await staffApi.delete(staff.value.id);
    toast.success(`${staff.value.name} deleted successfully!`);
    router.push('/staff');
  } catch (err) {
    console.error('Delete failed', err);
    toast.error(err.response?.data?.message || 'Failed to delete staff member.');
  }
}

onMounted(() => {
  loadStaffDetails();
});
</script>
