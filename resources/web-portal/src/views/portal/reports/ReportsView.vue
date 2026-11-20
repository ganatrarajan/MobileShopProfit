<template>
  <div class="space-y-6 font-['Outfit',sans-serif]">
    <!-- Top Action Bar & Header -->
    <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4 print:hidden">
      <div>
        <div class="flex items-center gap-2">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 border border-indigo-200/60 dark:border-indigo-800/60">
            Business Intelligence
          </span>
          <span class="text-xs text-slate-400">Financials, Ledgers & Audits</span>
        </div>
        <h2 class="text-2xl font-bold tracking-tight text-slate-900 dark:text-white mt-1">Reports Hub & Analytics</h2>
        <p class="text-xs sm:text-sm text-slate-500 dark:text-slate-400">
          Comprehensive real-time metrics, revenue reconciliations, and downloadable audit ledgers
        </p>
      </div>

      <!-- Controls: Period Selector, Custom Dates & Download/Export -->
      <div class="flex flex-wrap items-center gap-2.5">
        <!-- Period Preset Selector -->
        <SearchableSelect
          v-model="selectedPeriod"
          :options="periodOptions"
          @change="onFilterChange"
          placeholder="Select Period"
          searchPlaceholder="Search period..."
          minWidth="140px"
          alignRight
        />

        <!-- Custom Date Range Inputs (Shown when 'custom' period is selected) -->
        <div v-if="selectedPeriod === 'custom'" class="flex items-center gap-2">
          <div class="w-36">
            <DatePicker
              v-model="customStartDate"
              placeholder="From date"
              @change="onFilterChange"
            />
          </div>
          <span class="text-slate-400 font-bold text-xs">to</span>
          <div class="w-36">
            <DatePicker
              v-model="customEndDate"
              placeholder="To date"
              @change="onFilterChange"
            />
          </div>
        </div>

        <!-- Download CSV Button -->
        <button
          type="button"
          @click="downloadCsv"
          :disabled="loading"
          class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold shadow-sm shadow-emerald-600/20 transition cursor-pointer disabled:opacity-50"
          title="Download report data as CSV file"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
          <span>Export CSV</span>
        </button>

        <!-- Direct PDF File Download Button -->
        <button
          type="button"
          @click="downloadPdf"
          :disabled="loading"
          class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold shadow-sm shadow-indigo-600/20 transition cursor-pointer disabled:opacity-50"
          title="Download report as PDF file directly"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
          </svg>
          <span>Download PDF</span>
        </button>

        <!-- Print Window Button -->
        <button
          type="button"
          @click="printReport"
          class="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#111827] text-slate-700 dark:text-slate-200 text-xs font-bold hover:bg-slate-50 dark:hover:bg-slate-800/60 shadow-sm transition cursor-pointer"
          title="Open printer window"
        >
          <svg class="w-4 h-4 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z" />
          </svg>
          <span>Print</span>
        </button>
      </div>
    </div>

    <!-- Print-Only Report Header (Visible only when printing) -->
    <div class="hidden print:block p-4 border-b border-slate-400 mb-4">
      <div class="flex justify-between items-center">
        <div>
          <h1 class="text-xl font-black text-black">MyRepairHub — {{ activeReportMeta.title }}</h1>
          <p class="text-xs text-gray-600">Period: {{ currentPeriodLabel }} | Generated: {{ new Date().toLocaleString() }}</p>
        </div>
        <div class="text-right text-xs">
          <p class="font-bold">Official Business Report</p>
          <p class="text-gray-500">Confidential Financial Audit</p>
        </div>
      </div>
    </div>

    <!-- 8 Mobile App Report Category Selector (Scrollable Tabs) -->
    <div class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800/80 shadow-xs p-1.5 flex gap-1.5 overflow-x-auto custom-scrollbar select-none print:hidden">
      <button
        v-for="cat in reportCategories"
        :key="cat.id"
        type="button"
        @click="selectTab(cat.id)"
        :class="[
          'flex items-center gap-2 px-3.5 py-2.5 rounded-xl text-xs font-bold whitespace-nowrap transition cursor-pointer flex-shrink-0',
          activeTab === cat.id
            ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/20'
            : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-slate-800/60'
        ]"
      >
        <span class="text-sm leading-none">{{ cat.icon }}</span>
        <span>{{ cat.name }}</span>
      </button>
    </div>

    <!-- Loading State Indicator -->
    <div v-if="loading" class="py-16 text-center text-slate-400 dark:text-slate-500">
      <div class="inline-block animate-spin w-8 h-8 border-3 border-indigo-600 border-t-transparent rounded-full mb-3"></div>
      <p class="text-xs font-semibold">Generating {{ activeReportMeta.name }} metrics...</p>
    </div>

    <!-- Main Active Report View -->
    <div v-else class="space-y-6">

      <!-- ========================================================================= -->
      <!-- 1. OUTSTANDING DUES REPORT                                                -->
      <!-- ========================================================================= -->
      <div v-if="activeTab === 'outstanding'" class="space-y-6">
        <!-- Outstanding Summary Cards (Dynamic by active category filter) -->
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <!-- CARD 1 -->
          <div class="p-5 rounded-2xl bg-gradient-to-br from-rose-500/10 via-rose-500/5 to-transparent dark:from-rose-950/30 dark:via-rose-950/10 dark:to-transparent border border-rose-200/80 dark:border-rose-900/40">
            <div class="flex items-center gap-1.5">
              <span class="w-2 h-2 rounded-full bg-rose-500 animate-pulse"></span>
              <p class="text-[11px] font-bold uppercase tracking-wider text-rose-700 dark:text-rose-400">
                {{
                  filterParams.category === 'repairs' ? 'Total Repair Dues (Pending)' :
                  filterParams.category === 'sales' ? 'Total Sales Dues (Pending)' :
                  filterParams.category === 'purchases' ? 'Total Vendor Payables' :
                  'Total Customer Receivables'
                }}
              </p>
            </div>
            <p class="text-2xl sm:text-3xl font-black text-rose-600 dark:text-rose-400 mt-2">
              ₹{{
                formatAmount(
                  filterParams.category === 'repairs' ? (reportData.summary?.total_repair_dues || 0) :
                  filterParams.category === 'sales' ? (reportData.summary?.total_sales_dues || 0) :
                  filterParams.category === 'purchases' ? (reportData.summary?.total_vendor_dues || 0) :
                  (reportData.summary?.total_customer_dues || 0)
                )
              }}
            </p>
            <p class="text-[11px] text-rose-600/80 dark:text-rose-400/80 mt-1">
              {{
                filterParams.category === 'repairs' ? `${reportData.summary?.repairs_count || 0} repair jobs with pending customer balance` :
                filterParams.category === 'sales' ? `${reportData.summary?.sales_count || 0} unpaid or partial sales invoices` :
                filterParams.category === 'purchases' ? `${reportData.summary?.purchases_count || 0} supplier purchase bills pending payment` :
                `Pending payments across ${(reportData.summary?.repairs_count || 0) + (reportData.summary?.sales_count || 0)} customer accounts`
              }}
            </p>
          </div>

          <!-- CARD 2 -->
          <div class="p-5 rounded-2xl bg-gradient-to-br from-amber-500/10 via-amber-500/5 to-transparent dark:from-amber-950/30 dark:via-amber-950/10 dark:to-transparent border border-amber-200/80 dark:border-amber-900/40">
            <p class="text-[11px] font-bold uppercase tracking-wider text-amber-700 dark:text-amber-400">
              {{
                filterParams.category === 'repairs' ? 'Total Repair Bill Value' :
                filterParams.category === 'sales' ? 'Total Sales Billed' :
                filterParams.category === 'purchases' ? 'Total Purchases Billed' :
                'Vendor Dues (Purchases)'
              }}
            </p>
            <p class="text-2xl sm:text-3xl font-black text-amber-600 dark:text-amber-400 mt-2">
              ₹{{
                formatAmount(
                  filterParams.category === 'repairs' ? (reportData.summary?.total_repair_billed || 0) :
                  filterParams.category === 'sales' ? (reportData.summary?.total_sales_billed || 0) :
                  filterParams.category === 'purchases' ? (reportData.summary?.total_purchase_billed || 0) :
                  (reportData.summary?.total_vendor_dues || 0)
                )
              }}
            </p>
            <p class="text-[11px] text-amber-600/80 dark:text-amber-400/80 mt-1">
              {{
                filterParams.category === 'repairs' ? 'Estimated / final charges on pending jobs' :
                filterParams.category === 'sales' ? 'Gross billed value of unpaid invoices' :
                filterParams.category === 'purchases' ? 'Gross purchase invoices from suppliers' :
                `${reportData.summary?.purchases_count || 0} bills shop owes to spare parts suppliers`
              }}
            </p>
          </div>

          <!-- CARD 3 -->
          <div class="p-5 rounded-2xl bg-gradient-to-br from-indigo-500/10 via-indigo-500/5 to-transparent dark:from-indigo-950/30 dark:via-indigo-950/10 dark:to-transparent border border-indigo-200/80 dark:border-indigo-900/40">
            <p class="text-[11px] font-bold uppercase tracking-wider text-indigo-700 dark:text-indigo-400">
              {{
                filterParams.category === 'repairs' ? 'Advance Amount Paid' :
                filterParams.category === 'sales' ? 'Amount Collected at POS' :
                filterParams.category === 'purchases' ? 'Paid to Suppliers' :
                'Net Balance Position'
              }}
            </p>
            <p class="text-2xl sm:text-3xl font-black text-indigo-600 dark:text-indigo-400 mt-2">
              ₹{{
                formatAmount(
                  filterParams.category === 'repairs' ? (reportData.summary?.total_repair_paid || 0) :
                  filterParams.category === 'sales' ? (reportData.summary?.total_sales_paid || 0) :
                  filterParams.category === 'purchases' ? (reportData.summary?.total_purchase_paid || 0) :
                  (reportData.summary?.net_balance || 0)
                )
              }}
            </p>
            <p class="text-[11px] text-indigo-600/80 dark:text-indigo-400/80 mt-1">
              {{
                filterParams.category === 'repairs' ? 'Advance cash / UPI already paid by customers' :
                filterParams.category === 'sales' ? 'Initial partial settlements realized at counter' :
                filterParams.category === 'purchases' ? 'Payments disbursed to parts vendors' :
                'Total Receivables minus Vendor Payables'
              }}
            </p>
          </div>
        </div>

        <!-- Filter Sub-bar with Live Counts -->
        <div class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800/80 p-4 flex flex-col sm:flex-row gap-3 items-center justify-between shadow-xs print:hidden">
          <div class="flex items-center gap-2 w-full sm:w-auto overflow-x-auto pb-1 sm:pb-0">
            <button
              v-for="sub in duesCategoryTabs"
              :key="sub.id"
              type="button"
              @click="setSubFilter('category', sub.id)"
              :class="[
                'px-3 py-1.5 rounded-lg text-xs font-bold transition cursor-pointer flex items-center gap-1.5 shrink-0',
                (filterParams.category || 'all') === sub.id
                  ? 'bg-indigo-600 text-white shadow-xs'
                  : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
              ]"
            >
              <span>{{ sub.label }}</span>
              <span
                class="px-1.5 py-0.2 rounded-full text-[10px] font-mono font-bold"
                :class="(filterParams.category || 'all') === sub.id ? 'bg-white/25 text-white' : 'bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300'"
              >
                {{ sub.count }}
              </span>
            </button>
          </div>

          <div class="w-full sm:w-72">
            <input
              type="text"
              v-model="searchQuery"
              @input="debounceSearch"
              placeholder="Search customer, job #, mobile..."
              class="w-full px-3 py-2 text-xs rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 focus:outline-none focus:border-indigo-500"
            />
          </div>
        </div>

        <!-- Dues Table -->
        <div class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800/80 shadow-xs overflow-hidden">
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse text-xs">
              <thead>
                <tr class="border-b border-slate-100 dark:border-slate-800 bg-slate-50/70 dark:bg-slate-900/50 text-[11px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                  <th class="px-5 py-3.5">Ref / Job #</th>
                  <th class="px-5 py-3.5">Party / Customer</th>
                  <th class="px-5 py-3.5">Category</th>
                  <th class="px-5 py-3.5">Date</th>
                  <th class="px-5 py-3.5 text-right">Total Bill</th>
                  <th class="px-5 py-3.5 text-right">Paid</th>
                  <th class="px-5 py-3.5 text-right">Pending Due</th>
                  <th class="px-5 py-3.5 text-center">Action</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 dark:divide-slate-800/60 font-medium">
                <tr v-if="!reportData.details || reportData.details.length === 0">
                  <td colspan="8" class="text-center py-10 text-slate-400">No outstanding dues records found matching filters.</td>
                </tr>
                <tr v-for="item in (reportData.details?.data || reportData.details || [])" :key="item.id" class="hover:bg-slate-50/60 dark:hover:bg-slate-800/40 transition">
                  <td class="px-5 py-3 font-mono font-bold text-indigo-600 dark:text-indigo-400">
                    <router-link
                      v-if="item.category === 'repairs'"
                      :to="`/repairs/${item.raw_id || item.id}`"
                      class="hover:underline"
                    >
                      {{ item.ref_number || item.id }}
                    </router-link>
                    <router-link
                      v-else-if="item.category === 'sales'"
                      :to="`/sales/${item.raw_id || item.id}`"
                      class="hover:underline"
                    >
                      {{ item.ref_number || item.id }}
                    </router-link>
                    <span v-else>{{ item.ref_number || item.id }}</span>
                  </td>
                  <td class="px-5 py-3">
                    <p class="font-bold text-slate-900 dark:text-white">{{ item.party_name || 'Walk-in Customer' }}</p>
                    <p class="text-[11px] font-mono text-slate-500 dark:text-slate-400 flex items-center gap-1 mt-0.5">
                      <span v-if="item.party_phone" class="font-semibold text-slate-700 dark:text-slate-300">📞 {{ item.party_phone }}</span>
                      <span v-else class="text-slate-400">No Mobile</span>
                    </p>
                  </td>
                  <td class="px-5 py-3">
                    <span
                      class="inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-bold shadow-xs whitespace-nowrap"
                      :class="[
                        item.category === 'repairs' ? 'bg-amber-50 text-amber-700 dark:bg-amber-950/60 dark:text-amber-300 border border-amber-200/80 dark:border-amber-900/50' :
                        item.category === 'sales' ? 'bg-blue-50 text-blue-700 dark:bg-blue-950/60 dark:text-blue-300 border border-blue-200/80 dark:border-blue-900/50' :
                        'bg-purple-50 text-purple-700 dark:bg-purple-950/60 dark:text-purple-300 border border-purple-200/80 dark:border-purple-900/50'
                      ]"
                    >
                      <span
                        class="w-1.5 h-1.5 rounded-full mr-1.5 shrink-0"
                        :class="[
                          item.category === 'repairs' ? 'bg-amber-500' :
                          item.category === 'sales' ? 'bg-blue-500' : 'bg-purple-500'
                        ]"
                      ></span>
                      {{ item.category_label || item.categoryLabel || item.category }}
                    </span>
                  </td>
                  <td class="px-5 py-3 text-slate-500 whitespace-nowrap">{{ formatDate(item.date) }}</td>
                  <td class="px-5 py-3 text-right font-mono font-bold text-slate-900 dark:text-white">₹{{ formatAmount(item.total_amount || item.totalAmount) }}</td>
                  <td class="px-5 py-3 text-right font-mono text-emerald-600 dark:text-emerald-400 font-semibold">₹{{ formatAmount(item.amount_paid || item.amountPaid) }}</td>
                  <td class="px-5 py-3 text-right font-mono">
                    <span class="inline-block px-2.5 py-0.5 rounded-md font-bold text-rose-600 dark:text-rose-400 bg-rose-50 dark:bg-rose-950/50 border border-rose-200/80 dark:border-rose-900/40">
                      ₹{{ formatAmount(item.amount_due || item.amountDue) }}
                    </span>
                  </td>
                  <td class="px-5 py-3 text-center">
                    <a
                      v-if="item.party_phone"
                      :href="`https://wa.me/${cleanPhone(item.party_phone)}?text=${encodeURIComponent(`Hello ${item.party_name}, this is a gentle reminder from our shop regarding pending balance of ₹${formatAmount(item.amount_due || item.amountDue)} for ${item.ref_number}. Kindly clear at your earliest convenience.`)}`"
                      target="_blank"
                      class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-emerald-50 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-400 font-bold hover:bg-emerald-100 transition shadow-xs cursor-pointer"
                      title="Send WhatsApp Payment Reminder"
                    >
                      <WhatsAppIcon sizeClass="w-3.5 h-3.5 text-emerald-600" />
                      <span>Remind</span>
                    </a>
                    <span v-else class="text-slate-300 dark:text-slate-600">—</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <PaginationBar
            v-if="reportData.details?.last_page"
            :pagination="reportData.details"
            @page-change="goToPage"
          />
        </div>
      </div>

      <!-- ========================================================================= -->
      <!-- 2. SALES REPORT                                                           -->
      <!-- ========================================================================= -->
      <div v-else-if="activeTab === 'sales'" class="space-y-6">
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Total Billed Sales</p>
            <p class="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white mt-1.5">₹{{ formatAmount(reportData.summary?.total_sales || 0) }}</p>
            <p class="text-[11px] text-slate-400 mt-1">Across {{ reportData.summary?.total_transactions || 0 }} total invoices</p>
          </div>
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-emerald-600 dark:text-emerald-400">Cash / UPI Collected</p>
            <p class="text-2xl sm:text-3xl font-black text-emerald-600 dark:text-emerald-400 mt-1.5">₹{{ formatAmount(reportData.summary?.total_collected || 0) }}</p>
            <p class="text-[11px] text-slate-400 mt-1">Realized payments</p>
          </div>
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-rose-600 dark:text-rose-400">Uncollected (Sales Dues)</p>
            <p class="text-2xl sm:text-3xl font-black text-rose-600 dark:text-rose-400 mt-1.5">₹{{ formatAmount(reportData.summary?.total_outstanding || 0) }}</p>
            <p class="text-[11px] text-slate-400 mt-1">Pending customer credit</p>
          </div>
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-indigo-600 dark:text-indigo-400">Discounts Given</p>
            <p class="text-2xl sm:text-3xl font-black text-indigo-600 dark:text-indigo-400 mt-1.5">₹{{ formatAmount(reportData.summary?.total_discounts || 0) }}</p>
            <p class="text-[11px] text-slate-400 mt-1">Promotional concessions</p>
          </div>
        </div>

        <!-- Top Selling Products Section -->
        <div v-if="reportData.top_products && reportData.top_products.length > 0" class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800 p-5 shadow-xs">
          <h4 class="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3 flex items-center gap-1.5">
            <span>🔥</span> Top Fast-Moving Products Sold
          </h4>
          <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-5 gap-3">
            <div v-for="(p, i) in reportData.top_products.slice(0, 5)" :key="i" class="p-3 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200/70 dark:border-slate-800">
              <p class="text-xs font-bold text-slate-800 dark:text-slate-200 truncate">{{ p.product_name }}</p>
              <div class="flex items-center justify-between text-[11px] text-slate-500 mt-1">
                <span>{{ p.total_quantity }} sold</span>
                <span class="font-bold text-indigo-600">₹{{ formatAmount(p.total_revenue) }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Table Filters with Live Counts -->
        <div class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800 p-4 flex flex-col sm:flex-row gap-3 items-center justify-between shadow-xs print:hidden">
          <div class="flex items-center gap-2 overflow-x-auto pb-1 sm:pb-0">
            <button
              v-for="sub in salesTypeTabs"
              :key="sub.id"
              type="button"
              @click="setSubFilter('sale_type', sub.id)"
              :class="[
                'px-3 py-1.5 rounded-lg text-xs font-bold transition cursor-pointer flex items-center gap-1.5 shrink-0',
                (filterParams.sale_type || 'all') === sub.id
                  ? 'bg-indigo-600 text-white shadow-xs'
                  : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 hover:text-slate-900'
              ]"
            >
              <span>{{ sub.label }}</span>
              <span
                class="px-1.5 py-0.2 rounded-full text-[10px] font-mono font-bold"
                :class="(filterParams.sale_type || 'all') === sub.id ? 'bg-white/25 text-white' : 'bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300'"
              >
                {{ sub.count }}
              </span>
            </button>
          </div>
          <div class="w-full sm:w-72">
            <input
              type="text"
              v-model="searchQuery"
              @input="debounceSearch"
              placeholder="Search invoice #, customer..."
              class="w-full px-3 py-2 text-xs rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 focus:outline-none focus:border-indigo-500"
            />
          </div>
        </div>

        <!-- Sales Data Table -->
        <div class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800 shadow-xs overflow-hidden">
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse text-xs">
              <thead>
                <tr class="border-b border-slate-100 dark:border-slate-800 bg-slate-50/70 dark:bg-slate-900/50 text-[11px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                  <th class="px-5 py-3.5">Invoice #</th>
                  <th class="px-5 py-3.5">Date</th>
                  <th class="px-5 py-3.5">Customer</th>
                  <th class="px-5 py-3.5">Sale Type</th>
                  <th class="px-5 py-3.5 text-right">Subtotal</th>
                  <th class="px-5 py-3.5 text-right">Discount</th>
                  <th class="px-5 py-3.5 text-right">Grand Total</th>
                  <th class="px-5 py-3.5 text-right">Paid</th>
                  <th class="px-5 py-3.5 text-right">Due</th>
                  <th class="px-5 py-3.5 text-center">Status</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 dark:divide-slate-800/60 font-medium">
                <tr v-if="!reportData.details?.data || reportData.details.data.length === 0">
                  <td colspan="10" class="text-center py-10 text-slate-400">No sales transactions found for this period.</td>
                </tr>
                <tr v-for="sale in reportData.details?.data" :key="sale.id" class="hover:bg-slate-50/60 dark:hover:bg-slate-800/40 transition">
                  <td class="px-5 py-3 font-mono font-bold text-indigo-600 dark:text-indigo-400">
                    <router-link :to="`/sales/${sale.id}`" class="hover:underline">{{ sale.invoice_number }}</router-link>
                  </td>
                  <td class="px-5 py-3 text-slate-500 whitespace-nowrap">{{ formatDate(sale.sale_date) }}</td>
                  <td class="px-5 py-3">
                    <p class="font-bold text-slate-900 dark:text-white">{{ sale.customer_name || 'Walk-in Customer' }}</p>
                    <p class="text-[11px] text-slate-400">{{ sale.customer_mobile || '—' }}</p>
                  </td>
                  <td class="px-5 py-3">
                    <span class="px-2 py-0.5 rounded text-[10px] font-bold bg-slate-100 dark:bg-slate-800 text-slate-600 uppercase">
                      {{ sale.sale_type }}
                    </span>
                  </td>
                  <td class="px-5 py-3 text-right font-mono">₹{{ formatAmount(sale.subtotal) }}</td>
                  <td class="px-5 py-3 text-right font-mono text-rose-500">₹{{ formatAmount(sale.discount) }}</td>
                  <td class="px-5 py-3 text-right font-mono font-bold">₹{{ formatAmount(sale.grand_total) }}</td>
                  <td class="px-5 py-3 text-right font-mono text-emerald-600 dark:text-emerald-400 font-semibold">₹{{ formatAmount(sale.amount_paid) }}</td>
                  <td class="px-5 py-3 text-right font-mono">
                    <span
                      class="font-bold"
                      :class="Number(sale.amount_due) > 0 ? 'inline-block px-2 py-0.5 rounded-md text-rose-600 dark:text-rose-400 bg-rose-50 dark:bg-rose-950/50 border border-rose-200/80 dark:border-rose-900/40' : 'text-slate-400'"
                    >
                      ₹{{ formatAmount(sale.amount_due) }}
                    </span>
                  </td>
                  <td class="px-5 py-3 text-center">
                    <span
                      class="inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-bold shadow-xs whitespace-nowrap"
                      :class="getSaleStatusBadgeClass(sale.payment_status)"
                    >
                      <span class="w-1.5 h-1.5 rounded-full mr-1.5 shrink-0" :class="getSaleStatusDotClass(sale.payment_status)"></span>
                      {{ getSaleStatusLabel(sale.payment_status) }}
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <PaginationBar
            v-if="reportData.details?.last_page"
            :pagination="reportData.details"
            @page-change="goToPage"
          />
        </div>
      </div>

      <!-- ========================================================================= -->
      <!-- 3. REPAIRS REPORT                                                         -->
      <!-- ========================================================================= -->
      <div v-else-if="activeTab === 'repairs'" class="space-y-6">
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Total Booked Jobs</p>
            <p class="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white mt-1.5">{{ reportData.summary?.total_repairs || 0 }}</p>
            <p class="text-[11px] text-slate-400 mt-1">All service job cards</p>
          </div>
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-emerald-600">Fixed & Delivered</p>
            <p class="text-2xl sm:text-3xl font-black text-emerald-600 mt-1.5">{{ (reportData.summary?.completed || 0) + (reportData.summary?.delivered || 0) }}</p>
            <p class="text-[11px] text-slate-400 mt-1">Successfully resolved</p>
          </div>
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-amber-600">Active In Workshop</p>
            <p class="text-2xl sm:text-3xl font-black text-amber-600 mt-1.5">{{ reportData.summary?.active || 0 }}</p>
            <p class="text-[11px] text-slate-400 mt-1">Under diagnostics / repair</p>
          </div>
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-indigo-600">Total Repair Revenue</p>
            <p class="text-2xl sm:text-3xl font-black text-indigo-600 mt-1.5">₹{{ formatAmount(reportData.summary?.repair_revenue || 0) }}</p>
            <p class="text-[11px] text-slate-400 mt-1">Avg Ticket: ₹{{ formatAmount(reportData.summary?.average_repair_value || 0) }}</p>
          </div>
        </div>

        <!-- Filter Sub-bar for Repairs -->
        <div class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800 p-4 flex flex-col sm:flex-row gap-3 items-center justify-between shadow-xs print:hidden">
          <div class="flex items-center gap-2 overflow-x-auto pb-1 sm:pb-0">
            <button
              v-for="sub in repairStatusTabs"
              :key="sub.id"
              type="button"
              @click="setSubFilter('status', sub.id)"
              :class="[
                'px-3 py-1.5 rounded-lg text-xs font-bold transition cursor-pointer flex items-center gap-1.5 shrink-0',
                (filterParams.status || 'all') === sub.id
                  ? 'bg-indigo-600 text-white shadow-xs'
                  : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 hover:text-slate-900'
              ]"
            >
              <span>{{ sub.label }}</span>
              <span
                class="px-1.5 py-0.2 rounded-full text-[10px] font-mono font-bold"
                :class="(filterParams.status || 'all') === sub.id ? 'bg-white/25 text-white' : 'bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300'"
              >
                {{ sub.count }}
              </span>
            </button>
          </div>
          <div class="w-full sm:w-72">
            <input
              type="text"
              v-model="searchQuery"
              @input="debounceSearch"
              placeholder="Search job #, customer, device..."
              class="w-full px-3 py-2 text-xs rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 focus:outline-none focus:border-indigo-500"
            />
          </div>
        </div>

        <!-- Repairs Table -->
        <div class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800 shadow-xs overflow-hidden">
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse text-xs">
              <thead>
                <tr class="border-b border-slate-100 dark:border-slate-800 bg-slate-50/70 dark:bg-slate-900/50 text-[11px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                  <th class="px-5 py-3.5">Job #</th>
                  <th class="px-5 py-3.5">Date</th>
                  <th class="px-5 py-3.5">Customer</th>
                  <th class="px-5 py-3.5">Device & Issue</th>
                  <th class="px-5 py-3.5 text-right">Cost (₹)</th>
                  <th class="px-5 py-3.5 text-right">Paid (₹)</th>
                  <th class="px-5 py-3.5 text-right">Due (₹)</th>
                  <th class="px-5 py-3.5 text-center">Status</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 dark:divide-slate-800/60 font-medium">
                <tr v-if="!reportData.details?.data || reportData.details.data.length === 0">
                  <td colspan="8" class="text-center py-10 text-slate-400">No repair jobs found in this period.</td>
                </tr>
                <tr v-for="job in reportData.details?.data" :key="job.id" class="hover:bg-slate-50/60 dark:hover:bg-slate-800/40 transition">
                  <td class="px-5 py-3 font-mono font-bold text-indigo-600 dark:text-indigo-400">
                    <router-link :to="`/repairs/${job.id}`" class="hover:underline">{{ job.job_number }}</router-link>
                  </td>
                  <td class="px-5 py-3 text-slate-500 whitespace-nowrap">{{ formatDate(job.created_at) }}</td>
                  <td class="px-5 py-3">
                    <p class="font-bold text-slate-900 dark:text-white">{{ job.customer?.name || 'Customer' }}</p>
                    <p class="text-[11px] text-slate-400">{{ job.customer?.mobile || '—' }}</p>
                  </td>
                  <td class="px-5 py-3">
                    <p class="font-bold text-slate-800 dark:text-slate-200">{{ job.device ? `${job.device.brand} ${job.device.model}` : 'Device' }}</p>
                    <p class="text-[11px] text-slate-400 truncate max-w-xs">{{ job.problem_description || 'General repair' }}</p>
                  </td>
                  <td class="px-5 py-3 text-right font-mono font-bold text-slate-900 dark:text-white">₹{{ formatAmount(job.final_cost || job.estimated_cost) }}</td>
                  <td class="px-5 py-3 text-right font-mono text-emerald-600 dark:text-emerald-400 font-semibold">₹{{ formatAmount(job.amount_paid) }}</td>
                  <td class="px-5 py-3 text-right font-mono">
                    <span
                      class="font-bold"
                      :class="Number(job.amount_due) > 0 ? 'inline-block px-2 py-0.5 rounded-md text-rose-600 dark:text-rose-400 bg-rose-50 dark:bg-rose-950/50 border border-rose-200/80 dark:border-rose-900/40' : 'text-slate-400'"
                    >
                      ₹{{ formatAmount(job.amount_due) }}
                    </span>
                  </td>
                  <td class="px-5 py-3 text-center">
                    <span
                      class="inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-bold shadow-xs whitespace-nowrap"
                      :class="getRepairStatusBadgeClass(job.repair_status)"
                    >
                      <span class="w-1.5 h-1.5 rounded-full mr-1.5 shrink-0" :class="getRepairStatusDotClass(job.repair_status)"></span>
                      {{ getRepairStatusLabel(job.repair_status) }}
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <PaginationBar
            v-if="reportData.details?.last_page"
            :pagination="reportData.details"
            @page-change="goToPage"
          />
        </div>
      </div>

      <!-- ========================================================================= -->
      <!-- 4. INVENTORY REPORT                                                       -->
      <!-- ========================================================================= -->
      <div v-else-if="activeTab === 'inventory'" class="space-y-6">
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-indigo-600">Total Stock Valuation</p>
            <p class="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white mt-1.5">₹{{ formatAmount(reportData.summary?.total_inventory_value || 0) }}</p>
            <p class="text-[11px] text-slate-400 mt-1">Cost basis inventory worth</p>
          </div>
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-slate-500">Total Stocked Units</p>
            <p class="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white mt-1.5">{{ reportData.summary?.total_stock_qty || 0 }}</p>
            <p class="text-[11px] text-slate-400 mt-1">Across {{ reportData.summary?.total_items || 0 }} SKU lines</p>
          </div>
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-amber-600">Low Stock Warning</p>
            <p class="text-2xl sm:text-3xl font-black text-amber-600 mt-1.5">{{ reportData.summary?.low_stock || 0 }}</p>
            <p class="text-[11px] text-slate-400 mt-1">Items at or below reorder level</p>
          </div>
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-rose-600">Out of Stock</p>
            <p class="text-2xl sm:text-3xl font-black text-rose-600 mt-1.5">{{ reportData.summary?.out_of_stock || 0 }}</p>
            <p class="text-[11px] text-slate-400 mt-1">Zero quantity items</p>
          </div>
        </div>

        <!-- Inventory Stock Movement In Period -->
        <div class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800 p-5 shadow-xs">
          <h4 class="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3">📦 Stock Movements in Period</h4>
          <div class="grid grid-cols-2 sm:grid-cols-5 gap-3 text-center">
            <div class="p-3 bg-emerald-50 dark:bg-emerald-950/40 rounded-xl">
              <p class="text-lg font-black text-emerald-600">+{{ reportData.summary?.stock_purchased || 0 }}</p>
              <p class="text-[10px] uppercase font-bold text-emerald-700 dark:text-emerald-400">Purchased Units</p>
            </div>
            <div class="p-3 bg-blue-50 dark:bg-blue-950/40 rounded-xl">
              <p class="text-lg font-black text-blue-600">-{{ reportData.summary?.stock_sold || 0 }}</p>
              <p class="text-[10px] uppercase font-bold text-blue-700 dark:text-blue-400">Sold via POS</p>
            </div>
            <div class="p-3 bg-amber-50 dark:bg-amber-950/40 rounded-xl">
              <p class="text-lg font-black text-amber-600">-{{ reportData.summary?.stock_used_in_repairs || 0 }}</p>
              <p class="text-[10px] uppercase font-bold text-amber-700 dark:text-amber-400">Used in Repairs</p>
            </div>
            <div class="p-3 bg-rose-50 dark:bg-rose-950/40 rounded-xl">
              <p class="text-lg font-black text-rose-600">{{ reportData.summary?.damaged_stock || 0 }}</p>
              <p class="text-[10px] uppercase font-bold text-rose-700 dark:text-rose-400">Damaged / Scrap</p>
            </div>
            <div class="p-3 bg-purple-50 dark:bg-purple-950/40 rounded-xl">
              <p class="text-lg font-black text-purple-600">{{ reportData.summary?.returned_stock || 0 }}</p>
              <p class="text-[10px] uppercase font-bold text-purple-700 dark:text-purple-400">Returns</p>
            </div>
          </div>
        </div>

        <!-- Inventory Products Valuation Table -->
        <div class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800 shadow-xs overflow-hidden">
          <div class="p-4 border-b border-slate-100 dark:border-slate-800 flex flex-col sm:flex-row items-center justify-between gap-3">
            <h4 class="text-xs font-bold uppercase tracking-wider text-slate-600 dark:text-slate-300 flex items-center gap-1.5">
              <span>📦</span> Shop Inventory Items & Stock Valuation Ledger
            </h4>
            <div class="w-full sm:w-64">
              <input
                type="text"
                v-model="searchQuery"
                @input="debounceSearch"
                placeholder="Search product, SKU, brand..."
                class="w-full px-3 py-1.5 text-xs rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 focus:outline-none focus:border-indigo-500"
              />
            </div>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse text-xs">
              <thead>
                <tr class="border-b border-slate-100 dark:border-slate-800 bg-slate-50/70 dark:bg-slate-900/50 text-[11px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                  <th class="px-5 py-3.5">Product Name</th>
                  <th class="px-5 py-3.5">Category & Brand</th>
                  <th class="px-5 py-3.5 text-center">Current Stock</th>
                  <th class="px-5 py-3.5 text-right">Cost Price (₹)</th>
                  <th class="px-5 py-3.5 text-right">Selling Price (₹)</th>
                  <th class="px-5 py-3.5 text-right">Total Valuation (₹)</th>
                  <th class="px-5 py-3.5 text-center">Status</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 dark:divide-slate-800/60 font-medium">
                <tr v-if="!reportData.details?.data || reportData.details.data.length === 0">
                  <td colspan="7" class="text-center py-10 text-slate-400">No inventory products found.</td>
                </tr>
                <tr v-for="item in reportData.details?.data" :key="item.id" class="hover:bg-slate-50/60 dark:hover:bg-slate-800/40 transition">
                  <td class="px-5 py-3">
                    <p class="font-bold text-slate-900 dark:text-white">{{ item.name }}</p>
                    <p v-if="item.sku" class="text-[11px] font-mono text-slate-400">SKU: {{ item.sku }}</p>
                  </td>
                  <td class="px-5 py-3">
                    <p class="text-slate-800 dark:text-slate-200">{{ item.category?.name || item.category || 'General' }}</p>
                    <p v-if="item.brand" class="text-[11px] text-slate-400">{{ item.brand }}</p>
                  </td>
                  <td class="px-5 py-3 text-center">
                    <span
                      :class="[
                        'px-2.5 py-0.5 rounded-full text-xs font-bold font-mono',
                        Number(item.current_stock) <= 0 ? 'bg-rose-100 text-rose-700 dark:bg-rose-950/60 dark:text-rose-400' :
                        Number(item.current_stock) <= Number(item.min_stock || 3) ? 'bg-amber-100 text-amber-700 dark:bg-amber-950/60 dark:text-amber-400' :
                        'bg-emerald-100 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-400'
                      ]"
                    >
                      {{ item.current_stock ?? 0 }}
                    </span>
                  </td>
                  <td class="px-5 py-3 text-right font-mono">₹{{ formatAmount(item.purchase_cost || item.cost_price || 0) }}</td>
                  <td class="px-5 py-3 text-right font-mono font-semibold text-slate-900 dark:text-white">₹{{ formatAmount(item.selling_price || 0) }}</td>
                  <td class="px-5 py-3 text-right font-mono font-bold text-indigo-600 dark:text-indigo-400">
                    ₹{{ formatAmount((Number(item.purchase_cost || item.cost_price || 0)) * (Number(item.current_stock || 0))) }}
                  </td>
                  <td class="px-5 py-3 text-center">
                    <span
                      :class="[
                        'px-2 py-0.5 rounded-full text-[10px] font-bold uppercase',
                        Number(item.current_stock) <= 0 ? 'bg-rose-100 text-rose-700 dark:bg-rose-950/60 dark:text-rose-400' :
                        Number(item.current_stock) <= Number(item.min_stock || 3) ? 'bg-amber-100 text-amber-700 dark:bg-amber-950/60 dark:text-amber-400' :
                        'bg-emerald-100 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-400'
                      ]"
                    >
                      {{ Number(item.current_stock) <= 0 ? 'Out of Stock' : Number(item.current_stock) <= Number(item.min_stock || 3) ? 'Low Stock' : 'In Stock' }}
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <PaginationBar
            v-if="reportData.details?.last_page"
            :pagination="reportData.details"
            @page-change="goToPage"
          />
        </div>
      </div>

      <!-- ========================================================================= -->
      <!-- 5. EXPENSES REPORT                                                        -->
      <!-- ========================================================================= -->
      <div v-else-if="activeTab === 'expenses'" class="space-y-6">
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-rose-600">Total Shop Expenses</p>
            <p class="text-2xl sm:text-3xl font-black text-rose-600 mt-1.5">₹{{ formatAmount(reportData.summary?.total_expenses || 0) }}</p>
            <p class="text-[11px] text-slate-400 mt-1">Operational overhead disbursements</p>
          </div>
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-slate-500">Expense Vouchers</p>
            <p class="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white mt-1.5">{{ reportData.details?.total || reportData.by_category?.length || 0 }}</p>
            <p class="text-[11px] text-slate-400 mt-1">Individual payments logged</p>
          </div>
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-indigo-600">Active Categories</p>
            <p class="text-2xl sm:text-3xl font-black text-indigo-600 mt-1.5">{{ reportData.by_category?.length || 0 }}</p>
            <p class="text-[11px] text-slate-400 mt-1">Rent, tea, electricity, parts</p>
          </div>
        </div>

        <!-- Expense Category Breakdown Cards -->
        <div v-if="reportData.by_category && reportData.by_category.length > 0" class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800 p-5 shadow-xs">
          <h4 class="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3">Expense Spend By Category</h4>
          <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-3">
            <div v-for="cat in reportData.by_category" :key="cat.category_id || cat.category_name" class="p-3.5 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 flex items-center justify-between">
              <div>
                <p class="text-xs font-bold text-slate-800 dark:text-slate-200">{{ cat.category_name }}</p>
                <p class="text-[10px] text-slate-400">{{ cat.count }} transactions</p>
              </div>
              <p class="text-sm font-black font-mono text-rose-600">₹{{ formatAmount(cat.total_amount) }}</p>
            </div>
          </div>
        </div>

        <!-- Expense Details Table -->
        <div class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800 shadow-xs overflow-hidden">
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse text-xs">
              <thead>
                <tr class="border-b border-slate-100 dark:border-slate-800 bg-slate-50/70 dark:bg-slate-900/50 text-[11px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                  <th class="px-5 py-3.5">Date</th>
                  <th class="px-5 py-3.5">Category</th>
                  <th class="px-5 py-3.5">Title / Memo</th>
                  <th class="px-5 py-3.5">Payment Mode</th>
                  <th class="px-5 py-3.5 text-right">Amount</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 dark:divide-slate-800/60 font-medium">
                <tr v-if="!reportData.details?.data || reportData.details.data.length === 0">
                  <td colspan="5" class="text-center py-10 text-slate-400">No expense entries found for this period.</td>
                </tr>
                <tr v-for="exp in reportData.details?.data" :key="exp.id" class="hover:bg-slate-50/60 dark:hover:bg-slate-800/40 transition">
                  <td class="px-5 py-3 text-slate-500 whitespace-nowrap">{{ formatDate(exp.expense_date) }}</td>
                  <td class="px-5 py-3">
                    <span class="px-2 py-0.5 rounded text-[10px] font-bold bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300">
                      {{ exp.category?.name || 'Uncategorized' }}
                    </span>
                  </td>
                  <td class="px-5 py-3">
                    <p class="font-bold text-slate-900 dark:text-white">{{ exp.title }}</p>
                    <p v-if="exp.notes" class="text-[11px] text-slate-400">{{ exp.notes }}</p>
                  </td>
                  <td class="px-5 py-3 capitalize text-slate-600 dark:text-slate-400">{{ exp.payment_method }}</td>
                  <td class="px-5 py-3 text-right font-mono font-bold text-rose-600">₹{{ formatAmount(exp.amount) }}</td>
                </tr>
              </tbody>
            </table>
          </div>
          <PaginationBar
            v-if="reportData.details?.last_page"
            :pagination="reportData.details"
            @page-change="goToPage"
          />
        </div>
      </div>

      <!-- ========================================================================= -->
      <!-- 6. PAYMENTS & COLLECTIONS REPORT                                          -->
      <!-- ========================================================================= -->
      <div v-else-if="activeTab === 'payments'" class="space-y-6">
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Total Collected</p>
            <p class="text-2xl sm:text-3xl font-black text-emerald-600 mt-1.5">₹{{ formatAmount(reportData.summary?.total_payments || 0) }}</p>
            <p class="text-[11px] text-slate-400 mt-1">Across all payment channels</p>
          </div>
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-emerald-600">Cash Collections</p>
            <p class="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white mt-1.5">₹{{ formatAmount(reportData.summary?.cash_total || 0) }}</p>
            <p class="text-[11px] text-slate-400 mt-1">Physical counter cash</p>
          </div>
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-indigo-600">UPI / QR Collections</p>
            <p class="text-2xl sm:text-3xl font-black text-indigo-600 mt-1.5">₹{{ formatAmount(reportData.summary?.upi_total || 0) }}</p>
            <p class="text-[11px] text-slate-400 mt-1">PhonePe, GPay, Paytm QR</p>
          </div>
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-purple-600">Card / NetBanking</p>
            <p class="text-2xl sm:text-3xl font-black text-purple-600 mt-1.5">₹{{ formatAmount((reportData.summary?.card_total || 0) + (reportData.summary?.bank_total || 0)) }}</p>
            <p class="text-[11px] text-slate-400 mt-1">POS swipe & transfers</p>
          </div>
        </div>
      </div>

      <!-- ========================================================================= -->
      <!-- 7. CUSTOMERS & KHATA REPORT                                               -->
      <!-- ========================================================================= -->
      <div v-else-if="activeTab === 'customers'" class="space-y-6">
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Total Registered Customers</p>
            <p class="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white mt-1.5">{{ reportData.summary?.total_customers || 0 }}</p>
            <p class="text-[11px] text-slate-400 mt-1">Shop customer khata profiles</p>
          </div>
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-emerald-600">New In Period</p>
            <p class="text-2xl sm:text-3xl font-black text-emerald-600 mt-1.5">{{ reportData.summary?.new_customers || 0 }}</p>
            <p class="text-[11px] text-slate-400 mt-1">First-time customers</p>
          </div>
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-indigo-600">Repeat Customers</p>
            <p class="text-2xl sm:text-3xl font-black text-indigo-600 mt-1.5">{{ reportData.summary?.repeat_customers ?? 0 }}</p>
            <p class="text-[11px] text-slate-400 mt-1">Customers with 2+ visits</p>
          </div>
        </div>

        <!-- Top Spenders Section -->
        <div v-if="reportData.top_customers && reportData.top_customers.length > 0" class="bg-white dark:bg-[#111827] rounded-2xl border border-slate-200/80 dark:border-slate-800 p-5 shadow-xs">
          <h4 class="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3">👑 Top Spending VIP Customers</h4>
          <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-5 gap-3">
            <div v-for="c in reportData.top_customers" :key="c.id" class="p-3.5 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800">
              <p class="text-xs font-bold text-slate-800 dark:text-slate-200 truncate">{{ c.name }}</p>
              <p class="text-[11px] text-slate-400">{{ c.mobile || '—' }}</p>
              <p class="text-xs font-mono font-bold text-indigo-600 mt-2">₹{{ formatAmount(c.total_spent) }}</p>
            </div>
          </div>
        </div>
      </div>

      <!-- ========================================================================= -->
      <!-- 8. WARRANTIES REPORT                                                      -->
      <!-- ========================================================================= -->
      <div v-else-if="activeTab === 'warranties'" class="space-y-6">
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-slate-400">Total Warranties Issued</p>
            <p class="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white mt-1.5">{{ reportData.summary?.total_warranties || 0 }}</p>
            <p class="text-[11px] text-slate-400 mt-1">Guarantees issued on repairs & parts</p>
          </div>
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-emerald-600">Active Warranties</p>
            <p class="text-2xl sm:text-3xl font-black text-emerald-600 mt-1.5">{{ reportData.summary?.active || 0 }}</p>
            <p class="text-[11px] text-slate-400 mt-1">Currently under valid protection</p>
          </div>
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-amber-600">Claims Received</p>
            <p class="text-2xl sm:text-3xl font-black text-amber-600 mt-1.5">{{ reportData.summary?.total_claims || 0 }}</p>
            <p class="text-[11px] text-slate-400 mt-1">Claims submitted by customers</p>
          </div>
          <div class="p-5 rounded-2xl bg-white dark:bg-[#111827] border border-slate-200/80 dark:border-slate-800 shadow-xs">
            <p class="text-[11px] font-bold uppercase tracking-wider text-indigo-600">Claim Rate</p>
            <p class="text-2xl sm:text-3xl font-black text-indigo-600 mt-1.5">{{ reportData.summary?.claim_rate || '0%' }}</p>
            <p class="text-[11px] text-slate-400 mt-1">{{ reportData.summary?.resolved_claims || 0 }} claims settled</p>
          </div>
        </div>
      </div>

    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { reportApi } from '@/api/endpoints';
