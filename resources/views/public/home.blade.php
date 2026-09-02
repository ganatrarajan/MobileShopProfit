@extends('layouts.public')

@section('title', 'Mobile Profits — #1 Mobile Shop & Repair Management Platform')

@section('content')

<!-- Hero Section -->
<section class="relative overflow-hidden pt-16 pb-24 lg:pt-24 lg:pb-32 hero-gradient">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10 text-center">
        
        <div class="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-indigo-950/80 border border-indigo-500/30 text-indigo-300 text-xs font-semibold uppercase tracking-wider mb-8 shadow-inner">
            <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
            <span>Next-Gen Profit Intelligence SaaS</span>
        </div>

        <h1 class="text-4xl sm:text-6xl lg:text-7xl font-extrabold tracking-tight text-white max-w-5xl mx-auto leading-none">
            Maximize Profit. Streamline Repairs. <br class="hidden sm:inline">
            <span class="bg-gradient-to-r from-indigo-400 via-emerald-300 to-teal-200 bg-clip-text text-transparent">Empower Your Mobile Shop.</span>
        </h1>

        <p class="mt-6 text-lg sm:text-xl text-slate-300 max-w-3xl mx-auto font-normal leading-relaxed">
            Mobile Profits is the complete cloud-based solution for mobile repair centers and retail stores. Manage repairs, track serial/IMEI stock, automate technician payouts, and unlock real-time profit analytics.
        </p>

        <div class="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4">
            <a href="#download" class="w-full sm:w-auto px-8 py-4 rounded-xl font-bold text-base text-white bg-gradient-to-r from-indigo-600 via-indigo-500 to-emerald-500 hover:from-indigo-500 hover:to-emerald-400 shadow-xl shadow-indigo-600/30 transition-all transform hover:-translate-y-1">
                Download Mobile App
            </a>
            <a href="#pricing" class="w-full sm:w-auto px-8 py-4 rounded-xl font-bold text-base text-slate-200 bg-slate-800/80 hover:bg-slate-700 border border-slate-700 transition-all">
                View Pricing Plans
            </a>
        </div>

        <!-- Key Metrics Ribbon -->
        <div class="mt-16 grid grid-cols-2 md:grid-cols-4 gap-6 max-w-4xl mx-auto text-left">
            <div class="p-4 rounded-xl bg-slate-900/60 border border-slate-800">
                <div class="text-2xl font-black text-indigo-400">100%</div>
                <div class="text-xs text-slate-400 font-medium mt-1">Real-time Profit Analytics</div>
            </div>
            <div class="p-4 rounded-xl bg-slate-900/60 border border-slate-800">
                <div class="text-2xl font-black text-emerald-400">IMEI / Serial</div>
                <div class="text-xs text-slate-400 font-medium mt-1">Granular Stock Tracking</div>
            </div>
            <div class="p-4 rounded-xl bg-slate-900/60 border border-slate-800">
                <div class="text-2xl font-black text-indigo-400">Job Cards</div>
                <div class="text-xs text-slate-400 font-medium mt-1">Automated Repair Workflow</div>
            </div>
            <div class="p-4 rounded-xl bg-slate-900/60 border border-slate-800">
                <div class="text-2xl font-black text-emerald-400">Commission</div>
                <div class="text-xs text-slate-400 font-medium mt-1">Technician Payout Log</div>
            </div>
        </div>

    </div>
</section>

