<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-slate-900 dark:text-white flex items-center gap-2">
          <span>🎁</span>
          <span>Refer & Earn Program</span>
        </h1>
        <p class="text-sm text-slate-500 dark:text-slate-400 mt-1">
          Invite other mobile shop owners to use Mobile Repair Hub and earn wallet reward points on every recharge!
        </p>
      </div>
      <div class="flex items-center gap-2">
        <button
          @click="fetchReferralData"
          :disabled="loading"
          class="inline-flex items-center gap-1.5 px-3 py-2 text-xs font-semibold rounded-lg bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-750 transition-all shadow-xs"
        >
          <svg class="w-3.5 h-3.5" :class="{ 'animate-spin': loading }" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
          <span>Refresh</span>
        </button>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading && !summaryData" class="flex flex-col items-center justify-center py-20">
      <div class="animate-spin rounded-full h-10 w-10 border-3 border-indigo-600 border-t-transparent"></div>
      <p class="mt-4 text-sm text-slate-500">Loading referral dashboard...</p>
    </div>

    <!-- Error State -->
    <div v-else-if="error && !summaryData" class="rounded-xl border border-red-200 bg-red-50 p-6 text-center dark:border-red-900/50 dark:bg-red-950/20">
      <p class="text-red-700 dark:text-red-400 font-medium mb-3">{{ error }}</p>
      <button @click="fetchReferralData" class="px-4 py-2 bg-red-600 text-white rounded-lg text-xs font-bold hover:bg-red-700">
        Try Again
      </button>
    </div>

    <!-- Content -->
    <div v-else class="space-y-6">
      <!-- 1. Top Referral Hero Card & Share Actions -->
      <div class="rounded-2xl bg-gradient-to-br from-indigo-700 via-indigo-800 to-purple-900 text-white p-6 sm:p-8 shadow-xl relative overflow-hidden">
        <!-- Background Accent Circles -->
        <div class="absolute -top-12 -right-12 w-48 h-48 bg-white/10 rounded-full blur-2xl pointer-events-none"></div>
        <div class="absolute -bottom-10 -left-10 w-44 h-44 bg-purple-500/20 rounded-full blur-xl pointer-events-none"></div>

        <div class="relative z-10 grid grid-cols-1 lg:grid-cols-12 gap-6 items-center">
          <!-- Left: Code & Actions -->
          <div class="lg:col-span-7 space-y-4">
            <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/15 text-xs font-semibold text-indigo-100 backdrop-blur-xs">
              <span>⚡</span>
              <span>Shop Referral Program</span>
            </div>
            <div>
              <h2 class="text-2xl sm:text-3xl font-extrabold tracking-tight">Earn commission on every recharge!</h2>
              <p class="text-indigo-200 text-xs sm:text-sm mt-1 max-w-xl">
                Share your unique code with other mobile repair shops. When they register and recharge, you receive commission points instantly into your wallet.
              </p>
            </div>

            <!-- Referral Code Display & Actions -->
            <div class="flex flex-wrap items-center gap-3 pt-2">
              <div class="flex items-center bg-white/15 backdrop-blur-md rounded-xl border border-white/20 px-4 py-2">
                <span class="text-xs uppercase font-semibold text-indigo-200 mr-3">Your Code:</span>
                <span class="font-mono text-xl sm:text-2xl font-black text-amber-300 tracking-wider">
                  {{ referralCode || '...' }}
                </span>
                <button
                  type="button"
                  @click="copyReferralCode"
                  class="ml-3 p-1.5 rounded-lg bg-white/20 hover:bg-white/30 text-white transition-all cursor-pointer"
                  :title="copied ? 'Copied!' : 'Copy Code'"
                >
                  <svg v-if="!copied" class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                  </svg>
                  <span v-else class="text-xs font-bold text-emerald-300">Copied!</span>
                </button>
              </div>

              <!-- Share WhatsApp Button -->
              <a
                :href="whatsappShareUrl"
                target="_blank"
                rel="noopener noreferrer"
                class="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-emerald-500 hover:bg-emerald-600 text-white font-bold text-xs shadow-md transition-all cursor-pointer"
              >
                <svg class="w-4 h-4 fill-current" viewBox="0 0 24 24">
                  <path d="M12.031 6.172c-3.181 0-5.767 2.586-5.768 5.766-.001 1.298.38 2.27 1.019 3.287l-.711 2.598 2.669-.699c.969.585 1.961.884 2.791.884h.001c3.18 0 5.766-2.586 5.767-5.766 0-3.18-2.586-5.768-5.767-5.768zm3.385 8.163c-.145.409-.844.757-1.18.799-.336.042-.77.062-2.473-.623-1.455-.584-2.404-2.062-2.477-2.158-.073-.097-.588-.782-.588-1.492 0-.71.371-1.059.504-1.205.132-.146.29-.182.387-.182.096 0 .193.001.278.005.089.004.209-.034.327.25.121.29.412 1.004.449 1.077.036.073.06.158.012.255-.048.097-.072.158-.145.243-.073.085-.153.19-.218.255-.073.073-.149.153-.064.298.085.145.378.623.811 1.008.558.497 1.028.651 1.173.724.145.073.23.061.315-.036.085-.097.363-.424.46-.57.097-.145.194-.121.327-.073.133.048.848.4 1 .473.151.073.254.109.29.17.037.06.037.351-.108.76z" />
                </svg>
                <span>Share on WhatsApp</span>
              </a>

              <!-- Copy Share Text -->
              <button
                type="button"
                @click="copyShareMessage"
                class="inline-flex items-center gap-1.5 px-3 py-2.5 rounded-xl bg-white/20 hover:bg-white/30 text-white font-semibold text-xs transition-all cursor-pointer"
              >
                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z" />
                </svg>
                <span>{{ copiedMessage ? 'Copied Link!' : 'Copy Share Text' }}</span>
              </button>
            </div>
          </div>

          <!-- Right: Big Points Wallet Box -->
          <div class="lg:col-span-5">
            <div class="bg-white/10 backdrop-blur-md rounded-2xl p-5 border border-white/20 space-y-4">
              <div class="flex items-center justify-between">
                <span class="text-xs uppercase font-bold tracking-wider text-indigo-200">Wallet Points Balance</span>
                <span class="text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-400/20 text-emerald-300 border border-emerald-400/30">
                  Ready to Redeem
                </span>
              </div>

              <div>
                <div class="flex items-baseline gap-2">
                  <span class="text-4xl sm:text-5xl font-black text-white">
                    {{ formatNumber(pointsBalance) }}
                  </span>
                  <span class="text-sm font-semibold text-indigo-200">Points (₹{{ formatNumber(pointsBalance) }})</span>
                </div>
                <p class="text-xs text-indigo-200/90 mt-1">
                  1 Point = ₹1 Discount on your next subscription recharge (up to {{ maxRedeemPercent }}% of plan value).
                </p>
              </div>

              <!-- Quick Mini Stats in Hero -->
              <div class="grid grid-cols-3 gap-2 pt-2 border-t border-white/15 text-center">
                <div class="p-2 rounded-lg bg-black/15">
                  <span class="block text-[10px] text-indigo-200 font-medium">Earned</span>
                  <span class="font-bold text-xs sm:text-sm text-emerald-300">+{{ formatNumber(totalEarned) }}</span>
                </div>
                <div class="p-2 rounded-lg bg-black/15">
                  <span class="block text-[10px] text-indigo-200 font-medium">Used</span>
                  <span class="font-bold text-xs sm:text-sm text-amber-300">-{{ formatNumber(totalRedeemed) }}</span>
                </div>
                <div class="p-2 rounded-lg bg-black/15">
                  <span class="block text-[10px] text-indigo-200 font-medium">Referred</span>
                  <span class="font-bold text-xs sm:text-sm text-white">{{ referralsCount }} Shops</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Reward Rules Banner at Bottom of Hero -->
        <div class="relative z-10 mt-6 pt-4 border-t border-white/15 flex flex-wrap items-center gap-4 text-xs text-indigo-100">
          <div class="flex items-center gap-1.5" v-if="signupPoints > 0">
            <span class="w-2 h-2 rounded-full bg-emerald-400"></span>
            <span>Shop Signup Bonus: <strong>+{{ signupPoints }} pts</strong></span>
          </div>
          <div class="flex items-center gap-1.5" v-if="rechargePercent > 0">
            <span class="w-2 h-2 rounded-full bg-amber-400"></span>
            <span>Recharge Commission: <strong>{{ rechargePercent }}% points</strong> on every plan payment</span>
          </div>
          <div class="flex items-center gap-1.5">
            <span class="w-2 h-2 rounded-full bg-sky-400"></span>
            <span>Redeem Limit: <strong>Up to {{ maxRedeemPercent }}%</strong> of renewal invoice</span>
          </div>
        </div>
      </div>

      <!-- 2. Tabs: Referred Shops vs Wallet Passbook -->
      <div class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200/80 dark:border-slate-800 shadow-xs overflow-hidden">
        <div class="flex border-b border-slate-200 dark:border-slate-800 px-6 pt-3 gap-6">
          <button
            @click="activeTab = 'shops'"
            class="pb-3 text-sm font-bold border-b-2 transition-all flex items-center gap-2 cursor-pointer"
            :class="activeTab === 'shops' ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400' : 'border-transparent text-slate-500 hover:text-slate-800 dark:hover:text-slate-300'"
          >
            <span>🏪 Referred Shops</span>
            <span class="px-2 py-0.5 rounded-full text-xs" :class="activeTab === 'shops' ? 'bg-indigo-50 dark:bg-indigo-950/50 text-indigo-600 dark:text-indigo-400 font-semibold' : 'bg-slate-100 dark:bg-slate-800 text-slate-500'">
              {{ referrals.length }}
            </span>
          </button>
          <button
            @click="activeTab = 'passbook'"
            class="pb-3 text-sm font-bold border-b-2 transition-all flex items-center gap-2 cursor-pointer"
            :class="activeTab === 'passbook' ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400' : 'border-transparent text-slate-500 hover:text-slate-800 dark:hover:text-slate-300'"
          >
            <span>📜 Points Passbook</span>
            <span class="px-2 py-0.5 rounded-full text-xs" :class="activeTab === 'passbook' ? 'bg-indigo-50 dark:bg-indigo-950/50 text-indigo-600 dark:text-indigo-400 font-semibold' : 'bg-slate-100 dark:bg-slate-800 text-slate-500'">
              {{ transactions.length }}
            </span>
          </button>
        </div>

        <!-- TAB 1: REFERRED SHOPS -->
        <div v-show="activeTab === 'shops'" class="p-6 space-y-4">
          <!-- Search / Filters -->
          <div class="flex flex-col sm:flex-row items-center justify-between gap-4">
            <div class="relative w-full sm:w-80">
              <input
                v-model="searchShopQuery"
                type="text"
                placeholder="Search shop, owner, city or phone..."
                class="w-full pl-9 pr-4 py-2 rounded-xl text-xs bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700 text-slate-900 dark:text-white placeholder-slate-400 focus:outline-indigo-600"
              />
              <svg class="w-4 h-4 absolute left-3 top-2.5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </div>
            <div class="text-xs text-slate-500 dark:text-slate-400 font-medium">
              Showing {{ filteredReferrals.length }} of {{ referrals.length }} referred shops
            </div>
          </div>

          <!-- Empty State -->
          <div v-if="filteredReferrals.length === 0" class="py-16 text-center space-y-3">
            <div class="w-16 h-16 rounded-full bg-indigo-50 dark:bg-indigo-950/50 flex items-center justify-center mx-auto text-2xl">
              🏪
            </div>
            <h3 class="text-base font-bold text-slate-800 dark:text-white">No Referred Shops Found</h3>
            <p class="text-xs text-slate-500 max-w-md mx-auto">
              {{ searchShopQuery ? 'No shop matching your search query. Try searching by another keyword.' : 'You have not referred any shops yet. Share your code to get started!' }}
            </p>
            <button
              v-if="!searchShopQuery"
              @click="copyReferralCode"
              class="px-4 py-2 rounded-lg bg-indigo-600 text-white font-bold text-xs hover:bg-indigo-700"
            >
              Copy Referral Code
            </button>
          </div>

          <!-- Shops Table / Cards -->
          <div v-else class="overflow-x-auto">
            <table class="w-full text-left text-xs border-collapse">
              <thead>
                <tr class="border-b border-slate-200 dark:border-slate-800 text-slate-500 dark:text-slate-400 bg-slate-50/70 dark:bg-slate-800/40">
                  <th class="py-3 px-4 font-semibold">Shop & Owner</th>
                  <th class="py-3 px-4 font-semibold">City</th>
                  <th class="py-3 px-4 font-semibold">Contact / Actions</th>
                  <th class="py-3 px-4 font-semibold">Plan Status</th>
                  <th class="py-3 px-4 font-semibold">Last Payment</th>
                  <th class="py-3 px-4 font-semibold text-right">Commission Earned</th>
                  <th class="py-3 px-4 font-semibold text-center">Action</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
                <tr
                  v-for="shop in filteredReferrals"
                  :key="shop.id"
                  class="hover:bg-slate-50/80 dark:hover:bg-slate-800/50 transition-colors group cursor-pointer"
                  @click="openShopPaymentsModal(shop)"
                >
                  <!-- Shop & Owner -->
                  <td class="py-3.5 px-4">
                    <div class="flex items-center gap-3">
                      <div class="w-9 h-9 rounded-xl bg-indigo-100 dark:bg-indigo-950/60 border border-indigo-200 dark:border-indigo-800 flex items-center justify-center font-bold text-xs text-indigo-700 dark:text-indigo-400">
                        {{ (shop.shop_name || 'S').substring(0, 1).toUpperCase() }}
                      </div>
                      <div>
                        <div class="font-bold text-slate-900 dark:text-white group-hover:text-indigo-600 dark:group-hover:text-indigo-400 transition-colors">
                          {{ shop.shop_name }}
                        </div>
                        <div class="text-[11px] text-slate-500 dark:text-slate-400">
                          Owner: {{ shop.owner_name || 'N/A' }} • Joined {{ shop.joined_at }}
                        </div>
                      </div>
                    </div>
                  </td>

                  <!-- City -->
                  <td class="py-3.5 px-4">
                    <span class="inline-flex items-center gap-1 text-slate-700 dark:text-slate-300 font-medium">
                      <svg class="w-3.5 h-3.5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                      </svg>
                      <span>{{ shop.city || 'Not Specified' }}</span>
                    </span>
                  </td>

                  <!-- Phone & Action Links -->
                  <td class="py-3.5 px-4" @click.stop>
                    <div class="flex items-center gap-2">
                      <span class="font-mono text-slate-800 dark:text-slate-200 font-medium">
                        {{ shop.phone || 'No Phone' }}
                      </span>
                      <template v-if="shop.phone">
                        <!-- Call Link -->
                        <a
                          :href="'tel:' + shop.phone"
                          title="Call Shop"
                          class="p-1 rounded-md text-indigo-600 hover:bg-indigo-50 dark:hover:bg-indigo-950/40 transition-colors"
                        >
                          <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                          </svg>
                        </a>
                        <!-- WhatsApp Link -->
                        <a
                          :href="'https://wa.me/91' + cleanPhone(shop.phone)"
                          target="_blank"
                          rel="noopener noreferrer"
                          title="Message on WhatsApp"
                          class="p-1 rounded-md text-emerald-600 hover:bg-emerald-50 dark:hover:bg-emerald-950/40 transition-colors"
                        >
                          <svg class="w-3.5 h-3.5 fill-current" viewBox="0 0 24 24">
                            <path d="M12.031 6.172c-3.181 0-5.767 2.586-5.768 5.766-.001 1.298.38 2.27 1.019 3.287l-.711 2.598 2.669-.699c.969.585 1.961.884 2.791.884h.001c3.18 0 5.766-2.586 5.767-5.766 0-3.18-2.586-5.768-5.767-5.768zm3.385 8.163c-.145.409-.844.757-1.18.799-.336.042-.77.062-2.473-.623-1.455-.584-2.404-2.062-2.477-2.158-.073-.097-.588-.782-.588-1.492 0-.71.371-1.059.504-1.205.132-.146.29-.182.387-.182.096 0 .193.001.278.005.089.004.209-.034.327.25.121.29.412 1.004.449 1.077.036.073.06.158.012.255-.048.097-.072.158-.145.243-.073.085-.153.19-.218.255-.073.073-.149.153-.064.298.085.145.378.623.811 1.008.558.497 1.028.651 1.173.724.145.073.23.061.315-.036.085-.097.363-.424.46-.57.097-.145.194-.121.327-.073.133.048.848.4 1 .473.151.073.254.109.29.17.037.06.037.351-.108.76z" />
                          </svg>
                        </a>
                      </template>
                    </div>
                  </td>

                  <!-- Plan Status -->
                  <td class="py-3.5 px-4">
                    <span
                      class="inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-bold"
                      :class="getPlanBadgeClass(shop.plan_status)"
                    >
                      {{ shop.plan_status }}
                    </span>
                  </td>

                  <!-- Last Payment -->
                  <td class="py-3.5 px-4">
                    <div v-if="shop.last_payment && shop.last_payment.type !== 'signup_bonus' && shop.last_payment.amount > 0" class="space-y-0.5">
                      <div class="font-bold text-slate-800 dark:text-slate-200">
                        ₹{{ formatNumber(shop.last_payment.amount) }}
                        <span class="text-[11px] font-normal text-slate-500">({{ shop.last_payment.plan_name }})</span>
                      </div>
                      <div class="text-[10px] text-slate-400">
                        {{ shop.last_payment.date }}
                      </div>
                      <div v-if="shop.last_payment.commission_earned > 0" class="text-[10px] text-emerald-600 dark:text-emerald-400 font-semibold">
                        +₹{{ formatNumber(shop.last_payment.commission_earned) }} <span v-if="shop.last_payment.commission_percent">({{ shop.last_payment.commission_percent }}%)</span>
                      </div>
                    </div>
                    <div v-else-if="shop.last_payment && shop.last_payment.type === 'signup_bonus'" class="space-y-0.5">
                      <span class="inline-flex items-center px-2 py-0.5 rounded text-[11px] font-semibold bg-amber-50 text-amber-700 dark:bg-amber-950/40 dark:text-amber-300">
                        🎁 Signup Bonus (+{{ formatNumber(shop.last_payment.commission_earned) }} pts)
                      </span>
                      <div class="text-[10px] text-slate-400">
                        Awaiting first recharge
                      </div>
                    </div>
                    <div v-else class="text-slate-400 text-[11px]">
                      No recharges yet
                    </div>
                  </td>

                  <!-- Total Commission Earned -->
                  <td class="py-3.5 px-4 text-right">
                    <div class="font-extrabold text-sm text-emerald-600 dark:text-emerald-400">
                      +{{ formatNumber(shop.total_commission_earned) }} pts
                    </div>
                    <div class="text-[10px] text-slate-400">
                      ₹{{ formatNumber(shop.total_commission_earned) }} total
                    </div>
                  </td>

                  <!-- Action -->
                  <td class="py-3.5 px-4 text-center">
                    <button
                      type="button"
                      @click.stop="openShopPaymentsModal(shop)"
                      class="px-2.5 py-1 text-[11px] font-bold rounded-lg bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 hover:bg-indigo-600 hover:text-white transition-all cursor-pointer"
                    >
                      View Payments
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- TAB 2: POINTS PASSBOOK -->
        <div v-show="activeTab === 'passbook'" class="p-6 space-y-4">
          <div class="flex items-center justify-between">
            <h3 class="text-sm font-bold text-slate-800 dark:text-white">Transaction History</h3>
            <span class="text-xs text-slate-400">{{ transactions.length }} entries</span>
          </div>

          <div v-if="transactions.length === 0" class="py-16 text-center text-slate-400 text-xs">
            No wallet point transactions recorded yet.
          </div>

          <div v-else class="overflow-x-auto">
            <table class="w-full text-left text-xs border-collapse">
              <thead>
                <tr class="border-b border-slate-200 dark:border-slate-800 text-slate-500 dark:text-slate-400 bg-slate-50/70 dark:bg-slate-800/40">
                  <th class="py-3 px-4 font-semibold">Date & Time</th>
                  <th class="py-3 px-4 font-semibold">Description</th>
                  <th class="py-3 px-4 font-semibold">Type</th>
                  <th class="py-3 px-4 font-semibold text-right">Points</th>
                  <th class="py-3 px-4 font-semibold text-right">Balance After</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
                <tr v-for="tx in transactions" :key="tx.id" class="hover:bg-slate-50/60 dark:hover:bg-slate-800/40">
                  <td class="py-3 px-4 font-mono text-slate-500 dark:text-slate-400">{{ tx.date }}</td>
                  <td class="py-3 px-4 font-medium text-slate-800 dark:text-slate-200">{{ tx.description }}</td>
                  <td class="py-3 px-4">
                    <span
                      class="px-2 py-0.5 rounded-full text-[10px] font-bold uppercase"
                      :class="tx.type === 'credit' ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-400' : 'bg-red-100 text-red-700 dark:bg-red-950/60 dark:text-red-400'"
                    >
                      {{ tx.type }}
                    </span>
                  </td>
                  <td class="py-3 px-4 text-right font-bold text-sm" :class="tx.type === 'credit' ? 'text-emerald-600 dark:text-emerald-400' : 'text-red-600 dark:text-red-400'">
                    {{ tx.type === 'credit' ? '+' : '-' }}{{ formatNumber(tx.points) }}
                  </td>
                  <td class="py-3 px-4 text-right font-mono font-medium text-slate-700 dark:text-slate-300">
                    {{ formatNumber(tx.balance_after) }} pts
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>

    <!-- 3. MODAL: SHOP PAYMENTS & COMMISSION BREAKDOWN -->
    <div
      v-if="selectedShop"
      class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
      @click.self="closeShopPaymentsModal"
    >
      <div class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-2xl max-w-3xl w-full max-h-[90vh] flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        <!-- Modal Header -->
        <div class="p-6 border-b border-slate-200 dark:border-slate-800 flex items-start justify-between bg-slate-50/50 dark:bg-slate-850">
          <div class="space-y-1">
            <div class="flex items-center gap-2">
              <span class="text-xl">🏪</span>
              <h3 class="text-lg font-bold text-slate-900 dark:text-white">{{ selectedShop.shop_name }}</h3>
              <span class="px-2 py-0.5 rounded-full text-[10px] font-bold" :class="getPlanBadgeClass(selectedShop.plan_status)">
                {{ selectedShop.plan_status }}
              </span>
            </div>
            <p class="text-xs text-slate-500 dark:text-slate-400 flex items-center gap-3">
              <span>Owner: <strong>{{ selectedShop.owner_name }}</strong></span>
              <span>City: <strong>{{ selectedShop.city }}</strong></span>
              <span>Phone: <strong>{{ selectedShop.phone }}</strong></span>
            </p>
          </div>
          <button
            @click="closeShopPaymentsModal"
            class="p-1 rounded-lg text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <!-- Modal Summary Cards -->
        <div class="grid grid-cols-2 sm:grid-cols-3 gap-3 p-6 bg-indigo-50/50 dark:bg-indigo-950/20 border-b border-indigo-100 dark:border-indigo-900/30">
          <div class="p-3 bg-white dark:bg-slate-800 rounded-xl border border-indigo-100/60 dark:border-indigo-900/40">
            <span class="text-[10px] uppercase font-bold text-slate-400">Total Payments</span>
            <div class="text-base font-extrabold text-slate-800 dark:text-white mt-0.5">
              {{ (selectedShop.payments || []).filter(p => p.type === 'recharge').length }} Recharges
            </div>
          </div>
          <div class="p-3 bg-white dark:bg-slate-800 rounded-xl border border-indigo-100/60 dark:border-indigo-900/40">
            <span class="text-[10px] uppercase font-bold text-slate-400">Total Recharge Value</span>
            <div class="text-base font-extrabold text-slate-800 dark:text-white mt-0.5">
              ₹{{ formatNumber(calculateTotalRecharge(selectedShop.payments)) }}
            </div>
          </div>
          <div class="p-3 bg-white dark:bg-slate-800 rounded-xl border border-indigo-100/60 dark:border-indigo-900/40 col-span-2 sm:col-span-1">
            <span class="text-[10px] uppercase font-bold text-slate-400">Total Commission Earned</span>
            <div class="text-base font-extrabold text-emerald-600 dark:text-emerald-400 mt-0.5">
              +{{ formatNumber(selectedShop.total_commission_earned) }} pts
            </div>
          </div>
        </div>

        <!-- Modal Content: Payments List -->
        <div class="p-6 overflow-y-auto flex-1 space-y-4">
          <h4 class="text-xs uppercase font-bold tracking-wider text-slate-400">
            Payment & Commission Breakdown
          </h4>

          <div v-if="!selectedShop.payments || selectedShop.payments.length === 0" class="py-12 text-center text-slate-400 space-y-2">
            <svg class="w-10 h-10 mx-auto text-slate-300 dark:text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            <p class="text-xs font-semibold">No payments made by this shop yet.</p>
            <p class="text-[11px] text-slate-400">When this shop recharges their subscription, payment details and your commission will appear here automatically.</p>
          </div>

          <div v-else class="space-y-3">
            <div
              v-for="item in selectedShop.payments"
              :key="item.id"
              class="p-4 rounded-xl border border-slate-200/90 dark:border-slate-800 bg-white dark:bg-slate-850 shadow-2xs space-y-2"
            >
              <div class="flex items-start justify-between gap-3">
                <div>
                  <div class="flex items-center gap-2">
                    <span class="font-bold text-slate-900 dark:text-white text-xs sm:text-sm">
                      {{ item.title }}
                    </span>
                    <span class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-100 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-400">
                      {{ item.status }}
                    </span>
                  </div>
                  <div class="text-[11px] text-slate-400 mt-0.5">
                    {{ item.date }} • Mode: {{ item.payment_method }}
                  </div>
                </div>

                <!-- Payment Amount -->
                <div class="text-right">
                  <div class="font-mono text-sm font-extrabold text-slate-800 dark:text-white">
                    <span v-if="item.amount > 0">₹{{ formatNumber(item.amount) }}</span>
                    <span v-else class="text-emerald-600 font-bold">Free Bonus</span>
                  </div>
                </div>
              </div>

              <!-- Commission Highlight Ribbon -->
              <div class="flex items-center justify-between px-3 py-2 rounded-lg bg-emerald-50/80 dark:bg-emerald-950/40 border border-emerald-200/60 dark:border-emerald-900/40 text-xs">
                <span class="font-semibold text-emerald-800 dark:text-emerald-300">
                  <template v-if="item.commission_percent">
                    Referral Commission ({{ item.commission_percent }}%)
                  </template>
                  <template v-else>
                    Referral Bonus
                  </template>
                </span>
                <span class="font-bold text-emerald-700 dark:text-emerald-300">
                  +{{ formatNumber(item.commission_earned) }} Points Credited
                </span>
              </div>
            </div>
          </div>
        </div>

        <!-- Modal Footer -->
        <div class="p-4 border-t border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-850 flex justify-end">
          <button
            @click="closeShopPaymentsModal"
            class="px-4 py-2 rounded-xl bg-slate-200 hover:bg-slate-300 dark:bg-slate-700 dark:hover:bg-slate-600 text-slate-800 dark:text-white font-bold text-xs transition-colors cursor-pointer"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { referralApi } from '@/api/endpoints'