import { formatDate } from '@/utils/date';
import SearchableSelect from '@/components/common/SearchableSelect.vue';
import PaginationBar from '@/components/common/PaginationBar.vue';
import WhatsAppIcon from '@/components/common/WhatsAppIcon.vue';
import DatePicker from '@/components/common/DatePicker.vue';

// 8 Official Mobile App Report Categories
const reportCategories = [
  { id: 'outstanding', name: 'Outstanding Dues', icon: '🚨', title: 'Outstanding Dues Ledger' },
  { id: 'sales', name: 'Sales & POS', icon: '🧾', title: 'Sales Performance & POS Audit' },
  { id: 'repairs', name: 'Repair Service', icon: '🛠️', title: 'Repair Operations & Ticket Margin' },
  { id: 'inventory', name: 'Inventory Valuation', icon: '📦', title: 'Inventory Stock Valuation & Movement' },
  { id: 'expenses', name: 'Shop Expenses', icon: '💸', title: 'Overhead Expenses & Cost Log' },
  { id: 'payments', name: 'Collections', icon: '💳', title: 'Payment Collections & Tenders' },
  { id: 'customers', name: 'Customer Khata', icon: '👥', title: 'Customer Accounts & Top Spenders' },
  { id: 'warranties', name: 'Warranties', icon: '🛡️', title: 'Warranty Coverage & Service Claims' },
];