<!-- Features Section -->
<section id="features" class="py-20 bg-slate-950">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        <div class="text-center max-w-3xl mx-auto mb-16">
            <h2 class="text-xs font-bold text-indigo-400 uppercase tracking-widest">Everything You Need</h2>
            <p class="text-3xl sm:text-4xl font-extrabold text-white mt-2">Engineered Specifically For Mobile Shops</p>
            <p class="text-slate-400 mt-4 text-sm sm:text-base">Replaces spreadsheets, manual paper job receipts, and fragmented registers with one unified, automated cloud system.</p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            
            <!-- Feature 1 -->
            <div class="card-glass p-8 rounded-2xl transition-all">
                <div class="w-12 h-12 rounded-xl bg-indigo-600/20 border border-indigo-500/30 flex items-center justify-center mb-6 text-indigo-400">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
                </div>
                <h3 class="text-xl font-bold text-white mb-2">Customer Management</h3>
                <p class="text-xs sm:text-sm text-slate-400 leading-relaxed">Centralized customer directory with complete repair history, active warranties, pending dues, and quick contact action links.</p>
            </div>

            <!-- Feature 2 -->
            <div class="card-glass p-8 rounded-2xl transition-all">
                <div class="w-12 h-12 rounded-xl bg-emerald-600/20 border border-emerald-500/30 flex items-center justify-center mb-6 text-emerald-400">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"/></svg>
                </div>
                <h3 class="text-xl font-bold text-white mb-2">Device & IMEI Management</h3>
                <p class="text-xs sm:text-sm text-slate-400 leading-relaxed">Track serial numbers, dual IMEI codes, device condition logs, and brand model catalogs accurately.</p>
            </div>

            <!-- Feature 3 -->
            <div class="card-glass p-8 rounded-2xl transition-all">
                <div class="w-12 h-12 rounded-xl bg-indigo-600/20 border border-indigo-500/30 flex items-center justify-center mb-6 text-indigo-400">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 14l6-6m-5.5.5h.01m4.99 5h.01M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16l4-2 4 2 4-2 4 2z"/></svg>
                </div>
                <h3 class="text-xl font-bold text-white mb-2">Sales & Billing</h3>
                <p class="text-xs sm:text-sm text-slate-400 leading-relaxed">Fast POS checkout for phone sales, accessories, and spare parts with digital receipts and payment status tags.</p>
            </div>

            <!-- Feature 4 -->
            <div class="card-glass p-8 rounded-2xl transition-all">
                <div class="w-12 h-12 rounded-xl bg-amber-600/20 border border-amber-500/30 flex items-center justify-center mb-6 text-amber-400">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
                </div>
                <h3 class="text-xl font-bold text-white mb-2">Repair & Job Cards</h3>
                <p class="text-xs sm:text-sm text-slate-400 leading-relaxed">Digital job cards with status progression (Received, Diagnosis, Pending Parts, Ready, Delivered) and part cost calculation.</p>
            </div>

            <!-- Feature 5 -->
            <div class="card-glass p-8 rounded-2xl transition-all">
                <div class="w-12 h-12 rounded-xl bg-cyan-600/20 border border-cyan-500/30 flex items-center justify-center mb-6 text-cyan-400">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/></svg>
                </div>
                <h3 class="text-xl font-bold text-white mb-2">Warranty Management</h3>
                <p class="text-xs sm:text-sm text-slate-400 leading-relaxed">Automated warranty period tracking for repair jobs and sold accessories with instant claim verification.</p>
            </div>

            <!-- Feature 6 -->
            <div class="card-glass p-8 rounded-2xl transition-all">
                <div class="w-12 h-12 rounded-xl bg-purple-600/20 border border-purple-500/30 flex items-center justify-center mb-6 text-purple-400">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/></svg>
                </div>
                <h3 class="text-xl font-bold text-white mb-2">Inventory & Stock</h3>
                <p class="text-xs sm:text-sm text-slate-400 leading-relaxed">Real-time stock level monitoring, low-stock warnings, purchase cost logging, and selling price configuration.</p>
            </div>

            <!-- Feature 7 -->
            <div class="card-glass p-8 rounded-2xl transition-all">
                <div class="w-12 h-12 rounded-xl bg-rose-600/20 border border-rose-500/30 flex items-center justify-center mb-6 text-rose-400">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                </div>
                <h3 class="text-xl font-bold text-white mb-2">Expenses & Overhead</h3>
                <p class="text-xs sm:text-sm text-slate-400 leading-relaxed">Categorized expense recording (rent, utilities, tools, tea/refreshment) to calculate true net shop profit.</p>
            </div>

            <!-- Feature 8 -->
            <div class="card-glass p-8 rounded-2xl transition-all border-emerald-500/40">
                <div class="w-12 h-12 rounded-xl bg-emerald-500/20 border border-emerald-400/40 flex items-center justify-center mb-6 text-emerald-400">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/></svg>
                </div>
                <h3 class="text-xl font-bold text-white mb-2">Profit Intelligence USP</h3>
                <p class="text-xs sm:text-sm text-slate-400 leading-relaxed">Advanced profit breakdown matrix dissecting Revenue vs Spare Costs vs Technician Cuts vs Shop Expenses.</p>
            </div>

            <!-- Feature 9 -->
            <div class="card-glass p-8 rounded-2xl transition-all">
                <div class="w-12 h-12 rounded-xl bg-blue-600/20 border border-blue-500/30 flex items-center justify-center mb-6 text-blue-400">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
                </div>
                <h3 class="text-xl font-bold text-white mb-2">Technician Management</h3>
                <p class="text-xs sm:text-sm text-slate-400 leading-relaxed">Log technician assigned jobs, track repair completion speed, calculate percentage/fixed commissions, and record payouts.</p>
            </div>

        </div>
    </div>
</section>

