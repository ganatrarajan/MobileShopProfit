<template>
  <div class="max-w-4xl mx-auto space-y-6 pb-16 font-['Outfit',sans-serif]">
    <!-- Top Action Bar -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 no-print">
      <div class="flex items-center gap-3">
        <router-link
          to="/sales"
          class="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-semibold rounded-xl bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-200 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 shadow-sm transition"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/></svg>
          Back to Sales
        </router-link>
        <div>
          <div class="flex items-center gap-2">
            <h1 class="text-2xl font-bold text-slate-900 dark:text-white">
              Invoice #{{ sale.invoice_number || sale.invoice_no || sale.id }}
            </h1>
            <span
              :class="dueAmount > 0 ? 'bg-amber-100 text-amber-800 border-amber-200' : 'bg-emerald-100 text-emerald-800 border-emerald-200'"
              class="px-2.5 py-0.5 rounded-full text-xs font-bold uppercase tracking-wide border"
            >
              {{ dueAmount > 0 ? 'Due: ₹' + formatAmount(dueAmount) : 'Fully Paid' }}
            </span>
          </div>
          <p class="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
            Billed on {{ formatDate(sale.sale_date || sale.created_at) }}
            <span v-if="sale.creator_name" class="ml-1">• Issued by {{ sale.creator_name }}</span>
          </p>
        </div>
      </div>

      <div class="flex flex-wrap items-center gap-2">
        <!-- WhatsApp Share (Only if mobile number exists) -->
        <button
          v-if="getCustomerPhone(sale)"
          @click="openWhatsAppModal"
          class="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold rounded-xl bg-[#25D366] text-white hover:bg-[#20ba5a] shadow-sm transition shadow-green-500/20 cursor-pointer"
        >
          <WhatsAppIcon sizeClass="w-4 h-4 text-white" />
          <span>WhatsApp Bill</span>
        </button>

        <!-- Collect Payment if Due -->
        <button
          v-if="dueAmount > 0"
          @click="openCollectModal"
          class="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white shadow-sm transition cursor-pointer"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
          + Collect Payment
        </button>

        <!-- Edit Invoice Info -->
        <button
          @click="openEditModal"
          class="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold rounded-xl bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-200 border border-slate-200 dark:border-slate-700 shadow-sm transition cursor-pointer"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
          Edit Info
        </button>

        <!-- Print Invoice -->
        <button
          @click="triggerPrint"
          class="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold rounded-xl bg-slate-800 text-white dark:bg-slate-700 hover:bg-slate-900 shadow-sm transition cursor-pointer"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"/></svg>
          Print Bill
        </button>
      </div>
    </div>

    <!-- Printable Official Invoice Document Card -->
    <div id="invoice-printable" class="bg-white dark:bg-[#111827] rounded-3xl p-6 sm:p-8 border border-slate-200/80 dark:border-slate-800/80 shadow-md space-y-6">
      <!-- Invoice Header: Shop & Bill Meta -->
      <div class="flex flex-col sm:flex-row sm:items-start justify-between border-b border-slate-200 dark:border-slate-800 pb-6 gap-4">
        <div>
          <div class="flex items-center gap-2.5">
            <div class="w-10 h-10 rounded-2xl bg-indigo-600 text-white flex items-center justify-center font-extrabold text-lg shadow-sm">
              {{ (shop.name || 'M')[0] }}
            </div>
            <div>
              <h1 class="text-2xl font-bold text-slate-900 dark:text-white">{{ shop.name || 'MyRepairHub Shop' }}</h1>
              <p class="text-xs text-slate-500 dark:text-slate-400">{{ shop.address || 'Smart Mobile Service & Electronics Store' }}</p>
            </div>
          </div>
          <div class="text-xs text-slate-500 dark:text-slate-400 mt-2 space-y-0.5">
            <p>{{ shop.city }} {{ shop.state }} {{ shop.pincode ? '-' + shop.pincode : '' }}</p>
            <p>Phone: {{ shop.phone || shop.mobile || '-' }}</p>
            <p v-if="shop.gst_number" class="font-mono text-slate-500 font-bold">GSTIN: {{ shop.gst_number }}</p>
          </div>
        </div>

        <div class="text-left sm:text-right">
          <span
            :class="sale.sale_type === 'quick' ? 'bg-amber-100 dark:bg-amber-950/60 text-amber-800 dark:text-amber-300' : 'bg-indigo-100 dark:bg-indigo-950/60 text-indigo-800 dark:text-indigo-300'"
            class="inline-block px-3 py-1 font-extrabold text-xs uppercase tracking-wider rounded-lg"
          >
            {{ sale.sale_type === 'quick' ? '⚡ QUICK POS RECEIPT' : 'RETAIL TAX INVOICE' }}
          </span>
          <p class="text-xl font-black text-slate-900 dark:text-white mt-2 font-mono">
            #{{ sale.invoice_number || sale.invoice_no || ('INV-' + String(sale.id || '').padStart(6, '0')) }}
          </p>
          <p class="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
            Date: {{ formatDate(sale.sale_date || sale.created_at) }}
          </p>
        </div>
      </div>

      <!-- Customer & Connected Device Row -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4 py-2 border-b border-slate-200 dark:border-slate-800">
        <!-- Billed To -->
        <div class="p-4 rounded-2xl bg-slate-50/70 dark:bg-slate-900/40 border border-slate-100 dark:border-slate-800">
          <div class="flex items-center justify-between">
            <p class="text-[10px] text-slate-400 font-extrabold uppercase tracking-wider">Billed To Customer</p>
            <button
              v-if="getCustomerPhone(sale)"
              @click="openWhatsAppModal"
              class="text-[11px] font-bold text-emerald-600 hover:text-emerald-700 flex items-center gap-1 cursor-pointer no-print"
            >
              <WhatsAppIcon sizeClass="w-3.5 h-3.5" />
              <span>WhatsApp</span>
            </button>
          </div>
          <p class="font-bold text-slate-900 dark:text-white text-base mt-1">
            {{ getCustomerName(sale) }}
          </p>
          <div class="text-xs text-slate-500 dark:text-slate-400 font-mono mt-1 space-y-0.5">
            <p v-if="getCustomerPhone(sale)">📞 {{ getCustomerPhone(sale) }}</p>
            <p v-if="sale.customer?.email" class="font-sans">✉️ {{ sale.customer.email }}</p>
            <p v-if="sale.customer?.city" class="font-sans">📍 {{ sale.customer.city }}</p>
          </div>
        </div>

        <!-- Connected Device / Notes -->
        <div class="p-4 rounded-2xl bg-slate-50/70 dark:bg-slate-900/40 border border-slate-100 dark:border-slate-800">
          <p class="text-[10px] text-slate-400 font-extrabold uppercase tracking-wider">
            {{ sale.device ? 'Connected Device' : 'Payment Status & Notes' }}
          </p>
          <div v-if="sale.device" class="mt-1">
            <p class="font-bold text-slate-900 dark:text-white text-sm">
              {{ sale.device.brand }} {{ sale.device.model }}
            </p>
            <div class="text-xs text-slate-500 dark:text-slate-400 font-mono mt-1 space-y-0.5">
              <p v-if="sale.device.imei1">IMEI 1: {{ sale.device.imei1 }}</p>
              <p v-if="sale.device.imei2">IMEI 2: {{ sale.device.imei2 }}</p>
            </div>
          </div>
          <div v-else class="mt-1">
            <p :class="dueAmount > 0 ? 'text-rose-600 dark:text-rose-400' : 'text-emerald-600 dark:text-emerald-400'" class="font-bold text-sm">
              {{ dueAmount > 0 ? 'Balance Due: ₹' + formatAmount(dueAmount) : 'Fully Paid & Cleared' }}
            </p>
            <p v-if="sale.notes" class="text-xs text-slate-500 dark:text-slate-400 mt-1 italic">
              "{{ sale.notes }}"
            </p>
          </div>
        </div>
      </div>

      <!-- Warranty Status Strip (Matching Flutter) -->
      <div v-if="sale.warranty" class="p-4 rounded-2xl bg-emerald-50/60 dark:bg-emerald-950/30 border border-emerald-200/80 dark:border-emerald-800/80 flex items-center justify-between">
        <div class="flex items-center gap-3">
          <div class="w-8 h-8 rounded-xl bg-emerald-100 dark:bg-emerald-900/50 text-emerald-700 dark:text-emerald-400 flex items-center justify-center font-bold">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/></svg>
          </div>
          <div>
            <div class="flex items-center gap-2">
              <span class="font-bold text-emerald-950 dark:text-emerald-300 text-xs">Active Warranty Linked</span>
              <span class="px-2 py-0.2 rounded text-[10px] font-black uppercase bg-emerald-200/60 text-emerald-800 dark:bg-emerald-800/60 dark:text-emerald-200">
                #{{ sale.warranty.warranty_number }}
              </span>
            </div>
            <p class="text-[11px] text-emerald-700 dark:text-emerald-400 mt-0.5">
              Valid until {{ formatDate(sale.warranty.warranty_end_date) }} ({{ sale.warranty.days_remaining }} days remaining)
              <span v-if="sale.warranty.warranty_terms" class="italic">• {{ sale.warranty.warranty_terms }}</span>
            </p>
          </div>
        </div>
      </div>

      <!-- Line Items Table -->
      <div class="overflow-x-auto">
        <table class="w-full text-xs">
          <thead>
            <tr class="text-slate-400 uppercase font-bold border-b border-slate-200 dark:border-slate-800 text-left">
              <th class="py-2.5 w-8">#</th>
              <th class="py-2.5">Item Description</th>
              <th class="py-2.5 text-center">Qty</th>
              <th class="py-2.5 text-right">Unit Rate</th>
              <th class="py-2.5 text-right">Tax / GST</th>
              <th class="py-2.5 text-right">Total</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100 dark:divide-slate-800/60 font-medium">
            <tr v-for="(it, i) in (sale.items || [])" :key="it.id || i" class="hover:bg-slate-50/50 dark:hover:bg-slate-800/30">
              <td class="py-3 text-slate-400 font-mono">{{ i + 1 }}</td>
              <td class="py-3 text-slate-800 dark:text-slate-200">
                <p class="font-bold text-slate-900 dark:text-white text-xs">
                  {{ it.product_name || it.item_name || 'Item' }}
                </p>
                <div class="text-[10px] text-slate-400 font-mono mt-0.5 space-y-0.5">
                  <p v-if="it.brand || it.model">{{ it.brand }} {{ it.model }}</p>
                  <p v-if="it.imei_1">IMEI: {{ it.imei_1 }}</p>
                  <p v-if="it.serial_number">SN: {{ it.serial_number }}</p>
                </div>
                <!-- Owner Cost & Item Profit Strip -->
                <div v-if="it.cost_price && Number(it.cost_price) > 0" class="mt-1 flex items-center gap-2 text-[10px] font-bold no-print">
                  <span class="text-slate-400">Cost: ₹{{ formatAmount(Number(it.cost_price) * Number(it.quantity || 1)) }}</span>
                  <span :class="(Number(it.unit_price) - Number(it.cost_price)) >= 0 ? 'text-emerald-600 dark:text-emerald-400' : 'text-rose-600'">
                    Profit: +₹{{ formatAmount((Number(it.unit_price) - Number(it.cost_price)) * Number(it.quantity || 1)) }}
                  </span>
                </div>
              </td>
              <td class="py-3 text-center text-slate-700 dark:text-slate-300 font-bold">{{ it.quantity }}</td>
              <td class="py-3 text-right text-slate-700 dark:text-slate-300 font-mono">₹{{ formatAmount(it.unit_price) }}</td>
              <td class="py-3 text-right text-slate-500 font-mono">
                <span v-if="Number(it.tax_rate) > 0 || Number(it.tax_amount) > 0" class="px-1.5 py-0.5 rounded bg-slate-100 dark:bg-slate-800 text-[10px] font-bold text-indigo-600 dark:text-indigo-400">
                  {{ it.tax_rate }}% GST (₹{{ formatAmount(it.tax_amount) }})
                </span>
                <span v-else class="text-slate-400">-</span>
              </td>
              <td class="py-3 text-right font-extrabold text-slate-900 dark:text-white font-mono text-xs">
                ₹{{ formatAmount(it.total || (Number(it.quantity || 1) * Number(it.unit_price || 0))) }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Financial Totals & Owner Margin Section -->
      <div class="border-t border-slate-200 dark:border-slate-800 pt-5 flex flex-col md:flex-row justify-between gap-6">
        <!-- Left: Net Profit & Margin Card (For Shop Owner) -->
        <div class="flex-1 p-4 rounded-2xl bg-teal-50/60 dark:bg-teal-950/30 border border-teal-200/80 dark:border-teal-800/80 space-y-2.5">
          <div class="flex items-center justify-between">
            <span class="text-xs font-bold text-teal-900 dark:text-teal-300 uppercase tracking-wide">Owner Profit Ledger</span>
            <span v-if="Number(sale.profit_margin_percent || 0) > 0" class="px-2 py-0.5 rounded text-[10px] font-black bg-emerald-600 text-white">
              {{ Math.round(sale.profit_margin_percent) }}% MARGIN
            </span>
          </div>

          <div class="grid grid-cols-2 gap-3 text-xs pt-1">
            <div>
              <p class="text-[10px] text-slate-400 uppercase font-semibold">Total Item Cost</p>
              <p class="font-bold text-slate-800 dark:text-slate-200 font-mono mt-0.5">₹{{ formatAmount(sale.total_cost || 0) }}</p>
            </div>
            <div>
              <p class="text-[10px] text-slate-400 uppercase font-semibold">Realized Net Profit</p>
              <p :class="Number(sale.net_profit || 0) >= 0 ? 'text-emerald-600 dark:text-emerald-400' : 'text-rose-600'" class="font-black text-sm font-mono mt-0.5">
                {{ Number(sale.net_profit || 0) >= 0 ? '+' : '' }}₹{{ formatAmount(sale.net_profit || 0) }}
              </p>
            </div>
          </div>

          <div v-if="dueAmount > 0" class="pt-2 border-t border-teal-200/50 dark:border-teal-900/50 text-[11px] text-teal-800 dark:text-teal-300 flex items-center justify-between">
            <span>Expected Profit on Full Collection:</span>
            <span class="font-bold font-mono">+₹{{ formatAmount(sale.expected_net_profit || sale.net_profit) }}</span>
          </div>
        </div>

        <!-- Right: Official Invoice Breakdown -->
        <div class="w-full md:w-80 space-y-2 text-xs">
          <div class="flex justify-between text-slate-500">
            <span>Subtotal:</span>
            <span class="font-semibold text-slate-800 dark:text-slate-200 font-mono">₹{{ formatAmount(sale.subtotal || sale.grand_total) }}</span>
          </div>

          <div v-if="Number(sale.discount || sale.total_discount || 0) > 0" class="flex justify-between text-slate-500">
            <span>Discount:</span>
            <span class="font-semibold text-emerald-600 font-mono">- ₹{{ formatAmount(sale.total_discount || sale.discount) }}</span>
          </div>

          <div v-if="Number(sale.tax_amount || 0) > 0" class="space-y-1 py-1 border-y border-slate-100 dark:border-slate-800">
            <div class="flex justify-between text-slate-500 text-[11px]">
              <span>Tax ({{ sale.tax_rate }}% GST {{ sale.tax_type === 'inclusive' ? 'Incl.' : 'Extra' }}):</span>
              <span class="font-mono font-semibold text-slate-800 dark:text-slate-200">₹{{ formatAmount(sale.tax_amount) }}</span>
            </div>
            <div v-if="Number(sale.cgst_amount || 0) > 0" class="flex justify-between text-slate-400 text-[10px] pl-2 font-mono">
              <span>CGST ({{ sale.tax_rate / 2 }}%):</span>
              <span>₹{{ formatAmount(sale.cgst_amount) }}</span>
            </div>
            <div v-if="Number(sale.sgst_amount || 0) > 0" class="flex justify-between text-slate-400 text-[10px] pl-2 font-mono">
              <span>SGST ({{ sale.tax_rate / 2 }}%):</span>
              <span>₹{{ formatAmount(sale.sgst_amount) }}</span>
            </div>
          </div>

          <div class="flex justify-between text-base font-black text-slate-900 dark:text-white pt-2 border-t border-slate-200 dark:border-slate-800">
            <span>Grand Total:</span>
            <span class="text-indigo-600 dark:text-indigo-400 font-mono">₹{{ formatAmount(sale.grand_total || sale.total_amount) }}</span>
          </div>

          <div class="flex justify-between text-emerald-600 font-bold pt-1">
            <span>Amount Paid:</span>
            <span class="font-mono">₹{{ formatAmount(paidAmount) }}</span>
          </div>

          <div class="flex justify-between font-black pt-1 border-t border-slate-100 dark:border-slate-800">
            <span>Balance Due:</span>
            <span :class="dueAmount > 0 ? 'text-rose-600' : 'text-emerald-600'" class="font-mono text-sm">
              ₹{{ formatAmount(dueAmount) }}
            </span>
          </div>
        </div>
      </div>

      <!-- Payment History Ledger -->
      <div class="pt-6 border-t border-slate-200 dark:border-slate-800 space-y-3">
        <h3 class="font-bold text-slate-900 dark:text-white text-sm">Payment History</h3>
        <div v-if="!sale.payments || sale.payments.length === 0" class="text-xs text-slate-400 italic">
          No payment transaction records found.
        </div>
        <div v-else class="space-y-2">
          <div
            v-for="p in sale.payments"
            :key="p.id"
            class="p-3 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-100 dark:border-slate-800 flex items-center justify-between text-xs"
          >
            <div class="flex items-center gap-2.5">
              <div class="w-7 h-7 rounded-lg bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 flex items-center justify-center font-bold">
                ✓
              </div>
              <div>
                <p class="font-bold text-slate-800 dark:text-slate-200 capitalize">
                  Paid via {{ (p.payment_method || 'Cash').toUpperCase() }}
                </p>
                <p class="text-[10px] text-slate-400 font-mono">
                  {{ formatDate(p.payment_date || p.created_at) }}
                  <span v-if="p.notes" class="font-sans">• {{ p.notes }}</span>
                </p>
              </div>
            </div>
            <p class="font-black text-emerald-600 dark:text-emerald-400 font-mono text-sm">
              + ₹{{ formatAmount(p.amount) }}
            </p>
          </div>
        </div>
      </div>

      <!-- Terms & Signature Footer -->
      <div class="pt-6 border-t border-slate-100 dark:border-slate-800 text-center text-[11px] text-slate-400 space-y-1">
        <p class="font-bold text-slate-600 dark:text-slate-300">Thank you for your business!</p>
        <p>Goods once sold will not be returned without original cash memo receipt.</p>
      </div>
    </div>

    <!-- Collect Payment Modal (Scroll-Safe, Non-Cutoff) -->
    <div
      v-if="showPaymentModal"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-3 sm:p-5 no-print"
      @wheel.stop
    >
      <div class="bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-3xl w-full max-w-md shadow-2xl flex flex-col max-h-[85vh] overflow-hidden animate-in fade-in zoom-in-95">
        <!-- Pinned Header -->
        <div class="p-5 sm:p-6 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between shrink-0 bg-slate-50/50 dark:bg-slate-900/50">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-2xl bg-emerald-50 dark:bg-emerald-950/50 text-emerald-600 dark:text-emerald-400 flex items-center justify-center font-bold">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
            </div>
            <div>
              <h3 class="text-base font-bold text-slate-900 dark:text-white">Collect Payment</h3>
              <p class="text-xs text-slate-400">#{{ sale.invoice_number || sale.invoice_no || sale.id }}</p>
            </div>
          </div>
          <button @click="showPaymentModal = false" class="text-slate-400 hover:text-slate-600 p-1.5 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800">✕</button>
        </div>

        <!-- Scrollable Body -->
        <div class="overflow-y-auto custom-scroll flex-1 p-5 sm:p-6 space-y-4 pb-8">
          <div class="p-4 rounded-2xl bg-amber-50 dark:bg-amber-950/40 border border-amber-200/80 dark:border-amber-800/80 flex items-center justify-between">
            <div>
              <p class="text-[11px] font-bold text-amber-800 dark:text-amber-400 uppercase tracking-wide">Outstanding Due</p>
              <p class="text-2xl font-black text-amber-700 dark:text-amber-300 mt-0.5">₹{{ formatAmount(dueAmount) }}</p>
            </div>
            <div class="text-right text-xs text-slate-500">
              <p class="font-bold text-slate-700 dark:text-slate-300">{{ getCustomerName(sale) }}</p>
              <p class="font-mono text-[11px]">{{ getCustomerPhone(sale) }}</p>
            </div>
          </div>

          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">
              Collection Amount (₹) <span class="text-rose-500">*</span>
            </label>
            <input
              v-model.number="paymentAmount"
              type="number"
              step="0.01"
              min="0.01"
              :max="dueAmount"
              required
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900 font-bold text-slate-900 dark:text-white text-sm"
            />
          </div>

          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">Payment Date</label>
            <input
              v-model="paymentDate"
              type="date"
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900 font-semibold text-xs"
            />
          </div>

          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">Payment Mode</label>
            <SearchableSelect
              v-model="paymentMethod"
              :options="paymentMethodOptions"
              placeholder="Select Method"
              minWidth="100%"
            />
          </div>

          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">Payment Notes (Optional)</label>
            <input
              v-model="paymentNotes"
              type="text"
              placeholder="e.g. Cleared pending balance"
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900 text-xs font-semibold"
            />
          </div>
        </div>

        <!-- Pinned Footer -->
        <div class="p-5 sm:p-6 border-t border-slate-100 dark:border-slate-800 flex items-center justify-end gap-2.5 shrink-0 bg-slate-50/50 dark:bg-slate-900/50">
          <button
            type="button"
            @click="showPaymentModal = false"
            class="px-4 py-2.5 rounded-xl text-xs font-bold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition"
          >
            Cancel
          </button>
          <button
            type="button"
            @click="submitPayment"
            :disabled="paymentSubmitting"
            class="px-5 py-2.5 rounded-xl text-xs font-bold bg-emerald-600 hover:bg-emerald-700 text-white shadow-md shadow-emerald-600/20 disabled:opacity-50 transition"
          >
            {{ paymentSubmitting ? 'Recording...' : 'Confirm Payment' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Edit Invoice Info Modal (Scroll-Safe, Non-Cutoff) -->
    <div
      v-if="showEditModal"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-3 sm:p-5 no-print"
      @wheel.stop
    >
      <div class="bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-3xl w-full max-w-md shadow-2xl flex flex-col max-h-[85vh] overflow-hidden animate-in fade-in zoom-in-95">
        <!-- Pinned Header -->
        <div class="p-5 sm:p-6 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between shrink-0 bg-slate-50/50 dark:bg-slate-900/50">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-2xl bg-indigo-50 dark:bg-indigo-950/50 text-indigo-600 dark:text-indigo-400 flex items-center justify-center font-bold">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
            </div>
            <div>
              <h3 class="text-base font-bold text-slate-900 dark:text-white">Edit Invoice Details</h3>
              <p class="text-xs text-slate-400">#{{ sale.invoice_number || sale.invoice_no || sale.id }}</p>
            </div>
          </div>
          <button @click="showEditModal = false" class="text-slate-400 hover:text-slate-600 p-1.5 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800">✕</button>
        </div>

        <!-- Scrollable Body -->
        <div class="overflow-y-auto custom-scroll flex-1 p-5 sm:p-6 space-y-4 pb-8">
          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">Customer Name</label>
            <input
              v-model="editForm.customer_name"
              type="text"
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900 text-xs font-semibold"
            />
          </div>

          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">Customer Mobile</label>
            <input
              v-model="editForm.customer_mobile"
              type="tel"
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900 text-xs font-mono font-semibold"
            />
          </div>

          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">Sale Date</label>
            <input
              v-model="editForm.sale_date"
              type="date"
              class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900 text-xs font-semibold"
            />
          </div>

          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">Invoice Notes / Remarks</label>
            <textarea
              v-model="editForm.notes"
              rows="3"
              class="w-full p-3 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900 text-xs font-semibold leading-relaxed"
            ></textarea>
          </div>
        </div>

        <!-- Pinned Footer -->
        <div class="p-5 sm:p-6 border-t border-slate-100 dark:border-slate-800 flex items-center justify-end gap-2.5 shrink-0 bg-slate-50/50 dark:bg-slate-900/50">
          <button
            type="button"
            @click="showEditModal = false"
            class="px-4 py-2.5 rounded-xl text-xs font-bold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition"
          >
            Cancel
          </button>
          <button
            type="button"
            @click="submitEditSale"
            :disabled="editSubmitting"
            class="px-5 py-2.5 rounded-xl text-xs font-bold bg-indigo-600 hover:bg-indigo-500 text-white shadow-md shadow-indigo-600/20 disabled:opacity-50 transition"
          >
            {{ editSubmitting ? 'Saving...' : 'Update Details' }}
          </button>
        </div>
      </div>
    </div>

    <!-- WhatsApp Share Modal (Scroll-Safe, Non-Cutoff) -->
    <div
      v-if="showWhatsAppModal"
      class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-3 sm:p-5 no-print"
      @wheel.stop
    >
      <div class="bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800/80 rounded-3xl w-full max-w-lg shadow-2xl flex flex-col max-h-[85vh] overflow-hidden animate-in fade-in zoom-in-95">
        <!-- Pinned Header -->
        <div class="p-5 sm:p-6 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between shrink-0 bg-slate-50/50 dark:bg-slate-900/50">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-2xl bg-emerald-50 dark:bg-emerald-950/50 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
              <WhatsAppIcon sizeClass="w-5 h-5" />
            </div>
            <div>
              <h3 class="text-base font-bold text-slate-900 dark:text-white">Send WhatsApp Invoice</h3>
              <p class="text-xs text-slate-400">{{ getCustomerName(sale) }} ({{ getCustomerPhone(sale) || 'No phone' }})</p>
            </div>
          </div>
          <button @click="showWhatsAppModal = false" class="text-slate-400 hover:text-slate-600 p-1.5 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800">✕</button>
        </div>

        <!-- Scrollable Body -->
        <div class="overflow-y-auto custom-scroll flex-1 p-5 sm:p-6 space-y-4 pb-8">
          <div>
            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">Message Preview</label>
            <textarea
              v-model="whatsAppMessageText"
              rows="7"
              class="w-full p-3 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900 font-mono text-xs leading-relaxed"
            ></textarea>
          </div>
        </div>

        <!-- Pinned Footer -->
        <div class="p-5 sm:p-6 border-t border-slate-100 dark:border-slate-800 flex items-center justify-end gap-2.5 shrink-0 bg-slate-50/50 dark:bg-slate-900/50">
          <button
            type="button"
            @click="showWhatsAppModal = false"
            class="px-4 py-2.5 rounded-xl text-xs font-bold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition"
          >
            Cancel
          </button>
          <button
            type="button"
            @click="sendWhatsAppMessage"
            class="px-5 py-2.5 rounded-xl text-xs font-bold bg-[#25D366] hover:bg-[#20ba5a] text-white shadow-md shadow-green-600/20 transition flex items-center gap-1.5 cursor-pointer"
          >
            <WhatsAppIcon sizeClass="w-4 h-4 text-white" />
            <span>Open in WhatsApp</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useToastStore } from '@/stores/toast';
import { saleApi, shopApi } from '@/api/endpoints';
import { formatDate } from '@/utils/date';
import WhatsAppIcon from '@/components/common/WhatsAppIcon.vue';
import SearchableSelect from '@/components/common/SearchableSelect.vue';

const toast = useToastStore();
const route = useRoute();

const paymentMethodOptions = [
  { value: 'cash', label: 'Cash', icon: '💵' },
  { value: 'upi', label: 'UPI / PhonePe / GPay', icon: '⚡' },
  { value: 'card', label: 'Debit / Credit Card', icon: '💳' },
  { value: 'bank_transfer', label: 'Bank Transfer', icon: '🏦' },
];

const sale = ref({});
const shop = ref({});

// Collect Payment State
const showPaymentModal = ref(false);
const paymentAmount = ref(0);
const paymentDate = ref(new Date().toISOString().substring(0, 10));
const paymentMethod = ref('cash');
const paymentNotes = ref('');
const paymentSubmitting = ref(false);

// Edit Sale State
const showEditModal = ref(false);
const editSubmitting = ref(false);
const editForm = reactive({
  customer_name: '',
  customer_mobile: '',
  sale_date: '',
  notes: '',
});

// WhatsApp State
const showWhatsAppModal = ref(false);
const whatsAppMessageText = ref('');

const paidAmount = computed(() => {
  const s = sale.value;
  if (!s) return 0;
  if (s.amount_paid !== undefined && s.amount_paid !== null) return Number(s.amount_paid);
  if (s.paid_amount !== undefined && s.paid_amount !== null) return Number(s.paid_amount);
  return Number(s.grand_total || s.total_amount || 0) - Number(s.amount_due || 0);
});

const dueAmount = computed(() => {
  const s = sale.value;
  if (!s) return 0;
  if (s.amount_due !== undefined && s.amount_due !== null) return Math.max(0, Number(s.amount_due));
  if (s.due_amount !== undefined && s.due_amount !== null) return Math.max(0, Number(s.due_amount));
  return Math.max(0, Number(s.grand_total || s.total_amount || 0) - paidAmount.value);
});

async function loadData() {
  try {
    const [saleRes, shopRes] = await Promise.all([
      saleApi.get(route.params.id),
      shopApi.get().catch(() => ({ data: { data: {} } })),
    ]);
    sale.value = saleRes.data?.data || saleRes.data || {};
    shop.value = shopRes.data?.data || shopRes.data || {};
    paymentAmount.value = dueAmount.value;
  } catch (err) {
    console.error('Failed to load invoice:', err);
    toast.error('Failed to load invoice details.', 'Error');
  }
}

function getCustomerName(s) {
  if (!s) return 'Walk-in Customer';
  return s.customer?.name || s.customer_name || 'Walk-in Customer';
}

function getCustomerPhone(s) {
  if (!s) return '';
  return s.customer?.mobile || s.customer?.phone || s.customer_mobile || s.customer_phone || '';
}

function openCollectModal() {
  paymentAmount.value = dueAmount.value;
  paymentDate.value = new Date().toISOString().substring(0, 10);
  paymentMethod.value = 'cash';
  paymentNotes.value = '';
  showPaymentModal.value = true;
}

async function submitPayment() {
  if (!paymentAmount.value || paymentAmount.value <= 0) {
    toast.error('Please enter a valid payment amount.', 'Invalid Amount');
    return;
  }
  paymentSubmitting.value = true;
  try {
    await saleApi.addPayment(sale.value.id, {
      amount: paymentAmount.value,
      payment_date: paymentDate.value,
      payment_method: paymentMethod.value,
      notes: paymentNotes.value || undefined,
    });
    showPaymentModal.value = false;
    toast.success(`Payment of ₹${formatAmount(paymentAmount.value)} collected successfully!`, 'Payment Received');
    await loadData();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to collect payment.';
    toast.error(msg, 'Payment Failed');
  } finally {
    paymentSubmitting.value = false;
  }
}

function openEditModal() {
  const s = sale.value;
  editForm.customer_name = s.customer_name || s.customer?.name || '';
  editForm.customer_mobile = s.customer_mobile || s.customer?.mobile || '';
  editForm.sale_date = s.sale_date ? s.sale_date.substring(0, 10) : (s.created_at ? s.created_at.substring(0, 10) : '');
  editForm.notes = s.notes || '';
  showEditModal.value = true;
}

async function submitEditSale() {
  editSubmitting.value = true;
  try {
    await saleApi.update(sale.value.id, {
      customer_name: editForm.customer_name || undefined,
      customer_mobile: editForm.customer_mobile || undefined,
      sale_date: editForm.sale_date || undefined,
      notes: editForm.notes,
    });
    showEditModal.value = false;
    toast.success('Invoice details updated.', 'Updated');
    await loadData();
  } catch (err) {
    const msg = err.response?.data?.message || 'Failed to update invoice.';
    toast.error(msg, 'Update Failed');
  } finally {
    editSubmitting.value = false;
  }
}

function openWhatsAppModal() {
  const s = sale.value;
  const custName = getCustomerName(s);
  const invNo = s.invoice_number || s.invoice_no || s.id;
  const grandTotal = formatAmount(s.grand_total || s.total_amount);
  const paid = formatAmount(paidAmount.value);
  const due = formatAmount(dueAmount.value);

  whatsAppMessageText.value =
    `Hello ${custName} 👋\n\n` +
    `Thank you for your purchase at *${shop.value.name || 'MyRepairHub'}*!\n\n` +
    `🧾 *Invoice #:* ${invNo}\n` +
    `📅 *Date:* ${formatDate(s.sale_date || s.created_at)}\n` +
    `💰 *Total Amount:* ₹${grandTotal}\n` +
    `✅ *Paid Amount:* ₹${paid}\n` +
    (dueAmount.value > 0 ? `⚠️ *Balance Due:* ₹${due}\n\n` : `🎉 *Payment Status:* Fully Cleared\n\n`) +
    `Thank you for visiting us!`;

  showWhatsAppModal.value = true;
}

function sendWhatsAppMessage() {
  const phone = getCustomerPhone(sale.value);
  if (!phone) {
    toast.warning('Customer has no phone number recorded.', 'No Phone Number');
    return;
  }
  let cleanPhone = String(phone).replace(/\D/g, '');
  if (cleanPhone.length === 10) cleanPhone = '91' + cleanPhone;
  const encoded = encodeURIComponent(whatsAppMessageText.value);
  window.open(`https://wa.me/${cleanPhone}?text=${encoded}`, '_blank');
  showWhatsAppModal.value = false;
  toast.success('WhatsApp chat opened!', 'WhatsApp');
}

function triggerPrint() {
  window.print();
}

function formatAmount(val) {
  if (val === undefined || val === null || isNaN(val)) return '0.00';
  return Number(val).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

onMounted(() => {
  loadData();
});
</script>

<style>
@media print {
  body * {
    visibility: hidden;
  }
  .no-print {
    display: none !important;
  }
  #invoice-printable,
  #invoice-printable * {
    visibility: visible;
  }
  #invoice-printable {
    position: absolute;
    left: 0;
    top: 0;
    width: 100%;
    margin: 0;
    padding: 20px;
    border: none;
    box-shadow: none;
  }
}
</style>