const periodOptions = [
  { value: 'today', label: 'Today' },
  { value: 'yesterday', label: 'Yesterday' },
  { value: 'this_week', label: 'This Week' },
  { value: 'this_month', label: 'This Month' },
  { value: 'last_month', label: 'Last Month' },
  { value: 'this_year', label: 'This Year' },
  { value: 'all_time', label: 'All Time' },
  { value: 'custom', label: 'Custom Date Range...' },
];

const activeTab = ref('outstanding');
const selectedPeriod = ref('this_month');
const customStartDate = ref('');
const customEndDate = ref('');
const searchQuery = ref('');
const currentPage = ref(1);
const loading = ref(false);

const filterParams = reactive({
  category: 'all',
  sale_type: 'all',
  status: 'all',
});

const reportData = ref({});
let searchDebounceTimer = null;

const activeReportMeta = computed(() => {
  return reportCategories.find((c) => c.id === activeTab.value) || reportCategories[0];
});

const currentPeriodLabel = computed(() => {
  if (selectedPeriod.value === 'custom') {
    return `${customStartDate.value || 'Start'} to ${customEndDate.value || 'End'}`;
  }
  const match = periodOptions.find((p) => p.value === selectedPeriod.value);
  return match ? match.label : selectedPeriod.value;
});