<!-- Pricing Section -->
<section id="pricing" class="py-20 bg-slate-900/60 border-y border-slate-800">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        <div class="text-center max-w-3xl mx-auto mb-16">
            <h2 class="text-xs font-bold text-emerald-400 uppercase tracking-widest">Transparent Pricing</h2>
            <p class="text-3xl sm:text-4xl font-extrabold text-white mt-2">Simple Subscription Plans for Every Shop</p>
            <p class="text-slate-400 mt-4 text-sm sm:text-base">No hidden charges. Upgrade or cancel your subscription at any time.</p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-8 max-w-4xl mx-auto">
            @forelse($plans as $plan)
            <div class="card-glass p-8 rounded-3xl relative overflow-hidden flex flex-col justify-between @if($loop->last) border-indigo-500/50 shadow-2xl shadow-indigo-500/10 @endif">
                @if($loop->last)
                <div class="absolute top-0 right-0 bg-gradient-to-l from-emerald-500 to-indigo-600 text-white text-[10px] font-extrabold uppercase px-4 py-1.5 rounded-bl-xl tracking-wider">
                    Best Value
                </div>
                @endif

                <div>
                    <h3 class="text-2xl font-bold text-white">{{ $plan->name }}</h3>
                    <p class="text-xs text-indigo-300 mt-1 capitalize">{{ $plan->billing_period }} Billing Cycle</p>
                    
                    <div class="mt-6 flex items-baseline gap-2">
                        <span class="text-4xl sm:text-5xl font-black text-white">₹{{ number_format($plan->price, 0) }}</span>
                        <span class="text-sm text-slate-400 font-medium">/ {{ $plan->billing_period == 'annual' ? 'year' : 'month' }}</span>
                    </div>

                    <ul class="mt-8 space-y-3.5 text-xs sm:text-sm text-slate-300">
                        <li class="flex items-center gap-3">
                            <svg class="w-5 h-5 text-emerald-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                            <span>Unlimited Repair Job Cards</span>
                        </li>
                        <li class="flex items-center gap-3">
                            <svg class="w-5 h-5 text-emerald-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                            <span>Full Inventory & Serial/IMEI Tracking</span>
                        </li>
                        <li class="flex items-center gap-3">
                            <svg class="w-5 h-5 text-emerald-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                            <span>Technician Commission Calculator</span>
                        </li>
                        <li class="flex items-center gap-3">
                            <svg class="w-5 h-5 text-emerald-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                            <span>Profit Intelligence Analytics</span>
                        </li>
                        <li class="flex items-center gap-3">
                            <svg class="w-5 h-5 text-emerald-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                            <span>Cloud Backups & Mobile App Access</span>
                        </li>
                    </ul>
                </div>

                <div class="mt-8">
                    <a href="#download" class="w-full block text-center py-3.5 rounded-xl font-bold text-sm text-white bg-indigo-600 hover:bg-indigo-500 transition-all">
                        Get Started Now
                    </a>
                </div>
            </div>
            @empty
            <div class="col-span-2 text-center text-slate-400 py-10">
                Contact sales for custom pricing plans.
            </div>
            @endforelse
        </div>

    </div>
</section>

<!-- Mobile App Download Section -->
<section id="download" class="py-20 bg-slate-950 relative">
    <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
        <div class="p-10 sm:p-16 rounded-3xl bg-gradient-to-b from-indigo-900/60 to-slate-900 border border-indigo-500/30 relative overflow-hidden">
            <h2 class="text-3xl sm:text-5xl font-black text-white tracking-tight">
                Run Your Mobile Shop From Anywhere
            </h2>
            <p class="text-slate-300 mt-4 text-sm sm:text-base max-w-2xl mx-auto">
                Download the official Mobile Profits App on Android and iOS to check daily shop profits, approve job cards, and track repairs on the go.
            </p>
            <div class="mt-8 flex flex-col sm:flex-row items-center justify-center gap-4">
                <a href="{{ $settings['android_app_url'] ?? '#' }}" class="inline-flex items-center gap-3 px-6 py-3.5 rounded-xl bg-slate-900 hover:bg-slate-800 border border-slate-700 text-white font-semibold text-sm transition-all">
                    <svg class="w-6 h-6 text-emerald-400" fill="currentColor" viewBox="0 0 24 24"><path d="M17.523 15.3414c-.5511 0-.9993-.4486-.9993-.9997s.4482-.9993.9993-.9993c.552 0 .9997.4482.9997.9993s-.4477.9997-.9997.9997zm-11.046 0c-.5511 0-.9993-.4486-.9993-.9997s.4482-.9993.9993-.9993c.552 0 .9997.4482.9997.9993s-.4477.9997-.9997.9997zm11.3945-6.602l1.8344-3.1772c.1081-.1873.0439-.427-.1434-.5351-.1873-.1081-.427-.0439-.5351.1434l-1.8703 3.2394c-1.5794-.7206-3.3705-1.1274-5.2571-1.1274s-3.6777.4068-5.2571 1.1274l-1.8703-3.2394c-.1081-.1873-.3478-.2515-.5351-.1434-.1873.1081-.2515.3478-.1434.5351l1.8344 3.1772c-3.1779 1.7709-5.3204 4.9757-5.5907 8.7563h23.1245c-.2703-3.7806-2.4128-6.9854-5.5907-8.7563z"/></svg>
                    <span>Download for Android</span>
                </a>
                <a href="{{ $settings['ios_app_url'] ?? '#' }}" class="inline-flex items-center gap-3 px-6 py-3.5 rounded-xl bg-slate-900 hover:bg-slate-800 border border-slate-700 text-white font-semibold text-sm transition-all">
                    <svg class="w-6 h-6 text-indigo-400" fill="currentColor" viewBox="0 0 24 24"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.09c.67-.82 1.13-1.96.99-3.09-1 .04-2.17.67-2.88 1.49-.6.69-1.12 1.84-.97 2.95 1.12.09 2.22-.53 2.86-1.35z"/></svg>
                    <span>Download for iOS</span>
                </a>
            </div>
        </div>
    </div>
</section>

@endsection
