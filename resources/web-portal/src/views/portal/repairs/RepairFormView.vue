<template>
  <div class="max-w-5xl mx-auto space-y-6 pb-20 font-['Outfit',sans-serif]">
    <!-- Top Action Bar -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div class="flex items-center gap-3">
        <router-link
          to="/repairs"
          class="inline-flex items-center gap-1.5 px-3 py-2 text-xs font-semibold rounded-xl bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-200 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 shadow-xs transition cursor-pointer"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/></svg>
          Back to Repairs
        </router-link>
        <div>
          <h1 class="text-2xl font-bold text-slate-900 dark:text-white">
            {{ isEdit ? 'Edit Repair Job #' + (repairNumber || route.params.id) : 'Create New Repair Job' }}
          </h1>
          <p class="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
            {{ isEdit ? 'Update job details, diagnostic checklists, and technician assignment' : 'Select customer, choose registered device, and record diagnosis & intake details' }}
          </p>
        </div>
      </div>

      <div class="flex items-center gap-2">
        <router-link :to="isEdit ? `/repairs/${route.params.id}` : '/repairs'" class="px-4 py-2 text-xs font-semibold rounded-xl border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 hover:bg-slate-50 cursor-pointer">
          {{ isDelivered ? 'Back to Job Card' : 'Cancel' }}
        </router-link>
        <button
          v-if="!isDelivered"
          type="button"
          @click="submitRepair"
          :disabled="submitting"
          class="px-5 py-2 text-xs font-bold rounded-xl bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white shadow-md shadow-indigo-500/20 transition flex items-center gap-1.5 cursor-pointer"
        >
          <svg v-if="submitting" class="w-3.5 h-3.5 animate-spin" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path></svg>
          {{ submitting ? 'Saving...' : (isEdit ? 'Update Job Card' : 'Save & Create Job Card') }}
        </button>
        <div v-else class="px-3.5 py-1.5 rounded-xl bg-emerald-100 dark:bg-emerald-950/60 border border-emerald-300 dark:border-emerald-800 text-emerald-800 dark:text-emerald-300 text-xs font-bold flex items-center gap-1.5">
          <span>🔒 Order Finalized (Frozen)</span>
        </div>
      </div>
    </div>

    <!-- Delivered & Finalized Freeze Banner -->
    <div v-if="isDelivered" class="p-5 bg-gradient-to-r from-emerald-50 to-teal-50 dark:from-emerald-950/40 dark:to-teal-950/40 border-2 border-emerald-400 dark:border-emerald-700 rounded-3xl flex flex-col sm:flex-row sm:items-center justify-between gap-4 shadow-sm animate-in fade-in">
      <div class="flex items-center gap-3.5">
        <div class="w-11 h-11 rounded-2xl bg-emerald-600 text-white flex items-center justify-center font-bold text-xl shadow-md shrink-0">
          🔒
        </div>
        <div>
          <h4 class="font-extrabold text-emerald-950 dark:text-emerald-100 text-sm flex items-center gap-2">
            Job Card Delivered & Finalized
            <span class="text-[10px] uppercase font-extrabold bg-emerald-200 dark:bg-emerald-900 text-emerald-900 dark:text-emerald-200 px-2.5 py-0.5 rounded-full border border-emerald-300 dark:border-emerald-800">All Fields Frozen</span>
          </h4>
          <p class="text-xs text-emerald-800 dark:text-emerald-300 mt-1">
            This device has already been delivered to the customer. All specifications, costs, parts, and notes are frozen in read-only mode to safeguard store records.
          </p>
        </div>
      </div>

      <router-link
        :to="`/repairs/${route.params.id}`"
        class="px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs shadow-md shadow-emerald-600/20 text-center shrink-0 cursor-pointer transition hover:scale-105"
      >
        View Closed Job Card →
      </router-link>
    </div>

    <!-- Alert / Validation Banner -->
    <div v-if="errorMsg" class="p-4 bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-800 rounded-2xl text-xs font-semibold text-red-700 dark:text-red-300 flex items-center justify-between">
      <div class="flex items-center gap-2">
        <svg class="w-4 h-4 text-red-500 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
        <span>{{ errorMsg }}</span>
      </div>
      <button @click="errorMsg = ''" class="text-red-400 hover:text-red-600 cursor-pointer">✕</button>
    </div>

    <form @submit.prevent="submitRepair" class="space-y-6">
      <fieldset :disabled="isDelivered" class="space-y-6" :class="{ 'pointer-events-none opacity-85 select-none': isDelivered }">
      <!-- ───────────────────────────────────────────────────────────── -->
      <!-- 1. CUSTOMER INFORMATION (Search Modal & Quick Add) -->
      <!-- ───────────────────────────────────────────────────────────── -->
      <div class="bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200/80 dark:border-slate-700/80 shadow-xs space-y-4">
        <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-lg bg-indigo-50 dark:bg-indigo-950/40 text-indigo-600 dark:text-indigo-400 flex items-center justify-center font-bold">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
            </div>
            <div>
              <h3 class="font-bold text-slate-900 dark:text-white text-sm">Customer Profile</h3>
              <p class="text-[11px] text-slate-400">Search customer from database or quickly register new</p>
            </div>
          </div>

          <button
            type="button"
            @click="showQuickCustomerModal = true"
            class="text-xs font-bold text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 flex items-center gap-1 bg-indigo-50 dark:bg-indigo-950/40 px-3 py-1.5 rounded-xl border border-indigo-200 dark:border-indigo-800 cursor-pointer transition hover:scale-105"
          >
            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
            + Add Customer
          </button>
        </div>

        <!-- Selected Customer Card -->
        <div v-if="selectedCustomer" class="p-4 bg-indigo-50/60 dark:bg-indigo-950/30 rounded-2xl border border-indigo-100 dark:border-indigo-900/40 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-xl bg-indigo-600 text-white flex items-center justify-center font-extrabold text-base shadow-xs">
              {{ (selectedCustomer.name || 'C')[0] }}
            </div>
            <div>
              <div class="flex items-center gap-2">
                <h4 class="font-bold text-slate-900 dark:text-white text-sm">{{ selectedCustomer.name }}</h4>
                <span class="text-[10px] font-bold text-indigo-700 dark:text-indigo-300 bg-white dark:bg-slate-800 px-2 py-0.5 rounded-full border border-indigo-200 dark:border-indigo-800">
                  Customer #{{ selectedCustomer.id }}
                </span>
              </div>
              <div class="flex items-center gap-3 text-xs text-slate-500 dark:text-slate-400 mt-0.5 font-mono">
                <span>📞 {{ selectedCustomer.phone || selectedCustomer.mobile || 'No mobile' }}</span>
                <span v-if="selectedCustomer.city" class="font-sans">📍 {{ selectedCustomer.city }}</span>
              </div>
            </div>
          </div>

          <div class="flex items-center gap-2">
            <button
              v-if="!isEdit"
              type="button"
              @click="openCustomerSearchModal"
              class="px-3 py-1.5 text-xs font-bold rounded-xl bg-white dark:bg-slate-800 border border-indigo-200 dark:border-indigo-800 text-indigo-600 dark:text-indigo-400 hover:bg-indigo-50 cursor-pointer transition"
            >
              Change Customer
            </button>
          </div>
        </div>

        <!-- No Customer Selected Trigger -->
        <div v-else class="space-y-2">
          <button
            type="button"
            @click="openCustomerSearchModal"
            class="w-full p-4 rounded-2xl border-2 border-dashed border-indigo-200 dark:border-indigo-800/60 hover:border-indigo-500 bg-indigo-50/30 dark:bg-indigo-950/20 text-indigo-600 dark:text-indigo-400 flex items-center justify-center gap-2.5 text-xs font-bold transition hover:bg-indigo-50/60 cursor-pointer"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
            Click to Search & Select Customer from Database
          </button>
        </div>
      </div>

      <!-- ───────────────────────────────────────────────────────────── -->
      <!-- 2. DEVICE SELECTION (Customer's Registered Devices Only) -->
      <!-- ───────────────────────────────────────────────────────────── -->
      <div class="bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200/80 dark:border-slate-700/80 shadow-xs space-y-4">
        <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-lg bg-purple-50 dark:bg-purple-950/40 text-purple-600 dark:text-purple-400 flex items-center justify-center font-bold">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"/></svg>
            </div>
            <div>
              <h3 class="font-bold text-slate-900 dark:text-white text-sm">Customer Device</h3>
              <p class="text-[11px] text-slate-400">Select from customer's registered devices or register this phone</p>
            </div>
          </div>

          <button
            v-if="selectedCustomer"
            type="button"
            @click="openQuickDeviceModal"
            class="text-xs font-bold text-purple-600 dark:text-purple-400 hover:text-purple-700 flex items-center gap-1 bg-purple-50 dark:bg-purple-950/40 px-3 py-1.5 rounded-xl border border-purple-200 dark:border-purple-800 cursor-pointer transition hover:scale-105"
          >
            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
            + Add Device
          </button>
        </div>

        <!-- If no customer is chosen yet -->
        <div v-if="!selectedCustomer" class="p-6 text-center text-xs text-slate-400 bg-slate-50 dark:bg-slate-900/50 rounded-2xl border border-slate-200/60 dark:border-slate-800">
          <svg class="w-8 h-8 text-slate-300 dark:text-slate-600 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"/></svg>
          Please select a customer first above to view or register their devices.
        </div>

        <!-- When customer IS selected -->
        <div v-else class="space-y-3">
          <!-- A) Device is Selected -->
          <div v-if="selectedDevice" class="p-4 bg-purple-50/60 dark:bg-purple-950/30 rounded-2xl border border-purple-100 dark:border-purple-900/40 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-xl bg-purple-600 text-white flex items-center justify-center font-bold text-base shadow-xs">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"/></svg>
              </div>
              <div>
                <div class="flex items-center gap-2">
                  <h4 class="font-bold text-slate-900 dark:text-white text-sm">
                    {{ selectedDevice.brand }} {{ selectedDevice.model }}
                  </h4>
                  <span class="text-[10px] font-bold text-purple-700 dark:text-purple-300 bg-white dark:bg-slate-800 px-2 py-0.5 rounded-full border border-purple-200 dark:border-purple-800">
                    Device #{{ selectedDevice.id || 'Current' }}
                  </span>
                </div>
                <div class="flex items-center gap-3 text-xs text-slate-500 dark:text-slate-400 mt-0.5 font-mono">
                  <span>IMEI: {{ selectedDevice.imei1 || selectedDevice.imei || form.imei || 'Not recorded' }}</span>
                  <span v-if="selectedDevice.color" class="font-sans">Color: {{ selectedDevice.color }}</span>
                </div>
              </div>
            </div>

            <button
              type="button"
              @click="clearDeviceSelection"
              class="px-3 py-1.5 text-xs font-bold rounded-xl bg-white dark:bg-slate-800 border border-purple-200 dark:border-purple-800 text-purple-600 dark:text-purple-400 hover:bg-purple-50 cursor-pointer transition self-start sm:self-center"
            >
              Change Device
            </button>
          </div>

          <!-- B) No Device Selected: Show Customer's Registered Devices -->
          <div v-else class="space-y-3">
            <div v-if="loadingDevices" class="py-6 text-center text-xs text-slate-400">
              <div class="w-5 h-5 border-2 border-purple-600 border-t-transparent rounded-full animate-spin mx-auto mb-2"></div>
              Loading customer devices...
            </div>

            <div v-else-if="customerDevices.length > 0" class="space-y-2">
              <div class="flex items-center justify-between">
                <label class="block text-xs font-bold text-slate-700 dark:text-slate-300">
                  Select from {{ selectedCustomer.name }}'s Registered Devices ({{ customerDevices.length }} saved):
                </label>
                <div class="relative w-48">
                  <input
                    v-model="deviceSearchQuery"
                    type="text"
                    placeholder="Search device..."
                    class="w-full px-2.5 py-1 text-xs rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900"
                  />
                </div>
              </div>

              <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 max-h-56 overflow-y-auto pr-1">
                <div
                  v-for="d in filteredCustomerDevices"
                  :key="d.id"
                  @click="selectDevice(d)"
                  class="p-3.5 rounded-xl border border-slate-200 dark:border-slate-700 hover:border-purple-500 hover:bg-purple-50/40 dark:hover:bg-purple-950/20 cursor-pointer transition flex items-center justify-between group"
                >
                  <div class="flex items-center gap-2.5">
                    <div class="w-8 h-8 rounded-lg bg-purple-100 dark:bg-purple-950/50 text-purple-600 dark:text-purple-400 flex items-center justify-center font-bold text-xs">
                      📱
                    </div>
                    <div>
                      <p class="font-bold text-slate-900 dark:text-white text-xs group-hover:text-purple-600">{{ d.brand }} {{ d.model }}</p>
                      <p class="text-[11px] font-mono text-slate-400">{{ d.imei1 ? 'IMEI: ' + d.imei1 : 'No IMEI' }}</p>
                    </div>
                  </div>
                  <span class="text-[10px] font-bold text-purple-600 bg-purple-50 dark:bg-purple-950/60 px-2 py-1 rounded-lg border border-purple-200 dark:border-purple-800">
                    Select
                  </span>
                </div>
              </div>
            </div>

            <!-- Empty Devices State -->
            <div v-else class="p-6 text-center bg-slate-50/80 dark:bg-slate-900/40 rounded-2xl border border-dashed border-slate-300 dark:border-slate-700">
              <svg class="w-8 h-8 text-purple-400 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"/></svg>
              <p class="text-xs font-bold text-slate-700 dark:text-slate-300">No saved devices found for {{ selectedCustomer.name }}</p>
              <p class="text-[11px] text-slate-400 mt-0.5">Click below to register the phone being repaired for this customer.</p>
              <button
                type="button"
                @click="openQuickDeviceModal"
                class="mt-3 inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-purple-600 hover:bg-purple-700 text-white text-xs font-bold shadow-xs cursor-pointer transition hover:scale-105"
              >
                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
                + Register Device for {{ selectedCustomer.name }}
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- ───────────────────────────────────────────────────────────── -->
      <!-- 3. ASSIGNED TECHNICIAN (Search Modal & Quick Add) -->
      <!-- ───────────────────────────────────────────────────────────── -->
      <div class="bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200/80 dark:border-slate-700/80 shadow-xs space-y-4">
        <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-lg bg-blue-50 dark:bg-blue-950/40 text-blue-600 dark:text-blue-400 flex items-center justify-center font-bold">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
            </div>
            <div>
              <h3 class="font-bold text-slate-900 dark:text-white text-sm">Assigned Technician</h3>
              <p class="text-[11px] text-slate-400">Assign technician to perform repair and configure technician fee</p>
            </div>
          </div>

          <button
            type="button"
            @click="showQuickTechModal = true"
            class="text-xs font-bold text-blue-600 dark:text-blue-400 hover:text-blue-700 flex items-center gap-1 bg-blue-50 dark:bg-blue-950/40 px-3 py-1.5 rounded-xl border border-blue-200 dark:border-blue-800 cursor-pointer transition hover:scale-105"
          >
            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
            + Add Technician
          </button>
        </div>

        <!-- Selected Technician Card -->
        <div v-if="selectedTechnician" class="p-4 bg-blue-50/60 dark:bg-blue-950/30 rounded-2xl border border-blue-100 dark:border-blue-900/40 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-xl bg-blue-600 text-white flex items-center justify-center font-bold text-base shadow-xs">
              {{ (selectedTechnician.name || 'T')[0] }}
            </div>
            <div>
              <div class="flex items-center gap-2">
                <h4 class="font-bold text-slate-900 dark:text-white text-sm">{{ selectedTechnician.name }}</h4>
                <span class="text-[10px] font-bold text-blue-700 dark:text-blue-300 bg-white dark:bg-slate-800 px-2 py-0.5 rounded-full border border-blue-200 dark:border-blue-800">
                  {{ selectedTechnician.specialization || 'General Technician' }}
                </span>
              </div>
              <div class="text-xs text-slate-500 dark:text-slate-400 mt-0.5 font-mono">
                <span>📞 {{ selectedTechnician.phone || selectedTechnician.mobile || 'No contact' }}</span>
              </div>
            </div>
          </div>

          <div class="flex items-center gap-2">
            <button
              type="button"
              @click="openTechnicianSearchModal"
              class="px-3 py-1.5 text-xs font-bold rounded-xl bg-white dark:bg-slate-800 border border-blue-200 dark:border-blue-800 text-blue-600 dark:text-blue-400 hover:bg-blue-50 cursor-pointer transition"
            >
              Change Technician
            </button>
            <button
              type="button"
              @click="unassignTechnician"
              class="px-3 py-1.5 text-xs font-bold rounded-xl border border-rose-200 text-rose-600 hover:bg-rose-50 cursor-pointer transition"
            >
              Unassign
            </button>
          </div>
        </div>

        <!-- No Technician Assigned Trigger -->
        <div v-else>
          <button
            type="button"
            @click="openTechnicianSearchModal"
            class="w-full p-4 rounded-2xl border-2 border-dashed border-blue-200 dark:border-blue-800/60 hover:border-blue-500 bg-blue-50/30 dark:bg-blue-950/20 text-blue-600 dark:text-blue-400 flex items-center justify-center gap-2.5 text-xs font-bold transition hover:bg-blue-50/60 cursor-pointer"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
            Click to Search & Assign Technician
          </button>
        </div>

        <!-- Technician Labour Earning Input & Live Shop Share Breakdown (Matching Flutter App Card 2) -->
        <div v-if="selectedTechnician" class="pt-3 border-t border-slate-100 dark:border-slate-700/60 space-y-3">
          <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
                Estimated Repair Cost (₹)
              </label>
              <div class="relative">
                <span class="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400 font-bold text-xs">₹</span>
                <input
                  v-model.number="form.estimated_cost"
                  type="number"
                  step="0.01"
                  min="0"
                  placeholder="e.g. 1500"
                  class="w-full pl-8 pr-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-bold text-slate-900 dark:text-white focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <p class="text-[10px] text-slate-400 mt-1">Total repair fee charged to customer.</p>
            </div>

            <div>
              <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
                Technician Earning / Fee (₹)
              </label>
              <div class="relative">
                <span class="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400 font-bold text-xs">₹</span>
                <input
                  v-model.number="form.technician_earning"
                  type="number"
                  step="0.01"
                  min="0"
                  placeholder="e.g. 200"
                  class="w-full pl-8 pr-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-bold text-emerald-600 dark:text-emerald-400 focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <p class="text-[10px] text-slate-400 mt-1">Fixed earning assigned to this technician.</p>
            </div>

            <!-- Live Shop Share Card -->
            <div class="p-3 bg-blue-50/70 dark:bg-blue-950/40 rounded-xl border border-blue-200/80 dark:border-blue-900/60 flex flex-col justify-center">
              <div class="flex items-center justify-between text-xs font-bold">
                <span class="text-blue-900 dark:text-blue-200">Shop Net Profit:</span>
                <span class="text-sm font-extrabold text-blue-600 dark:text-blue-400">
                  ₹{{ formatAmount(Math.max(0, (Number(form.estimated_cost) || 0) - (Number(form.technician_earning) || 0))) }}
                </span>
              </div>
              <div class="flex items-center justify-between text-[11px] text-slate-500 dark:text-slate-400 mt-1 pt-1 border-t border-blue-200/50 dark:border-blue-900/40">
                <span>Tech Earning:</span>
                <span class="font-bold text-emerald-600 dark:text-emerald-400">₹{{ formatAmount(form.technician_earning) }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- ───────────────────────────────────────────────────────────── -->
      <!-- 4. FAULT DESCRIPTION & CONDITION CHECKLISTS -->
      <!-- ───────────────────────────────────────────────────────────── -->
      <div class="bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200/80 dark:border-slate-700/80 shadow-xs space-y-4">
        <div class="border-b border-slate-100 dark:border-slate-700 pb-3">
          <h3 class="font-bold text-slate-900 dark:text-white text-sm">Diagnosis & Intake Checklist</h3>
          <p class="text-[11px] text-slate-400">Capture faults and physical condition checklist matching the app</p>
        </div>

        <div>
          <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
            Problem Description <span class="text-rose-500">*</span>
          </label>
          <textarea
            v-model="form.problem_description"
            rows="3"
            required
            placeholder="Describe fault details: e.g. Display glass cracked, touch not working, charging port loose..."
            class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-medium focus:ring-2 focus:ring-indigo-500"
          ></textarea>
        </div>

        <!-- 10 Condition Toggle Badges (From App) -->
        <div>
          <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
            Device Physical Condition Tags (Click to toggle)
          </label>
          <div class="flex flex-wrap gap-2 mb-2">
            <button
              type="button"
              v-for="cond in availableConditions"
              :key="cond"
              @click="toggleCondition(cond)"
              :class="[
                'px-3 py-1.5 rounded-xl text-xs font-semibold transition border cursor-pointer',
                selectedConditions.includes(cond)
                  ? 'bg-rose-600 text-white border-rose-600 shadow-xs scale-105'
                  : 'bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-300 hover:bg-slate-100'
              ]"
            >
              {{ selectedConditions.includes(cond) ? '✓ ' + cond : '+ ' + cond }}
            </button>
          </div>

          <!-- Other Condition Notes (Optional) -->
          <input
            v-model="form.condition_notes"
            type="text"
            placeholder="Other condition notes (Optional) - e.g. Back cover missing screw, corner dent..."
            class="w-full px-3.5 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs text-slate-800 dark:text-slate-200 placeholder-slate-400 focus:ring-2 focus:ring-rose-500"
          />
        </div>

        <!-- 7 Accessories Toggle Badges (From App) -->
        <div>
          <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
            Accessories Received with Device
          </label>
          <div class="flex flex-wrap gap-2 mb-2">
            <button
              type="button"
              v-for="acc in availableAccessories"
              :key="acc"
              @click="toggleAccessory(acc)"
              :class="[
                'px-3 py-1.5 rounded-xl text-xs font-semibold transition border cursor-pointer',
                selectedAccessories.includes(acc)
                  ? 'bg-emerald-600 text-white border-emerald-600 shadow-xs scale-105'
                  : 'bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-300 hover:bg-slate-100'
              ]"
            >
              {{ selectedAccessories.includes(acc) ? '✓ ' + acc : '+ ' + acc }}
            </button>
          </div>

          <!-- Accessories Notes (Optional) -->
          <input
            v-model="form.accessories_notes"
            type="text"
            placeholder="Accessories notes (Optional) - e.g. 25W original charger without cable..."
            class="w-full px-3.5 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs text-slate-800 dark:text-slate-200 placeholder-slate-400 focus:ring-2 focus:ring-emerald-500"
          />
        </div>
      </div>

      <!-- ───────────────────────────────────────────────────────────── -->
      <!-- 5. SECURITY & DELIVERY SCHEDULE (Matching Mobile App Card 5) -->
      <!-- ───────────────────────────────────────────────────────────── -->
      <div class="bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200/80 dark:border-slate-700/80 shadow-xs space-y-4">
        <div class="border-b border-slate-100 dark:border-slate-700 pb-3 flex items-center justify-between">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-lg bg-amber-50 dark:bg-amber-950/40 text-amber-600 dark:text-amber-400 flex items-center justify-center font-bold">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/></svg>
            </div>
            <div>
              <h3 class="font-bold text-slate-900 dark:text-white text-sm">Security & Delivery Schedule</h3>
              <p class="text-[11px] text-slate-400">Device unlock credentials and promised customer handover date</p>
            </div>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
          <!-- Screen Lock / Pattern -->
          <div class="space-y-2">
            <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300">
              Screen Lock Type
            </label>

            <!-- Mode Switcher Choice Chips (Matching Flutter App) -->
            <div class="flex items-center gap-2">
              <button
                type="button"
                @click="showPatternDrawer = false"
                :class="[
                  'px-3 py-1.5 rounded-xl text-xs font-bold border transition flex items-center gap-1.5 cursor-pointer',
                  !showPatternDrawer
                    ? 'bg-amber-600 text-white border-amber-600 shadow-xs'
                    : 'bg-slate-50 dark:bg-slate-900 text-slate-600 dark:text-slate-300 border-slate-200 dark:border-slate-700 hover:bg-slate-100'
                ]"
              >
                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z"/></svg>
                PIN / Password
              </button>

              <button
                type="button"
                @click="showPatternDrawer = true"
                :class="[
                  'px-3 py-1.5 rounded-xl text-xs font-bold border transition flex items-center gap-1.5 cursor-pointer',
                  showPatternDrawer
                    ? 'bg-amber-600 text-white border-amber-600 shadow-xs'
                    : 'bg-slate-50 dark:bg-slate-900 text-slate-600 dark:text-slate-300 border-slate-200 dark:border-slate-700 hover:bg-slate-100'
                ]"
              >
                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"/></svg>
                Pattern Lock (3×3)
              </button>
            </div>

            <!-- Pattern Mode Drawer with Realtime Interactive SVG Grid -->
            <div v-if="showPatternDrawer" class="p-4 bg-amber-50 dark:bg-amber-950/20 rounded-2xl border border-amber-200 dark:border-amber-800/60 space-y-3">
              <div class="flex items-center justify-between text-xs text-amber-900 dark:text-amber-200 font-bold">
                <span class="flex items-center gap-1.5">
                  <span class="w-2 h-2 rounded-full bg-amber-600 animate-pulse"></span>
                  <span>Draw Customer 3×3 Pattern:</span>
                </span>
                <button type="button" @click="resetPattern" class="text-rose-600 text-[11px] font-bold hover:underline cursor-pointer">
                  Reset Pattern
                </button>
              </div>

              <!-- Interactive 3x3 SVG Pattern Grid (Matching App PatternPreviewWidget) -->
              <div class="flex justify-center py-1">
                <div class="w-44 h-44 bg-white dark:bg-slate-900 rounded-2xl p-2 border border-amber-300 dark:border-amber-700 shadow-sm flex items-center justify-center">
                  <svg viewBox="0 0 160 160" class="w-40 h-40 select-none">
                    <!-- Realtime Connecting Lines -->
                    <polyline
                      :points="getFormSvgPolylinePoints"
                      fill="none"
                      stroke="#d97706"
                      stroke-width="4"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                    />
                    <!-- 9 Interactive Dots -->
                    <g v-for="idx in 9" :key="idx" class="cursor-pointer" @click="addPatternPoint(idx)">
                      <!-- Invisible wider click area -->
                      <circle :cx="getDotX(idx)" :cy="getDotY(idx)" r="22" fill="transparent" />
                      <!-- Visual Dot Circle -->
                      <circle
                        :cx="getDotX(idx)"
                        :cy="getDotY(idx)"
                        :r="getFormPatternStep(idx) ? 14 : 8"
                        :class="getFormPatternStep(idx) ? 'fill-amber-600 stroke-2 stroke-amber-200 dark:stroke-amber-800' : 'fill-slate-300 dark:fill-slate-600 hover:fill-amber-300'"
                      />
                      <!-- Step number if tapped -->
                      <text
                        v-if="getFormPatternStep(idx)"
                        :x="getDotX(idx)"
                        :y="getDotY(idx) + 4"
                        text-anchor="middle"
                        class="fill-white font-bold text-[11px] pointer-events-none select-none"
                      >
                        {{ getFormPatternStep(idx) }}
                      </text>
                      <!-- Subdued dot number if inactive -->
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
              </div>

              <!-- Realtime Readable Sequence -->
              <div class="p-2.5 bg-white/90 dark:bg-slate-900/90 rounded-xl border border-amber-200 dark:border-amber-800 text-center">
                <p class="text-[11px] font-mono font-bold text-amber-900 dark:text-amber-300">
                  {{ patternPoints.length > 0 ? 'Pattern Sequence: ' + patternPoints.join(' ➔ ') : 'Click dots in sequence (1 to 9)' }}
                </p>
              </div>
            </div>

            <!-- Numeric PIN or Password input -->
            <div v-else>
              <input
                v-model="form.pin_passcode"
                type="text"
                placeholder="e.g. 1234 or device password"
                class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-mono font-semibold focus:ring-2 focus:ring-amber-500"
              />
            </div>
          </div>

          <!-- Expected Delivery Date with Stylish Date Formatter & Presets -->
          <div class="space-y-2">
            <div class="flex items-center justify-between">
              <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300">
                Expected Delivery Date
              </label>
              <span v-if="form.expected_delivery_date" class="text-[10px] font-bold text-indigo-700 dark:text-indigo-300 bg-indigo-50 dark:bg-indigo-950/60 px-2.5 py-0.5 rounded-full border border-indigo-200 dark:border-indigo-800">
                {{ getDeliveryBadge(form.expected_delivery_date) }}
              </span>
            </div>

            <!-- Quick Preset Chips -->
            <div class="flex flex-wrap gap-1.5 mb-1.5">
              <button
                type="button"
                @click="setDeliveryPreset(0)"
                :class="[
                  'px-2.5 py-1 text-[11px] font-bold rounded-lg border transition cursor-pointer',
                  isDateSelected(0)
                    ? 'bg-indigo-600 text-white border-indigo-600 shadow-xs'
                    : 'bg-slate-50 dark:bg-slate-900 text-slate-600 dark:text-slate-300 border-slate-200 dark:border-slate-700 hover:bg-slate-100'
                ]"
              >
                Today
              </button>
              <button
                type="button"
                @click="setDeliveryPreset(1)"
                :class="[
                  'px-2.5 py-1 text-[11px] font-bold rounded-lg border transition cursor-pointer',
                  isDateSelected(1)
                    ? 'bg-indigo-600 text-white border-indigo-600 shadow-xs'
                    : 'bg-slate-50 dark:bg-slate-900 text-slate-600 dark:text-slate-300 border-slate-200 dark:border-slate-700 hover:bg-slate-100'
                ]"
              >
                Tomorrow (+1d)
              </button>
              <button
                type="button"
                @click="setDeliveryPreset(3)"
                :class="[
                  'px-2.5 py-1 text-[11px] font-bold rounded-lg border transition cursor-pointer',
                  isDateSelected(3)
                    ? 'bg-indigo-600 text-white border-indigo-600 shadow-xs'
                    : 'bg-slate-50 dark:bg-slate-900 text-slate-600 dark:text-slate-300 border-slate-200 dark:border-slate-700 hover:bg-slate-100'
                ]"
              >
                +3 Days
              </button>
              <button
                type="button"
                @click="setDeliveryPreset(7)"
                :class="[
                  'px-2.5 py-1 text-[11px] font-bold rounded-lg border transition cursor-pointer',
                  isDateSelected(7)
                    ? 'bg-indigo-600 text-white border-indigo-600 shadow-xs'
                    : 'bg-slate-50 dark:bg-slate-900 text-slate-600 dark:text-slate-300 border-slate-200 dark:border-slate-700 hover:bg-slate-100'
                ]"
              >
                +1 Week
              </button>
            </div>

            <!-- Custom DatePicker Component -->
            <DatePicker
              v-model="form.expected_delivery_date"
              placeholder="Select expected handover date..."
            />

            <!-- Stylish Formatted Date Display -->
            <p v-if="form.expected_delivery_date" class="text-xs font-semibold text-slate-700 dark:text-slate-300 flex items-center gap-1.5 pt-0.5">
              <span class="text-emerald-600 font-bold">✓ Handover Promise:</span>
              <span>{{ formatDeliveryDate(form.expected_delivery_date) }}</span>
            </p>
            <p v-else class="text-[11px] text-slate-400">
              Estimated handover date to customer. Printed on Job Card ticket & receipt.
            </p>
          </div>
        </div>
      </div>

      <!-- ───────────────────────────────────────────────────────────── -->
      <!-- 6. DEVICE PHOTO (Optional - Select from storage/disk, not camera) -->
      <!-- ───────────────────────────────────────────────────────────── -->
      <div class="bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200/80 dark:border-slate-700/80 shadow-xs space-y-4">
        <div class="border-b border-slate-100 dark:border-slate-700 pb-3 flex items-center justify-between">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-lg bg-sky-50 dark:bg-sky-950/40 text-sky-600 dark:text-sky-400 flex items-center justify-center font-bold">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
            </div>
            <div>
              <h3 class="font-bold text-slate-900 dark:text-white text-sm">Device Photo <span class="text-xs font-normal text-slate-400">(Optional)</span></h3>
              <p class="text-[11px] text-slate-400">Attach device intake/condition photo from computer storage (Proof of physical condition)</p>
            </div>
          </div>
          <span v-if="photoPreview" class="text-[11px] font-bold text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/40 px-2.5 py-0.5 rounded-full border border-emerald-200 dark:border-emerald-800">
            ✓ Photo Attached
          </span>
        </div>

        <!-- Hidden Native File Input (Select from file storage/disk) -->
        <input
          ref="photoInputRef"
          type="file"
          accept="image/*"
          @change="handlePhotoUpload"
          class="hidden"
        />

        <!-- Preview State when a photo is attached/loaded -->
        <div v-if="photoPreview" class="max-w-md mx-auto space-y-2">
          <div class="relative group overflow-hidden rounded-2xl border-2 border-slate-200 dark:border-slate-700 bg-slate-900/5 aspect-video sm:aspect-4/3 flex items-center justify-center shadow-xs">
            <img
              :src="photoPreview"
              alt="Device Condition Photo"
              class="w-full h-full object-contain rounded-2xl"
            />
            <div class="absolute inset-0 bg-slate-900/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-3">
              <button
                type="button"
                @click="triggerPhotoSelect"
                class="px-3.5 py-1.5 rounded-xl bg-white text-slate-800 text-xs font-bold shadow-md hover:bg-slate-100 cursor-pointer transition flex items-center gap-1.5"
              >
                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"/></svg>
                Change Photo
              </button>
              <button
                type="button"
                @click="removePhoto"
                class="px-3.5 py-1.5 rounded-xl bg-rose-600 text-white text-xs font-bold shadow-md hover:bg-rose-700 cursor-pointer transition flex items-center gap-1.5"
              >
                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                Remove
              </button>
            </div>
          </div>
          <div class="flex items-center justify-between text-xs text-slate-500 px-1">
            <span class="text-[11px] text-slate-400">Selected device condition photo</span>
            <div class="flex items-center gap-2">
              <button type="button" @click="triggerPhotoSelect" class="text-sky-600 hover:text-sky-700 font-semibold hover:underline text-xs cursor-pointer">
                Choose Different File
              </button>
              <span class="text-slate-300">|</span>
              <button type="button" @click="removePhoto" class="text-rose-500 hover:text-rose-600 font-semibold hover:underline text-xs cursor-pointer">
                Remove Photo
              </button>
            </div>
          </div>
        </div>

        <!-- Empty State Dropzone: Pick File from Storage -->
        <div
          v-else
          @click="triggerPhotoSelect"
          class="p-6 border-2 border-dashed border-slate-300 dark:border-slate-700 hover:border-sky-500 dark:hover:border-sky-400 rounded-2xl bg-slate-50/50 dark:bg-slate-900/30 text-center cursor-pointer transition hover:bg-sky-50/30 dark:hover:bg-sky-950/20 group"
        >
          <div class="w-12 h-12 rounded-2xl bg-sky-100 dark:bg-sky-950/60 text-sky-600 dark:text-sky-400 flex items-center justify-center mx-auto mb-2.5 group-hover:scale-110 transition">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
          </div>
          <p class="text-xs font-bold text-slate-700 dark:text-slate-200 group-hover:text-sky-600 transition">
            Click to Select Device Photo from Storage / Disk
          </p>
          <p class="text-[11px] text-slate-400 mt-0.5">
            Select an image file from your computer (JPG, PNG, WEBP, up to 10MB)
          </p>
        </div>
      </div>

      <!-- ───────────────────────────────────────────────────────────── -->
      <!-- 7. PRICING & ADVANCE PAYMENT -->
      <!-- ───────────────────────────────────────────────────────────── -->
      <div class="bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200/80 dark:border-slate-700/80 shadow-xs space-y-4">
        <div class="border-b border-slate-100 dark:border-slate-700 pb-3 flex items-center justify-between">
          <div>
            <h3 class="font-bold text-slate-900 dark:text-white text-sm">Pricing & Advance Settlement</h3>
            <p class="text-[11px] text-slate-400">Estimated repair bill and initial advance received</p>
          </div>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div>
            <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
              Estimated / Final Bill (₹) (Optional)
            </label>
            <input
              v-model.number="form.estimated_cost"
              type="number"
              step="0.01"
              min="0"
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-sm font-bold text-slate-900 dark:text-white focus:ring-2 focus:ring-indigo-500"
            />
          </div>

          <div v-if="!isEdit">
            <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
              Advance Paid Now (₹)
            </label>
            <input
              v-model.number="form.payment_amount"
              type="number"
              step="0.01"
              min="0"
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-sm font-bold text-emerald-600 focus:ring-2 focus:ring-emerald-500"
            />
          </div>

          <div v-if="!isEdit">
            <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">Payment Method</label>
            <SearchableSelect
              v-model="form.payment_method"
              :options="paymentMethodOptions"
              placeholder="Select Method"
              minWidth="100%"
            />
          </div>
        </div>

        <!-- Live Pending Balance Due Banner -->
        <div v-if="!isEdit && (Number(form.estimated_cost) || 0) > 0" class="p-3 bg-slate-50 dark:bg-slate-900/60 rounded-xl border border-slate-200/80 dark:border-slate-800 flex items-center justify-between text-xs">
          <span class="text-slate-500">Pending Balance Due at Delivery:</span>
          <span class="font-extrabold text-sm" :class="((Number(form.estimated_cost) || 0) - (Number(form.payment_amount) || 0)) > 0 ? 'text-amber-600' : 'text-emerald-600'">
            ₹{{ formatAmount(Math.max(0, (Number(form.estimated_cost) || 0) - (Number(form.payment_amount) || 0))) }}
          </span>
        </div>
      </div>

      <!-- ───────────────────────────────────────────────────────────── -->
      <!-- 8. ADDITIONAL NOTES (Customer Notes & Internal Shop Notes) -->
      <!-- ───────────────────────────────────────────────────────────── -->
      <div class="bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200/80 dark:border-slate-700/80 shadow-xs space-y-4">
        <div class="border-b border-slate-100 dark:border-slate-700 pb-3 flex items-center justify-between">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-lg bg-teal-50 dark:bg-teal-950/40 text-teal-600 dark:text-teal-400 flex items-center justify-center font-bold">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
            </div>
            <div>
              <h3 class="font-bold text-slate-900 dark:text-white text-sm">Additional Notes <span class="text-xs font-normal text-slate-400">(Optional)</span></h3>
              <p class="text-[11px] text-slate-400">Customer communication notes and private internal technician logs</p>
            </div>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <!-- Customer Notes -->
          <div>
            <div class="flex items-center justify-between mb-1">
              <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300">
                Customer Notes (Visible on Job Card & Bill)
              </label>
              <span class="text-[10px] text-teal-600 dark:text-teal-400 font-bold bg-teal-50 dark:bg-teal-950/40 px-1.5 py-0.5 rounded">Public</span>
            </div>
            <textarea
              v-model="form.customer_notes"
              rows="3"
              placeholder="Special customer requests, instructions, or delivery notes printed on job card..."
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs text-slate-800 dark:text-slate-200 placeholder-slate-400 focus:ring-2 focus:ring-teal-500"
            ></textarea>
            <p class="text-[10px] text-slate-400 mt-1">
              Printed on customer job card receipt and visible to customer.
            </p>
          </div>

          <!-- Internal Technician Notes -->
          <div>
            <div class="flex items-center justify-between mb-1">
              <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300">
                Internal Technician Notes (Shop Only)
              </label>
              <span class="text-[10px] text-rose-500 font-bold bg-rose-50 dark:bg-rose-950/40 px-1.5 py-0.5 rounded">Private</span>
            </div>
            <textarea
              v-model="form.internal_notes"
              rows="3"
              placeholder="Bench notes, suspected IC faults, parts remarks, technician handover log..."
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs text-slate-800 dark:text-slate-200 placeholder-slate-400 focus:ring-2 focus:ring-rose-500"
            ></textarea>
            <p class="text-[10px] text-slate-400 mt-1">
              Confidential for internal shop team only. Never shown on customer receipts.
            </p>
          </div>
        </div>
      </div>

      <!-- ───────────────────────────────────────────────────────────── -->
      <!-- 7. WARRANTY CERTIFICATE (On Create) -->
      <!-- ───────────────────────────────────────────────────────────── -->
      <div v-if="!isEdit" class="bg-gradient-to-r from-emerald-50 to-teal-50 dark:from-emerald-950/30 dark:to-teal-950/30 rounded-2xl p-5 border border-emerald-200 dark:border-emerald-800/50 space-y-3">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2">
            <input
              v-model="addWarranty"
              id="warranty-chk"
              type="checkbox"
              class="w-4 h-4 rounded text-emerald-600 focus:ring-emerald-500 cursor-pointer"
            />
            <label for="warranty-chk" class="text-xs font-bold text-emerald-900 dark:text-emerald-200 cursor-pointer">
              Provide Repair Warranty Certificate on this Job Card
            </label>
          </div>
        </div>

        <div v-if="addWarranty" class="grid grid-cols-1 md:grid-cols-2 gap-4 pt-2">
          <div>
            <label class="block text-[11px] font-semibold text-slate-700 dark:text-slate-300 mb-1">Warranty Duration</label>
            <select
              v-model="warrantyDuration"
              class="w-full px-3.5 py-2 rounded-xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-xs font-semibold cursor-pointer"
            >
              <option :value="7">7 Days</option>
              <option :value="15">15 Days</option>
              <option :value="30">30 Days (1 Month)</option>
              <option :value="90">90 Days (3 Months)</option>
              <option :value="180">180 Days (6 Months)</option>
              <option :value="365">365 Days (1 Year)</option>
              <option value="custom">Custom Days</option>
            </select>
            <div v-if="warrantyDuration === 'custom'" class="mt-2 relative">
              <input
                type="number"
                v-model.number="customWarrantyDuration"
                min="1"
                max="3650"
                placeholder="Enter days (e.g. 45)"
                class="w-full pl-3.5 pr-12 py-2 rounded-xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-xs font-semibold text-slate-900 dark:text-white"
              />
              <span class="absolute right-3.5 top-2 text-[11px] font-semibold text-slate-400">Days</span>
            </div>
          </div>
          <div>
            <div class="flex items-center justify-between mb-1">
              <label class="block text-[11px] font-semibold text-slate-700 dark:text-slate-300">Warranty Terms Note</label>
              <span class="text-[10px] text-slate-400 font-medium">Click to auto-fill:</span>
            </div>
            <!-- Quick preset chips -->
            <div class="flex flex-wrap gap-1.5 mb-2">
              <button
                type="button"
                v-for="preset in warrantyPresets"
                :key="preset.label"
                @click="warrantyTerms = preset.text"
                class="px-2 py-0.5 rounded-lg text-[10px] font-semibold border transition cursor-pointer"
                :class="warrantyTerms === preset.text
                  ? 'bg-emerald-600 text-white border-emerald-600 shadow-xs'
                  : 'bg-emerald-50/70 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 border-emerald-200/60 dark:border-emerald-800/60 hover:bg-emerald-100 dark:hover:bg-emerald-900/50'"
              >
                {{ preset.label }}
              </button>
            </div>
            <input
              v-model="warrantyTerms"
              type="text"
              placeholder="e.g. Touch replacement covered. Physical/liquid damage void."
              class="w-full px-3.5 py-2 rounded-xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-xs"
            />
          </div>
        </div>
      </div>
      </fieldset>

      <!-- Submit Footer -->
      <div class="flex items-center justify-end gap-3 pt-4">
        <router-link :to="isEdit ? `/repairs/${route.params.id}` : '/repairs'" class="px-5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 text-xs font-semibold hover:bg-slate-50 cursor-pointer">
          {{ isDelivered ? 'Back to Job Card' : 'Cancel' }}
        </router-link>
        <button
          v-if="!isDelivered"
          type="submit"
          :disabled="submitting || isDelivered"
          class="px-6 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white text-xs font-bold shadow-lg shadow-indigo-500/20 cursor-pointer transition hover:scale-[1.02]"
        >
          {{ submitting ? 'Saving...' : (isEdit ? 'Update Repair Job' : 'Save & Create Job Card') }}
        </button>
        <div v-else class="px-4 py-2 rounded-xl bg-slate-100 dark:bg-slate-700 text-slate-500 dark:text-slate-300 text-xs font-bold flex items-center gap-2">
          <span>🔒 Order Finalized (Changes Frozen)</span>
        </div>
      </div>
    </form>

    <!-- ───────────────────────────────────────────────────────────── -->
    <!-- MODAL 1: SEARCH & SELECT CUSTOMER MODAL -->
    <!-- ───────────────────────────────────────────────────────────── -->
    <div
      v-if="showCustomerSearchModal"
      class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-5 bg-slate-900/60 backdrop-blur-xs"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-slate-800 rounded-3xl max-w-lg w-full p-6 shadow-2xl border border-slate-200 dark:border-slate-700 space-y-4 animate-in fade-in zoom-in-95 duration-150 max-h-[85vh] flex flex-col overflow-hidden">
        <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3 shrink-0">
          <div>
            <h3 class="font-bold text-slate-900 dark:text-white text-base">Select Customer</h3>
            <p class="text-xs text-slate-400">Search existing customer or add a new one</p>
          </div>
          <div class="flex items-center gap-2">
            <button
              type="button"
              @click="openQuickCustomerModalFromSearch"
              class="text-xs font-bold text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 flex items-center gap-1 bg-indigo-50 dark:bg-indigo-950/40 px-2.5 py-1 rounded-xl border border-indigo-200 dark:border-indigo-800 cursor-pointer"
            >
              + Add Customer
            </button>
            <button @click="showCustomerSearchModal = false" class="text-slate-400 hover:text-slate-600 text-lg cursor-pointer">✕</button>
          </div>
        </div>

        <!-- Search Input -->
        <div class="relative">
          <svg class="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
          <input
            v-model="customerSearchQuery"
            type="text"
            autofocus
            placeholder="Search by customer name, mobile number, or city..."
            class="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-semibold focus:ring-2 focus:ring-indigo-500"
          />
        </div>

        <!-- Customer List -->
        <div class="divide-y divide-slate-100 dark:divide-slate-700/60 max-h-72 overflow-y-auto">
          <div
            v-if="filteredCustomers.length === 0"
            class="py-8 text-center text-xs text-slate-400"
          >
            No matching customers found.
            <button
              type="button"
              @click="openQuickCustomerModalFromSearch"
              class="block mx-auto mt-2 text-xs font-bold text-indigo-600 hover:underline cursor-pointer"
            >
              + Register "{{ customerSearchQuery }}" as new customer
            </button>
          </div>

          <div
            v-for="c in filteredCustomers"
            :key="c.id"
            @click="selectCustomer(c)"
            class="p-3 hover:bg-indigo-50/70 dark:hover:bg-indigo-950/40 cursor-pointer flex items-center justify-between transition group"
          >
            <div class="flex items-center gap-2.5">
              <div class="w-8 h-8 rounded-xl bg-indigo-100 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 flex items-center justify-center font-bold text-xs">
                {{ (c.name || 'C')[0] }}
              </div>
              <div>
                <p class="font-bold text-slate-900 dark:text-white text-xs group-hover:text-indigo-600">{{ c.name }}</p>
                <p class="text-[11px] font-mono text-slate-400">{{ c.phone || c.mobile }} {{ c.city ? '• ' + c.city : '' }}</p>
              </div>
            </div>
            <span class="text-[10px] font-bold text-indigo-600 bg-indigo-50 dark:bg-indigo-950/60 px-2 py-1 rounded-lg border border-indigo-200 dark:border-indigo-800">
              Select
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- ───────────────────────────────────────────────────────────── -->
    <!-- MODAL 2: QUICK ADD CUSTOMER MODAL -->
    <!-- ───────────────────────────────────────────────────────────── -->
    <div
      v-if="showQuickCustomerModal"
      class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-5 bg-slate-900/60 backdrop-blur-xs"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-slate-800 rounded-3xl max-w-md w-full p-6 shadow-2xl border border-slate-200 dark:border-slate-700 space-y-4 animate-in fade-in zoom-in-95 duration-150 max-h-[85vh] flex flex-col overflow-hidden">
        <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3 shrink-0">
          <h3 class="font-bold text-slate-900 dark:text-white text-base">+ Quick Add Customer</h3>
          <button @click="showQuickCustomerModal = false" class="text-slate-400 hover:text-slate-600 cursor-pointer">✕</button>
        </div>

        <form @submit.prevent="submitQuickCustomer" class="space-y-4 text-xs overflow-y-auto custom-scroll flex-1 pr-1">
          <div>
            <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">
              Customer Name <span class="text-rose-500">*</span>
            </label>
            <input
              v-model="quickCustomerForm.name"
              type="text"
              required
              placeholder="e.g. Ramesh Patel"
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-semibold"
            />
          </div>
          <div>
            <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">
              Mobile Number <span class="text-rose-500">*</span>
            </label>
            <input
              v-model="quickCustomerForm.phone"
              type="tel"
              required
              placeholder="10-digit mobile"
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-mono font-semibold"
            />
          </div>
          <div>
            <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">City / Area</label>
            <input
              v-model="quickCustomerForm.city"
              type="text"
              placeholder="e.g. Surat, Mumbai"
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs"
            />
          </div>
          <div class="flex items-center justify-end gap-2 pt-2">
            <button
              type="button"
              @click="showQuickCustomerModal = false"
              class="px-4 py-2 rounded-xl border border-slate-200 text-slate-600 font-semibold cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="quickCustomerSubmitting"
              class="px-5 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold cursor-pointer"
            >
              {{ quickCustomerSubmitting ? 'Saving...' : 'Save & Select' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- ───────────────────────────────────────────────────────────── -->
    <!-- MODAL 3: QUICK ADD DEVICE MODAL (For Customer - Dual Mode Catalog vs Manual) -->
    <!-- ───────────────────────────────────────────────────────────── -->
    <div
      v-if="showQuickDeviceModal"
      class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-5 bg-slate-900/60 backdrop-blur-xs"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-slate-800 rounded-3xl max-w-lg w-full p-6 shadow-2xl border border-slate-200 dark:border-slate-700 space-y-4 animate-in fade-in zoom-in-95 duration-150 max-h-[85vh] flex flex-col overflow-hidden">
        <!-- Modal Header -->
        <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3 shrink-0">
          <div class="flex items-center gap-2.5">
            <div class="w-9 h-9 rounded-xl bg-purple-100 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400 flex items-center justify-center font-bold text-base shadow-xs">
              📱
            </div>
            <div>
              <h3 class="font-bold text-slate-900 dark:text-white text-base">Quick Add Device</h3>
              <p class="text-xs text-purple-600 dark:text-purple-400 font-semibold">
                For Customer: {{ selectedCustomer?.name || 'Selected Customer' }}
              </p>
            </div>
          </div>
          <button @click="showQuickDeviceModal = false" class="text-slate-400 hover:text-slate-600 text-lg cursor-pointer">✕</button>
        </div>

        <form @submit.prevent="submitQuickDevice" class="space-y-4 text-xs overflow-y-auto custom-scroll flex-1 pr-1">
          <!-- Device Category Chips -->
          <div>
            <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
              Device Category <span class="text-rose-500">*</span>
            </label>
            <div class="flex flex-wrap gap-1.5">
              <button
                type="button"
                v-for="cat in ['Mobile', 'Tablet', 'Laptop', 'Watch', 'Other']"
                :key="cat"
                @click="quickDeviceForm.device_type = cat"
                :class="[
                  'px-3 py-1.5 rounded-xl text-xs font-bold border transition cursor-pointer',
                  quickDeviceForm.device_type === cat
                    ? 'bg-purple-600 text-white border-purple-600 shadow-xs'
                    : 'bg-slate-50 dark:bg-slate-900 text-slate-600 dark:text-slate-300 border-slate-200 dark:border-slate-700 hover:bg-slate-100'
                ]"
              >
                {{ cat }}
              </button>
            </div>
          </div>

          <!-- Dual Entry Mode Toggle Header (Matching App's Catalog vs Manual Toggle) -->
          <div class="flex items-center justify-between p-2.5 bg-slate-50 dark:bg-slate-900/60 rounded-xl border border-slate-200/80 dark:border-slate-700/80">
            <div class="flex items-center gap-2">
              <span class="w-2 h-2 rounded-full" :class="isDeviceManualEntry ? 'bg-amber-500' : 'bg-purple-600'"></span>
              <span class="font-bold text-slate-800 dark:text-slate-200 text-xs">
                {{ isDeviceManualEntry ? 'Manual Specifications' : 'Catalog Specifications' }}
              </span>
            </div>
            <button
              type="button"
              @click="toggleDeviceEntryMode"
              class="inline-flex items-center gap-1.5 px-3 py-1 rounded-lg text-xs font-bold text-purple-600 dark:text-purple-400 bg-purple-50 dark:bg-purple-950/50 hover:bg-purple-100 dark:hover:bg-purple-900/50 transition cursor-pointer border border-purple-200/60 dark:border-purple-800/60"
            >
              <svg v-if="!isDeviceManualEntry" class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
              <svg v-else class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/></svg>
              {{ isDeviceManualEntry ? 'Use Catalog' : 'Enter Manually' }}
            </button>
          </div>

          <!-- MODE 1: CATALOG SPECIFICATIONS (DROPDOWN / CATALOG SELECT) -->
          <div v-if="!isDeviceManualEntry" class="space-y-3.5">
            <!-- Brand Selection -->
            <div>
              <div class="flex items-center justify-between mb-1">
                <label class="block font-semibold text-slate-700 dark:text-slate-300">
                  Mobile Brand <span class="text-rose-500">*</span>
                </label>
                <span v-if="catalogBrands.length > 0" class="text-[10px] text-slate-400">
                  {{ catalogBrands.length }} brands available
                </span>
              </div>

              <!-- Quick Popular Brand Pills (User can click one to instantly pick) -->
              <div class="flex flex-wrap gap-1.5 mb-2">
                <button
                  type="button"
                  v-for="b in ['Samsung', 'Vivo', 'Oppo', 'Realme', 'OnePlus', 'Xiaomi', 'Motorola']"
                  :key="b"
                  @click="selectCatalogBrand(b)"
                  :class="[
                    'px-2.5 py-1 rounded-lg text-[11px] font-bold border transition cursor-pointer',
                    quickDeviceForm.brand && quickDeviceForm.brand.toLowerCase() === b.toLowerCase()
                      ? 'bg-purple-600 text-white border-purple-600 shadow-xs'
                      : 'bg-slate-50 dark:bg-slate-900 text-slate-600 dark:text-slate-300 border-slate-200 dark:border-slate-700 hover:bg-slate-100 dark:hover:bg-slate-800'
                  ]"
                >
                  {{ b }}
                </button>
              </div>

              <!-- Stylish Searchable Brand Dropdown -->
              <div class="relative">
                <button
                  type="button"
                  @click="isBrandDropdownOpen = !isBrandDropdownOpen; if (isBrandDropdownOpen) isModelDropdownOpen = false"
                  class="w-full px-3.5 py-2.5 rounded-xl border bg-slate-50 dark:bg-slate-900 text-xs font-semibold flex items-center justify-between transition cursor-pointer"
                  :class="isBrandDropdownOpen ? 'border-purple-500 ring-2 ring-purple-500/20' : 'border-slate-200 dark:border-slate-700 hover:border-slate-300'"
                >
                  <span :class="quickDeviceForm.brand ? 'text-slate-900 dark:text-white font-bold' : 'text-slate-400'">
                    {{ quickDeviceForm.brand ? quickDeviceForm.brand : '-- Select Mobile Brand --' }}
                  </span>
                  <svg
                    class="w-4 h-4 text-slate-400 transition-transform duration-200"
                    :class="{ 'rotate-180 text-purple-600': isBrandDropdownOpen }"
                    fill="none" stroke="currentColor" viewBox="0 0 24 24"
                  >
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                  </svg>
                </button>

                <!-- Invisible Backdrop to close dropdown -->
                <div v-if="isBrandDropdownOpen" @click="isBrandDropdownOpen = false" class="fixed inset-0 z-20"></div>

                <!-- Dropdown Menu -->
                <div
                  v-if="isBrandDropdownOpen"
                  class="absolute left-0 right-0 top-full mt-1.5 z-30 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-2xl shadow-xl p-2.5 space-y-2 animate-in fade-in zoom-in-95 duration-100"
                >
                  <div class="relative">
                    <svg class="w-3.5 h-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                    </svg>
                    <input
                      v-model="brandSearchQuery"
                      type="text"
                      placeholder="Search brand (e.g. Samsung, Vivo, Oppo)..."
                      class="w-full pl-9 pr-7 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-950 text-xs text-slate-800 dark:text-slate-100 placeholder-slate-400 focus:outline-none focus:ring-1 focus:ring-purple-500"
                      @click.stop
                    />
                    <button
                      v-if="brandSearchQuery"
                      @click.stop="brandSearchQuery = ''"
                      type="button"
                      class="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 text-xs"
                    >
                      ✕
                    </button>
                  </div>

                  <div class="max-h-48 overflow-y-auto space-y-0.5 pr-1">
                    <div
                      v-for="b in filteredCatalogBrands"
                      :key="b"
                      @click="selectCatalogBrand(b)"
                      class="px-3 py-2 rounded-lg text-xs font-semibold cursor-pointer transition flex items-center justify-between"
                      :class="quickDeviceForm.brand && quickDeviceForm.brand.toLowerCase() === b.toLowerCase() ? 'bg-purple-50 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400 font-bold' : 'text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800'"
                    >
                      <span>{{ b }}</span>
                      <svg
                        v-if="quickDeviceForm.brand && quickDeviceForm.brand.toLowerCase() === b.toLowerCase()"
                        class="w-3.5 h-3.5 text-purple-600 dark:text-purple-400"
                        fill="none" stroke="currentColor" viewBox="0 0 24 24"
                      >
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7" />
                      </svg>
                    </div>

                    <div v-if="filteredCatalogBrands.length === 0" class="py-4 text-center text-xs text-slate-400">
                      No brands found matching "{{ brandSearchQuery }}"
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Model Selection -->
            <div>
              <div class="flex items-center justify-between mb-1">
                <label class="block font-semibold text-slate-700 dark:text-slate-300">
                  Device Model <span class="text-rose-500">*</span>
                </label>
                <span v-if="catalogModels.length > 0" class="text-[10px] text-purple-600 dark:text-purple-400 font-bold bg-purple-50 dark:bg-purple-950/60 px-2 py-0.5 rounded-full border border-purple-200/60 dark:border-purple-800/60">
                  {{ catalogModels.length }} models found
                </span>
              </div>

              <!-- State A: No Brand Selected -->
              <div
                v-if="!quickDeviceForm.brand"
                class="p-3 bg-slate-50 dark:bg-slate-900 rounded-xl border border-dashed border-slate-200 dark:border-slate-700 flex items-center gap-2 text-slate-400 text-xs"
              >
                <svg class="w-4 h-4 text-slate-400 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                <span>Select a mobile brand above to choose from available models.</span>
              </div>

              <!-- State B: Loading Models -->
              <div
                v-else-if="loadingCatalogModels"
                class="p-3 bg-purple-50/50 dark:bg-purple-950/20 rounded-xl border border-purple-100 dark:border-purple-900/40 flex items-center gap-2 text-purple-600 dark:text-purple-400 text-xs"
              >
                <div class="w-4 h-4 border-2 border-purple-600 border-t-transparent rounded-full animate-spin"></div>
                <span>Loading {{ quickDeviceForm.brand }} models catalog...</span>
              </div>

              <!-- State C: Models Loaded -> Proper Stylish Searchable Dropdown -->
              <div v-else class="space-y-1.5">
                <div class="relative">
                  <!-- Dropdown Trigger Button -->
                  <button
                    type="button"
                    @click="isModelDropdownOpen = !isModelDropdownOpen; if (isModelDropdownOpen) isBrandDropdownOpen = false"
                    class="w-full px-3.5 py-2.5 rounded-xl border bg-slate-50 dark:bg-slate-900 text-xs font-semibold flex items-center justify-between transition cursor-pointer"
                    :class="isModelDropdownOpen ? 'border-purple-500 ring-2 ring-purple-500/20' : 'border-slate-200 dark:border-slate-700 hover:border-slate-300'"
                  >
                    <span :class="quickDeviceForm.model ? 'text-slate-900 dark:text-white font-bold' : 'text-slate-400'">
                      {{ quickDeviceForm.model ? quickDeviceForm.model : ('-- Select ' + quickDeviceForm.brand + ' Model (' + catalogModels.length + ' available) --') }}
                    </span>
                    <svg
                      class="w-4 h-4 text-slate-400 transition-transform duration-200"
                      :class="{ 'rotate-180 text-purple-600': isModelDropdownOpen }"
                      fill="none" stroke="currentColor" viewBox="0 0 24 24"
                    >
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                    </svg>
                  </button>

                  <!-- Invisible Backdrop to close dropdown -->
                  <div v-if="isModelDropdownOpen" @click="isModelDropdownOpen = false" class="fixed inset-0 z-20"></div>

                  <!-- Dropdown Menu -->
                  <div
                    v-if="isModelDropdownOpen"
                    class="absolute left-0 right-0 top-full mt-1.5 z-30 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-2xl shadow-xl p-2.5 space-y-2 animate-in fade-in zoom-in-95 duration-100"
                  >
                    <!-- Search input inside dropdown -->
                    <div class="relative">
                      <svg class="w-3.5 h-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                      </svg>
                      <input
                        v-model="modelSearchQuery"
                        type="text"
                        placeholder="Search model (e.g. S21, Reno, Note, A15)..."
                        class="w-full pl-9 pr-7 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-950 text-xs text-slate-800 dark:text-slate-100 placeholder-slate-400 focus:outline-none focus:ring-1 focus:ring-purple-500"
                        @click.stop
                      />
                      <button
                        v-if="modelSearchQuery"
                        @click.stop="modelSearchQuery = ''"
                        type="button"
                        class="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 text-xs"
                      >
                        ✕
                      </button>
                    </div>

                    <!-- Scrollable List of Models -->
                    <div class="max-h-52 overflow-y-auto space-y-0.5 pr-1">
                      <div
                        v-for="m in filteredCatalogModels"
                        :key="m"
                        @click="selectCatalogModel(m)"
                        class="px-3 py-2 rounded-lg text-xs font-semibold cursor-pointer transition flex items-center justify-between"
                        :class="quickDeviceForm.model === m ? 'bg-purple-50 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400 font-bold' : 'text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800'"
                      >
                        <span class="truncate">{{ m }}</span>
                        <svg
                          v-if="quickDeviceForm.model === m"
                          class="w-3.5 h-3.5 text-purple-600 dark:text-purple-400 shrink-0 ml-2"
                          fill="none" stroke="currentColor" viewBox="0 0 24 24"
                        >
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7" />
                        </svg>
                      </div>

                      <div v-if="filteredCatalogModels.length === 0" class="py-4 text-center text-xs text-slate-400 space-y-1">
                        <p>No model found matching "{{ modelSearchQuery }}".</p>
                        <button
                          type="button"
                          @click="quickDeviceForm.model = modelSearchQuery; isModelDropdownOpen = false"
                          class="text-purple-600 font-bold hover:underline"
                        >
                          Use "{{ modelSearchQuery }}" as Custom Model →
                        </button>
                      </div>
                    </div>
                  </div>
                </div>

                <div class="flex items-center justify-between text-[11px] text-slate-400 pt-0.5">
                  <span>Model not listed in catalog?</span>
                  <button
                    type="button"
                    @click="isDeviceManualEntry = true"
                    class="text-purple-600 dark:text-purple-400 font-bold hover:underline cursor-pointer"
                  >
                    Enter Manually
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- MODE 2: MANUAL SPECIFICATIONS (TEXT ENTRY) -->
          <div v-else class="space-y-3.5">
            <!-- Brand -->
            <div>
              <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">
                Device Brand <span class="text-rose-500">*</span>
              </label>
              <div class="flex flex-wrap gap-1.5 mb-2">
                <button
                  type="button"
                  v-for="b in ['Samsung', 'Vivo', 'Oppo', 'Realme', 'OnePlus', 'Xiaomi', 'Motorola']"
                  :key="b"
                  @click="quickDeviceForm.brand = b"
                  :class="[
                    'px-2.5 py-1 rounded-lg text-[11px] font-bold border transition cursor-pointer',
                    quickDeviceForm.brand.toLowerCase() === b.toLowerCase()
                      ? 'bg-purple-600 text-white border-purple-600'
                      : 'bg-slate-50 dark:bg-slate-900 text-slate-600 dark:text-slate-300 border-slate-200 dark:border-slate-700 hover:bg-slate-100'
                  ]"
                >
                  {{ b }}
                </button>
              </div>
              <input
                v-model="quickDeviceForm.brand"
                type="text"
                required
                placeholder="e.g. Samsung, Vivo, OnePlus"
                class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-semibold focus:ring-2 focus:ring-purple-500"
              />
            </div>

            <!-- Model -->
            <div>
              <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">
                Device Model Name / Number <span class="text-rose-500">*</span>
              </label>
              <input
                v-model="quickDeviceForm.model"
                type="text"
                required
                placeholder="e.g. Galaxy S21 / iPhone 13 Pro"
                class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-semibold focus:ring-2 focus:ring-purple-500"
              />
            </div>
          </div>

          <!-- COMMON FIELDS -->
          <!-- IMEI 1 / Serial -->
          <div>
            <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">
              IMEI / Serial Number (Optional)
            </label>
            <input
              v-model="quickDeviceForm.imei1"
              type="text"
              maxlength="18"
              placeholder="e.g. 864201948102931 (15 numeric digits)"
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-mono focus:ring-2 focus:ring-purple-500"
            />
          </div>

          <!-- Color / Variant -->
          <div>
            <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">
              Color / Variant (Optional)
            </label>
            <input
              v-model="quickDeviceForm.color"
              type="text"
              placeholder="e.g. Phantom Black, 128GB"
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs focus:ring-2 focus:ring-purple-500"
            />
          </div>

          <!-- Actions -->
          <div class="flex items-center justify-end gap-2 pt-2 border-t border-slate-100 dark:border-slate-700 shrink-0">
            <button
              type="button"
              @click="showQuickDeviceModal = false"
              class="px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 font-semibold cursor-pointer hover:bg-slate-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="quickDeviceSubmitting"
              class="px-5 py-2 rounded-xl bg-purple-600 hover:bg-purple-700 text-white font-bold cursor-pointer transition shadow-xs disabled:opacity-60"
            >
              {{ quickDeviceSubmitting ? 'Registering...' : 'Save & Select Device' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- ───────────────────────────────────────────────────────────── -->
    <!-- MODAL 4: SEARCH & SELECT TECHNICIAN MODAL -->
    <!-- ───────────────────────────────────────────────────────────── -->
    <div
      v-if="showTechnicianSearchModal"
      class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-5 bg-slate-900/60 backdrop-blur-xs"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-slate-800 rounded-3xl max-w-lg w-full p-6 shadow-2xl border border-slate-200 dark:border-slate-700 space-y-4 animate-in fade-in zoom-in-95 duration-150 max-h-[85vh] flex flex-col overflow-hidden">
        <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3 shrink-0">
          <div>
            <h3 class="font-bold text-slate-900 dark:text-white text-base">Select Technician</h3>
            <p class="text-xs text-slate-400">Choose technician to perform repair</p>
          </div>
          <div class="flex items-center gap-2">
            <button
              type="button"
              @click="openQuickTechModalFromSearch"
              class="text-xs font-bold text-blue-600 dark:text-blue-400 hover:text-blue-700 flex items-center gap-1 bg-blue-50 dark:bg-blue-950/40 px-2.5 py-1 rounded-xl border border-blue-200 dark:border-blue-800 cursor-pointer"
            >
              + Add Technician
            </button>
            <button @click="showTechnicianSearchModal = false" class="text-slate-400 hover:text-slate-600 text-lg cursor-pointer">✕</button>
          </div>
        </div>

        <!-- Search Input -->
        <div class="relative">
          <svg class="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
          <input
            v-model="technicianSearchQuery"
            type="text"
            autofocus
            placeholder="Search by technician name, specialization, or phone..."
            class="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-semibold focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <!-- Option: Unassigned -->
        <div
          @click="selectTechnician(null)"
          class="p-3 rounded-xl border border-dashed border-slate-300 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-900 cursor-pointer flex items-center justify-between transition"
        >
          <div class="flex items-center gap-2.5">
            <div class="w-7 h-7 rounded-lg bg-slate-200 dark:bg-slate-700 text-slate-600 dark:text-slate-300 flex items-center justify-center font-bold text-xs">
              ∅
            </div>
            <div>
              <p class="font-bold text-slate-700 dark:text-slate-300 text-xs">Unassigned / In-house</p>
              <p class="text-[10px] text-slate-400">Handle without assigning a technician</p>
            </div>
          </div>
          <span class="text-[10px] font-bold text-slate-500 bg-slate-100 dark:bg-slate-700 px-2 py-0.5 rounded-lg">Unassign</span>
        </div>

        <!-- Technicians List -->
        <div class="divide-y divide-slate-100 dark:divide-slate-700/60 max-h-72 overflow-y-auto">
          <div
            v-if="filteredTechnicians.length === 0"
            class="py-6 text-center text-xs text-slate-400"
          >
            No matching technicians found.
          </div>

          <div
            v-for="t in filteredTechnicians"
            :key="t.id"
            @click="selectTechnician(t)"
            class="p-3 hover:bg-blue-50/70 dark:hover:bg-blue-950/40 cursor-pointer flex items-center justify-between transition group"
          >
            <div class="flex items-center gap-2.5">
              <div class="w-8 h-8 rounded-xl bg-blue-100 dark:bg-blue-950/60 text-blue-600 dark:text-blue-400 flex items-center justify-center font-bold text-xs">
                {{ (t.name || 'T')[0] }}
              </div>
              <div>
                <p class="font-bold text-slate-900 dark:text-white text-xs group-hover:text-blue-600">{{ t.name }}</p>
                <p class="text-[11px] text-slate-400">
                  <span class="text-blue-600 font-semibold">{{ t.specialization || 'General Tech' }}</span>
                  <span v-if="t.phone || t.mobile" class="font-mono"> • {{ t.phone || t.mobile }}</span>
                </p>
              </div>
            </div>
            <span class="text-[10px] font-bold text-blue-600 bg-blue-50 dark:bg-blue-950/60 px-2 py-1 rounded-lg border border-blue-200 dark:border-blue-800">
              Assign
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- ───────────────────────────────────────────────────────────── -->
    <!-- MODAL 5: QUICK ADD TECHNICIAN MODAL -->
    <!-- ───────────────────────────────────────────────────────────── -->
    <div
      v-if="showQuickTechModal"
      class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-5 bg-slate-900/60 backdrop-blur-xs"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-slate-800 rounded-3xl max-w-md w-full p-6 shadow-2xl border border-slate-200 dark:border-slate-700 space-y-4 animate-in fade-in zoom-in-95 duration-150 max-h-[85vh] flex flex-col overflow-hidden">
        <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3 shrink-0">
          <h3 class="font-bold text-slate-900 dark:text-white text-base">+ Quick Add Technician</h3>
          <button @click="showQuickTechModal = false" class="text-slate-400 hover:text-slate-600 cursor-pointer">✕</button>
        </div>

        <form @submit.prevent="submitQuickTechnician" class="space-y-4 text-xs overflow-y-auto custom-scroll flex-1 pr-1">
          <div>
            <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">
              Technician Name <span class="text-rose-500">*</span>
            </label>
            <input
              v-model="quickTechForm.name"
              type="text"
              required
              placeholder="e.g. Jay Verma"
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-semibold"
            />
          </div>
          <div>
            <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">
              Mobile Number <span class="text-rose-500">*</span>
            </label>
            <input
              v-model="quickTechForm.mobile"
              type="tel"
              required
              placeholder="10-digit mobile"
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-mono font-semibold"
            />
          </div>
          <div>
            <label class="block font-semibold text-slate-700 dark:text-slate-300 mb-1">Specialization / Skill</label>
            <input
              v-model="quickTechForm.specialization"
              type="text"
              placeholder="e.g. Screen & Display, Motherboard, Software"
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs"
            />
          </div>
          <div class="flex items-center justify-end gap-2 pt-2 border-t border-slate-100 dark:border-slate-700 shrink-0">
            <button
              type="button"
              @click="showQuickTechModal = false"
              class="px-4 py-2 rounded-xl border border-slate-200 text-slate-600 font-semibold cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="quickTechSubmitting"
              class="px-5 py-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold cursor-pointer"
            >
              {{ quickTechSubmitting ? 'Saving...' : 'Save & Assign' }}
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
import { repairApi, customerApi, deviceApi, technicianApi, warrantyApi } from '@/api/endpoints';
import SearchableSelect from '@/components/common/SearchableSelect.vue';
import DatePicker from '@/components/common/DatePicker.vue';

const route = useRoute();
const router = useRouter();
const toast = useToastStore();

const paymentMethodOptions = [
  { value: 'cash', label: 'Cash', icon: '💵' },
  { value: 'upi', label: 'UPI / Scanner', icon: '⚡' },
  { value: 'card', label: 'Card / POS', icon: '💳' },
];

const isEdit = computed(() => !!route.params.id);
const repairNumber = ref('');
const repairStatus = ref('');
const isDelivered = computed(() => isEdit.value && (String(repairStatus.value).toLowerCase() === 'delivered'));
const submitting = ref(false);
const errorMsg = ref('');

// Lists
const customers = ref([]);
const technicians = ref([]);
const customerDevices = ref([]);
const loadingDevices = ref(false);

// Customer selection
const showCustomerSearchModal = ref(false);
const customerSearchQuery = ref('');
const selectedCustomer = ref(null);

// Device selection
const showQuickDeviceModal = ref(false);
const quickDeviceSubmitting = ref(false);
const deviceSearchQuery = ref('');
const selectedDevice = ref(null);

const quickDeviceForm = reactive({
  device_type: 'Mobile',
  brand: 'Samsung',
  model: '',
  imei1: '',
  color: '',
});

// Dual entry mode state (Catalog vs Manual) - Matching Flutter QuickAddDeviceModal
const isDeviceManualEntry = ref(false);
const catalogBrands = ref([
  'Samsung', 'Apple', 'Vivo', 'Oppo', 'Realme', 'OnePlus', 'Xiaomi', 'Motorola',
  'Google', 'Nothing', 'Nokia', 'Poco', 'Infinix', 'Tecno', 'Honor', 'Lenovo', 'Asus', 'Sony'
]);
const catalogModels = ref([]);
const loadingCatalogBrands = ref(false);
const loadingCatalogModels = ref(false);
const modelSearchQuery = ref('');

// Technician selection
const showTechnicianSearchModal = ref(false);
const technicianSearchQuery = ref('');
const selectedTechnician = ref(null);
const showQuickTechModal = ref(false);
const quickTechSubmitting = ref(false);

const quickTechForm = reactive({
  name: '',
  mobile: '',
  specialization: '',
});

// Conditions Checklist (From Flutter App)
const availableConditions = [
  'Screen damaged',
  'Body damaged',
  'Back glass damaged',
  'Camera damaged',
  'Water damage',
  'Power button issue',
  'Charging port issue',
  'Battery issue',
  'Speaker issue',
  'No network',
];
const selectedConditions = ref([]);

// Accessories Checklist (From Flutter App)
const availableAccessories = [
  'Charger',
  'Cable',
  'SIM',
  'Memory Card',
  'Cover',
  'Box',
  'Other',
];
const selectedAccessories = ref([]);

// Pattern Lock State & Helpers (Compatible with Mobile App PatternHelper)
const showPatternDrawer = ref(false);
const patternPoints = ref([]);

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

function getFormPatternStep(idx) {
  const i = patternPoints.value.indexOf(idx);
  return i !== -1 ? i + 1 : null;
}

const getFormSvgPolylinePoints = computed(() => {
  return patternPoints.value.map(p => `${getDotX(p)},${getDotY(p)}`).join(' ');
});

function addPatternPoint(idx) {
  // idx is 1..9
  if (!patternPoints.value.includes(idx)) {
    patternPoints.value.push(idx);
    form.pin_passcode = 'PATTERN: ' + patternPoints.value.join('-');
  }
}

function resetPattern() {
  patternPoints.value = [];
  form.pin_passcode = '';
}

// Delivery Date Helpers (Stylish Date Formatter & Presets)
function formatDeliveryDate(dateStr) {
  if (!dateStr) return '';
  try {
    const parts = dateStr.split('-');
    if (parts.length === 3) {
      const d = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
      return d.toLocaleDateString('en-IN', { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric' });
    }
    const d = new Date(dateStr);
    return d.toLocaleDateString('en-IN', { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric' });
  } catch {
    return dateStr;
  }
}

function getDeliveryBadge(dateStr) {
  if (!dateStr) return '';
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const parts = dateStr.split('-');
  let target;
  if (parts.length === 3) {
    target = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
  } else {
    target = new Date(dateStr);
  }
  target.setHours(0, 0, 0, 0);
  const diffDays = Math.round((target - today) / (1000 * 60 * 60 * 24));
  if (diffDays === 0) return 'Today';
  if (diffDays === 1) return 'Tomorrow';
  if (diffDays > 1) return `In ${diffDays} days`;
  if (diffDays === -1) return 'Yesterday';
  return `${Math.abs(diffDays)}d ago`;
}

function setDeliveryPreset(days) {
  const d = new Date();
  d.setDate(d.getDate() + days);
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  form.expected_delivery_date = `${year}-${month}-${day}`;
}

function isDateSelected(days) {
  const d = new Date();
  d.setDate(d.getDate() + days);
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return form.expected_delivery_date === `${year}-${month}-${day}`;
}

const warrantyPresets = [
  {
    label: 'Service Center Warranty',
    text: 'Official Brand Service Center Warranty. Customer can claim directly at authorized service center with invoice.',
  },
  {
    label: 'Shop Testing Warranty',
    text: 'Shop Testing Warranty. Covers hardware & manufacturing defects. Physical and liquid damage void.',
  },
  {
    label: 'Display & Touch Only',
    text: 'Covers screen and touch failure only. Glass crack, black spot, lines, drop or liquid damage strictly void.',
  },
  {
    label: 'Parts Replaced Only',
    text: 'Covers repair & replaced parts only. Physical damage, water ingress, or unauthorized opening voids warranty.',
  },
  {
    label: 'Full Device Warranty',
    text: 'Comprehensive device warranty covering internal components. Excludes physical drop and liquid exposure.',
  },
];

// Warranty On Create
const addWarranty = ref(false);
const warrantyDuration = ref(180);
const customWarrantyDuration = ref(30);
const warrantyTerms = ref('Covers screen & touch replacement. Water and physical damage void.');

// Quick Customer Modal
const showQuickCustomerModal = ref(false);
const quickCustomerSubmitting = ref(false);
const quickCustomerForm = reactive({
  name: '',
  phone: '',
  city: '',
});

// Main Form
const form = reactive({
  customer_id: null,
  device_id: null,
  device_brand: '',
  device_model: '',
  imei: '',
  pin_passcode: '',
  problem_description: '',
  condition_notes: '',
  accessories_notes: '',
  device_photo: '',
  expected_delivery_date: '',
  technician_id: null,
  technician_earning: 0,
  estimated_cost: 0,
  payment_amount: 0,
  payment_method: 'cash',
  customer_notes: '',
  internal_notes: '',
});

// Device Photo Upload Helpers (From computer storage/disk)
const photoInputRef = ref(null);
const photoPreview = ref('');

function triggerPhotoSelect() {
  if (photoInputRef.value) {
    photoInputRef.value.click();
  }
}

function handlePhotoUpload(event) {
  const file = event.target.files?.[0];
  if (!file) return;

  if (file.size > 10 * 1024 * 1024) {
    toast.warning('Selected image size exceeds 10MB limit. Please choose a smaller photo.', 'Photo Size Limit');
    return;
  }

  const reader = new FileReader();
  reader.onload = (e) => {
    const dataUrl = e.target.result;
    photoPreview.value = dataUrl;
    form.device_photo = dataUrl;
  };
  reader.readAsDataURL(file);
}

function removePhoto() {
  photoPreview.value = '';
  form.device_photo = '';
  if (photoInputRef.value) {
    photoInputRef.value.value = '';
  }
}

// Computed Filters
const filteredCustomers = computed(() => {
  const q = customerSearchQuery.value.trim().toLowerCase();
  if (!q) return customers.value.slice(0, 20);
  return customers.value.filter(c =>
    (c.name && c.name.toLowerCase().includes(q)) ||
    (c.phone && c.phone.includes(q)) ||
    (c.mobile && c.mobile.includes(q)) ||
    (c.city && c.city.toLowerCase().includes(q))
  ).slice(0, 30);
});

const filteredCustomerDevices = computed(() => {
  const q = deviceSearchQuery.value.trim().toLowerCase();
  if (!q) return customerDevices.value;
  return customerDevices.value.filter(d =>
    (d.brand && d.brand.toLowerCase().includes(q)) ||
    (d.model && d.model.toLowerCase().includes(q)) ||
    (d.imei1 && String(d.imei1).includes(q))
  );
});

const brandSearchQuery = ref('');
const isBrandDropdownOpen = ref(false);
const isModelDropdownOpen = ref(false);

const filteredCatalogBrands = computed(() => {
  const q = brandSearchQuery.value.trim().toLowerCase();
  if (!q) return catalogBrands.value;
  return catalogBrands.value.filter(b => String(b).toLowerCase().includes(q));
});

const filteredCatalogModels = computed(() => {
  const q = modelSearchQuery.value.trim().toLowerCase();
  if (!q) return catalogModels.value;
  return catalogModels.value.filter(m => String(m).toLowerCase().includes(q));
});

const filteredTechnicians = computed(() => {
  const q = technicianSearchQuery.value.trim().toLowerCase();
  if (!q) return technicians.value;
  return technicians.value.filter(t =>
    (t.name && t.name.toLowerCase().includes(q)) ||
    (t.specialization && t.specialization.toLowerCase().includes(q)) ||
    (t.phone && t.phone.includes(q)) ||
    (t.mobile && t.mobile.includes(q))
  );
});

// Customer methods
function openCustomerSearchModal() {
  customerSearchQuery.value = '';
  showCustomerSearchModal.value = true;
}

function openQuickCustomerModalFromSearch() {
  quickCustomerForm.name = customerSearchQuery.value;
  quickCustomerForm.phone = '';
  quickCustomerForm.city = '';
  showCustomerSearchModal.value = false;
  showQuickCustomerModal.value = true;
}

function selectCustomer(c) {
  selectedCustomer.value = c;
  form.customer_id = c.id;
  showCustomerSearchModal.value = false;
  selectedDevice.value = null;
  form.device_id = null;
  loadCustomerDevices(c.id);
}

function clearCustomerSelection() {
  selectedCustomer.value = null;
  form.customer_id = null;
  selectedDevice.value = null;
  form.device_id = null;
  customerDevices.value = [];
}

async function submitQuickCustomer() {
  quickCustomerSubmitting.value = true;
  try {
    const res = await customerApi.create(quickCustomerForm);
    const created = res.data?.data || res.data;
    if (created) {
      customers.value.unshift(created);
      selectCustomer(created);
      showQuickCustomerModal.value = false;
      toast.success(`Customer "${created.name}" registered and selected!`, 'Customer Added');
      quickCustomerForm.name = '';
      quickCustomerForm.phone = '';
      quickCustomerForm.city = '';
    }
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to create customer.';
    toast.error(msg, 'Customer Registration Failed');
  } finally {
    quickCustomerSubmitting.value = false;
  }
}

// Device methods
async function loadCustomerDevices(customerId) {
  loadingDevices.value = true;
  try {
    const res = await deviceApi.listForCustomer(customerId);
    const list = res.data?.data || res.data || [];
    customerDevices.value = Array.isArray(list) ? list : [];

    // If edit mode and form has device_id, match it
    if (form.device_id) {
      const match = customerDevices.value.find(d => d.id === form.device_id);
      if (match) selectedDevice.value = match;
    }
  } catch {
    customerDevices.value = [];
  } finally {
    loadingDevices.value = false;
  }
}

function selectDevice(d) {
  selectedDevice.value = d;
  form.device_id = d.id;
  form.device_brand = d.brand || '';
  form.device_model = d.model || '';
  form.imei = d.imei1 || d.imei || '';
}

function clearDeviceSelection() {
  selectedDevice.value = null;
  form.device_id = null;
  form.device_brand = '';
  form.device_model = '';
  form.imei = '';
}

async function fetchCatalogBrands() {
  loadingCatalogBrands.value = true;
  try {
    const res = await deviceApi.brands();
    const list = res.data?.data || res.data || [];
    if (Array.isArray(list) && list.length > 0) {
      // Keep popular brands easily accessible or union
      const brandSet = new Set([...catalogBrands.value, ...list]);
      catalogBrands.value = Array.from(brandSet);
    }
  } catch (err) {
    console.error('Failed to load catalog brands', err);
  } finally {
    loadingCatalogBrands.value = false;
  }
}

async function fetchCatalogModels(brand) {
  if (!brand) {
    catalogModels.value = [];
    return;
  }
  loadingCatalogModels.value = true;
  catalogModels.value = [];
  try {
    const res = await deviceApi.models({ brand });
    const list = res.data?.data || res.data || [];
    catalogModels.value = Array.isArray(list) ? list : [];
  } catch (err) {
    console.error('Failed to load catalog models', err);
    catalogModels.value = [];
  } finally {
    loadingCatalogModels.value = false;
  }
}

function selectCatalogBrand(brand) {
  quickDeviceForm.brand = brand;
  quickDeviceForm.model = '';
  modelSearchQuery.value = '';
  brandSearchQuery.value = '';
  isBrandDropdownOpen.value = false;
  isModelDropdownOpen.value = false;
  fetchCatalogModels(brand);
}

function selectCatalogModel(model) {
  quickDeviceForm.model = model;
  isModelDropdownOpen.value = false;
}

function toggleDeviceEntryMode() {
  isDeviceManualEntry.value = !isDeviceManualEntry.value;
  if (!isDeviceManualEntry.value) {
    fetchCatalogBrands();
    if (quickDeviceForm.brand) {
      fetchCatalogModels(quickDeviceForm.brand);
    }
  }
}

function openQuickDeviceModal() {
  quickDeviceForm.device_type = 'Mobile';
  quickDeviceForm.brand = '';
  quickDeviceForm.model = '';
  quickDeviceForm.imei1 = '';
  quickDeviceForm.color = '';
  brandSearchQuery.value = '';
  modelSearchQuery.value = '';
  isBrandDropdownOpen.value = false;
  isModelDropdownOpen.value = false;
  catalogModels.value = [];
  showQuickDeviceModal.value = true;
  fetchCatalogBrands();
}

async function submitQuickDevice() {
  if (!selectedCustomer.value) return;
  if (!quickDeviceForm.brand || !quickDeviceForm.model) {
    toast.warning('Please enter or select both device brand and model.', 'Missing Information');
    return;
  }
  quickDeviceSubmitting.value = true;
  try {
    const res = await deviceApi.createForCustomer(selectedCustomer.value.id, {
      device_type: quickDeviceForm.device_type || 'Mobile',
      brand: quickDeviceForm.brand,
      model: quickDeviceForm.model,
      imei_1: quickDeviceForm.imei1 || null,
      imei1: quickDeviceForm.imei1 || null,
      color: quickDeviceForm.color || null,
    });
    const created = res.data?.data || res.data;
    if (created) {
      customerDevices.value.unshift(created);
      selectDevice(created);
      showQuickDeviceModal.value = false;
      toast.success(`Device "${created.brand} ${created.model}" registered & attached!`, 'Device Saved');
    }
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to save customer device.';
    toast.error(msg, 'Save Device Failed');
  } finally {
    quickDeviceSubmitting.value = false;
  }
}

// Technician methods
function openTechnicianSearchModal() {
  technicianSearchQuery.value = '';
  showTechnicianSearchModal.value = true;
}

function selectTechnician(t) {
  selectedTechnician.value = t;
  form.technician_id = t ? t.id : null;
  showTechnicianSearchModal.value = false;
}

function unassignTechnician() {
  selectedTechnician.value = null;
  form.technician_id = null;
}

function openQuickTechModalFromSearch() {
  quickTechForm.name = technicianSearchQuery.value;
  quickTechForm.mobile = '';
  quickTechForm.specialization = '';
  showTechnicianSearchModal.value = false;
  showQuickTechModal.value = true;
}

async function submitQuickTechnician() {
  quickTechSubmitting.value = true;
  try {
    const res = await technicianApi.create({
      name: quickTechForm.name,
      mobile: quickTechForm.mobile,
      specialization: quickTechForm.specialization || null,
      is_active: true,
    });
    const created = res.data?.data || res.data;
    if (created) {
      technicians.value.unshift(created);
      selectTechnician(created);
      showQuickTechModal.value = false;
      toast.success(`Technician "${created.name}" registered and assigned!`, 'Technician Added');
    }
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to add technician.';
    toast.error(msg, 'Technician Failed');
  } finally {
    quickTechSubmitting.value = false;
  }
}

function toggleCondition(c) {
  const idx = selectedConditions.value.indexOf(c);
  if (idx !== -1) selectedConditions.value.splice(idx, 1);
  else selectedConditions.value.push(c);
}

function toggleAccessory(a) {
  const idx = selectedAccessories.value.indexOf(a);
  if (idx !== -1) selectedAccessories.value.splice(idx, 1);
  else selectedAccessories.value.push(a);
}

function formatAmount(amt) {
  return (Number(amt) || 0).toLocaleString('en-IN');
}

async function loadInitialData() {
  try {
    const [custRes, techRes] = await Promise.all([
      customerApi.list({ per_page: 200 }),
      technicianApi.list({ per_page: 50 }),
    ]);

    customers.value = custRes.data?.data?.data || custRes.data?.data || [];
    technicians.value = techRes.data?.data?.data || techRes.data?.data || [];

    if (isEdit.value) {
      const repRes = await repairApi.get(route.params.id);
      const rep = repRes.data?.data || repRes.data;
      if (rep) {
        repairNumber.value = rep.job_number || ('#JOB-' + rep.id);
        repairStatus.value = rep.repair_status || rep.status || '';
        form.customer_id = rep.customer_id;
        form.device_id = rep.device_id;
        form.device_brand = rep.device?.brand || rep.device_brand || '';
        form.device_model = rep.device?.model || rep.device_model || '';
        form.imei = rep.device?.imei1 || rep.imei || '';
        form.pin_passcode = rep.pin_passcode || '';
        form.problem_description = rep.problem_description || '';
        form.condition_notes = rep.condition_notes || '';
        form.accessories_notes = rep.accessories_notes || '';
        form.customer_notes = rep.customer_notes || '';
        form.internal_notes = rep.internal_notes || '';
        if (rep.device_photo) {
          form.device_photo = rep.device_photo;
          photoPreview.value = rep.device_photo;
        } else {
          form.device_photo = '';
          photoPreview.value = '';
        }
        form.expected_delivery_date = rep.expected_delivery_date ? rep.expected_delivery_date.substring(0, 10) : '';
        form.technician_id = rep.technician_id;
        form.technician_earning = Number(rep.technician_earning || 0);
        form.estimated_cost = Number(rep.final_cost || rep.estimated_cost || 0);

        if (rep.customer) {
          selectedCustomer.value = rep.customer;
          await loadCustomerDevices(rep.customer.id);
        }

        // Set device card
        if (rep.device) {
          selectedDevice.value = rep.device;
        } else if (form.device_brand || form.device_model) {
          selectedDevice.value = {
            id: rep.device_id,
            brand: form.device_brand,
            model: form.device_model,
            imei1: form.imei,
          };
        }

        // Set technician card
        if (rep.technician_id) {
          const matchedTech = technicians.value.find(t => t.id === rep.technician_id);
          if (matchedTech) {
            selectedTechnician.value = matchedTech;
          } else {
            selectedTechnician.value = {
              id: rep.technician_id,
              name: rep.technician_name || rep.technician?.name || `Technician #${rep.technician_id}`,
              specialization: rep.technician?.specialization || 'Assigned',
            };
          }
        }

        // Detect if pin_passcode is pattern
        if (form.pin_passcode && isPatternLock(form.pin_passcode)) {
          showPatternDrawer.value = true;
          patternPoints.value = parsePatternPoints(form.pin_passcode);
        }

        if (rep.device_condition) {
          try {
            selectedConditions.value = Array.isArray(rep.device_condition) ? rep.device_condition : JSON.parse(rep.device_condition);
          } catch {
            selectedConditions.value = [];
          }
        }

        if (rep.accessories_received) {
          try {
            selectedAccessories.value = Array.isArray(rep.accessories_received) ? rep.accessories_received : JSON.parse(rep.accessories_received);
          } catch {
            selectedAccessories.value = [];
          }
        }
      }
    }
  } catch (err) {
    console.error('Failed to load initial data:', err);
  }
}

async function submitRepair() {
  errorMsg.value = '';

  if (isDelivered.value) {
    errorMsg.value = 'Job Card is Delivered & finalized. It is frozen and cannot be modified.';
    return;
  }

  if (!form.customer_id) {
    errorMsg.value = 'Please select or add a customer for this repair order.';
    return;
  }
  if (!form.device_id && (!form.device_brand || !form.device_model)) {
    errorMsg.value = 'Please select or register a device for this customer.';
    return;
  }
  if (!form.problem_description) {
    errorMsg.value = 'Problem description is required.';
    return;
  }

  submitting.value = true;
  try {
    const payload = {
      customer_id: form.customer_id,
      device_id: form.device_id,
      technician_id: form.technician_id || null,
      technician_earning: form.technician_earning || 0,
      problem_description: form.problem_description,
      device_condition: selectedConditions.value,
      condition_notes: form.condition_notes || null,
      accessories_received: selectedAccessories.value,
      accessories_notes: form.accessories_notes || null,
      pin_passcode: form.pin_passcode || null,
      device_photo: form.device_photo || null,
      expected_delivery_date: form.expected_delivery_date || null,
      estimated_cost: form.estimated_cost,
      final_cost: form.estimated_cost,
      payment_amount: form.payment_amount || 0,
      payment_method: form.payment_method || 'cash',
      customer_notes: form.customer_notes || null,
      internal_notes: form.internal_notes || null,
    };

    if (isEdit.value) {
      await repairApi.update(route.params.id, payload);
      toast.success(`Repair Job #${repairNumber.value || route.params.id} updated successfully!`, 'Job Card Saved');
      router.push(`/repairs/${route.params.id}`);
    } else {
      const createRes = await repairApi.create(payload);
      const created = createRes.data?.data || createRes.data;
      const jobIdentifier = created?.job_number || created?.jobNumber || ('JOB-' + String(created?.id || '').padStart(6, '0'));
      toast.success(`Repair Job #${jobIdentifier} created successfully!`, 'Job Card Created');

      // Add warranty if selected
      if (addWarranty.value && created?.id) {
        try {
          await warrantyApi.create({
            repair_id: created.id,
            customer_id: form.customer_id,
            device_id: form.device_id,
            warranty_type: 'repair',
            duration_days: warrantyDuration.value === 'custom' ? (Number(customWarrantyDuration.value) || 30) : Number(warrantyDuration.value),
            warranty_terms: warrantyTerms.value,
          });
        } catch (wErr) {
          console.error('Failed to attach warranty:', wErr);
        }
      }

      router.push(`/repairs/${created?.id || ''}`);
    }
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to save repair job. Please verify all fields.';
    errorMsg.value = msg;
    toast.error(msg, 'Save Repair Failed');
  } finally {
    submitting.value = false;
  }
}

onMounted(() => {
  loadInitialData();
});
</script>