// Dynamic live counts for Outstanding Dues tabs
const duesCategoryTabs = computed(() => {
  const sum = reportData.value?.summary || {};
  const total = (sum.repairs_count || 0) + (sum.sales_count || 0) + (sum.purchases_count || 0);
  return [
    { id: 'all', label: 'All Dues', count: total },
    { id: 'repairs', label: 'Repairs Only', count: sum.repairs_count || 0 },
    { id: 'sales', label: 'Sales Only', count: sum.sales_count || 0 },
    { id: 'purchases', label: 'Vendors (Payables)', count: sum.purchases_count || 0 },
  ];
});

// Dynamic live counts for Repair status tabs
const repairStatusTabs = computed(() => {
  const sum = reportData.value?.summary || {};
  return [
    { id: 'all', label: 'All Repairs', count: sum.total_repairs || 0 },
    { id: 'in_progress', label: 'Active on Bench', count: sum.active || 0 },
    { id: 'delivered', label: 'Delivered', count: sum.delivered || 0 },
    { id: 'completed', label: 'Completed Ready', count: sum.completed || 0 },
    { id: 'cancelled', label: 'Cancelled', count: sum.cancelled || 0 },
  ];
});

// Dynamic live counts for Sales type tabs
const salesTypeTabs = computed(() => {
  const sum = reportData.value?.summary || {};
  return [
    { id: 'all', label: 'All Invoices', count: sum.total_transactions || 0 },
    { id: 'regular', label: 'Standard Counter', count: sum.regular_count || 0 },
    { id: 'quick', label: 'Quick POS Sales', count: sum.quick_count || 0 },
  ];
});

