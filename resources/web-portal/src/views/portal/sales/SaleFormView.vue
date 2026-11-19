<template>
  <div class="max-w-5xl mx-auto space-y-6 pb-16 font-['Outfit',sans-serif]">
    <!-- Top Action Bar -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div class="flex items-center gap-3">
        <router-link
          to="/sales"
          class="inline-flex items-center gap-1.5 px-3 py-2 text-xs font-semibold rounded-xl bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-200 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 shadow-sm transition"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/></svg>
          Back to Sales
        </router-link>
        <div>
          <h1 class="text-2xl font-bold text-slate-900 dark:text-white">New Sale / POS Counter</h1>
          <p class="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
            Bill accessories, devices, or inventory parts with real-time stock deduction and invoice generation
          </p>
        </div>
      </div>

      <div class="flex items-center gap-2">
        <router-link to="/sales" class="px-4 py-2 text-xs font-semibold rounded-xl border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 hover:bg-slate-50">
          Cancel
        </router-link>
        <button
          type="button"
          @click="submitSale"
          :disabled="submitting"
          class="px-5 py-2 text-xs font-bold rounded-xl bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-white shadow-md shadow-emerald-500/20 transition flex items-center gap-1.5"
        >
          <svg v-if="submitting" class="w-3.5 h-3.5 animate-spin" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path></svg>
          {{ submitting ? 'Processing...' : 'Complete & Generate Invoice' }}
        </button>
      </div>
    </div>

    <!-- Alert Banner -->
    <div v-if="errorMsg" class="p-4 bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-800 rounded-2xl text-xs font-semibold text-red-700 dark:text-red-300 flex items-center justify-between">
      <div class="flex items-center gap-2">
        <svg class="w-4 h-4 text-red-500 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
        <span>{{ errorMsg }}</span>
      </div>
      <button @click="errorMsg = ''" class="text-red-400 hover:text-red-600">✕</button>
    </div>

    <form @submit.prevent="submitSale" class="space-y-6">
      <!-- 1. Customer Selection (Dropdown & Quick Add) -->
      <div class="bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200/80 dark:border-slate-700/80 shadow-sm space-y-4">
        <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-lg bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 flex items-center justify-center font-bold">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
            </div>
            <div>
              <h3 class="font-bold text-slate-900 dark:text-white text-sm">Customer Profile</h3>
              <p class="text-[11px] text-slate-400">Select registered customer or enter walk-in customer details</p>
            </div>
          </div>

          <button
            type="button"
            @click="showQuickCustomerModal = true"
            class="text-xs font-bold text-emerald-600 hover:text-emerald-700 flex items-center gap-1 bg-emerald-50 dark:bg-emerald-950/40 px-3 py-1.5 rounded-xl border border-emerald-200 dark:border-emerald-800"
          >
            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
            + Add Customer
          </button>
        </div>

        <!-- Selected Customer Card -->
        <div v-if="selectedCustomer" class="p-4 bg-emerald-50/60 dark:bg-emerald-950/30 rounded-2xl border border-emerald-100 dark:border-emerald-900/40 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-xl bg-emerald-600 text-white flex items-center justify-center font-extrabold text-base shadow-sm">
              {{ (selectedCustomer.name || 'C')[0] }}
            </div>
            <div>
              <div class="flex items-center gap-2">
                <h4 class="font-bold text-slate-900 dark:text-white text-sm">{{ selectedCustomer.name }}</h4>
                <span class="text-[10px] font-bold text-emerald-700 dark:text-emerald-300 bg-white dark:bg-slate-800 px-2 py-0.5 rounded-full border border-emerald-200 dark:border-emerald-800">
                  Customer #{{ selectedCustomer.id }}
                </span>
              </div>
              <div class="flex items-center gap-3 text-xs text-slate-500 dark:text-slate-400 mt-0.5 font-mono">
                <span>📞 {{ selectedCustomer.phone || selectedCustomer.mobile || 'No mobile' }}</span>
                <span v-if="selectedCustomer.city" class="font-sans">📍 {{ selectedCustomer.city }}</span>
              </div>
            </div>
          </div>

          <button
            type="button"
            @click="clearCustomerSelection"
            class="text-xs font-bold text-emerald-600 dark:text-emerald-400 hover:underline self-start sm:self-center"
          >
            Change / Walk-in
          </button>
        </div>

        <!-- Customer Search & Walk-in Inputs -->
        <div v-else class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          <div>
            <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
              Search Registered Customer
            </label>
            <div class="relative" ref="customerSearchContainer">
              <input
                v-model="customerSearchQuery"
                @focus="showCustomerDropdown = true"
                type="text"
                placeholder="Type customer name or mobile..."
                class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-semibold focus:ring-2 focus:ring-emerald-500"
              />
              <!-- Invisible Backdrop to close dropdown on click outside -->
              <div
                v-if="showCustomerDropdown"
                @click="showCustomerDropdown = false"
                class="fixed inset-0 z-20"
              ></div>

              <div
                v-if="showCustomerDropdown && filteredCustomers.length > 0"
                class="absolute left-0 right-0 top-full mt-1 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl shadow-xl max-h-52 overflow-y-auto z-30 divide-y divide-slate-100 dark:divide-slate-700"
              >
                <div
                  v-for="c in filteredCustomers"
                  :key="c.id"
                  @click="selectCustomer(c)"
                  class="p-2.5 hover:bg-emerald-50 dark:hover:bg-emerald-950/40 cursor-pointer flex items-center justify-between text-xs"
                >
                  <div>
                    <p class="font-bold text-slate-800 dark:text-slate-200">{{ c.name }}</p>
                    <p class="text-slate-400 font-mono text-[11px]">{{ c.phone || c.mobile }}</p>
                  </div>
                  <span class="text-[10px] font-bold text-emerald-600 bg-white dark:bg-slate-700 px-2 py-0.5 rounded">Select</span>
                </div>
              </div>
            </div>
          </div>

          <div>
            <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
              Or Walk-in Customer Name
            </label>
            <input
              v-model="form.customer_name"
              type="text"
              placeholder="e.g. Walk-in Customer, Amit, etc."
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-semibold"
            />
          </div>

          <div>
            <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
              Walk-in Mobile No. (For WhatsApp Bill)
            </label>
            <input
              v-model="form.customer_phone"
              type="tel"
              maxlength="10"
              placeholder="10-digit mobile number"
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs font-semibold font-mono"
            />
          </div>
        </div>
      </div>

      <!-- 2. Product Items & Inventory Selector Table -->
      <div class="bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200/80 dark:border-slate-700/80 shadow-sm space-y-4 overflow-visible">
        <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-lg bg-indigo-50 dark:bg-indigo-950/40 text-indigo-600 dark:text-indigo-400 flex items-center justify-center font-bold">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"/></svg>
            </div>
            <div>
              <h3 class="font-bold text-slate-900 dark:text-white text-sm">Line Items & Products</h3>
              <p class="text-[11px] text-slate-400">Pick from shop inventory stock or type custom line item</p>
            </div>
          </div>

          <div class="flex items-center gap-2">
            <button
              type="button"
              @click="openScannerModal(null)"
              class="text-xs font-bold text-emerald-700 dark:text-emerald-300 flex items-center gap-1.5 bg-emerald-50 dark:bg-emerald-950/50 hover:bg-emerald-100 dark:hover:bg-emerald-900/60 px-3 py-1.5 rounded-xl border border-emerald-200 dark:border-emerald-800 transition cursor-pointer shadow-sm"
              title="Scan barcode or IMEI sticker to add to cart"
            >
              <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z"/></svg>
              <span>📷 Scan Barcode / IMEI</span>
            </button>

            <button
              type="button"
              @click="addItemRow"
              class="text-xs font-bold text-indigo-600 hover:text-indigo-700 flex items-center gap-1 bg-indigo-50 dark:bg-indigo-950/40 px-3 py-1.5 rounded-xl border border-indigo-200 dark:border-indigo-800"
            >
              <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
              + Add Row
            </button>
          </div>
        </div>

        <!-- Items Table: overflow-visible so dropdown menu floats smoothly without artificial empty space -->
        <div class="overflow-visible">
          <table class="w-full text-xs">
            <thead>
              <tr class="text-slate-400 uppercase font-semibold border-b border-slate-200 dark:border-slate-700 text-left">
                <th class="py-2.5 w-1/3">Item Description / Inventory Picker</th>
                <th class="py-2.5 w-24 text-center">Qty</th>
                <th class="py-2.5 w-32 text-right">Unit Rate (₹)</th>
                <th class="py-2.5 w-32 text-right">Line Total (₹)</th>
                <th class="py-2.5 w-12 text-center"></th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100 dark:divide-slate-700/60 font-medium">
              <tr v-for="(item, idx) in form.items" :key="idx">
                <td class="py-3 pr-2 align-top">
                  <!-- Case 1: An inventory product is selected -> Clean single chip, NO duplicate input! -->
                  <div
                    v-if="item.inventory_item_id"
                    class="flex items-center justify-between p-2.5 rounded-xl bg-indigo-50/70 dark:bg-indigo-950/40 border border-indigo-200 dark:border-indigo-800/80 transition"
                  >
                    <div class="min-w-0 pr-2">
                      <div class="flex items-center gap-2">
                        <span class="text-base shrink-0">📦</span>
                        <span class="font-bold text-slate-900 dark:text-white truncate text-xs">{{ item.item_name }}</span>
                        <span class="px-2 py-0.5 rounded-md text-[10px] font-bold bg-emerald-100 dark:bg-emerald-900/60 text-emerald-700 dark:text-emerald-300 shrink-0">
                          Stock: {{ item.stock ?? getInventoryStock(item.inventory_item_id) }}
                        </span>
                      </div>
                    </div>
                    <button
                      type="button"
                      @click="unlinkInventoryItem(item)"
                      class="text-[11px] font-bold text-slate-500 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/50 px-2 py-1 rounded-lg transition shrink-0 cursor-pointer flex items-center gap-1"
                      title="Clear inventory item link to change or enter custom item"
                    >
                      <span>✕ Change</span>
                    </button>
                  </div>

                  <!-- Case 2: No inventory selected -> Single input with search dropdown like Customer Search -->
                  <div v-else class="relative">
                    <div class="relative">
                      <input
                        v-model="item.item_name"
                        @focus="openItemDropdown(idx)"
                        type="text"
                        placeholder="Search inventory or type custom item..."
                        required
                        class="w-full pl-8 pr-7 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-xs font-semibold focus:ring-2 focus:ring-indigo-500 text-slate-900 dark:text-slate-100 placeholder-slate-400"
                      />
                      <svg class="w-3.5 h-3.5 text-slate-400 absolute left-2.5 top-1/2 -translate-y-1/2 pointer-events-none" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                      </svg>
                      <button
                        v-if="item.item_name"
                        type="button"
                        @click="item.item_name = ''"
                        class="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 text-xs cursor-pointer p-0.5"
                      >
                        ✕
                      </button>
                      <button
                        v-else
                        type="button"
                        @click="openScannerModal(idx)"
                        class="absolute right-2 top-1/2 -translate-y-1/2 text-slate-400 hover:text-indigo-600 text-xs cursor-pointer p-1"
                        title="Scan barcode or IMEI for this row"
                      >
                        📷
                      </button>
                    </div>

                    <!-- Invisible Backdrop to close dropdown on click outside -->
                    <div
                      v-if="activeItemDropdownIndex === idx"
                      @click="activeItemDropdownIndex = null"
                      class="fixed inset-0 z-30"
                    ></div>

                    <!-- Dropdown List with Stock and Price (like Image 3 & Image 4) -->
                    <div
                      v-if="activeItemDropdownIndex === idx"
                      class="absolute left-0 top-full mt-1.5 w-[380px] sm:w-[480px] max-w-[90vw] bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl shadow-2xl z-40 max-h-64 overflow-y-auto custom-scroll divide-y divide-slate-100 dark:divide-slate-700/60 animate-in fade-in zoom-in-95"
                    >
                      <!-- Sticky Header -->
                      <div class="px-3.5 py-2 bg-slate-50 dark:bg-slate-900/70 text-[11px] font-bold text-slate-400 flex items-center justify-between sticky top-0 z-10 backdrop-blur-xs">
                        <span>Shop Inventory Stock ({{ getMatchingInventory(item.item_name).length }})</span>
                        <span class="text-[10px] text-indigo-500 font-semibold">Click item to select</span>
                      </div>

                      <!-- Inventory items -->
                      <div
                        v-for="inv in getMatchingInventory(item.item_name)"
                        :key="inv.id"
                        @click="selectInventoryItem(item, inv)"
                        class="p-2.5 hover:bg-indigo-50/80 dark:hover:bg-indigo-950/40 cursor-pointer flex items-center justify-between transition text-xs select-none"
                      >
                        <div class="min-w-0 pr-3">
                          <p class="font-bold text-slate-800 dark:text-slate-100 truncate text-xs">{{ inv.name }}</p>
                          <div class="flex items-center gap-2 text-[11px] text-slate-400 mt-0.5">
                            <span
                              :class="Number(inv.current_stock ?? 0) > 0 ? 'text-emerald-600 dark:text-emerald-400 font-semibold' : 'text-rose-500 font-semibold'"
                            >
                              Stock: {{ inv.current_stock ?? 0 }}
                            </span>
                            <span v-if="inv.brand" class="truncate">• {{ inv.brand }}</span>
                            <span v-if="inv.category?.name || inv.category" class="truncate">• {{ inv.category?.name || inv.category }}</span>
                          </div>
                        </div>
                        <div class="flex items-center gap-2.5 shrink-0">
                          <span class="font-bold text-slate-900 dark:text-white font-mono text-xs">
                            ₹{{ formatAmount(inv.selling_price) }}
                          </span>
                          <span class="text-[10px] font-bold text-indigo-600 dark:text-indigo-400 bg-indigo-50 dark:bg-indigo-900/40 border border-indigo-200 dark:border-indigo-800/80 px-2 py-0.5 rounded-lg hover:bg-indigo-600 hover:text-white transition">
                            Select
                          </span>
                        </div>
                      </div>

                      <!-- No matching inventory -->
                      <div v-if="getMatchingInventory(item.item_name).length === 0" class="p-3.5 text-center text-xs text-slate-400">
                        <p class="font-medium text-slate-600 dark:text-slate-300">No inventory item matches "{{ item.item_name }}"</p>
                        <p class="text-[11px] text-slate-400 mt-0.5">You can keep this as a custom line item or clear to view inventory</p>
                      </div>
                    </div>
                  </div>
                </td>

                <td class="py-3 px-2 text-center align-top">
                  <input
                    v-model.number="item.quantity"
                    type="number"
                    min="1"
                    required
                    class="w-20 px-2.5 py-2 text-center rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-xs font-bold"
                  />
                </td>

                <td class="py-3 px-2 text-right align-top">
                  <input
                    v-model.number="item.unit_price"
                    type="number"
                    step="0.01"
                    min="0"
                    required
                    class="w-28 px-2.5 py-2 text-right rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-xs font-bold font-mono"
                  />
                </td>

                <td class="py-3 px-2 text-right align-top pt-4">
                  <span class="font-bold text-slate-900 dark:text-white font-mono text-sm">
                    ₹{{ formatAmount(Number(item.quantity || 1) * Number(item.unit_price || 0)) }}
                  </span>
                </td>

                <td class="py-3 pl-2 text-center align-top pt-4">
                  <button
                    v-if="form.items.length > 1"
                    type="button"
                    @click="removeItemRow(idx)"
                    class="text-rose-500 hover:text-rose-700 p-1 rounded hover:bg-rose-50"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- 3. Billing, Discount & Settlement Summary -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Payment Method & Notes -->
        <div class="bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200/80 dark:border-slate-700/80 shadow-sm space-y-4">
          <h3 class="font-bold text-slate-900 dark:text-white text-sm border-b border-slate-100 dark:border-slate-700 pb-2">
            Payment & Settlement
          </h3>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">Payment Method</label>
              <SearchableSelect
                v-model="form.payment_method"
                :options="salePaymentOptions"
                placeholder="Select Method"
                minWidth="100%"
              />
            </div>

            <div>
              <div class="flex items-center justify-between mb-1">
                <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300">
                  Amount Paid Now (₹)
                </label>
                <!-- Quick Full Paid Action -->
                <div class="flex items-center gap-1.5">
                  <button
                    type="button"
                    @click="setFullPaid"
                    class="text-[11px] font-bold text-emerald-600 dark:text-emerald-400 hover:text-emerald-700 dark:hover:text-emerald-300 bg-emerald-50 dark:bg-emerald-950/50 hover:bg-emerald-100 dark:hover:bg-emerald-900/40 px-2 py-0.5 rounded-lg border border-emerald-200 dark:border-emerald-800 transition cursor-pointer flex items-center gap-1 shadow-xs"
                    title="Auto-fill total amount as paid"
                  >
                    <span>⚡ Full Paid</span>
                    <span v-if="grandTotal > 0" class="font-mono text-[10px] opacity-80">(₹{{ formatAmount(grandTotal) }})</span>
                  </button>
                  <button
                    type="button"
                    @click="setZeroPaid"
                    class="text-[10px] font-bold text-slate-500 hover:text-slate-700 dark:hover:text-slate-300 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 px-1.5 py-0.5 rounded-lg transition cursor-pointer"
                    title="Set paid amount to 0 (Due / Udhar)"
                  >
                    ₹0
                  </button>
                </div>
              </div>
              <input
                v-model.number="form.payment_amount"
                type="number"
                step="0.01"
                min="0"
                :max="grandTotal"
                class="w-full px-3.5 py-2.5 rounded-xl border bg-slate-50 dark:bg-slate-900 text-xs font-bold font-mono transition-colors"
                :class="[
                  Number(form.payment_amount || 0) > Number(grandTotal)
                    ? 'border-rose-500 text-rose-600 focus:ring-rose-500 bg-rose-50/40 dark:bg-rose-950/20'
                    : 'border-slate-200 dark:border-slate-700 text-emerald-600 focus:ring-emerald-500'
                ]"
              />
              <p
                v-if="Number(form.payment_amount || 0) > Number(grandTotal)"
                class="text-[11px] text-rose-500 font-bold mt-1 flex items-center gap-1"
              >
                <span>⚠️ Paid amount cannot exceed bill amount of ₹{{ formatAmount(grandTotal) }}</span>
              </p>
            </div>
          </div>

          <div>
            <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">Invoice Remarks / Customer Note</label>
            <input
              v-model="form.notes"
              type="text"
              placeholder="e.g. 6 Months warranty on display. No return on opened box."
              class="w-full px-3.5 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-xs"
            />
          </div>
        </div>

        <!-- Order Summary Card -->
        <div class="bg-slate-50 dark:bg-slate-900 rounded-2xl p-5 border border-slate-200 dark:border-slate-800 space-y-3 flex flex-col justify-between">
          <div>
            <h3 class="font-bold text-slate-900 dark:text-white text-sm border-b border-slate-200 dark:border-slate-700 pb-2 mb-3">
              Invoice Ledger Summary
            </h3>

            <div class="space-y-2 text-xs">
              <div class="flex justify-between text-slate-500">
                <span>Subtotal:</span>
                <span class="font-semibold text-slate-800 dark:text-slate-200 font-mono">₹{{ formatAmount(subtotal) }}</span>
              </div>
              <div class="flex justify-between items-center text-slate-500">
                <span>Special Discount (₹):</span>
                <input
                  v-model.number="form.discount"
                  type="number"
                  min="0"
                  class="w-24 px-2 py-1 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg text-right font-mono font-bold text-xs"
                />
              </div>
              <div class="flex justify-between font-extrabold text-base text-slate-900 dark:text-white pt-2 border-t border-slate-200 dark:border-slate-700">
                <span>Grand Total:</span>
                <span class="text-indigo-600 dark:text-indigo-400 font-mono">₹{{ formatAmount(grandTotal) }}</span>
              </div>
              <div class="flex justify-between text-emerald-600 font-semibold pt-1">
                <span>Amount Paid:</span>
                <span class="font-mono">₹{{ formatAmount(form.payment_amount) }}</span>
              </div>
              <div class="flex justify-between font-bold text-sm pt-2 border-t border-slate-200 dark:border-slate-700">
                <span>Balance Due:</span>
                <span :class="dueAmount > 0 ? 'text-rose-600' : 'text-emerald-600'" class="font-mono">
                  ₹{{ formatAmount(dueAmount) }}
                </span>
              </div>
            </div>
          </div>

          <button
            type="submit"
            :disabled="submitting"
            class="w-full py-3 rounded-xl bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-white font-bold text-xs shadow-lg shadow-emerald-500/20 transition"
          >
            {{ submitting ? 'Generating Invoice...' : 'Complete & Generate Tax Invoice' }}
          </button>
        </div>
      </div>
    </form>

    <!-- Quick Add Customer Modal -->
    <div
      v-if="showQuickCustomerModal"
      class="fixed inset-0 z-50 overflow-y-auto flex min-h-full items-center justify-center p-4 py-6 sm:py-10 bg-black/60 backdrop-blur-sm animate-fade-in"
      @wheel.stop
    >
      <div class="relative bg-white dark:bg-slate-800 rounded-3xl max-w-md w-full p-6 shadow-2xl border border-slate-200 dark:border-slate-700 space-y-4 my-auto max-h-[calc(100vh-3rem)] flex flex-col overflow-hidden">
        <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-3">
          <h3 class="font-bold text-slate-900 dark:text-white text-base">+ Quick Add Customer</h3>
          <button @click="showQuickCustomerModal = false" class="text-slate-400 hover:text-slate-600">✕</button>
        </div>

        <form @submit.prevent="submitQuickCustomer" class="space-y-4 text-xs">
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
              class="px-4 py-2 rounded-xl border border-slate-200 text-slate-600 font-semibold"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="quickCustomerSubmitting"
              class="px-5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold"
            >
              {{ quickCustomerSubmitting ? 'Saving...' : 'Save & Select' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Barcode & IMEI Scanner Modal -->
    <BarcodeScannerModal
      :is-open="scannerOpen"
      :title="scannerTitle"
      :initial-mode="scannerInitialMode"
      @close="scannerOpen = false"
      @scan="handleScannedSaleItem"
      @box-result="handleBoxResult"
    />
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { useToastStore } from '@/stores/toast';
import { useFilterStore } from '@/stores/filter';
import { saleApi, customerApi, inventoryApi } from '@/api/endpoints';
import SearchableSelect from '@/components/common/SearchableSelect.vue';
import BarcodeScannerModal from '@/components/common/BarcodeScannerModal.vue';

const router = useRouter();
const toast = useToastStore();
const filterStore = useFilterStore();

const customerSearchContainer = ref(null);

function handleClickOutside(event) {
  if (customerSearchContainer.value && !customerSearchContainer.value.contains(event.target)) {
    showCustomerDropdown.value = false;
  }
}

const salePaymentOptions = [
  { value: 'cash', label: 'Cash', icon: '💵' },
  { value: 'upi', label: 'UPI / Scanner', icon: '⚡' },
  { value: 'card', label: 'Card / POS', icon: '💳' },
  { value: 'bank_transfer', label: 'Bank Transfer', icon: '🏦' },
  { value: 'credit', label: 'On Credit (Due / Udhar)', icon: '⏳' },
];
const submitting = ref(false);
const errorMsg = ref('');

// Lists
const customers = ref([]);
const inventoryList = ref([]);

// Barcode & IMEI Scanner State
const scannerOpen = ref(false);
const scannerTitle = ref('Scan Barcode or IMEI');
const scannerInitialMode = ref('camera');
const scannerTargetIndex = ref(null);

function openScannerModal(targetIdx = null) {
  scannerTargetIndex.value = targetIdx;
  scannerTitle.value = targetIdx !== null ? 'Scan Item for Row' : 'Scan Product Barcode or IMEI';
  scannerInitialMode.value = 'camera';
  scannerOpen.value = true;
}

async function handleScannedSaleItem(code) {
  if (!code) return;
  const clean = code.trim();
  scannerOpen.value = false;

  // 1. Search in memory inventoryList (by SKU, barcode, or serialized IMEIs)
  let found = inventoryList.value.find(inv => {
    if (inv.sku && inv.sku.toLowerCase() === clean.toLowerCase()) return true;
    if (inv.barcode && inv.barcode.toLowerCase() === clean.toLowerCase()) return true;
    if (Array.isArray(inv.serials)) {
      return inv.serials.some(s =>
        (s.imei1 && s.imei1.toLowerCase() === clean.toLowerCase()) ||
        (s.imei2 && s.imei2.toLowerCase() === clean.toLowerCase()) ||
        (s.serial_number && s.serial_number.toLowerCase() === clean.toLowerCase())
      );
    }
    return false;
  });

  // 2. If not found in memory, query API
  if (!found) {
    try {
      const res = await inventoryApi.list({ search: clean, per_page: 5 });
      const results = res.data?.data?.data || res.data?.data || [];
      if (results.length > 0) {
        found = results[0];
      }
    } catch (_) {}
  }

  if (found) {
    if (scannerTargetIndex.value !== null && form.items[scannerTargetIndex.value]) {
      selectInventoryItem(form.items[scannerTargetIndex.value], found);
    } else {
      // Check if first row is untouched
      if (form.items.length === 1 && !form.items[0].inventory_item_id && !form.items[0].item_name) {
        selectInventoryItem(form.items[0], found);
      } else {
        // If already in list and not serialized, increment qty
        const existing = form.items.find(it => it.inventory_item_id === found.id);
        if (existing && found.item_type !== 'mobile') {
          existing.quantity = Number(existing.quantity || 1) + 1;
          toast.success(`Incremented quantity for ${found.name}!`, 'Item Updated');
          return;
        }
        form.items.push({
          inventory_item_id: found.id,
          item_name: found.name,
          quantity: 1,
          unit_price: Number(found.selling_price || 0),
          stock: Number(found.current_stock ?? 0),
        });
      }
    }
    toast.success(`Added "${found.name}" (₹${found.selling_price || 0})`, 'Item Scanned');
  } else {
    // Fallback: put scanned code as item description
    if (scannerTargetIndex.value !== null && form.items[scannerTargetIndex.value]) {
      form.items[scannerTargetIndex.value].item_name = clean;
    } else if (form.items.length === 1 && !form.items[0].inventory_item_id && !form.items[0].item_name) {
      form.items[0].item_name = clean;
    } else {
      form.items.push({
        inventory_item_id: null,
        item_name: clean,
        quantity: 1,
        unit_price: 0,
        stock: null,
      });
    }
    toast.info(`Scanned code "${clean}" added. Please specify price.`, 'Scanned');
  }
}

function handleBoxResult(res) {
  if (res.imei1) {
    handleScannedSaleItem(res.imei1);
  } else if (res.serialNumber) {
    handleScannedSaleItem(res.serialNumber);
  }
}

// Customer selection
const customerSearchQuery = ref('');
const showCustomerDropdown = ref(false);
const selectedCustomer = ref(null);

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
  customer_name: '',
  customer_phone: '',
  payment_method: 'cash',
  discount: 0,
  payment_amount: 0,
  notes: '',
  items: [
    { inventory_item_id: null, item_name: '', quantity: 1, unit_price: 0 },
  ],
});

