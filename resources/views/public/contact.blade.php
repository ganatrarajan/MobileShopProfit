@extends('layouts.public')

@section('title', 'Contact & Support — Mobile Profits')
@section('meta_description', 'Get in touch with Mobile Profits support team for assistance, billing queries, or technical support.')

@section('content')

<div class="py-12 sm:py-20 bg-slate-950 min-h-screen">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        
        <div class="text-center max-w-2xl mx-auto mb-12">
            <h1 class="text-3xl sm:text-5xl font-black text-white tracking-tight">Contact & Support</h1>
            <p class="text-slate-400 mt-3 text-sm sm:text-base">We are here to help your mobile shop succeed. Reach out through any of our channels below.</p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
            <!-- Email -->
            <div class="card-glass p-6 rounded-2xl text-center">
                <div class="w-12 h-12 rounded-xl bg-indigo-600/20 text-indigo-400 flex items-center justify-center mx-auto mb-4">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/></svg>
                </div>
                <h3 class="text-base font-bold text-white mb-1">Email Support</h3>
                <p class="text-xs text-indigo-300 font-medium mb-3">{{ $settings['support_email'] ?? 'support@mobileprofits.com' }}</p>
                <p class="text-[11px] text-slate-400">Response within 24 hours</p>
            </div>

            <!-- Phone -->
            <div class="card-glass p-6 rounded-2xl text-center">
                <div class="w-12 h-12 rounded-xl bg-emerald-600/20 text-emerald-400 flex items-center justify-center mx-auto mb-4">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/></svg>
                </div>
                <h3 class="text-base font-bold text-white mb-1">Phone & Helpline</h3>
                <p class="text-xs text-emerald-400 font-medium mb-3">{{ $settings['support_phone'] ?? '+91 98765 43210' }}</p>
                <p class="text-[11px] text-slate-400">{{ $settings['support_hours'] ?? 'Mon - Sat: 9:00 AM - 8:00 PM IST' }}</p>
            </div>

            <!-- WhatsApp -->
            <div class="card-glass p-6 rounded-2xl text-center">
                <div class="w-12 h-12 rounded-xl bg-teal-600/20 text-teal-400 flex items-center justify-center mx-auto mb-4">
                    <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24"><path d="M.057 24l1.687-6.163c-1.041-1.804-1.588-3.849-1.587-5.946.003-6.556 5.338-11.891 11.893-11.891 3.181.001 6.167 1.24 8.413 3.488 2.245 2.248 3.481 5.236 3.48 8.414-.003 6.557-5.338 11.892-11.893 11.892-1.99-.001-3.951-.5-5.688-1.448l-6.305 1.654zm6.597-3.807c1.676.995 3.276 1.591 5.392 1.592 5.448 0 9.886-4.434 9.889-9.885.002-5.462-4.415-9.89-9.881-9.892-5.452 0-9.887 4.434-9.889 9.884-.001 2.225.651 3.891 1.746 5.634l-.999 3.648 3.742-.981z"/></svg>
                </div>
                <h3 class="text-base font-bold text-white mb-1">WhatsApp Chat</h3>
                <p class="text-xs text-teal-300 font-medium mb-3">{{ $settings['whatsapp_number'] ?? '+91 98765 43210' }}</p>
                <p class="text-[11px] text-slate-400">Instant Messaging Support</p>
            </div>
        </div>

        @if($page && $page->content)
        <div class="card-glass p-8 rounded-2xl text-slate-300 text-sm leading-relaxed mb-8">
            {!! $page->content !!}
        </div>
        @endif

    </div>
</div>

@endsection
