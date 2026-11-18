<template>
  <div class="max-w-6xl mx-auto space-y-6 pb-12 font-['Outfit',sans-serif]">
    <!-- Top Action & Navigation Bar -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div class="flex items-center gap-3">
        <router-link
          to="/repairs"
          class="inline-flex items-center gap-1.5 px-3 py-2 text-xs font-semibold rounded-xl bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-200 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 shadow-sm transition"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/></svg>
          Back to Repairs
        </router-link>
        <div>
          <div class="flex items-center gap-2">
            <h1 class="text-2xl font-bold text-slate-900 dark:text-white">
              {{ repair.job_number || ('#JOB-' + String(repair.id || '').padStart(6, '0')) }}
            </h1>
            <span :class="getStatusBadgeClass(repair.repair_status)" class="px-2.5 py-0.5 rounded-full text-xs font-bold uppercase tracking-wide">
              {{ getStatusLabel(repair.repair_status) }}
            </span>
          </div>
          <p class="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
            Received on {{ formatDate(repair.date_received || repair.created_at) }}
            <span v-if="repair.creator_name" class="ml-1">• Logged by {{ repair.creator_name }}</span>
          </p>
        </div>
      </div>

      <!-- Quick Action Buttons -->
      <div class="flex flex-wrap items-center gap-2">
        <!-- WhatsApp Ticket Button -->
        <button
          @click="openWhatsAppModal"
          class="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold rounded-xl bg-[#25D366] text-white hover:bg-[#20ba5a] shadow-sm transition shadow-green-500/20 cursor-pointer"
        >
          <WhatsAppIcon sizeClass="w-4 h-4" />
          <span>WhatsApp Ticket</span>
        </button>

        <!-- Print Job Card / Invoice -->
        <button
          @click="openPrintModal"
          class="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold rounded-xl bg-slate-800 text-white dark:bg-slate-700 hover:bg-slate-900 shadow-sm transition"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"/></svg>
          Print Job Card
        </button>

        <!-- Edit Job Card (Hidden if Delivered) -->
        <router-link
          v-if="repair.repair_status !== 'delivered'"
          :to="`/repairs/${repair.id}/edit`"
          class="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold rounded-xl bg-indigo-50 dark:bg-indigo-950/40 text-indigo-600 dark:text-indigo-400 border border-indigo-200 dark:border-indigo-800/60 hover:bg-indigo-100 transition"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
          Edit
        </router-link>

        <!-- Finalized Freeze Badge if Delivered -->
        <span
          v-else
          class="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold rounded-xl bg-emerald-50 dark:bg-emerald-950/40 text-emerald-800 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800/60 select-none"
        >
          🔒 Delivered (Frozen)
        </span>

        <!-- Delete Job Card (Hidden if Delivered) -->
        <button
          v-if="repair.repair_status !== 'delivered'"
          @click="showDeleteModal = true"
          class="inline-flex items-center gap-1.5 px-3 py-2 text-xs font-semibold rounded-xl bg-red-50 dark:bg-red-950/30 text-red-600 dark:text-red-400 border border-red-200 dark:border-red-800/50 hover:bg-red-100 transition"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
        </button>
      </div>
    </div>

    <!-- Hero Overview Gradient Banner (Identical to Mobile App) -->
    <div :class="getHeroGradient(repair.repair_status)" class="rounded-3xl p-6 text-white shadow-xl shadow-indigo-500/10 relative overflow-hidden">
      <div class="absolute -right-8 -bottom-8 w-44 h-44 bg-white/10 rounded-full blur-2xl pointer-events-none"></div>
      
      <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 relative z-10">
        <div>
          <div class="flex items-center gap-3">
            <span class="text-xs uppercase font-extrabold tracking-widest text-white/80">Repair Job Card</span>
            <span class="bg-white/20 backdrop-blur-md px-2.5 py-0.5 rounded-full text-xs font-bold text-white uppercase">
              {{ getStatusLabel(repair.repair_status) }}
            </span>
          </div>
          <h2 class="text-3xl font-extrabold tracking-tight mt-1">
            {{ repair.job_number || ('#JOB-' + String(repair.id || '').padStart(6, '0')) }}
          </h2>
          <p class="text-sm text-white/90 font-medium mt-1">
            {{ getDeviceTitle(repair) }}
          </p>
        </div>

        <!-- Dates Grid -->
        <div class="grid grid-cols-2 sm:grid-cols-3 gap-3 bg-white/10 backdrop-blur-md p-3.5 rounded-2xl border border-white/20 text-xs">
          <div>
            <p class="text-white/70 font-medium flex items-center gap-1">
              <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
              Received
            </p>
            <p class="font-bold text-white mt-0.5">{{ formatDate(repair.date_received) }}</p>
          </div>
          <div>
            <p class="text-white/70 font-medium flex items-center gap-1">
              <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
              Expected
            </p>
            <p class="font-bold text-white mt-0.5">{{ repair.expected_delivery_date ? formatDate(repair.expected_delivery_date) : 'Not specified' }}</p>
          </div>
          <div v-if="repair.delivered_date" class="col-span-2 sm:col-span-1">
            <p class="text-white/70 font-medium flex items-center gap-1">
              <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
              Delivered
            </p>
            <p class="font-bold text-white mt-0.5">{{ formatDate(repair.delivered_date) }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Status Transition Bar (Direct Quick Change) -->
    <div class="bg-white dark:bg-slate-800 rounded-2xl p-4 border border-slate-200/80 dark:border-slate-700/80 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
      <div class="flex items-center gap-3">
        <div class="w-10 h-10 rounded-xl bg-indigo-50 dark:bg-indigo-950/40 text-indigo-600 dark:text-indigo-400 flex items-center justify-center font-bold">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/></svg>
        </div>
        <div>
          <span class="text-xs uppercase font-extrabold tracking-wider text-slate-400">Current Lifecycle Status</span>
          <div class="flex items-center gap-2 mt-0.5">
            <span :class="getStatusBadgeClass(repair.repair_status)" class="px-2.5 py-0.5 rounded-full text-xs font-extrabold uppercase">
              {{ getStatusLabel(repair.repair_status) }}
            </span>
            <span v-if="repair.repair_status === 'delivered'" class="text-xs text-emerald-600 font-semibold flex items-center gap-1">
              <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
              Finalized & Delivered
            </span>
          </div>
        </div>
      </div>

      <!-- Status Updater Controls -->
      <div v-if="repair.repair_status !== 'delivered'" class="flex flex-wrap items-center gap-2">
        <SearchableSelect
          v-model="targetStatus"
          :options="statusChangeOptions"
          placeholder="Select Status"
          searchPlaceholder="Search status..."
          minWidth="180px"
        />

        <input
          v-model="statusNotes"
          type="text"
          placeholder="Status change notes (optional)..."
          class="px-3.5 py-2 text-xs rounded-xl bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-100 placeholder-slate-400 w-48 sm:w-60 focus:ring-2 focus:ring-indigo-500"
        />

        <button
          @click="attemptStatusChange"
          :disabled="statusUpdating || targetStatus === repair.repair_status"
          class="px-4 py-2 text-xs font-bold rounded-xl bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white shadow-sm transition"
        >
          {{ statusUpdating ? 'Updating...' : 'Update Status' }}
        </button>

        <button
          v-if="amountDue > 0"
          @click="openCollectPaymentModal"
          class="px-4 py-2 text-xs font-bold rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white shadow-sm transition"
        >
          + Collect Payment
        </button>
      </div>

      <!-- Closed & Finalized Indicator when Delivered -->
      <div v-else class="flex items-center gap-2 px-3.5 py-2 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800/80 text-xs">
        <span class="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse"></span>
        <span class="font-extrabold text-emerald-900 dark:text-emerald-200">Delivered & Finalized</span>
        <span class="text-emerald-700 dark:text-emerald-400">Lifecycle closed. Details are frozen in read-only mode.</span>
      </div>
    </div>

    <!-- Active Warranty Banner / Quick Add Warranty -->
    <div
      v-if="repair.warranty"
      class="bg-gradient-to-r from-emerald-50 to-teal-50 dark:from-emerald-950/30 dark:to-teal-950/30 rounded-2xl p-4 border border-emerald-200 dark:border-emerald-800/50 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
    >
      <div class="flex items-center gap-3">
        <div class="w-10 h-10 rounded-xl bg-emerald-600 text-white flex items-center justify-center font-bold shadow-md shadow-emerald-500/20">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/></svg>
        </div>
        <div>
          <div class="flex items-center gap-2">
            <span class="text-xs font-bold uppercase tracking-wider text-emerald-700 dark:text-emerald-400">Warranty Active</span>
            <span class="px-2 py-0.5 rounded-full text-[10px] font-extrabold bg-emerald-600 text-white">
              {{ repair.warranty.warranty_number || 'WAR-ACTIVE' }}
            </span>
          </div>
          <p class="text-xs text-slate-600 dark:text-slate-300 mt-0.5">
            Valid until <strong>{{ formatDate(repair.warranty.warranty_end_date) }}</strong>
            <span v-if="repair.warranty.days_remaining !== undefined" class="text-emerald-700 dark:text-emerald-400 font-semibold ml-1">
              ({{ repair.warranty.days_remaining }} days left)
            </span>
          </p>
        </div>
      </div>
      <router-link
        to="/warranties"
        class="text-xs font-bold text-emerald-700 dark:text-emerald-400 hover:underline flex items-center gap-1"
      >
        View Warranty Hub
        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
      </router-link>
    </div>

    <!-- If No Warranty: Offer Quick Add Warranty -->
    <div
      v-else-if="repair.repair_status === 'delivered' || repair.repair_status === 'ready'"
      class="bg-white dark:bg-slate-800 rounded-2xl p-4 border border-slate-200 dark:border-slate-700 flex flex-col sm:flex-row sm:items-center justify-between gap-3 shadow-sm"
    >
      <div class="flex items-center gap-3">
        <div class="w-10 h-10 rounded-xl bg-slate-100 dark:bg-slate-700 text-slate-500 flex items-center justify-center">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/></svg>
        </div>
        <div>
          <h4 class="text-xs font-bold uppercase tracking-wider text-slate-700 dark:text-slate-300">Device Repair Warranty</h4>
          <p class="text-xs text-slate-500">Protect this repair with an official shop warranty certificate.</p>
        </div>
      </div>
      <button
        @click="showAddWarrantyModal = true"
        class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-bold rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white shadow-sm transition"
      >
        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
        + Add Warranty
      </button>
    </div>

    <!-- Main Detail Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Left Column: Customer & Device & Technician Info (2 cols) -->
      <div class="lg:col-span-2 space-y-6">
        <!-- 1. Customer Information Card -->
        <div class="bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200/80 dark:border-slate-700/80 shadow-sm">
          <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3 mb-4">
            <div class="flex items-center gap-2">
              <div class="w-8 h-8 rounded-lg bg-indigo-50 dark:bg-indigo-950/40 text-indigo-600 dark:text-indigo-400 flex items-center justify-center font-bold">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
              </div>
              <h3 class="font-bold text-slate-900 dark:text-white text-sm">Customer Information</h3>
            </div>
            <span v-if="repair.customer_id" class="text-xs font-semibold text-slate-400">
              Customer #{{ repair.customer_id }}
            </span>
          </div>

          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div class="space-y-1">
              <h4 class="text-base font-bold text-slate-900 dark:text-white">
                {{ repair.customer?.name || repair.customer_name || 'Walk-in Customer' }}
              </h4>
              <div class="flex flex-wrap items-center gap-3 text-xs text-slate-500 dark:text-slate-400">
                <span class="flex items-center gap-1 font-mono">
                  📞 {{ repair.customer?.mobile || repair.customer?.phone || repair.customer_phone || 'No phone' }}
                </span>
                <span v-if="repair.customer?.city" class="flex items-center gap-1">
                  📍 {{ repair.customer.city }}
                </span>
                <span v-if="repair.customer?.email" class="flex items-center gap-1">
                  ✉️ {{ repair.customer.email }}
                </span>
              </div>
            </div>

            <!-- Customer Direct Actions -->
            <div class="flex items-center gap-2">
              <a
                v-if="getCustomerMobile(repair)"
                :href="`https://wa.me/${formatPhoneForWhatsApp(getCustomerMobile(repair))}`"
                target="_blank"
                class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-emerald-50 dark:bg-emerald-950/30 text-emerald-700 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-800 text-xs font-bold hover:bg-emerald-100 transition"
              >
                <WhatsAppIcon sizeClass="w-3.5 h-3.5" />
                <span>Chat</span>
              </a>
              <a
                v-if="getCustomerMobile(repair)"
                :href="`tel:${getCustomerMobile(repair)}`"
                class="inline-flex items-center gap-1 px-3 py-1.5 rounded-xl bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-200 text-xs font-semibold hover:bg-slate-200 transition"
              >
                Call
              </a>
            </div>
          </div>
        </div>

        <!-- 2. Device Details Card & Passcode Reveal -->
        <div class="bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200/80 dark:border-slate-700/80 shadow-sm">
          <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3 mb-4">
            <div class="flex items-center gap-2">
              <div class="w-8 h-8 rounded-lg bg-purple-50 dark:bg-purple-950/40 text-purple-600 dark:text-purple-400 flex items-center justify-center font-bold">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"/></svg>
              </div>
              <h3 class="font-bold text-slate-900 dark:text-white text-sm">Device & Security Details</h3>
            </div>
            <span class="text-xs text-slate-400">ID #{{ repair.device_id || repair.device?.id || '-' }}</span>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-3 bg-slate-50 dark:bg-slate-900/50 rounded-xl">
              <p class="text-xs text-slate-400 font-semibold uppercase">Brand & Model</p>
              <p class="text-base font-bold text-slate-900 dark:text-white mt-0.5">
                {{ getDeviceTitle(repair) }}
              </p>
            </div>

            <div class="p-3 bg-slate-50 dark:bg-slate-900/50 rounded-xl">
              <p class="text-xs text-slate-400 font-semibold uppercase">IMEI / Serial</p>
              <div class="flex items-center justify-between mt-0.5">
                <p class="text-xs font-mono font-bold text-slate-800 dark:text-slate-200">
                  {{ repair.device?.imei1 || repair.imei || 'Not recorded' }}
                </p>
                <button
                  v-if="repair.device?.imei1 || repair.imei"
                  @click="copyText(repair.device?.imei1 || repair.imei)"
                  class="text-[10px] font-bold text-indigo-600 hover:underline"
                >
                  Copy
                </button>
              </div>
              <p v-if="repair.device?.imei2" class="text-[11px] font-mono text-slate-500 mt-1">
                IMEI 2: {{ repair.device.imei2 }}
              </p>
            </div>
          </div>

          <!-- Pattern Lock / PIN Security Box -->
          <div class="mt-4 p-4 rounded-xl border border-amber-200 dark:border-amber-800/60 bg-amber-50/70 dark:bg-amber-950/20">
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2">
                <svg class="w-4 h-4 text-amber-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/></svg>
                <span class="text-xs font-bold text-amber-900 dark:text-amber-200">
                  {{ isPatternLock(repair.pin_passcode) ? 'Device Pattern Lock' : 'Device PIN / Passcode' }}
                </span>
              </div>
              <button
                @click="obscurePasscode = !obscurePasscode"
                class="px-2.5 py-1 text-[11px] font-bold rounded-lg bg-white dark:bg-slate-800 border border-amber-300 dark:border-amber-700 text-amber-900 dark:text-amber-200 shadow-sm"
              >
                {{ obscurePasscode ? 'Show Security' : 'Hide' }}
              </button>
            </div>

            <!-- Pattern / PIN Content -->
            <div class="mt-3">
              <div v-if="!repair.pin_passcode" class="text-xs text-amber-700 dark:text-amber-300 italic">
                No screen lock or passcode recorded.
              </div>

              <!-- Obscured State -->
              <div v-else-if="obscurePasscode" class="text-xs font-mono font-bold tracking-widest text-amber-800 dark:text-amber-300">
                •••••••• (Protected)
              </div>

              <!-- Pattern Lock Graphical Representation -->
              <div v-else-if="isPatternLock(repair.pin_passcode)" class="space-y-3">
                <div class="flex flex-col sm:flex-row sm:items-center gap-6">
                  <!-- Visual 3x3 pattern SVG with connecting lines -->
                  <div class="w-36 h-36 bg-white dark:bg-slate-900 rounded-2xl p-2 border border-amber-300 dark:border-amber-700/80 shadow-xs flex items-center justify-center shrink-0">
                    <svg viewBox="0 0 160 160" class="w-32 h-32">
                      <!-- Connecting lines between pattern nodes -->
                      <polyline
                        :points="getSvgPolylinePoints(repair.pin_passcode)"
                        fill="none"
                        stroke="#d97706"
                        stroke-width="3.5"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                      />
                      <!-- 9 Pattern Grid Nodes -->
                      <g v-for="idx in 9" :key="idx">
                        <circle
                          :cx="getDotX(idx)"
                          :cy="getDotY(idx)"
                          :r="getPatternStep(idx, repair.pin_passcode) ? 14 : 7"
                          :class="getPatternStep(idx, repair.pin_passcode) ? 'fill-amber-600 stroke-2 stroke-amber-200 dark:stroke-amber-800' : 'fill-slate-300 dark:fill-slate-600'"
                        />
                        <text
                          v-if="getPatternStep(idx, repair.pin_passcode)"
                          :x="getDotX(idx)"
                          :y="getDotY(idx) + 4"
                          text-anchor="middle"
                          class="fill-white font-bold text-[11px] pointer-events-none select-none"
                        >
                          {{ getPatternStep(idx, repair.pin_passcode) }}
                        </text>
                        <text
                          v-else
                          :x="getDotX(idx)"
                          :y="getDotY(idx) + 3"
                          text-anchor="middle"
                          class="fill-slate-400 dark:fill-slate-500 font-semibold text-[9px] pointer-events-none select-none"
                        >
                          {{ idx }}
                        </text>
                      </g>
                    </svg>
                  </div>

                  <div class="space-y-1.5">
                    <p class="text-xs font-semibold text-amber-900 dark:text-amber-200 flex items-center gap-1.5">
                      <span class="w-2 h-2 rounded-full bg-amber-600"></span>
                      Connect in Sequence:
                    </p>
                    <div class="inline-flex items-center gap-2 p-2 bg-white dark:bg-slate-900 rounded-xl border border-amber-200 dark:border-amber-800">
                      <p class="text-xs font-mono font-bold text-amber-900 dark:text-amber-300">
                        {{ formatPatternSequence(repair.pin_passcode) }}
                      </p>
                      <button
                        type="button"
                        @click="copyText(formatPatternSequence(repair.pin_passcode))"
                        class="px-2 py-0.5 text-[10px] font-bold rounded-lg bg-amber-50 dark:bg-amber-950/40 text-amber-800 dark:text-amber-300 border border-amber-300 dark:border-amber-700 hover:bg-amber-100 cursor-pointer"
                      >
                        Copy
                      </button>
                    </div>
                    <p class="text-[11px] text-amber-700 dark:text-amber-400">
                      Numbers represent dots 1 to 9 (top-left to bottom-right).
                    </p>
                  </div>
                </div>
              </div>

              <!-- PIN Display -->
              <div v-else class="flex items-center gap-3">
                <span class="font-mono text-lg font-bold text-amber-900 dark:text-amber-200 bg-white dark:bg-slate-900 px-3 py-1 rounded-lg border border-amber-300 dark:border-amber-700">
                  {{ repair.pin_passcode }}
                </span>
                <button
                  @click="copyText(repair.pin_passcode)"
                  class="px-2.5 py-1 text-xs font-semibold text-amber-800 dark:text-amber-300 hover:underline"
                >
                  Copy PIN
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- 3. Assigned Technician Card -->
        <div class="bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200/80 dark:border-slate-700/80 shadow-sm flex items-center justify-between">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-xl bg-blue-50 dark:bg-blue-950/40 text-blue-600 dark:text-blue-400 flex items-center justify-center font-bold">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37.996.608 2.296.07 2.572-1.065z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
            </div>
            <div>
              <p class="text-xs text-slate-400 font-semibold uppercase">Assigned Technician</p>
              <h4 class="text-base font-bold text-slate-900 dark:text-white mt-0.5">
                {{ repair.technician_name || repair.technician?.name || 'Unassigned' }}
              </h4>
              <p class="text-xs text-slate-500">
                Labour / Tech Fee: <strong class="text-slate-800 dark:text-slate-200">₹{{ formatAmount(repair.technician_earning || repair.labour_cost || 0) }}</strong>
              </p>
            </div>
          </div>
          <div class="flex items-center gap-2">
            <button
              v-if="repair.repair_status !== 'delivered'"
              type="button"
              @click="openReassignTechModal"
              class="px-2.5 py-1 text-xs font-bold rounded-xl border border-blue-200 dark:border-blue-800 text-blue-600 dark:text-blue-400 hover:bg-blue-50 dark:hover:bg-blue-950/40 cursor-pointer transition hover:scale-105"
            >
              Change Tech
            </button>
            <div class="px-3 py-1 rounded-xl bg-blue-50 dark:bg-blue-950/40 text-blue-700 dark:text-blue-300 font-bold text-xs border border-blue-200 dark:border-blue-800">
              ₹{{ formatAmount(repair.technician_earning || repair.labour_cost || 0) }}
            </div>
          </div>
        </div>

        <!-- 4. Problem & Intake Condition Checklist -->
        <div class="bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200/80 dark:border-slate-700/80 shadow-sm space-y-4">
          <div class="border-b border-slate-100 dark:border-slate-700 pb-3 flex items-center justify-between">
            <h3 class="font-bold text-slate-900 dark:text-white text-sm">Fault & Intake Checklist</h3>
            <span class="text-xs text-slate-400">Diagnosis Details</span>
          </div>

          <!-- Problem Description -->
          <div>
            <p class="text-xs text-slate-400 font-semibold uppercase">Reported Problem</p>
            <div class="mt-1 p-3.5 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-100 dark:border-slate-700 text-sm font-medium text-slate-800 dark:text-slate-200">
              {{ repair.problem_description || 'No specific fault description entered.' }}
            </div>
          </div>

          <!-- Device Conditions -->
          <div v-if="parseChecklist(repair.device_condition).length > 0">
            <p class="text-xs text-slate-400 font-semibold uppercase mb-2">Device Physical Condition</p>
            <div class="flex flex-wrap gap-1.5">
              <span
                v-for="cond in parseChecklist(repair.device_condition)"
                :key="cond"
                class="px-2.5 py-1 rounded-lg text-xs font-semibold bg-rose-50 dark:bg-rose-950/30 text-rose-700 dark:text-rose-300 border border-rose-200 dark:border-rose-800"
              >
                ⚠️ {{ cond }}
              </span>
            </div>
            <p v-if="repair.condition_notes" class="text-xs text-slate-500 mt-2 italic">
              Note: {{ repair.condition_notes }}
            </p>
          </div>

          <!-- Accessories Received -->
          <div v-if="parseChecklist(repair.accessories_received).length > 0">
            <p class="text-xs text-slate-400 font-semibold uppercase mb-2">Accessories Received</p>
            <div class="flex flex-wrap gap-1.5">
              <span
                v-for="acc in parseChecklist(repair.accessories_received)"
                :key="acc"
                class="px-2.5 py-1 rounded-lg text-xs font-semibold bg-emerald-50 dark:bg-emerald-950/30 text-emerald-700 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800"
              >
                📦 {{ acc }}
              </span>
            </div>
            <p v-if="repair.accessories_notes" class="text-xs text-slate-500 mt-2 italic">
              Note: {{ repair.accessories_notes }}
            </p>
          </div>

          <!-- Customer / Internal Notes -->
          <div v-if="repair.customer_notes || repair.internal_notes" class="grid grid-cols-1 md:grid-cols-2 gap-3 pt-2">
            <div v-if="repair.customer_notes" class="p-3 bg-slate-50 dark:bg-slate-900 rounded-xl text-xs">
              <p class="text-slate-400 font-bold uppercase mb-1">Customer Notes</p>
              <p class="text-slate-700 dark:text-slate-300">{{ repair.customer_notes }}</p>
            </div>
            <div v-if="repair.internal_notes" class="p-3 bg-slate-50 dark:bg-slate-900 rounded-xl text-xs">
              <p class="text-slate-400 font-bold uppercase mb-1">Internal Shop Notes</p>
              <p class="text-slate-700 dark:text-slate-300">{{ repair.internal_notes }}</p>
            </div>
          </div>
        </div>

        <!-- 4b. Device Intake Photo (If Present) -->
        <div v-if="repair.device_photo" class="bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200/80 dark:border-slate-700/80 shadow-sm space-y-3">
          <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3">
            <div class="flex items-center gap-2">
              <div class="w-8 h-8 rounded-lg bg-sky-50 dark:bg-sky-950/40 text-sky-600 dark:text-sky-400 flex items-center justify-center font-bold">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
              </div>
              <h3 class="font-bold text-slate-900 dark:text-white text-sm">Device Intake Photo</h3>
            </div>
            <a
              :href="repair.device_photo"
              target="_blank"
              class="text-xs font-bold text-sky-600 dark:text-sky-400 hover:underline flex items-center gap-1 cursor-pointer"
            >
              Open Full Image
              <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"/></svg>
            </a>
          </div>
          <div class="overflow-hidden rounded-2xl border border-slate-200 dark:border-slate-700 bg-slate-900/5 max-h-80 flex items-center justify-center">
            <img
              :src="repair.device_photo"
              alt="Device Intake Photo"
              class="w-full h-auto max-h-80 object-contain rounded-2xl"
            />
          </div>
        </div>

        <!-- 5. Spare Parts Used (Identical to Mobile App) -->
        <div class="bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200/80 dark:border-slate-700/80 shadow-sm space-y-4">
          <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3">
            <div class="flex items-center gap-2">
              <div class="w-8 h-8 rounded-lg bg-amber-50 dark:bg-amber-950/40 text-amber-600 dark:text-amber-400 flex items-center justify-center font-bold">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/></svg>
              </div>
              <h3 class="font-bold text-slate-900 dark:text-white text-sm">Spare Parts Used</h3>
              <span class="px-2 py-0.5 rounded-full text-[10px] font-extrabold bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300">
                {{ (repair.parts || []).length }}
              </span>
            </div>

            <button
              v-if="repair.repair_status !== 'delivered'"
              @click="showAddPartModal = true"
              class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-bold rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white shadow-sm transition"
            >
              <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
              + Add Part
            </button>
          </div>

          <!-- Empty State -->
          <div v-if="!repair.parts || repair.parts.length === 0" class="text-center py-8 text-slate-400 text-xs">
            <svg class="w-8 h-8 mx-auto mb-2 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/></svg>
            No spare parts logged for this repair yet.
          </div>

          <!-- Parts Table -->
          <div v-else class="overflow-x-auto">
            <table class="w-full text-xs">
              <thead>
                <tr class="text-slate-400 uppercase font-semibold border-b border-slate-100 dark:border-slate-700 text-left">
                  <th class="py-2">Part Name</th>
                  <th class="py-2 text-center">Qty</th>
                  <th class="py-2 text-right">Selling Price</th>
                  <th class="py-2 text-right">Subtotal</th>
                  <th v-if="repair.repair_status !== 'delivered'" class="py-2 text-right">Action</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 dark:divide-slate-700/60 font-medium">
                <tr v-for="part in repair.parts" :key="part.id">
                  <td class="py-2.5 text-slate-800 dark:text-slate-200">
                    {{ part.part_name }}
                    <span v-if="part.part_number" class="text-[10px] text-slate-400 block font-mono">#{{ part.part_number }}</span>
                  </td>
                  <td class="py-2.5 text-center text-slate-600 dark:text-slate-400">{{ part.quantity }}</td>
                  <td class="py-2.5 text-right text-slate-700 dark:text-slate-300">₹{{ formatAmount(part.selling_price) }}</td>
                  <td class="py-2.5 text-right font-bold text-slate-900 dark:text-white">
                    ₹{{ formatAmount(part.quantity * part.selling_price) }}
                  </td>
                  <td v-if="repair.repair_status !== 'delivered'" class="py-2.5 text-right">
                    <button
                      @click="removePart(part)"
                      class="text-rose-500 hover:text-rose-700 p-1 rounded hover:bg-rose-50"
                      title="Remove Part"
                    >
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Right Column: Financials & Payments (1 col) -->
      <div class="space-y-6">
        <!-- 6. Financial Breakdown & Profit Card -->
        <div class="bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200/80 dark:border-slate-700/80 shadow-sm space-y-4">
          <div class="border-b border-slate-100 dark:border-slate-700 pb-3 flex items-center justify-between">
            <h3 class="font-bold text-slate-900 dark:text-white text-sm">Financial Breakdown</h3>
            <span class="text-xs text-slate-400">Ledger</span>
          </div>

          <div class="space-y-2.5 text-xs">
            <div class="flex justify-between text-slate-500">
              <span>Estimated Cost:</span>
              <span class="font-semibold text-slate-800 dark:text-slate-200">₹{{ formatAmount(repair.estimated_cost) }}</span>
            </div>
            <div v-if="partsSubtotal > 0" class="flex justify-between text-slate-500">
              <span>Spare Parts Cost:</span>
              <span class="font-semibold text-slate-800 dark:text-slate-200">₹{{ formatAmount(partsSubtotal) }}</span>
            </div>
            <div v-if="repair.labour_cost || repair.technician_earning" class="flex justify-between text-slate-500">
              <span>Technician Fee:</span>
              <span class="font-semibold text-slate-800 dark:text-slate-200">₹{{ formatAmount(repair.technician_earning || repair.labour_cost) }}</span>
            </div>

            <!-- Total Net Bill -->
            <div class="flex justify-between items-center text-sm font-extrabold text-slate-900 dark:text-white pt-2 border-t border-slate-100 dark:border-slate-700">
              <span>TOTAL NET BILL:</span>
              <span class="text-base text-indigo-600 dark:text-indigo-400">₹{{ formatAmount(totalBill) }}</span>
            </div>

            <!-- Net Profit (Owner View) -->
            <div v-if="repair.net_profit !== undefined" class="flex justify-between items-center text-xs text-slate-500 pt-1">
              <span class="flex items-center gap-1">
                Net Profit:
                <button @click="showProfit = !showProfit" class="text-slate-400 hover:text-slate-600">
                  <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                </button>
              </span>
              <span :class="[showProfit ? (repair.net_profit >= 0 ? 'text-emerald-600 font-bold' : 'text-rose-600 font-bold') : 'font-mono text-slate-400']">
                {{ showProfit ? '₹' + formatAmount(repair.net_profit) : '••••' }}
              </span>
            </div>

            <!-- Advance / Total Paid -->
            <div class="flex justify-between text-emerald-600 font-semibold pt-1">
              <span>Total Paid / Advance:</span>
              <span>₹{{ formatAmount(totalPaid) }}</span>
            </div>

            <!-- Balance Due Callout -->
            <div
              :class="amountDue > 0 ? 'bg-red-50 dark:bg-red-950/40 border-red-200 dark:border-red-800 text-red-700 dark:text-red-300' : 'bg-emerald-50 dark:bg-emerald-950/40 border-emerald-200 dark:border-emerald-800 text-emerald-700 dark:text-emerald-300'"
              class="p-3.5 rounded-xl border mt-3 flex items-center justify-between"
            >
              <div>
                <p class="text-[10px] uppercase font-extrabold tracking-wider opacity-80">
                  {{ amountDue > 0 ? 'Remaining Balance Due' : 'Payment Status' }}
                </p>
                <p class="text-lg font-extrabold mt-0.5">
                  {{ amountDue > 0 ? '₹' + formatAmount(amountDue) : 'Fully Settled' }}
                </p>
              </div>

              <button
                v-if="amountDue > 0 && repair.repair_status !== 'delivered'"
                @click="openCollectPaymentModal"
                class="px-3 py-1.5 rounded-lg bg-red-600 text-white text-xs font-bold hover:bg-red-700 shadow-sm"
              >
                Pay Now
              </button>
            </div>
          </div>
        </div>

        <!-- 7. Payment History Card -->
        <div class="bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200/80 dark:border-slate-700/80 shadow-sm space-y-4">
          <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3">
            <div class="flex items-center gap-2">
              <div class="w-8 h-8 rounded-lg bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 flex items-center justify-center font-bold">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
              </div>
              <h3 class="font-bold text-slate-900 dark:text-white text-sm">Payment History</h3>
            </div>
            <span class="text-xs text-slate-400 font-semibold">{{ (repair.payments || []).length }} entries</span>
          </div>

          <div v-if="!repair.payments || repair.payments.length === 0" class="text-center py-6 text-slate-400 text-xs">
            No payments recorded yet.
          </div>

          <div v-else class="space-y-2.5">
            <div
              v-for="pmt in repair.payments"
              :key="pmt.id"
              class="p-3 bg-slate-50 dark:bg-slate-900/60 rounded-xl flex items-center justify-between text-xs"
            >
              <div>
                <div class="flex items-center gap-2">
                  <span class="font-bold text-emerald-600">₹{{ formatAmount(pmt.amount) }}</span>
                  <span class="px-1.5 py-0.5 rounded text-[10px] uppercase font-bold bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300">
                    {{ pmt.payment_method || 'CASH' }}
                  </span>
                </div>
                <p class="text-[11px] text-slate-400 mt-0.5">
                  {{ formatDate(pmt.payment_date || pmt.created_at) }}
                  <span v-if="pmt.notes" class="ml-1">• {{ pmt.notes }}</span>
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ───────────────────────────────────────────────────────────── -->
    <!-- MODALS & DIALOGS -->
    <!-- ───────────────────────────────────────────────────────────── -->

    <!-- 1. Collect Payment Modal -->
    <div v-if="showPaymentModal" class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-5 bg-black/60 backdrop-blur-sm animate-fade-in" @wheel.stop>
      <div class="bg-white dark:bg-slate-800 rounded-3xl max-w-md w-full p-6 shadow-2xl border border-slate-200 dark:border-slate-700 space-y-4 max-h-[85vh] flex flex-col overflow-hidden">
        <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center font-bold">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/></svg>
            </div>
            <h3 class="font-bold text-slate-900 dark:text-white text-base">Collect Payment</h3>
          </div>
          <button @click="showPaymentModal = false" class="text-slate-400 hover:text-slate-600">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
          </button>
        </div>

        <form @submit.prevent="submitCollectPayment" class="space-y-4 text-xs">
          <div>
            <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">
              Payment Amount (₹) <span class="text-rose-500">*</span>
            </label>
            <input
              v-model.number="paymentForm.amount"
              type="number"
              step="0.01"
              min="0.01"
              :max="amountDue"
              required
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-sm font-bold text-slate-900 dark:text-white focus:ring-2 focus:ring-emerald-500"
            />
            <p class="text-[11px] text-slate-400 mt-1">Remaining Balance: ₹{{ formatAmount(amountDue) }}</p>
          </div>

          <div>
            <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">Payment Method</label>
            <SearchableSelect
              v-model="paymentForm.payment_method"
              :options="repairPaymentOptions"
              placeholder="Select Method"
              minWidth="100%"
            />
          </div>

          <div>
            <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">Notes / Transaction Ref</label>
            <input
              v-model="paymentForm.notes"
              type="text"
              placeholder="e.g. GPay ref #123456"
              class="w-full px-3.5 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs"
            />
          </div>

          <div class="flex items-center justify-end gap-2 pt-2">
            <button
              type="button"
              @click="showPaymentModal = false"
              class="px-4 py-2 rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-50 font-semibold"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="paymentSubmitting"
              class="px-5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-white font-bold shadow-md shadow-emerald-500/20"
            >
              {{ paymentSubmitting ? 'Recording...' : 'Save Payment' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- 2. Add Part Modal -->
    <div v-if="showAddPartModal" class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-5 bg-black/60 backdrop-blur-sm animate-fade-in" @wheel.stop>
      <div class="bg-white dark:bg-slate-800 rounded-3xl max-w-md w-full p-6 shadow-2xl border border-slate-200 dark:border-slate-700 space-y-4 max-h-[85vh] flex flex-col overflow-hidden">
        <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center font-bold">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
            </div>
            <h3 class="font-bold text-slate-900 dark:text-white text-base">Add Spare Part</h3>
          </div>
          <button @click="showAddPartModal = false" class="text-slate-400 hover:text-slate-600">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
          </button>
        </div>

        <form @submit.prevent="submitAddPart" class="space-y-4 text-xs">
          <div>
            <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">
              Part Name <span class="text-rose-500">*</span>
            </label>
            <input
              v-model="partForm.part_name"
              type="text"
              placeholder="e.g. Display Combo, Battery, Charging Ribbon"
              required
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-semibold focus:ring-2 focus:ring-indigo-500"
            />
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">Quantity</label>
              <input
                v-model.number="partForm.quantity"
                type="number"
                min="1"
                required
                class="w-full px-3.5 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-semibold"
              />
            </div>
            <div>
              <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">Selling Price (₹)</label>
              <input
                v-model.number="partForm.selling_price"
                type="number"
                step="0.01"
                min="0"
                required
                class="w-full px-3.5 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-bold text-slate-900 dark:text-white"
              />
            </div>
          </div>

          <div>
            <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">Cost Price (₹) (Shop cost)</label>
            <input
              v-model.number="partForm.cost_price"
              type="number"
              step="0.01"
              min="0"
              class="w-full px-3.5 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs"
            />
          </div>

          <div>
            <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">Notes</label>
            <input
              v-model="partForm.notes"
              type="text"
              placeholder="Warranty details or supplier name"
              class="w-full px-3.5 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs"
            />
          </div>

          <div class="flex items-center justify-end gap-2 pt-2">
            <button
              type="button"
              @click="showAddPartModal = false"
              class="px-4 py-2 rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-50 font-semibold"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="partSubmitting"
              class="px-5 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white font-bold shadow-md shadow-indigo-500/20"
            >
              {{ partSubmitting ? 'Adding...' : 'Add Part' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- 3. Add Warranty Modal -->
    <div v-if="showAddWarrantyModal" class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-5 bg-black/60 backdrop-blur-sm animate-fade-in" @wheel.stop>
      <div class="bg-white dark:bg-slate-800 rounded-3xl max-w-md w-full p-6 shadow-2xl border border-slate-200 dark:border-slate-700 space-y-4 max-h-[85vh] flex flex-col overflow-hidden">
        <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center font-bold">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/></svg>
            </div>
            <h3 class="font-bold text-slate-900 dark:text-white text-base">Add Repair Warranty</h3>
          </div>
          <button @click="showAddWarrantyModal = false" class="text-slate-400 hover:text-slate-600">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
          </button>
        </div>

        <form @submit.prevent="submitAddWarranty" class="space-y-4 text-xs">
          <div>
            <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">Warranty Duration</label>
            <div class="grid grid-cols-4 gap-2">
              <button
                type="button"
                v-for="d in [30, 90, 180, 365]"
                :key="d"
                @click="warrantyForm.duration_days = d"
                :class="[
                  'py-2 rounded-xl text-xs font-bold border transition',
                  warrantyForm.duration_days === d
                    ? 'bg-emerald-600 text-white border-emerald-600 shadow-sm'
                    : 'bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-300'
                ]"
              >
                {{ d < 365 ? d + ' Days' : '1 Year' }}
              </button>
            </div>
          </div>

          <div>
            <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">Warranty Terms & Conditions</label>
            <textarea
              v-model="warrantyForm.warranty_terms"
              rows="3"
              class="w-full px-3.5 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs"
              placeholder="e.g. Covers touch failure only. Physical and liquid damage not covered."
            ></textarea>
          </div>

          <div class="flex items-center justify-end gap-2 pt-2">
            <button
              type="button"
              @click="showAddWarrantyModal = false"
              class="px-4 py-2 rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-50 font-semibold"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="warrantySubmitting"
              class="px-5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-white font-bold shadow-md shadow-emerald-500/20"
            >
              {{ warrantySubmitting ? 'Creating...' : 'Activate Warranty' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- 4. Delivery Blocked Warning Modal (Amount Due > 0) -->
    <div v-if="showDeliveryWarningModal" class="fixed inset-0 z-50 overflow-y-auto flex min-h-full items-center justify-center p-4 py-6 sm:py-10 bg-black/60 backdrop-blur-sm animate-fade-in" @wheel.stop>
      <div class="bg-white dark:bg-slate-800 rounded-3xl max-w-md w-full p-6 shadow-2xl border border-red-200 dark:border-red-900/60 space-y-4">
        <div class="flex items-center gap-3">
          <div class="w-10 h-10 rounded-2xl bg-red-100 dark:bg-red-950/60 text-red-600 flex items-center justify-center">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
          </div>
          <div>
            <h3 class="font-bold text-red-600 dark:text-red-400 text-lg">Payment Due - Cannot Deliver</h3>
            <p class="text-xs text-slate-500">Unsettled Job Card Balance</p>
          </div>
        </div>

        <div class="p-3.5 bg-red-50 dark:bg-red-950/30 rounded-2xl border border-red-200 dark:border-red-800 text-xs text-red-800 dark:text-red-200 space-y-1">
          <p class="font-bold">⚠️ Remaining Balance Due: ₹{{ formatAmount(amountDue) }}</p>
          <p>Delivery is blocked until full payment is collected. Please collect the pending amount first!</p>
        </div>

        <div class="flex flex-col gap-2 pt-2">
          <button
            @click="resolveDeliveryViaPayment"
            class="w-full py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs shadow-md shadow-emerald-500/20"
          >
            Collect Payment (₹{{ formatAmount(amountDue) }})
          </button>
          <button
            @click="showDeliveryWarningModal = false"
            class="w-full py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 font-semibold text-xs hover:bg-slate-50"
          >
            Cancel Delivery
          </button>
        </div>
      </div>
    </div>

    <!-- 5. WhatsApp Message Modal -->
    <div v-if="showWhatsAppModal" class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-5 bg-black/60 backdrop-blur-sm animate-fade-in" @wheel.stop>
      <div class="bg-white dark:bg-slate-800 rounded-3xl max-w-lg w-full p-6 shadow-2xl border border-slate-200 dark:border-slate-700 space-y-4 max-h-[85vh] flex flex-col overflow-hidden">
        <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-lg bg-emerald-500 text-white flex items-center justify-center font-bold">
              <WhatsAppIcon sizeClass="w-4 h-4 text-white" />
            </div>
            <h3 class="font-bold text-slate-900 dark:text-white text-base">Send WhatsApp Ticket Update</h3>
          </div>
          <button @click="showWhatsAppModal = false" class="text-slate-400 hover:text-slate-600">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
          </button>
        </div>

        <div class="space-y-3 text-xs">
          <div>
            <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">Customer Mobile</label>
            <input
              :value="getCustomerMobile(repair)"
              readonly
              class="w-full px-3 py-2 rounded-xl bg-slate-100 dark:bg-slate-900 font-mono text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700"
            />
          </div>

          <div>
            <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">Message Preview</label>
            <textarea
              v-model="whatsAppMessageText"
              rows="6"
              class="w-full p-3 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 font-mono text-xs leading-relaxed"
            ></textarea>
          </div>

          <div class="flex items-center justify-end gap-2 pt-2">
            <button
              @click="showWhatsAppModal = false"
              class="px-4 py-2 rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-50 font-semibold"
            >
              Cancel
            </button>
            <button
              @click="sendWhatsAppMessage"
              class="px-5 py-2 rounded-xl bg-[#25D366] hover:bg-[#20ba5a] text-white font-bold shadow-md shadow-green-500/20 flex items-center gap-1.5 cursor-pointer"
            >
              <WhatsAppIcon sizeClass="w-4 h-4 text-white" />
              <span>Open in WhatsApp</span>
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- 6. Print Job Card Modal (Thermal Slip / Standard Invoice) -->
    <div v-if="showPrintModal" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-fade-in">
      <div class="bg-white dark:bg-slate-800 rounded-3xl max-w-2xl w-full p-6 shadow-2xl border border-slate-200 dark:border-slate-700 flex flex-col max-h-[90vh]">
        <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3">
          <div class="flex items-center gap-2">
            <h3 class="font-bold text-slate-900 dark:text-white text-base">Print Job Card / Receipt</h3>
            <span class="text-xs font-mono text-slate-400">#{{ repair.job_number }}</span>
          </div>
          <button @click="showPrintModal = false" class="text-slate-400 hover:text-slate-600">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
          </button>
        </div>

        <!-- Printable Document Container -->
        <div class="overflow-y-auto py-4 flex justify-center">
          <div id="printable-job-card" class="bg-white text-slate-900 p-6 rounded-xl border border-slate-200 w-full max-w-md shadow-sm font-mono text-xs">
            <!-- Header -->
            <div class="text-center border-b border-dashed border-slate-300 pb-3 mb-3">
              <h2 class="text-base font-extrabold uppercase tracking-wider">MYREPAIRHUB</h2>
              <p class="text-[11px] text-slate-500">Smart Mobile Service Center</p>
              <p class="text-[10px] text-slate-400 mt-1">JOB CARD / REPAIR ESTIMATE</p>
            </div>

            <!-- Job Info -->
            <div class="space-y-1 border-b border-dashed border-slate-300 pb-3 mb-3">
              <div class="flex justify-between">
                <span>Job Number:</span>
                <span class="font-bold">{{ repair.job_number }}</span>
              </div>
              <div class="flex justify-between">
                <span>Date:</span>
                <span>{{ formatDate(repair.date_received) }}</span>
              </div>
              <div class="flex justify-between">
                <span>Customer:</span>
                <span class="font-bold">{{ repair.customer?.name || repair.customer_name || 'Walk-in' }}</span>
              </div>
              <div class="flex justify-between">
                <span>Phone:</span>
                <span>{{ getCustomerMobile(repair) || '-' }}</span>
              </div>
              <div class="flex justify-between">
                <span>Device:</span>
                <span class="font-bold">{{ getDeviceTitle(repair) }}</span>
              </div>
              <div v-if="repair.imei || repair.device?.imei1" class="flex justify-between">
                <span>IMEI:</span>
                <span>{{ repair.device?.imei1 || repair.imei }}</span>
              </div>
              <div class="flex justify-between">
                <span>Status:</span>
                <span class="uppercase font-bold">{{ getStatusLabel(repair.repair_status) }}</span>
              </div>
            </div>

            <!-- Problem -->
            <div class="border-b border-dashed border-slate-300 pb-3 mb-3">
              <p class="font-bold uppercase text-[10px] text-slate-500">Problem Reported:</p>
              <p class="mt-0.5">{{ repair.problem_description || 'General inspection' }}</p>
            </div>

            <!-- Financials -->
            <div class="space-y-1.5 border-b border-dashed border-slate-300 pb-3 mb-3">
              <div class="flex justify-between">
                <span>Estimated / Net Bill:</span>
                <span class="font-bold">₹{{ formatAmount(totalBill) }}</span>
              </div>
              <div class="flex justify-between text-emerald-600">
                <span>Amount Paid:</span>
                <span>₹{{ formatAmount(totalPaid) }}</span>
              </div>
              <div class="flex justify-between font-bold text-sm pt-1 border-t border-slate-200">
                <span>Balance Due:</span>
                <span :class="amountDue > 0 ? 'text-rose-600' : 'text-emerald-600'">
                  ₹{{ formatAmount(amountDue) }}
                </span>
              </div>
            </div>

            <!-- Footer & Terms -->
            <div class="text-[10px] text-slate-500 text-center space-y-1">
              <p>Please present this slip at the time of delivery.</p>
              <p>Devices not collected within 30 days are not our responsibility.</p>
              <p class="pt-1 font-bold">Thank You For Choosing Us!</p>
            </div>
          </div>
        </div>

        <div class="flex items-center justify-end gap-2 pt-3 border-t border-slate-100 dark:border-slate-700">
          <button
            @click="showPrintModal = false"
            class="px-4 py-2 rounded-xl border border-slate-200 text-slate-600 text-xs font-semibold hover:bg-slate-50"
          >
            Close
          </button>
          <button
            @click="triggerPrint"
            class="px-5 py-2 rounded-xl bg-slate-900 text-white text-xs font-bold hover:bg-black flex items-center gap-1.5 shadow-md"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"/></svg>
            Print Slip
          </button>
        </div>
      </div>
    </div>

    <!-- 7. Confirm Delete Repair Modal -->
    <div v-if="showDeleteModal" class="fixed inset-0 z-50 overflow-y-auto flex min-h-full items-center justify-center p-4 py-6 sm:py-10 bg-black/60 backdrop-blur-sm animate-fade-in" @wheel.stop>
      <div class="bg-white dark:bg-slate-800 rounded-3xl max-w-sm w-full p-6 shadow-2xl border border-slate-200 dark:border-slate-700 space-y-4">
        <div class="flex items-center gap-3">
          <div class="w-10 h-10 rounded-2xl bg-rose-100 text-rose-600 flex items-center justify-center font-bold">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
          </div>
          <div>
            <h3 class="font-bold text-slate-900 dark:text-white text-base">Delete Repair Order</h3>
            <p class="text-xs text-slate-500">This action cannot be undone</p>
          </div>
        </div>

        <p class="text-xs text-slate-600 dark:text-slate-300">
          Are you sure you want to delete job card <strong>{{ repair.job_number }}</strong>? All attached parts and logs will be permanently deleted.
        </p>

        <div class="flex items-center justify-end gap-2 pt-2">
          <button
            @click="showDeleteModal = false"
            class="px-4 py-2 rounded-xl border border-slate-200 text-slate-600 text-xs font-semibold hover:bg-slate-50"
          >
            Cancel
          </button>
          <button
            @click="deleteRepair"
            :disabled="deleting"
            class="px-5 py-2 rounded-xl bg-rose-600 hover:bg-rose-700 disabled:opacity-50 text-white text-xs font-bold shadow-md shadow-rose-500/20"
          >
            {{ deleting ? 'Deleting...' : 'Delete Job' }}
          </button>
        </div>
      </div>
    </div>
    <!-- 8. Reassign Technician Modal -->
    <div
      v-if="showReassignTechModal"
      class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-5 bg-slate-900/60 backdrop-blur-xs"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-slate-800 rounded-3xl max-w-md w-full p-6 shadow-2xl border border-slate-200 dark:border-slate-700 space-y-4 max-h-[85vh] flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3 shrink-0">
          <div>
            <h3 class="font-bold text-slate-900 dark:text-white text-base">Reassign Technician</h3>
            <p class="text-xs text-slate-400">Update technician assignment and labour payout</p>
          </div>
          <button @click="showReassignTechModal = false" class="text-slate-400 hover:text-slate-600 cursor-pointer">✕</button>
        </div>

        <form @submit.prevent="submitReassignTech" class="space-y-4 text-xs">
          <div>
            <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">Select Technician</label>
            <SearchableSelect
              v-model="reassignForm.technician_id"
              :options="reassignTechnicianOptions"
              placeholder="-- Select Technician --"
              searchPlaceholder="Search technician..."
              minWidth="100%"
            />
          </div>

          <div>
            <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">
              Technician Labour / Fee (₹)
            </label>
            <input
              v-model.number="reassignForm.technician_earning"
              type="number"
              step="0.01"
              min="0"
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-semibold"
            />
          </div>

          <div class="flex items-center justify-end gap-2 pt-2 border-t border-slate-100 dark:border-slate-700">
            <button
              type="button"
              @click="showReassignTechModal = false"
              class="px-4 py-2 rounded-xl border border-slate-200 text-slate-600 font-semibold cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="reassignSubmitting"
              class="px-5 py-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold cursor-pointer"
            >
              {{ reassignSubmitting ? 'Updating...' : 'Save Assignment' }}
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
import { useToastStore } from '@/stores/toast';
import { repairApi, warrantyApi, technicianApi } from '@/api/endpoints';
import SearchableSelect from '@/components/common/SearchableSelect.vue';
import WhatsAppIcon from '@/components/common/WhatsAppIcon.vue';

const route = useRoute();
const router = useRouter();
const toast = useToastStore();

const statusChangeOptions = [
  { value: 'received', label: 'Received' },
  { value: 'diagnosing', label: 'Diagnosing' },
  { value: 'waiting_customer', label: 'Waiting Customer Approval' },
  { value: 'waiting_parts', label: 'Waiting for Parts' },
  { value: 'repairing', label: 'Under Repair' },
  { value: 'ready', label: 'Ready for Pickup' },
  { value: 'delivered', label: 'Delivered' },
  { value: 'cancelled', label: 'Cancelled' },
];

const repairPaymentOptions = [
  { value: 'cash', label: 'Cash', icon: '💵' },
  { value: 'upi', label: 'UPI / QR', icon: '⚡' },
  { value: 'card', label: 'Debit / Credit Card', icon: '💳' },
  { value: 'bank_transfer', label: 'Bank Transfer / NEFT', icon: '🏦' },
  { value: 'other', label: 'Other', icon: '📋' },
];

const repair = ref({});
const loading = ref(true);
const targetStatus = ref('received');
const statusNotes = ref('');
const statusUpdating = ref(false);
const obscurePasscode = ref(true);
const showProfit = ref(false);

// Modals
const showPaymentModal = ref(false);
const showAddPartModal = ref(false);
const showAddWarrantyModal = ref(false);
const showDeliveryWarningModal = ref(false);
const showWhatsAppModal = ref(false);
const showPrintModal = ref(false);
const showDeleteModal = ref(false);
const deleting = ref(false);

// Technician Reassign
const showReassignTechModal = ref(false);
const reassignSubmitting = ref(false);
const allTechnicians = ref([]);
const reassignForm = reactive({
  technician_id: null,
  technician_earning: 0,
});

const reassignTechnicianOptions = computed(() => {
  const opts = [{ value: null, label: '-- Unassigned / In-house --' }];
  for (const t of allTechnicians.value) {
    opts.push({
      value: t.id,
      label: t.name + (t.specialization ? ' • ' + t.specialization : ''),
    });
  }
  return opts;
});

// Submissions
const paymentSubmitting = ref(false);
const partSubmitting = ref(false);
const warrantySubmitting = ref(false);

// Forms
const paymentForm = ref({
  amount: 0,
  payment_method: 'cash',
  notes: '',
});

const partForm = ref({
  part_name: '',
  quantity: 1,
  cost_price: 0,
  selling_price: 0,
  notes: '',
});

const warrantyForm = ref({
  duration_days: 180,
  warranty_terms: 'Covers repair & parts replaced only. Physical and liquid damage not covered under warranty.',
});

const whatsAppMessageText = ref('');

// Computed Financials
const partsSubtotal = computed(() => {
  if (!repair.value.parts || !Array.isArray(repair.value.parts)) return 0;
  return repair.value.parts.reduce((sum, p) => sum + (Number(p.quantity || 1) * Number(p.selling_price || 0)), 0);
});

const totalBill = computed(() => {
  const r = repair.value;
  if (!r) return 0;
  return Number(r.final_cost || r.estimated_cost || r.effective_cost || 0);
});

const totalPaid = computed(() => {
  const r = repair.value;
  if (!r) return 0;
  if (r.amount_paid !== undefined && r.amount_paid !== null) {
    return Number(r.amount_paid);
  }
  if (r.payments && Array.isArray(r.payments)) {
    return r.payments.reduce((sum, p) => sum + Number(p.amount || 0), 0);
  }
  return 0;
});

const amountDue = computed(() => {
  const r = repair.value;
  if (!r) return 0;
  if (r.amount_due !== undefined && r.amount_due !== null) {
    return Math.max(0, Number(r.amount_due));
  }
  return Math.max(0, totalBill.value - totalPaid.value);
});

// Load repair data
async function loadRepair() {
  loading.value = true;
  try {
    const res = await repairApi.get(route.params.id);
    const data = res.data?.data || res.data;
    if (data) {
      repair.value = data;
      targetStatus.value = data.repair_status || 'received';
    }
  } catch (err) {
    console.error('Failed to load repair:', err);
  } finally {
    loading.value = false;
  }
}

// Status Updates
async function attemptStatusChange() {
  if (targetStatus.value === 'delivered' && amountDue.value > 0) {
    showDeliveryWarningModal.value = true;
    return;
  }
  await executeStatusChange();
}

async function executeStatusChange() {
  statusUpdating.value = true;
  try {
    const res = await repairApi.updateStatus(repair.value.id, {
      repair_status: targetStatus.value,
      notes: statusNotes.value,
    });
    if (res.data?.data) {
      repair.value = res.data.data;
      targetStatus.value = repair.value.repair_status;
      statusNotes.value = '';
    } else {
      await loadRepair();
    }
    toast.success(`Repair status updated to "${targetStatus.value}"`, 'Status Updated');
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to update status.';
    toast.error(msg, 'Status Update Failed');
  } finally {
    statusUpdating.value = false;
    showDeliveryWarningModal.value = false;
  }
}

function resolveDeliveryViaPayment() {
  showDeliveryWarningModal.value = false;
  openCollectPaymentModal();
}

async function openReassignTechModal() {
  try {
    const res = await technicianApi.list({ per_page: 50 });
    const list = res.data?.data?.data || res.data?.data || [];
    allTechnicians.value = Array.isArray(list) ? list : [];
  } catch {
    allTechnicians.value = [];
  }
  reassignForm.technician_id = repair.value.technician_id || null;
  reassignForm.technician_earning = Number(repair.value.technician_earning || repair.value.labour_cost || 0);
  showReassignTechModal.value = true;
}

async function submitReassignTech() {
  reassignSubmitting.value = true;
  try {
    await repairApi.update(repair.value.id, {
      customer_id: repair.value.customer_id,
      device_id: repair.value.device_id,
      technician_id: reassignForm.technician_id,
      technician_earning: reassignForm.technician_earning,
      problem_description: repair.value.problem_description,
    });
    showReassignTechModal.value = false;
    await loadRepair();
    toast.success('Technician assignment updated!', 'Technician Assigned');
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to update technician assignment.';
    toast.error(msg, 'Reassign Failed');
  } finally {
    reassignSubmitting.value = false;
  }
}

// Payment Methods
function openCollectPaymentModal() {
  paymentForm.value = {
    amount: amountDue.value > 0 ? amountDue.value : 0,
    payment_method: 'cash',
    notes: 'Payment collected',
  };
  showPaymentModal.value = true;
}

async function submitCollectPayment() {
  paymentSubmitting.value = true;
  try {
    await repairApi.addPayment(repair.value.id, paymentForm.value);
    showPaymentModal.value = false;
    toast.success(`Payment of ₹${formatAmount(paymentForm.value.amount)} recorded!`, 'Payment Collected');
    await loadRepair();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to record payment.';
    toast.error(msg, 'Payment Failed');
  } finally {
    paymentSubmitting.value = false;
  }
}

// Part Methods
async function submitAddPart() {
  partSubmitting.value = true;
  try {
    await repairApi.addPart(repair.value.id, partForm.value);
    showAddPartModal.value = false;
    const addedName = partForm.value.part_name;
    partForm.value = {
      part_name: '',
      quantity: 1,
      cost_price: 0,
      selling_price: 0,
      notes: '',
    };
    toast.success(`Spare part "${addedName}" added!`, 'Part Added');
    await loadRepair();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to add spare part.';
    toast.error(msg, 'Add Part Failed');
  } finally {
    partSubmitting.value = false;
  }
}

async function removePart(part) {
  const confirmed = await toast.confirm({
    title: 'Remove Spare Part?',
    message: `Are you sure you want to remove "${part.part_name}" from this repair order?`,
    confirmText: 'Yes, Remove',
    type: 'danger',
  });
  if (!confirmed) return;

  try {
    await repairApi.removePart(repair.value.id, part.id);
    toast.success(`Spare part "${part.part_name}" removed.`, 'Part Removed');
    await loadRepair();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to remove part.';
    toast.error(msg, 'Remove Part Failed');
  }
}

// Warranty Methods
async function submitAddWarranty() {
  warrantySubmitting.value = true;
  try {
    await warrantyApi.create({
      repair_id: repair.value.id,
      customer_id: repair.value.customer_id,
      device_id: repair.value.device_id,
      warranty_type: 'repair',
      duration_days: warrantyForm.value.duration_days,
      warranty_terms: warrantyForm.value.warranty_terms,
    });
    showAddWarrantyModal.value = false;
    toast.success('Warranty coverage attached!', 'Warranty Attached');
    await loadRepair();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to add warranty.';
    toast.error(msg, 'Warranty Failed');
  } finally {
    warrantySubmitting.value = false;
  }
}

// WhatsApp Integration
function openWhatsAppModal() {
  const r = repair.value;
  const custName = r.customer?.name || r.customer_name || 'Customer';
  const jobNo = r.job_number || ('#JOB-' + r.id);
  const status = getStatusLabel(r.repair_status);
  const due = formatAmount(amountDue.value);

  whatsAppMessageText.value =
    `Hello ${custName},\n\n` +
    `Your repair order *${jobNo}* is currently: *${status}*.\n\n` +
    `Device: ${getDeviceTitle(r)}\n` +
    `Total Bill: ₹${formatAmount(totalBill.value)}\n` +
    `Balance Due: ₹${due}\n\n` +
    `Thank you for trusting MyRepairHub!`;

  showWhatsAppModal.value = true;
}

function sendWhatsAppMessage() {
  const phone = getCustomerMobile(repair.value);
  if (!phone) {
    toast.warning('Customer does not have a phone number recorded.', 'No Phone Number');
    return;
  }
  const cleanPhone = formatPhoneForWhatsApp(phone);
  const encoded = encodeURIComponent(whatsAppMessageText.value);
  window.open(`https://wa.me/${cleanPhone}?text=${encoded}`, '_blank');
  showWhatsAppModal.value = false;
  toast.success('WhatsApp chat opened!', 'WhatsApp');
}

// Print Handler
function openPrintModal() {
  showPrintModal.value = true;
}

function triggerPrint() {
  window.print();
}

// Delete Handler
async function deleteRepair() {
  deleting.value = true;
  try {
    await repairApi.delete(repair.value.id);
    toast.success('Repair job order deleted successfully.', 'Job Deleted');
    router.push('/repairs');
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to delete repair order.';
    toast.error(msg, 'Delete Failed');
  } finally {
    deleting.value = false;
    showDeleteModal.value = false;
  }
}

// Utilities & Helpers
function formatAmount(val) {
  if (val === undefined || val === null || isNaN(val)) return '0.00';
  return Number(val).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function formatDate(val) {
  if (!val) return '-';
  try {
    const d = new Date(val);
    if (isNaN(d.getTime())) return String(val).substring(0, 10);
    return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
  } catch {
    return String(val).substring(0, 10);
  }
}

function getCustomerMobile(r) {
  return r.customer?.mobile || r.customer?.phone || r.customer_phone || '';
}

function formatPhoneForWhatsApp(phone) {
  if (!phone) return '';
  const cleaned = String(phone).replace(/\D/g, '');
  if (cleaned.length === 10) return '91' + cleaned;
  return cleaned;
}

function getDeviceTitle(r) {
  if (!r) return 'Device';
  if (r.device?.brand || r.device?.model) {
    return `${r.device.brand || ''} ${r.device.model || ''}`.trim();
  }
  if (r.device_brand || r.device_model) {
    return `${r.device_brand || ''} ${r.device_model || ''}`.trim();
  }
  return 'Mobile Device';
}

function parseChecklist(val) {
  if (!val) return [];
  if (Array.isArray(val)) return val;
  try {
    const parsed = JSON.parse(val);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return String(val).split(',').map(s => s.trim()).filter(Boolean);
  }
}

function isPatternLock(val) {
  if (!val) return false;
  const str = String(val).trim();
  if (str.toUpperCase().startsWith('PATTERN:')) return true;
  return /^[0-9]([\s\-,\>➔→]+[0-9])+$/.test(str) || /^[0-8](,[0-8])+$/.test(str);
}

function parsePatternPoints(val) {
  if (!val) return [];
  let str = String(val).trim();
  if (str.toUpperCase().startsWith('PATTERN:')) {
    str = str.substring(8).trim();
  }
  const parts = str.split(/[\s\-,\>➔→]+/).filter(Boolean);
  const points = [];
  let hasZero = false;
  for (const part of parts) {
    const num = parseInt(part.trim(), 10);
    if (!isNaN(num) && num >= 0 && num <= 9 && !points.includes(num)) {
      if (num === 0) hasZero = true;
      points.push(num);
    }
  }
  if (hasZero) {
    return points.map(p => p + 1);
  }
  return points.filter(p => p >= 1 && p <= 9);
}

function getDotX(p) {
  const col = (p - 1) % 3;
  return 28 + col * 52;
}

function getDotY(p) {
  const row = Math.floor((p - 1) / 3);
  return 28 + row * 52;
}

function getSvgPolylinePoints(val) {
  const pts = parsePatternPoints(val);
  return pts.map(p => `${getDotX(p)},${getDotY(p)}`).join(' ');
}

function getPatternStep(dotNum, val) {
  const pts = parsePatternPoints(val);
  const idx = pts.indexOf(dotNum);
  return idx !== -1 ? idx + 1 : null;
}

function formatPatternSequence(val) {
  const pts = parsePatternPoints(val);
  if (!pts.length) return 'None';
  return pts.join(' ➔ ');
}

function copyText(val) {
  if (!val) return;
  navigator.clipboard.writeText(String(val));
  toast.info(`Copied "${val}" to clipboard!`, 'Copied');
}

function getStatusLabel(status) {
  const map = {
    received: 'Received',
    diagnosing: 'Diagnosing',
    waiting_customer: 'Waiting Approval',
    waiting_parts: 'Waiting for Parts',
    repairing: 'Under Repair',
    ready: 'Ready for Pickup',
    delivered: 'Delivered',
    cancelled: 'Cancelled',
  };
  return map[status] || (status ? status.toUpperCase() : 'UNKNOWN');
}

function getStatusBadgeClass(status) {
  const map = {
    received: 'bg-blue-100 text-blue-700 dark:bg-blue-950/60 dark:text-blue-300 border border-blue-200 dark:border-blue-800',
    diagnosing: 'bg-amber-100 text-amber-700 dark:bg-amber-950/60 dark:text-amber-300 border border-amber-200 dark:border-amber-800',
    waiting_customer: 'bg-purple-100 text-purple-700 dark:bg-purple-950/60 dark:text-purple-300 border border-purple-200 dark:border-purple-800',
    waiting_parts: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-950/60 dark:text-yellow-300 border border-yellow-200 dark:border-yellow-800',
    repairing: 'bg-indigo-100 text-indigo-700 dark:bg-indigo-950/60 dark:text-indigo-300 border border-indigo-200 dark:border-indigo-800',
    ready: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800',
    delivered: 'bg-teal-100 text-teal-800 dark:bg-teal-950/60 dark:text-teal-300 border border-teal-200 dark:border-teal-800',
    cancelled: 'bg-rose-100 text-rose-700 dark:bg-rose-950/60 dark:text-rose-300 border border-rose-200 dark:border-rose-800',
  };
  return map[status] || 'bg-slate-100 text-slate-700';
}

function getHeroGradient(status) {
  const map = {
    received: 'bg-gradient-to-br from-blue-600 via-blue-700 to-indigo-800',
    diagnosing: 'bg-gradient-to-br from-amber-500 via-orange-600 to-amber-700',
    waiting_customer: 'bg-gradient-to-br from-purple-600 via-indigo-600 to-purple-800',
    waiting_parts: 'bg-gradient-to-br from-yellow-500 via-amber-600 to-yellow-700',
    repairing: 'bg-gradient-to-br from-indigo-600 via-blue-600 to-indigo-800',
    ready: 'bg-gradient-to-br from-emerald-600 via-teal-600 to-emerald-800',
    delivered: 'bg-gradient-to-br from-teal-600 via-emerald-700 to-teal-800',
    cancelled: 'bg-gradient-to-br from-rose-600 via-red-600 to-rose-800',
  };
  return map[status] || 'bg-gradient-to-br from-indigo-600 to-indigo-800';
}

onMounted(() => {
  loadRepair();
});
</script>

<style>
@media print {
  body * {
    visibility: hidden;
  }
  #printable-job-card,
  #printable-job-card * {
    visibility: visible;
  }
  #printable-job-card {
    position: absolute;
    left: 0;
    top: 0;
    width: 100%;
    margin: 0;
    padding: 10px;
    border: none;
    box-shadow: none;
  }
}
</style>