const filteredCustomers = computed(() => {
  const q = customerSearchQuery.value.trim().toLowerCase();
  if (!q) return customers.value.slice(0, 10);
  return customers.value.filter(c =>
    (c.name && c.name.toLowerCase().includes(q)) ||
    (c.phone && c.phone.includes(q)) ||
    (c.mobile && c.mobile.includes(q))
  ).slice(0, 15);
});

const subtotal = computed(() => {
  return form.items.reduce((sum, item) => sum + ((Number(item.quantity) || 0) * (Number(item.unit_price) || 0)), 0);
});

const grandTotal = computed(() => {
  const tot = subtotal.value - (Number(form.discount) || 0);
  return tot > 0 ? tot : 0;
});

const dueAmount = computed(() => {
  const due = grandTotal.value - (Number(form.payment_amount) || 0);
  return due > 0 ? due : 0;
});

function setFullPaid() {
  form.payment_amount = Number(grandTotal.value) || 0;
}

function setZeroPaid() {
  form.payment_amount = 0;
}

// Active dropdown row index for inventory picker
const activeItemDropdownIndex = ref(null);

function openItemDropdown(idx) {
  activeItemDropdownIndex.value = idx;
}

function getMatchingInventory(query) {
  const q = String(query || '').trim().toLowerCase();
  if (!q) return inventoryList.value.slice(0, 15);
  return inventoryList.value.filter(inv => {
    const name = (inv.name || '').toLowerCase();
    const brand = (inv.brand || '').toLowerCase();
    const sku = (inv.sku || '').toLowerCase();
    const cat = (inv.category?.name || inv.category || '').toLowerCase();
    return name.includes(q) || brand.includes(q) || sku.includes(q) || cat.includes(q);
  }).slice(0, 20);
}