function selectTab(tabId) {
  activeTab.value = tabId;
  currentPage.value = 1;
  searchQuery.value = '';
  filterParams.category = 'all';
  filterParams.sale_type = 'all';
  filterParams.status = 'all';
  loadActiveReport();
}

function setSubFilter(key, val) {
  filterParams[key] = val;
  currentPage.value = 1;
  loadActiveReport();
}

function onFilterChange() {
  currentPage.value = 1;
  loadActiveReport();
}

function debounceSearch() {
  clearTimeout(searchDebounceTimer);
  searchDebounceTimer = setTimeout(() => {
    currentPage.value = 1;
    loadActiveReport();
  }, 350);
}

function goToPage(page) {
  currentPage.value = page;
  loadActiveReport();
}

async function loadActiveReport() {
  loading.value = true;
  try {
    const params = {
      period: selectedPeriod.value,
      page: currentPage.value,
    };

    if (selectedPeriod.value === 'custom') {
      if (customStartDate.value) params.start_date = customStartDate.value;
      if (customEndDate.value) params.end_date = customEndDate.value;
    }

    if (searchQuery.value.trim()) {
      params.search = searchQuery.value.trim();
    }

    if (activeTab.value === 'outstanding' && filterParams.category !== 'all') {
      params.category = filterParams.category;
    }

    if (activeTab.value === 'sales' && filterParams.sale_type !== 'all') {
      params.sale_type = filterParams.sale_type;
    }

    if (activeTab.value === 'repairs' && filterParams.status !== 'all') {
      params.status = filterParams.status;
    }

    let res;
    switch (activeTab.value) {
      case 'outstanding':
        res = await reportApi.outstanding(params);
        break;
      case 'sales':
        res = await reportApi.sales(params);
        break;
      case 'repairs':
        res = await reportApi.repairs(params);
        break;
      case 'inventory':
        res = await reportApi.inventory(params);
        break;
      case 'expenses':
        res = await reportApi.expenses(params);
        break;
      case 'payments':
        res = await reportApi.payments(params);
        break;
      case 'customers':
        res = await reportApi.customers(params);
        break;
      case 'warranties':
        res = await reportApi.warranties(params);
        break;
      default:
        res = await reportApi.outstanding(params);
    }

    reportData.value = res.data?.data || {};
  } catch (err) {
    console.error('Failed to load report:', err);
    reportData.value = {};
  } finally {
    loading.value = false;
  }
}