const loading = ref(true)
const error = ref(null)
const summaryData = ref(null)
const activeTab = ref('shops')
const searchShopQuery = ref('')
const copied = ref(false)
const copiedMessage = ref(false)
const selectedShop = ref(null)

const fetchReferralData = async () => {
  loading.value = true
  error.value = null
  try {
    const res = await referralApi.summary()
    const data = res.data?.data || res.data || {}
    summaryData.value = data
  } catch (err) {
    error.value = err.response?.data?.message || 'Failed to load referral details.'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchReferralData()
})

const referralCode = computed(() => summaryData.value?.referral_code || '')
const shareMessage = computed(() => summaryData.value?.share_message || '')
const pointsBalance = computed(() => Number(summaryData.value?.points_balance || 0))
const totalEarned = computed(() => Number(summaryData.value?.total_earned || 0))
const totalRedeemed = computed(() => Number(summaryData.value?.total_redeemed || 0))
const referralsCount = computed(() => summaryData.value?.referrals_count || 0)

const config = computed(() => summaryData.value?.config || {})
const signupPoints = computed(() => Number(config.value?.signup_points || 0))
const rechargePercent = computed(() => Number(config.value?.recharge_percent || 0))
const maxRedeemPercent = computed(() => Number(config.value?.max_redeem_percent || 50))