function selectInventoryItem(item, inv) {
  item.inventory_item_id = inv.id;
  item.item_name = inv.name;
  item.unit_price = Number(inv.selling_price || 0);
  item.stock = Number(inv.current_stock ?? 0);
  activeItemDropdownIndex.value = null;
}

function unlinkInventoryItem(item) {
  item.inventory_item_id = null;
  item.stock = null;
  const idx = form.items.indexOf(item);
  if (idx !== -1) {
    activeItemDropdownIndex.value = idx;
  }
}

function getInventoryStock(id) {
  if (!id) return 0;
  const found = inventoryList.value.find(i => i.id === id);
  return found ? (found.current_stock ?? 0) : 0;
}

function addItemRow() {
  form.items.push({ inventory_item_id: null, item_name: '', quantity: 1, unit_price: 0, stock: null });
  activeItemDropdownIndex.value = form.items.length - 1;
}

function removeItemRow(index) {
  form.items.splice(index, 1);
  if (activeItemDropdownIndex.value === index) {
    activeItemDropdownIndex.value = null;
  }
}

function selectCustomer(c) {
  selectedCustomer.value = c;
  form.customer_id = c.id;
  form.customer_name = c.name;
  form.customer_phone = c.phone || c.mobile || '';
  showCustomerDropdown.value = false;
}