// Download CSV file using browser blob creation
function downloadCsv() {
  try {
    const params = new URLSearchParams({
      type: activeTab.value,
      period: selectedPeriod.value,
    });
    if (selectedPeriod.value === 'custom') {
      if (customStartDate.value) params.append('start_date', customStartDate.value);
      if (customEndDate.value) params.append('end_date', customEndDate.value);
    }
    const token = localStorage.getItem('auth_token');
    const downloadUrl = `/api/v1/reports/export?${params.toString()}`;

    fetch(downloadUrl, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    })
      .then((response) => response.blob())
      .then((blob) => {
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `Report_${activeTab.value}_${selectedPeriod.value}_${new Date().toISOString().slice(0, 10)}.csv`;
        document.body.appendChild(a);
        a.click();
        a.remove();
        window.URL.revokeObjectURL(url);
      })
      .catch((err) => {
        console.error('CSV export failed:', err);
        alert('Failed to generate CSV export. Please try again.');
      });
  } catch (e) {
    console.error(e);
  }
}

// Direct Client-Side PDF Generation & Instant File Download
function downloadPdf() {
  try {
    const doc = new jsPDF('landscape');
    const title = activeReportMeta.value.title || 'Business Report';
    const period = currentPeriodLabel.value;
    const dateStr = new Date().toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });

    // 1. Header Banner
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(16);
    doc.setTextColor(30, 27, 75); // Dark Indigo
    doc.text(`MyRepairHub — ${title}`, 14, 16);

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(9);
    doc.setTextColor(100, 116, 139); // Slate 500
    doc.text(`Period: ${period}  |  Generated on: ${dateStr}`, 14, 22);

    // 2. Summary Metric Bar
    const sum = reportData.value?.summary || {};
    let summaryText = '';
    if (activeTab.value === 'outstanding') {
      summaryText = `Receivables: Rs. ${formatAmount(sum.total_customer_dues)}   Payables: Rs. ${formatAmount(sum.total_vendor_dues)}   Net Balance: Rs. ${formatAmount(sum.net_balance)}   (Repairs: ${sum.repairs_count || 0}, Sales: ${sum.sales_count || 0})`;
    } else if (activeTab.value === 'repairs') {
      summaryText = `Total Booked: ${sum.total_repairs || 0}   Delivered: ${(sum.completed || 0) + (sum.delivered || 0)}   Active: ${sum.active || 0}   Revenue: Rs. ${formatAmount(sum.repair_revenue)}   Pending Due: Rs. ${formatAmount(sum.repair_dues)}`;
    } else if (activeTab.value === 'sales') {
      summaryText = `Total Sales: Rs. ${formatAmount(sum.total_sales)}   Collected: Rs. ${formatAmount(sum.total_collected)}   Dues: Rs. ${formatAmount(sum.total_outstanding)}   Discounts: Rs. ${formatAmount(sum.total_discounts)}   Invoices: ${sum.total_transactions || 0}`;
    } else if (activeTab.value === 'inventory') {
      summaryText = `Stock Valuation: Rs. ${formatAmount(sum.total_inventory_value)}   Units on Shelf: ${sum.total_stock_qty || 0}   Low Stock: ${sum.low_stock || 0}   Out of Stock: ${sum.out_of_stock || 0}`;
    } else if (activeTab.value === 'expenses') {
      summaryText = `Total Expenses: Rs. ${formatAmount(sum.total_expenses)}   Vouchers: ${reportData.value.details?.total || 0}`;
    } else if (activeTab.value === 'payments') {
      summaryText = `Total Collections: Rs. ${formatAmount(sum.total_payments)}   Cash: Rs. ${formatAmount(sum.cash_total)}   UPI: Rs. ${formatAmount(sum.upi_total)}   Card/Bank: Rs. ${formatAmount((sum.card_total || 0) + (sum.bank_total || 0))}`;
    }

    if (summaryText) {
      doc.setFillColor(241, 245, 249); // slate-100
      doc.roundedRect(14, 26, 268, 8, 2, 2, 'F');
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(8.5);
      doc.setTextColor(51, 65, 85);
      doc.text(summaryText, 17, 31.5);
    }

    // 3. Prepare Table Headers and Body
    let head = [];
    let body = [];
    const rows = reportData.value?.details?.data || reportData.value?.details || [];

    if (activeTab.value === 'outstanding') {
      head = [['Ref #', 'Party / Customer', 'Mobile', 'Category', 'Date', 'Total Bill', 'Paid', 'Pending Due', 'Status']];
      body = rows.map((it) => [
        it.ref_number || it.id,
        it.party_name || 'Walk-in',
        it.party_phone || '—',
        it.category_label || it.category,
        formatDate(it.date),
        `Rs. ${formatAmount(it.total_amount || it.totalAmount)}`,
        `Rs. ${formatAmount(it.amount_paid || it.amountPaid)}`,
        `Rs. ${formatAmount(it.amount_due || it.amountDue)}`,
        (it.status || 'Pending').toUpperCase(),
      ]);
    } else if (activeTab.value === 'repairs') {
      head = [['Job #', 'Received Date', 'Customer', 'Mobile', 'Device & Issue', 'Cost', 'Paid', 'Due', 'Status']];
      body = rows.map((job) => [
        job.job_number,
        formatDate(job.created_at),
        job.customer?.name || 'Customer',
        job.customer?.mobile || '—',
        `${job.device ? `${job.device.brand} ${job.device.model}` : 'Device'}\n${job.problem_description || ''}`.trim(),
        `Rs. ${formatAmount(job.final_cost || job.estimated_cost)}`,
        `Rs. ${formatAmount(job.amount_paid)}`,
        `Rs. ${formatAmount(job.amount_due)}`,
        getRepairStatusLabel(job.repair_status),
      ]);
    } else if (activeTab.value === 'sales') {
      head = [['Invoice #', 'Date', 'Customer', 'Mobile', 'Sale Type', 'Subtotal', 'Discount', 'Grand Total', 'Paid', 'Due', 'Payment Status']];
      body = rows.map((s) => [
        s.invoice_number,
        formatDate(s.sale_date),
        s.customer_name || 'Walk-in',
        s.customer_mobile || '—',
        (s.sale_type || '').toUpperCase(),
        `Rs. ${formatAmount(s.subtotal)}`,
        `Rs. ${formatAmount(s.discount)}`,
        `Rs. ${formatAmount(s.grand_total)}`,
        `Rs. ${formatAmount(s.amount_paid)}`,
        `Rs. ${formatAmount(s.amount_due)}`,
        getSaleStatusLabel(s.payment_status),
      ]);
    } else if (activeTab.value === 'inventory') {
      head = [['Product Name', 'SKU', 'Category', 'Current Stock', 'Cost Price', 'Selling Price', 'Total Valuation', 'Status']];
      body = rows.map((it) => [
        it.name,
        it.sku || '—',
        it.category?.name || it.category || 'General',
        String(it.current_stock ?? 0),
        `Rs. ${formatAmount(it.purchase_cost || it.cost_price || 0)}`,
        `Rs. ${formatAmount(it.selling_price || 0)}`,
        `Rs. ${formatAmount((Number(it.purchase_cost || it.cost_price || 0)) * (Number(it.current_stock || 0)))}`,
        Number(it.current_stock) <= 0 ? 'Out of Stock' : (Number(it.current_stock) <= Number(it.min_stock || 3) ? 'Low Stock' : 'In Stock'),
      ]);
    } else if (activeTab.value === 'expenses') {
      head = [['Date', 'Category', 'Title / Description', 'Payment Mode', 'Amount']];
      body = rows.map((e) => [
        formatDate(e.expense_date),
        e.category?.name || 'Uncategorized',
        `${e.title || ''} ${e.notes ? '(' + e.notes + ')' : ''}`.trim(),
        (e.payment_method || '').toUpperCase(),
        `Rs. ${formatAmount(e.amount)}`,
      ]);
    } else if (activeTab.value === 'payments') {
      head = [['Date', 'Invoice / Ref #', 'Customer', 'Payment Mode', 'Amount']];
      body = rows.map((p) => [
        formatDate(p.payment_date || p.created_at),
        p.sale?.invoice_number || p.reference || '—',
        p.sale?.customer_name || 'Customer',
        (p.payment_method || '').toUpperCase(),
        `Rs. ${formatAmount(p.amount)}`,
      ]);
    } else if (activeTab.value === 'customers') {
      head = [['Customer Name', 'Mobile', 'Email', 'City', 'Total Spent']];
      body = rows.map((c) => [
        c.name,
        c.mobile || '—',
        c.email || '—',
        c.city || '—',
        `Rs. ${formatAmount(c.total_spent || c.sales_sum_grand_total || 0)}`,
      ]);
    } else if (activeTab.value === 'warranties') {
      head = [['Warranty Code', 'Customer', 'Mobile', 'Item Name', 'Valid Until', 'Status']];
      body = rows.map((w) => [
        w.warranty_code || `WAR-${w.id}`,
        w.customer?.name || 'Customer',
        w.customer?.mobile || '—',
        w.item_name || '—',
        formatDate(w.end_date),
        (w.status || 'Active').toUpperCase(),
      ]);
    }

    autoTable(doc, {
      startY: summaryText ? 38 : 28,
      head: head,
      body: body,
      theme: 'grid',
      headStyles: {
        fillColor: [79, 70, 229], // Indigo 600
        textColor: [255, 255, 255],
        fontStyle: 'bold',
        fontSize: 8,
      },
      styles: {
        fontSize: 7.5,
        cellPadding: 2.5,
        textColor: [30, 41, 59],
      },
      alternateRowStyles: {
        fillColor: [248, 250, 252],
      },
      margin: { left: 14, right: 14 },
      didDrawPage: (data) => {
        // Page footer
        doc.setFontSize(8);
        doc.setTextColor(148, 163, 184);
        doc.text(`Page ${data.pageNumber} — MyRepairHub`, 14, doc.internal.pageSize.height - 8);
      },
    });

    const filename = `Report_${activeTab.value}_${selectedPeriod.value}_${new Date().toISOString().slice(0, 10)}.pdf`;
    doc.save(filename);
  } catch (err) {
    console.error('Failed to generate PDF:', err);
    alert('Failed to generate PDF download. Please check your data and try again.');
  }
}