const referrals = computed(() => summaryData.value?.referrals || [])
const transactions = computed(() => summaryData.value?.transactions || [])

const filteredReferrals = computed(() => {
  const q = searchShopQuery.value.trim().toLowerCase()
  if (!q) return referrals.value
  return referrals.value.filter(s => {
    return (
      (s.shop_name && s.shop_name.toLowerCase().includes(q)) ||
      (s.owner_name && s.owner_name.toLowerCase().includes(q)) ||
      (s.city && s.city.toLowerCase().includes(q)) ||
      (s.phone && s.phone.includes(q))
    )
  })
})

const whatsappShareUrl = computed(() => {
  const text = encodeURIComponent(shareMessage.value || `Use my referral code ${referralCode.value}`)
  return `https://wa.me/?text=${text}`
})

const copyReferralCode = async () => {
  if (!referralCode.value) return
  try {
    await navigator.clipboard.writeText(referralCode.value)
    copied.value = true
    setTimeout(() => { copied.value = false }, 2500)
  } catch (e) {
    console.error('Failed to copy', e)
  }
}

const copyShareMessage = async () => {
  if (!shareMessage.value) return
  try {
    await navigator.clipboard.writeText(shareMessage.value)
    copiedMessage.value = true
    setTimeout(() => { copiedMessage.value = false }, 2500)
  } catch (e) {
    console.error('Failed to copy', e)
  }
}

const cleanPhone = (phone) => {
  if (!phone) return ''
  return String(phone).replace(/[^0-9]/g, '')
}

const formatNumber = (val) => {
  const num = Number(val || 0)
  return isNaN(num) ? '0' : num.toLocaleString('en-IN', { maximumFractionDigits: 2 })
}

const getPlanBadgeClass = (planStatus) => {
  if (!planStatus) return 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300'
  const str = planStatus.toLowerCase()
  if (str.includes('active')) return 'bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-300'
  if (str.includes('expired')) return 'bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-300'
  return 'bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400'
}

const openShopPaymentsModal = (shop) => {
  selectedShop.value = shop
}

const closeShopPaymentsModal = () => {
  selectedShop.value = null
}

const calculateTotalRecharge = (payments) => {
  if (!payments || !Array.isArray(payments)) return 0
  return payments.reduce((sum, p) => sum + (Number(p.amount) || 0), 0)
}
</script>