function clearCustomerSelection() {
  selectedCustomer.value = null;
  form.customer_id = null;
  form.customer_name = '';
  form.customer_phone = '';
  customerSearchQuery.value = '';
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
      toast.success(`Customer "${created.name}" created and selected!`, 'Customer Added');
      quickCustomerForm.name = '';
      quickCustomerForm.phone = '';
      quickCustomerForm.city = '';
    }
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to create customer.';
    toast.error(msg, 'Customer Failed');
  } finally {
    quickCustomerSubmitting.value = false;
  }
}

async function loadData() {
  try {
    const [custRes, invRes] = await Promise.all([
      customerApi.list({ per_page: 200 }),
      inventoryApi.list({ per_page: 200 }),
    ]);
    customers.value = custRes.data?.data?.data || custRes.data?.data || [];
    inventoryList.value = invRes.data?.data?.data || invRes.data?.data || [];
  } catch (err) {
    console.error('Failed to load customers or inventory:', err);
  }
}

async function submitSale() {
  submitting.value = true;
  errorMsg.value = '';

  if (form.items.length === 0 || !form.items[0].item_name) {
    const msg = 'Please add at least one line item with a product name and price.';
    errorMsg.value = msg;
    toast.warning(msg, 'Incomplete Items');
    submitting.value = false;
    return;
  }

  // Strict Validation: Paid amount cannot be greater than the Grand Total
  const paid = Number(form.payment_amount ?? 0);
  const total = Number(grandTotal.value);
  if (paid > total) {
    const msg = `Paid amount (₹${formatAmount(paid)}) cannot exceed the total bill amount (₹${formatAmount(total)}).`;
    errorMsg.value = msg;
    toast.error(msg, 'Invalid Paid Amount');
    submitting.value = false;
    return;
  }

  try {
    const payload = {
      customer_id: form.customer_id || null,
      customer_name: form.customer_name || 'Walk-in Customer',
      customer_mobile: form.customer_phone || null,
      sale_type: form.customer_id ? 'regular' : 'quick',
      discount: Number(form.discount || 0),
      payment_amount: paid,
      payment_method: form.payment_method === 'credit' ? 'other' : (form.payment_method || 'cash'),
      notes: form.notes || null,
      items: form.items.map(it => ({
        inventory_item_id: it.inventory_item_id || null,
        product_name: it.item_name,
        item_name: it.item_name,
        quantity: Number(it.quantity || 1),
        unit_price: Number(it.unit_price || 0),
      })),
    };

    const res = await saleApi.create(payload);
    const saleId = res.data?.data?.id || res.data?.id;
    const invNo = res.data?.data?.invoice_number || res.data?.invoice_number || ('INV-' + saleId);
    toast.success(`Sale invoice #${invNo} generated successfully!`, 'Invoice Created');

    // Automatically set period filter to 'today' and redirect to Sales Listing
    filterStore.setPeriod('today');
    router.push('/sales');
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to complete sale. Check inputs.';
    errorMsg.value = msg;
    toast.error(msg, 'Sale Generation Failed');
  } finally {
    submitting.value = false;
  }
}

function formatAmount(amt) {
  return (Number(amt) || 0).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

onMounted(() => {
  loadData();
  document.addEventListener('click', handleClickOutside);
});

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside);
});
</script>