function printReport() {
  window.print();
}

function formatAmount(amt) {
  return (Number(amt) || 0).toLocaleString('en-IN', {
    maximumFractionDigits: 2,
  });
}

function cleanPhone(p) {
  if (!p) return '';
  const digits = String(p).replace(/\D/g, '');
  if (digits.length === 10) return `91${digits}`;
  return digits;
}

// Status Badges & Color Helpers for Repair Services
function getRepairStatusLabel(status) {
  const s = String(status || '').toLowerCase().trim();
  const map = {
    received: 'Received',
    diagnosing: 'Diagnosing',
    waiting_customer: 'Waiting Customer',
    waiting_parts: 'Waiting Parts',
    in_progress: 'In Progress',
    repairing: 'Repairing',
    ready: 'Ready for Pickup',
    completed: 'Completed',
    delivered: 'Delivered',
    cancelled: 'Cancelled',
    pending: 'Pending',
  };
  return map[s] || (status ? status.replace(/_/g, ' ') : 'Pending');
}

function getRepairStatusBadgeClass(status) {
  const s = String(status || '').toLowerCase();
  if (s.includes('delivered') || s.includes('completed')) {
    return 'bg-emerald-50 dark:bg-emerald-950/50 text-emerald-700 dark:text-emerald-400 border border-emerald-200/80 dark:border-emerald-900/50';
  }
  if (s.includes('ready')) {
    return 'bg-teal-50 dark:bg-teal-950/50 text-teal-700 dark:text-teal-400 border border-teal-200/80 dark:border-teal-900/50';
  }
  if (s.includes('repairing') || s.includes('progress')) {
    return 'bg-indigo-50 dark:bg-indigo-950/50 text-indigo-700 dark:text-indigo-400 border border-indigo-200/80 dark:border-indigo-900/50';
  }
  if (s.includes('waiting')) {
    return 'bg-amber-50 dark:bg-amber-950/50 text-amber-700 dark:text-amber-400 border border-amber-200/80 dark:border-amber-900/50';
  }
  if (s.includes('diagnosing')) {
    return 'bg-purple-50 dark:bg-purple-950/50 text-purple-700 dark:text-purple-400 border border-purple-200/80 dark:border-purple-900/50';
  }
  if (s.includes('cancel')) {
    return 'bg-rose-50 dark:bg-rose-950/50 text-rose-700 dark:text-rose-400 border border-rose-200/80 dark:border-rose-900/50';
  }
  return 'bg-sky-50 dark:bg-sky-950/50 text-sky-700 dark:text-sky-400 border border-sky-200/80 dark:border-sky-900/50';
}

