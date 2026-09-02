<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'Mobile Profits — All-in-One Mobile Shop & Repair Management')</title>
    <meta name="description" content="@yield('meta_description', 'Mobile Profits is the complete SaaS solution for mobile shop owners, offering Inventory, Invoicing, Repairs, Warranty Tracking, Technician Payouts, and Profit Intelligence.')">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        brand: {
                            50: '#eef2ff',
                            100: '#e0e7ff',
                            500: '#6366f1',
                            600: '#4f46e5',
                            700: '#4338ca',
                            900: '#1e1b4b',
                        },
                        accent: {
                            500: '#10b981',
                            600: '#059669',
                        }
                    },
                    fontFamily: {
                        sans: ['Outfit', 'Plus Jakarta Sans', 'sans-serif'],
                    }
                }
            }
        }
    </script>
    <style>
        body { font-family: 'Outfit', sans-serif; }
        .glass-header { background: rgba(15, 23, 42, 0.85); backdrop-filter: blur(12px); border-bottom: 1px solid rgba(255, 255, 255, 0.1); }
        .hero-gradient { background: radial-gradient(circle at 50% 0%, #1e1b4b 0%, #0f172a 100%); }
        .card-glass { background: rgba(30, 41, 59, 0.6); backdrop-filter: blur(8px); border: 1px solid rgba(255, 255, 255, 0.08); }
        .card-glass:hover { border-color: rgba(99, 102, 241, 0.4); transform: translateY(-3px); }
    </style>
</head>
<body class="bg-slate-950 text-slate-100 min-h-screen flex flex-col antialiased selection:bg-indigo-500 selection:text-white">

    <!-- Header / Navbar -->
    <header class="sticky top-0 z-50 glass-header">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-20 flex items-center justify-between">
            <a href="{{ route('home') }}" class="flex items-center gap-3 group">
                <div class="w-10 h-10 rounded-xl bg-gradient-to-tr from-indigo-600 to-emerald-400 p-0.5 shadow-lg shadow-indigo-500/20 group-hover:scale-105 transition-transform">
                    <div class="w-full h-full bg-slate-950 rounded-[10px] flex items-center justify-center">
                        <svg class="w-6 h-6 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"/></svg>
                    </div>
                </div>
                <div>
                    <span class="text-xl font-extrabold tracking-tight bg-gradient-to-r from-white via-slate-100 to-indigo-200 bg-clip-text text-transparent">Mobile Profits</span>
                    <span class="block text-[10px] uppercase tracking-widest text-indigo-400 font-bold -mt-1">Shop SaaS Platform</span>
                </div>
            </a>

            <!-- Navigation Links -->
            <nav class="hidden md:flex items-center gap-8 text-sm font-medium text-slate-300">
                <a href="{{ route('home') }}" class="hover:text-indigo-400 transition-colors">Home</a>
                <a href="{{ route('home') }}#features" class="hover:text-indigo-400 transition-colors">Features</a>
                <a href="{{ route('home') }}#pricing" class="hover:text-indigo-400 transition-colors">Pricing</a>
                <a href="{{ route('contact') }}" class="hover:text-indigo-400 transition-colors">Contact</a>
            </nav>

            <!-- CTA Buttons -->
            <div class="flex items-center gap-4">
                <a href="/admin" class="hidden sm:inline-flex text-sm font-semibold text-slate-300 hover:text-white px-4 py-2 rounded-lg hover:bg-slate-800 transition-all">Admin Portal</a>
                <a href="{{ route('home') }}#download" class="inline-flex items-center justify-center px-5 py-2.5 rounded-xl font-semibold text-sm text-white bg-gradient-to-r from-indigo-600 to-emerald-500 hover:from-indigo-500 hover:to-emerald-400 shadow-lg shadow-indigo-500/25 transition-all transform hover:-translate-y-0.5">
                    Download App
                </a>
            </div>
        </div>
    </header>

    <!-- Main Content -->
    <main class="flex-grow">
        @yield('content')
    </main>

    <!-- Footer -->
    <footer class="bg-slate-900 border-t border-slate-800/80 mt-20 pt-16 pb-12">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="grid grid-cols-1 md:grid-cols-4 gap-10 pb-12 border-b border-slate-800">
                <div class="md:col-span-1 space-y-4">
                    <div class="flex items-center gap-3">
                        <div class="w-8 h-8 rounded-lg bg-indigo-600 flex items-center justify-center">
                            <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"/></svg>
                        </div>
                        <span class="text-lg font-bold text-white">Mobile Profits</span>
                    </div>
                    <p class="text-xs text-slate-400 leading-relaxed">
                        The ultimate shop management, repair job tracking, billing & Profit Intelligence platform for mobile retail & service centers.
                    </p>
                </div>

                <div>
                    <h4 class="text-sm font-semibold text-white uppercase tracking-wider mb-4">Quick Links</h4>
                    <ul class="space-y-2.5 text-xs text-slate-400">
                        <li><a href="{{ route('home') }}" class="hover:text-indigo-400 transition-colors">Home</a></li>
                        <li><a href="{{ route('home') }}#features" class="hover:text-indigo-400 transition-colors">Features</a></li>
                        <li><a href="{{ route('home') }}#pricing" class="hover:text-indigo-400 transition-colors">Pricing Plans</a></li>
                        <li><a href="{{ route('contact') }}" class="hover:text-indigo-400 transition-colors">Contact Support</a></li>
                    </ul>
                </div>

                <div>
                    <h4 class="text-sm font-semibold text-white uppercase tracking-wider mb-4">Legal & Privacy</h4>
                    <ul class="space-y-2.5 text-xs text-slate-400">
                        <li><a href="{{ route('privacy-policy') }}" class="hover:text-indigo-400 transition-colors">Privacy Policy</a></li>
                        <li><a href="{{ route('terms-and-conditions') }}" class="hover:text-indigo-400 transition-colors">Terms & Conditions</a></li>
                        <li><a href="{{ route('refund-policy') }}" class="hover:text-indigo-400 transition-colors">Refund & Cancellation</a></li>
                        <li><a href="{{ route('delete-account') }}" class="hover:text-indigo-400 transition-colors">Request Account Deletion</a></li>
                    </ul>
                </div>

                <div>
                    <h4 class="text-sm font-semibold text-white uppercase tracking-wider mb-4">Support Contact</h4>
                    <ul class="space-y-2 text-xs text-slate-400">
                        <li class="flex items-center gap-2">
                            <svg class="w-4 h-4 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/></svg>
                            <span>{{ $settings['support_email'] ?? 'support@mobileprofits.com' }}</span>
                        </li>
                        <li class="flex items-center gap-2">
                            <svg class="w-4 h-4 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/></svg>
                            <span>{{ $settings['support_phone'] ?? '+91 98765 43210' }}</span>
                        </li>
                        <li class="mt-3 text-[11px] text-slate-500">
                            {{ $settings['support_hours'] ?? 'Mon - Sat: 9:00 AM - 8:00 PM IST' }}
                        </li>
                    </ul>
                </div>
            </div>

            <div class="pt-8 flex flex-col sm:flex-row items-center justify-between text-xs text-slate-500 gap-4">
                <p>{{ $settings['copyright_text'] ?? '© 2026 Mobile Profits. All rights reserved.' }}</p>
                <p>Designed for High-Performance Mobile Service & Retail Enterprises</p>
            </div>
        </div>
    </footer>

</body>
</html>
