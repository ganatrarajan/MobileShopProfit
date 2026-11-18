<template>
  <div class="space-y-6 max-w-7xl mx-auto pb-12">
    <!-- Header / Breadcrumb & Actions -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div class="flex items-center gap-3">
        <router-link
          to="/used-mobiles"
          class="w-10 h-10 rounded-xl bg-white dark:bg-slate-800 border border-slate-200/80 dark:border-slate-700/80 flex items-center justify-center text-slate-500 hover:text-indigo-600 hover:border-indigo-200 transition shadow-xs"
          title="Back to Used Mobiles"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
        </router-link>
        <div>
          <div class="flex items-center gap-2">
            <span class="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider bg-purple-50 dark:bg-purple-950/60 text-purple-700 dark:text-purple-300 border border-purple-200 dark:border-purple-800">
              Pre-owned Device
            </span>
            <span class="font-mono text-xs text-slate-400">#{{ mobile?.purchase_ref_number || mobile?.id }}</span>
          </div>
          <h2 class="text-2xl font-black text-slate-900 dark:text-white tracking-tight mt-0.5">
            {{ mobile?.brand }} {{ mobile?.model }}
          </h2>
        </div>
      </div>

      <!-- Action Buttons -->
      <div v-if="mobile" class="flex flex-wrap items-center gap-2.5">
        <!-- Sell Button (if in stock) -->
        <button
          v-if="mobile.status !== 'sold'"
          type="button"
          @click="openSellModal"
          class="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold shadow-md shadow-emerald-600/20 transition cursor-pointer"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <span>Sell Phone</span>
        </button>

        <!-- Add Repair Expense (if in stock) -->
        <button
          v-if="mobile.status !== 'sold'"
          type="button"
          @click="openRepairModal"
          class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-indigo-50 hover:bg-indigo-100 dark:bg-indigo-950/50 dark:hover:bg-indigo-900/50 text-indigo-700 dark:text-indigo-300 border border-indigo-200/80 dark:border-indigo-800/80 text-xs font-bold transition cursor-pointer"
        >
          <span>🔧</span>
          <span>+ Repair Expense</span>
        </button>

        <!-- WhatsApp Share -->
        <button
          type="button"
          @click="shareOnWhatsApp"
          class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-emerald-50 hover:bg-emerald-100 dark:bg-emerald-950/50 dark:hover:bg-emerald-900/50 text-emerald-700 dark:text-emerald-300 border border-emerald-200/80 dark:border-emerald-800/80 text-xs font-bold transition cursor-pointer"
          title="Share device details on WhatsApp"
        >
          <WhatsAppIcon sizeClass="w-3.5 h-3.5 text-emerald-600 dark:text-emerald-400" />
          <span>Share</span>
        </button>

        <!-- Edit Profile -->
        <button
          v-if="mobile.status !== 'sold'"
          type="button"
          @click="openEditModal"
          class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-white dark:bg-slate-800 border border-slate-200/80 dark:border-slate-700 text-slate-700 dark:text-slate-200 hover:text-indigo-600 hover:border-indigo-300 text-xs font-bold shadow-xs transition cursor-pointer"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
          </svg>
          <span>Edit</span>
        </button>

        <!-- Delete -->
        <button
          type="button"
          @click="confirmDelete"
          class="p-2 rounded-xl text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/30 transition cursor-pointer"
          title="Delete Record"
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
      <p class="text-sm font-semibold text-slate-500 dark:text-slate-400">Loading device details...</p>
    </div>

    <template v-else-if="mobile">
      <!-- Device Header Card -->
      <div class="bg-white dark:bg-[#111827] rounded-3xl p-6 border border-slate-200/80 dark:border-slate-800/80 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div class="flex items-center gap-4">
          <div class="w-16 h-16 rounded-2xl bg-purple-50 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400 font-black text-2xl flex items-center justify-center border border-purple-200/60 dark:border-purple-800/60 shadow-xs shrink-0">
            📱
          </div>
          <div>
            <div class="flex items-center gap-2.5 flex-wrap">
              <h1 class="text-xl font-black text-slate-900 dark:text-white">{{ mobile.brand }} {{ mobile.model }}</h1>
              <span
                :class="mobile.status === 'sold'
                  ? 'bg-emerald-50 dark:bg-emerald-950/50 text-emerald-700 dark:text-emerald-400 border-emerald-200 dark:border-emerald-800'
                  : 'bg-indigo-50 dark:bg-indigo-950/50 text-indigo-700 dark:text-indigo-400 border-indigo-200 dark:border-indigo-800'"
                class="px-2.5 py-0.5 rounded-full text-xs font-bold border capitalize"
              >
                {{ mobile.status === 'sold' ? 'Sold' : 'In Showroom Stock' }}
              </span>
              <span class="px-2 py-0.5 rounded text-[11px] font-bold uppercase bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300">
                Condition: {{ formatCondition(mobile.device_condition) }}
              </span>
            </div>
            <div class="flex flex-wrap items-center gap-y-1 gap-x-4 mt-2 text-xs text-slate-500 dark:text-slate-400">
              <span v-if="mobile.imei1 || mobile.imei" class="font-mono">
                IMEI 1: <strong class="text-slate-800 dark:text-slate-200">{{ mobile.imei1 || mobile.imei }}</strong>
              </span>
              <span v-if="mobile.imei2" class="font-mono">
                IMEI 2: <strong class="text-slate-800 dark:text-slate-200">{{ mobile.imei2 }}</strong>
              </span>
              <span v-if="mobile.serial_number" class="font-mono">
                S/N: <strong class="text-slate-800 dark:text-slate-200">{{ mobile.serial_number }}</strong>
              </span>
              <span>
                Ref: <strong class="font-mono text-slate-800 dark:text-slate-200">{{ mobile.purchase_ref_number || 'N/A' }}</strong>
              </span>
            </div>
          </div>
        </div>

        <div class="flex flex-col sm:flex-row items-start sm:items-center gap-3 shrink-0">
          <div class="px-4 py-2.5 rounded-2xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200/80 dark:border-slate-800/80 text-right">
            <p class="text-[10px] font-bold uppercase tracking-wider text-slate-400">Total Investment</p>
            <p class="text-lg font-black text-slate-900 dark:text-white">
              ₹{{ formatNumber(mobile.total_cost || Number(mobile.purchase_price || 0) + Number(mobile.repair_cost || 0)) }}
            </p>
          </div>
          <div v-if="mobile.status === 'sold'" class="px-4 py-2.5 rounded-2xl bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800/60 text-right">
            <p class="text-[10px] font-bold uppercase tracking-wider text-emerald-600 dark:text-emerald-400">Net Profit Earned</p>
            <p class="text-lg font-black text-emerald-600 dark:text-emerald-400">
              +₹{{ formatNumber(mobile.profit || 0) }}
            </p>
          </div>
        </div>
      </div>

      <!-- Financial Breakdown KPI Cards -->
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
        <!-- Purchase Price -->
        <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-xs">
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Purchase Cost</p>
          <h3 class="text-xl font-black text-slate-900 dark:text-white mt-1">₹{{ formatNumber(mobile.purchase_price) }}</h3>
          <p class="text-[11px] text-slate-400 mt-0.5">Mode: {{ mobile.payment_mode || 'Cash' }}</p>
        </div>

        <!-- Refurbishment / Repair Cost -->
        <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-xs">
          <div class="flex items-center justify-between">
            <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Repair & Parts</p>
            <button
              v-if="mobile.status !== 'sold'"
              type="button"
              @click="openRepairModal"
              class="text-[10px] font-bold text-indigo-600 dark:text-indigo-400 hover:underline cursor-pointer"
            >
              + Edit
            </button>
          </div>
          <h3 class="text-xl font-black text-amber-600 dark:text-amber-400 mt-1">₹{{ formatNumber(mobile.repair_cost || 0) }}</h3>
          <p class="text-[11px] text-slate-400 mt-0.5 truncate">{{ mobile.repair_details || 'No parts added' }}</p>
        </div>

        <!-- Total Landed Cost -->
        <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-xs">
          <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Total Investment</p>
          <h3 class="text-xl font-black text-slate-900 dark:text-white mt-1">
            ₹{{ formatNumber(mobile.total_cost || Number(mobile.purchase_price || 0) + Number(mobile.repair_cost || 0)) }}
          </h3>
          <p class="text-[11px] text-slate-400 mt-0.5">Purchase + Repairs</p>
        </div>

        <!-- Selling Price / Profit -->
        <div class="bg-white dark:bg-[#111827] rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800/80 shadow-xs">
          <p class="text-[11px] font-bold uppercase tracking-wider" :class="mobile.status === 'sold' ? 'text-emerald-600 dark:text-emerald-400' : 'text-slate-400'">
            {{ mobile.status === 'sold' ? 'Sold Price & Margin' : 'Expected Resale' }}
          </p>
          <h3 class="text-xl font-black mt-1" :class="mobile.status === 'sold' ? 'text-emerald-600 dark:text-emerald-400' : 'text-slate-900 dark:text-white'">
            {{ mobile.status === 'sold' ? `₹${formatNumber(mobile.selling_price)}` : (mobile.expected_selling_price ? `₹${formatNumber(mobile.expected_selling_price)}` : 'Ready to Sell') }}
          </h3>
          <p class="text-[11px] font-semibold mt-0.5" :class="mobile.status === 'sold' ? 'text-emerald-600 dark:text-emerald-400' : 'text-slate-400'">
            {{ mobile.status === 'sold' ? `Profit: +₹${formatNumber(mobile.profit || 0)}` : 'In Showroom' }}
          </p>
        </div>
      </div>

      <!-- Main Two-Column Layout -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Column 1: Device Specifications & Hardware Condition -->
        <div class="bg-white dark:bg-[#111827] rounded-3xl p-6 border border-slate-200/80 dark:border-slate-800/80 shadow-sm space-y-5">
          <div class="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800/80">
            <h3 class="text-base font-bold text-slate-900 dark:text-white flex items-center gap-2">
              <span>📋</span>
              <span>Device Specifications</span>
            </h3>
            <span class="px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider bg-indigo-50 dark:bg-indigo-950/60 text-indigo-700 dark:text-indigo-300">
              Hardware
            </span>
          </div>

          <div class="grid grid-cols-2 gap-4 text-xs">
            <div class="p-3 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200/60 dark:border-slate-800/60">
              <span class="text-slate-400 block mb-0.5 font-semibold">Memory & Storage</span>
              <span class="font-bold text-slate-800 dark:text-slate-200">
                {{ mobile.ram ? `${mobile.ram} RAM` : '' }} {{ mobile.storage ? `/ ${mobile.storage}` : 'Not Specified' }}
              </span>
            </div>
            <div class="p-3 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200/60 dark:border-slate-800/60">
              <span class="text-slate-400 block mb-0.5 font-semibold">Color / Variant</span>
              <span class="font-bold text-slate-800 dark:text-slate-200">
                {{ mobile.color || 'Standard Variant' }}
              </span>
            </div>
            <div class="p-3 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200/60 dark:border-slate-800/60">
              <span class="text-slate-400 block mb-0.5 font-semibold">Battery Health</span>
              <span class="font-bold text-slate-800 dark:text-slate-200">
                {{ mobile.battery_health ? `${mobile.battery_health}%` : 'Not Measured' }}
              </span>
            </div>
            <div class="p-3 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200/60 dark:border-slate-800/60">
              <span class="text-slate-400 block mb-0.5 font-semibold">Device Condition</span>
              <span class="font-bold text-slate-800 dark:text-slate-200 capitalize">
                {{ formatCondition(mobile.device_condition) }}
              </span>
            </div>
          </div>

          <!-- Accessories Included -->
          <div>
            <span class="text-xs font-bold text-slate-700 dark:text-slate-300 block mb-2">Accessories Included:</span>
            <div v-if="accessoriesList.length > 0" class="flex flex-wrap gap-2">
              <span
                v-for="(acc, idx) in accessoriesList"
                :key="idx"
                class="inline-flex items-center gap-1 px-2.5 py-1 rounded-xl text-xs font-semibold bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 border border-emerald-200/60 dark:border-emerald-800/60"
              >
                <span>✓</span>
                <span>{{ acc }}</span>
              </span>
            </div>
            <p v-else class="text-xs text-slate-400 italic">No original accessories included with this phone.</p>
          </div>

          <!-- Condition & Purchase Notes -->
          <div v-if="mobile.condition_notes || mobile.purchase_notes" class="p-3.5 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200/60 dark:border-slate-800/60 text-xs space-y-1.5">
            <div v-if="mobile.condition_notes">
              <span class="font-bold text-slate-700 dark:text-slate-300">Condition Notes: </span>
              <span class="text-slate-600 dark:text-slate-400">{{ mobile.condition_notes }}</span>
            </div>
            <div v-if="mobile.purchase_notes">
              <span class="font-bold text-slate-700 dark:text-slate-300">Intake Remarks: </span>
              <span class="text-slate-600 dark:text-slate-400">{{ mobile.purchase_notes }}</span>
            </div>
          </div>
        </div>

        <!-- Column 2: Seller & Buyer Profiles -->
        <div class="space-y-6">
          <!-- Seller Information Card -->
          <div class="bg-white dark:bg-[#111827] rounded-3xl p-6 border border-slate-200/80 dark:border-slate-800/80 shadow-sm space-y-4">
            <div class="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800/80">
              <h3 class="text-base font-bold text-slate-900 dark:text-white flex items-center gap-2">
                <span>👤</span>
                <span>Seller & Intake Info</span>
              </h3>
              <span class="font-mono text-xs text-slate-400">Date: {{ mobile.purchase_date || 'N/A' }}</span>
            </div>

            <div class="flex items-center justify-between">
              <div>
                <p class="font-bold text-slate-900 dark:text-slate-100 text-sm">{{ mobile.seller_name }}</p>
                <p class="text-xs text-slate-400 font-mono mt-0.5">{{ mobile.seller_phone }}</p>
              </div>
              <a
                v-if="mobile.seller_phone"
                :href="`https://wa.me/91${cleanPhone(mobile.seller_phone)}?text=Hello%20${encodeURIComponent(mobile.seller_name)},%20regarding%20your%20used%20phone%20sale%20at%20MyRepairHub.`"
                target="_blank"
                class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-emerald-50 hover:bg-emerald-100 dark:bg-emerald-950/60 dark:hover:bg-emerald-900/60 text-emerald-700 dark:text-emerald-300 text-xs font-bold border border-emerald-200/60 dark:border-emerald-800/60 transition"
              >
                <WhatsAppIcon sizeClass="w-3.5 h-3.5 text-emerald-600 dark:text-emerald-400" />
                <span>Chat</span>
              </a>
            </div>

            <div v-if="mobile.seller_address" class="text-xs text-slate-500 dark:text-slate-400">
              <strong class="text-slate-700 dark:text-slate-300">Address: </strong>
              <span>{{ mobile.seller_address }}</span>
            </div>

            <!-- ID Proof Details -->
            <div class="p-3 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200/60 dark:border-slate-800/60 text-xs flex items-center justify-between">
              <div>
                <span class="text-slate-400 block font-semibold">Government ID Proof</span>
                <span class="font-bold text-slate-800 dark:text-slate-200">
                  {{ mobile.id_proof_type || 'ID Document' }}: {{ mobile.id_proof_number || 'Recorded' }}
                </span>
              </div>
              <span v-if="mobile.id_proof_photo" class="text-xs font-bold text-indigo-600 dark:text-indigo-400">Document Attached ✓</span>
            </div>
          </div>

          <!-- Buyer & Sale Card (If Sold) -->
          <div v-if="mobile.status === 'sold'" class="bg-white dark:bg-[#111827] rounded-3xl p-6 border border-emerald-200/80 dark:border-emerald-800/80 shadow-sm space-y-4">
            <div class="flex items-center justify-between pb-3 border-b border-emerald-100 dark:border-emerald-900/60">
              <h3 class="text-base font-bold text-emerald-700 dark:text-emerald-400 flex items-center gap-2">
                <span>🛒</span>
                <span>Sold Customer Information</span>
              </h3>
              <span class="font-mono text-xs text-emerald-600 dark:text-emerald-400">Sold: {{ mobile.sale_date || 'N/A' }}</span>
            </div>

            <div class="flex items-center justify-between">
              <div>
                <p class="font-bold text-slate-900 dark:text-slate-100 text-sm">{{ mobile.buyer_name || 'Walk-in Customer' }}</p>
                <p class="text-xs text-slate-400 font-mono mt-0.5">{{ mobile.buyer_phone || 'No phone' }}</p>
              </div>
              <a
                v-if="mobile.buyer_phone"
                :href="`https://wa.me/91${cleanPhone(mobile.buyer_phone)}?text=Hello%20${encodeURIComponent(mobile.buyer_name || 'Customer')},%20here%20is%20your%20used%20phone%20purchase%20invoice%20and%20warranty%20receipt.`"
                target="_blank"
                class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-emerald-50 hover:bg-emerald-100 dark:bg-emerald-950/60 dark:hover:bg-emerald-900/60 text-emerald-700 dark:text-emerald-300 text-xs font-bold border border-emerald-200/60 dark:border-emerald-800/60 transition"
              >
                <WhatsAppIcon sizeClass="w-3.5 h-3.5 text-emerald-600 dark:text-emerald-400" />
                <span>Invoice Share</span>
              </a>
            </div>

            <div class="grid grid-cols-2 gap-3 text-xs">
              <div class="p-2.5 rounded-xl bg-emerald-50/50 dark:bg-emerald-950/30 border border-emerald-100 dark:border-emerald-900/40">
                <span class="text-slate-400 block font-semibold">Selling Amount</span>
                <span class="font-black text-emerald-600 dark:text-emerald-400 text-sm">₹{{ formatNumber(mobile.selling_price) }}</span>
              </div>
              <div class="p-2.5 rounded-xl bg-emerald-50/50 dark:bg-emerald-950/30 border border-emerald-100 dark:border-emerald-900/40">
                <span class="text-slate-400 block font-semibold">Warranty Given</span>
                <span class="font-bold text-slate-800 dark:text-slate-200">
                  {{ mobile.warranty_days ? `${mobile.warranty_days} Days Testing Warranty` : 'No Warranty' }}
                </span>
              </div>
            </div>

            <div v-if="mobile.sale_notes" class="text-xs text-slate-500 dark:text-slate-400">
              <strong class="text-slate-700 dark:text-slate-300">Sale Remarks: </strong>
              <span>{{ mobile.sale_notes }}</span>
            </div>
          </div>
        </div>
      </div>
    </template>

    <!-- SELL MODAL -->
    <div
      v-if="sellModalOpen"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-3 sm:p-5"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-3xl w-full max-w-lg shadow-2xl max-h-[85vh] flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        <div class="px-6 py-4 border-b border-slate-100 dark:border-slate-800/80 flex justify-between items-center bg-emerald-50/50 dark:bg-emerald-950/30 shrink-0">
          <div>
            <h3 class="font-bold text-slate-900 dark:text-white flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-emerald-500"></span>
              Sell Used Phone
            </h3>
            <p class="text-xs text-slate-400 mt-0.5">{{ mobile?.brand }} {{ mobile?.model }} (IMEI: {{ mobile?.imei1 || mobile?.imei || 'N/A' }})</p>
          </div>
          <button @click="sellModalOpen = false" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 cursor-pointer">✕</button>
        </div>

        <form @submit.prevent="executeSell" class="flex flex-col flex-1 overflow-hidden min-h-0">
          <div class="p-6 space-y-4 overflow-y-auto custom-scroll flex-1 pb-8">
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Buyer Name <span class="text-rose-500">*</span></label>
                <input v-model="sellForm.buyer_name" type="text" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-emerald-500 text-slate-900 dark:text-slate-100" placeholder="Customer name" required />
              </div>
              <div>
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Buyer Phone <span class="text-rose-500">*</span></label>
                <input v-model="sellForm.buyer_phone" type="tel" maxlength="10" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-emerald-500 text-slate-900 dark:text-slate-100 font-mono" placeholder="10-digit mobile" required />
              </div>
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Selling Price (₹) <span class="text-rose-500">*</span></label>
                <input v-model.number="sellForm.selling_price" type="number" step="1" min="1" class="w-full px-3 py-2 text-sm font-bold bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-emerald-500 text-slate-900 dark:text-slate-100" required />
              </div>
              <div>
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Sale Date <span class="text-rose-500">*</span></label>
                <input v-model="sellForm.sale_date" type="date" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-emerald-500 text-slate-900 dark:text-slate-100" required />
              </div>
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Payment Mode</label>
                <SearchableSelect
                  v-model="sellForm.sale_payment_mode"
                  :options="paymentModeOptions"
                  placeholder="Select Mode"
                  minWidth="100%"
                />
              </div>
              <div>
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Testing Warranty</label>
                <SearchableSelect
                  v-model="sellForm.warranty_days"
                  :options="warrantyOptions"
                  placeholder="Select Warranty"
                  minWidth="100%"
                  :searchable="false"
                />
              </div>
            </div>

            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Customer Address (Optional)</label>
              <input v-model="sellForm.buyer_address" type="text" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-emerald-500 text-slate-900 dark:text-slate-100" placeholder="City or street address" />
            </div>

            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">Sale Notes / Remarks</label>
              <input v-model="sellForm.sale_notes" type="text" class="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-emerald-500 text-slate-900 dark:text-slate-100" placeholder="Charger given, condition accepted, etc." />
            </div>
          </div>

          <div class="px-6 py-3.5 border-t border-slate-100 dark:border-slate-800/80 bg-slate-50/50 dark:bg-slate-900/30 flex justify-end gap-2 shrink-0">
            <button type="button" @click="sellModalOpen = false" class="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-xl transition cursor-pointer">Cancel</button>
            <button
              type="submit"
              :disabled="submitting"
              class="px-5 py-2 text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-500 rounded-xl shadow-md shadow-emerald-600/20 disabled:opacity-50 transition cursor-pointer"
            >
              {{ submitting ? 'Recording Sale...' : 'Confirm Sale' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- ADD REPAIR EXPENSE MODAL -->
    <div
      v-if="repairModalOpen"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-3 sm:p-5"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-3xl w-full max-w-md shadow-2xl max-h-[85vh] flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        <div class="px-6 py-4 border-b border-slate-100 dark:border-slate-800/80 flex justify-between items-center bg-indigo-50/50 dark:bg-indigo-950/30 shrink-0">
          <div>
            <h3 class="font-bold text-slate-900 dark:text-white flex items-center gap-2">
              <span>🔧</span>
              <span>Refurbishment & Repair Cost</span>
            </h3>
            <p class="text-xs text-slate-400 mt-0.5">Increments total investment of this device</p>
          </div>
          <button @click="repairModalOpen = false" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 cursor-pointer">✕</button>
        </div>

        <form @submit.prevent="executeAddRepair" class="flex flex-col flex-1 overflow-hidden min-h-0">
          <div class="p-6 space-y-4 overflow-y-auto custom-scroll flex-1 pb-8">
            <div class="p-3.5 rounded-2xl bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-800/40 text-xs">
              <span class="text-amber-700 dark:text-amber-400 font-bold block mb-1">Current Investment:</span>
              <div class="flex items-center justify-between text-slate-700 dark:text-slate-300">
                <span>Purchase Price:</span>
                <span class="font-bold">₹{{ formatNumber(mobile?.purchase_price) }}</span>
              </div>
              <div class="flex items-center justify-between text-slate-700 dark:text-slate-300 mt-0.5">
                <span>Existing Repair Cost:</span>
                <span class="font-bold text-amber-600">₹{{ formatNumber(mobile?.repair_cost || 0) }}</span>
              </div>
            </div>

            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                New / Total Repair Cost (₹) <span class="text-rose-500">*</span>
              </label>
              <input
                v-model.number="repairForm.repair_cost"
                type="number"
                step="0.01"
                min="0"
                class="w-full px-3 py-2 text-sm font-bold bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100"
                placeholder="e.g. 1500"
                required
              />
            </div>

            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Repair & Parts Details
              </label>
              <textarea
                v-model="repairForm.repair_details"
                rows="3"
                class="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 rounded-xl focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100"
                placeholder="e.g. Changed display combo, new battery installed, back glass replaced"
              ></textarea>
            </div>
          </div>

          <div class="px-6 py-3.5 border-t border-slate-100 dark:border-slate-800/80 bg-slate-50/50 dark:bg-slate-900/30 flex justify-end gap-2 shrink-0">
            <button type="button" @click="repairModalOpen = false" class="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-xl transition cursor-pointer">Cancel</button>
            <button
              type="submit"
              :disabled="submitting"
              class="px-5 py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-500 rounded-xl shadow-md shadow-indigo-600/20 disabled:opacity-50 transition cursor-pointer"
            >
              {{ submitting ? 'Updating...' : 'Save Repair Expense' }}
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
import { usedMobileApi } from '@/api/endpoints';
import SearchableSelect from '@/components/common/SearchableSelect.vue';
import WhatsAppIcon from '@/components/common/WhatsAppIcon.vue';

const route = useRoute();
const router = useRouter();
const toast = useToastStore();

const mobile = ref(null);
const loading = ref(false);
const submitting = ref(false);

const sellModalOpen = ref(false);
const repairModalOpen = ref(false);

const paymentModeOptions = [
  { value: 'Cash', label: 'Cash', icon: '💵' },
  { value: 'UPI / Online', label: 'UPI / PhonePe / GPay', icon: '⚡' },
  { value: 'Debit / Credit Card', label: 'Debit / Credit Card', icon: '💳' },
  { value: 'Bank Transfer', label: 'Bank Transfer', icon: '🏦' },
];

const warrantyOptions = [
  { value: 0, label: 'No Warranty' },
  { value: 7, label: '7 Days Testing Warranty' },
  { value: 15, label: '15 Days (Recommended)' },
  { value: 30, label: '30 Days Testing' },
  { value: 60, label: '60 Days Warranty' },
  { value: 90, label: '90 Days Warranty' },
];

const sellForm = reactive({
  buyer_name: '',
  buyer_phone: '',
  buyer_address: '',
  selling_price: 0,
  sale_date: new Date().toISOString().slice(0, 10),
  sale_payment_mode: 'Cash',
  warranty_days: 15,
  sale_notes: '',
});

const repairForm = reactive({
  repair_cost: 0,
  repair_details: '',
});

async function fetchMobileDetails() {
  loading.value = true;
  try {
    const id = route.params.id;
    const res = await usedMobileApi.get(id);
    if (res.data?.success) {
      mobile.value = res.data.data;
    }
  } catch (err) {
    console.error('Failed to load used mobile details:', err);
    toast.error('Failed to load device details', 'Error');
  } finally {
    loading.value = false;
  }
}

const accessoriesList = computed(() => {
  if (!mobile.value) return [];
  const acc = mobile.value.accessories_included;
  if (Array.isArray(acc)) return acc;
  if (typeof acc === 'string') {
    try {
      const parsed = JSON.parse(acc);
      if (Array.isArray(parsed)) return parsed;
    } catch (e) {
      return acc.split(',').map(s => s.trim()).filter(Boolean);
    }
  }
  return [];
});

function formatNumber(num) {
  if (num === null || num === undefined) return '0';
  return Number(num).toLocaleString('en-IN');
}

function formatCondition(cond) {
  if (!cond) return 'Good';
  switch (cond.toLowerCase()) {
    case 'mint': return 'Mint (Like New)';
    case 'good': return 'Good Condition';
    case 'fair': return 'Fair / Signs of Use';
    case 'damaged': return 'Damaged / Needs Repair';
    default: return cond;
  }
}

function cleanPhone(phone) {
  return String(phone || '').replace(/\D/g, '').slice(-10);
}

function shareOnWhatsApp() {
  if (!mobile.value) return;
  const m = mobile.value;
  const phone = m.buyer_phone || m.seller_phone || '';
  const isSold = m.status === 'sold';
  let msg = '';
  if (isSold) {
    msg = `*Pre-owned Device Sale Invoice*\n\n📱 *Device:* ${m.brand} ${m.model}\n🔢 *IMEI:* ${m.imei1 || m.imei || 'N/A'}\n👤 *Customer:* ${m.buyer_name || 'Customer'}\n💰 *Price:* ₹${formatNumber(m.selling_price)}\n🛡️ *Warranty:* ${m.warranty_days ? `${m.warranty_days} Days Testing Warranty` : 'No Warranty'}\n📅 *Date:* ${m.sale_date || 'N/A'}\n\nThank you for purchasing from our store!`;
  } else {
    msg = `*Used Mobile Intake Record*\n\n📱 *Device:* ${m.brand} ${m.model}\n🔢 *IMEI:* ${m.imei1 || m.imei || 'N/A'}\n👤 *Seller:* ${m.seller_name}\n💰 *Purchase Price:* ₹${formatNumber(m.purchase_price)}\n📅 *Date:* ${m.purchase_date || 'N/A'}`;
  }
  const url = `https://wa.me/91${cleanPhone(phone)}?text=${encodeURIComponent(msg)}`;
  window.open(url, '_blank');
}

function openSellModal() {
  if (!mobile.value) return;
  Object.assign(sellForm, {
    buyer_name: '',
    buyer_phone: '',
    buyer_address: '',
    selling_price: Number(mobile.value.expected_selling_price || mobile.value.selling_price || mobile.value.total_cost || 0),
    sale_date: new Date().toISOString().slice(0, 10),
    sale_payment_mode: 'Cash',
    warranty_days: 15,
    sale_notes: '',
  });
  sellModalOpen.value = true;
}

async function executeSell() {
  submitting.value = true;
  try {
    await usedMobileApi.sell(mobile.value.id, sellForm);
    toast.success(`${mobile.value.brand} ${mobile.value.model} marked as SOLD!`, 'Sale Complete');
    sellModalOpen.value = false;
    fetchMobileDetails();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to record sale';
    toast.error(msg, 'Sale Failed');
  } finally {
    submitting.value = false;
  }
}

function openRepairModal() {
  if (!mobile.value) return;
  Object.assign(repairForm, {
    repair_cost: Number(mobile.value.repair_cost || 0),
    repair_details: mobile.value.repair_details || '',
  });
  repairModalOpen.value = true;
}

async function executeAddRepair() {
  submitting.value = true;
  try {
    await usedMobileApi.addRepairExpense(mobile.value.id, repairForm);
    toast.success('Repair expense logged successfully!', 'Expense Added');
    repairModalOpen.value = false;
    fetchMobileDetails();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to update repair expense';
    toast.error(msg, 'Update Failed');
  } finally {
    submitting.value = false;
  }
}

async function confirmDelete() {
  if (!confirm(`Are you sure you want to delete ${mobile.value.brand} ${mobile.value.model}? This action cannot be undone.`)) return;
  try {
    await usedMobileApi.delete(mobile.value.id);
    toast.success('Used mobile entry removed', 'Deleted');
    router.push('/used-mobiles');
  } catch (err) {
    toast.error('Failed to delete used mobile entry', 'Error');
  }
}

onMounted(() => {
  fetchMobileDetails();
});
</script>