function getRepairStatusDotClass(status) {
  const s = String(status || '').toLowerCase();
  if (s.includes('delivered') || s.includes('completed')) return 'bg-emerald-500';
  if (s.includes('ready')) return 'bg-teal-500';
  if (s.includes('repairing') || s.includes('progress')) return 'bg-indigo-500';
  if (s.includes('waiting')) return 'bg-amber-500 animate-pulse';
  if (s.includes('diagnosing')) return 'bg-purple-500';
  if (s.includes('cancel')) return 'bg-rose-500';
  return 'bg-sky-500';
}

// Status Badges & Color Helpers for Sales
function getSaleStatusLabel(status) {
  const s = String(status || '').toLowerCase().trim();
  if (s === 'paid') return 'Paid';
  if (s === 'partial') return 'Partial Due';
  if (s === 'unpaid' || s === 'pending') return 'Unpaid (Udhar)';
  return status || 'Unpaid';
}

function getSaleStatusBadgeClass(status) {
  const s = String(status || '').toLowerCase();
  if (s === 'paid') {
    return 'bg-emerald-50 dark:bg-emerald-950/50 text-emerald-700 dark:text-emerald-400 border border-emerald-200/80 dark:border-emerald-900/50';
  }
  if (s === 'partial') {
    return 'bg-amber-50 dark:bg-amber-950/50 text-amber-700 dark:text-amber-400 border border-amber-200/80 dark:border-amber-900/50';
  }
  return 'bg-rose-50 dark:bg-rose-950/50 text-rose-700 dark:text-rose-400 border border-rose-200/80 dark:border-rose-900/50';
}

function getSaleStatusDotClass(status) {
  const s = String(status || '').toLowerCase();
  if (s === 'paid') return 'bg-emerald-500';
  if (s === 'partial') return 'bg-amber-500';
  return 'bg-rose-500';
}

onMounted(() => {
  loadActiveReport();
});
</script>

<style scoped>
@media print {
  /* Clean print view without sidebar or header buttons */
  aside,
  header,
  nav,
  .print\:hidden {
    display: none !important;
  }
  body {
    background: white !important;
    color: black !important;
  }
}
</style>
