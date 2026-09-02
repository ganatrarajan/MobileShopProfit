@extends('layouts.public')

@section('title', ($page->title ?? $fallbackTitle) . ' — Mobile Profits')
@section('meta_description', $page->meta_description ?? ($page->title ?? $fallbackTitle) . ' for Mobile Profits platform and Mobile Application.')

@section('content')

<div class="py-12 sm:py-20 bg-slate-950 min-h-screen">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        
        <!-- Breadcrumb / Header -->
        <div class="mb-8">
            <a href="{{ route('home') }}" class="inline-flex items-center text-xs font-semibold text-indigo-400 hover:text-indigo-300 gap-1 mb-4">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>
                <span>Back to Home</span>
            </a>
            <h1 class="text-3xl sm:text-5xl font-black text-white tracking-tight">
                {{ $page->title ?? $fallbackTitle }}
            </h1>
            <div class="mt-3 flex items-center gap-4 text-xs text-slate-400 border-b border-slate-800 pb-6">
                <span>Last Updated: {{ $page->updated_at ? $page->updated_at->format('F d, Y') : 'September 02, 2026' }}</span>
                <span>•</span>
                <span class="text-emerald-400 font-medium">Official Mobile Profits Document</span>
            </div>
        </div>

        <!-- Dynamic Content Body -->
        <div class="card-glass p-6 sm:p-10 rounded-2xl text-slate-300 text-sm sm:text-base leading-relaxed space-y-6 [&_h1]:text-2xl [&_h1]:font-bold [&_h1]:text-white [&_h1]:mt-6 [&_h1]:mb-3 [&_h2]:text-xl [&_h2]:font-bold [&_h2]:text-white [&_h2]:mt-6 [&_h2]:mb-3 [&_h3]:text-lg [&_h3]:font-semibold [&_h3]:text-indigo-300 [&_h3]:mt-4 [&_h3]:mb-2 [&_p]:mb-4 [&_ul]:list-disc [&_ul]:pl-6 [&_ul]:space-y-2 [&_li]:text-slate-300 [&_a]:text-indigo-400 [&_a]:underline hover:[&_a]:text-indigo-300">
            {!! $page->content !!}
        </div>

        <!-- Footer Help Callout -->
        <div class="mt-12 p-6 rounded-2xl bg-slate-900 border border-slate-800 flex flex-col sm:flex-row items-center justify-between gap-4">
            <div>
                <h4 class="text-sm font-bold text-white">Have questions about this policy?</h4>
                <p class="text-xs text-slate-400 mt-1">Our support team is available Mon-Sat to assist you.</p>
            </div>
            <a href="{{ route('contact') }}" class="px-5 py-2.5 rounded-xl font-semibold text-xs text-white bg-indigo-600 hover:bg-indigo-500 transition-all flex-shrink-0">
                Contact Support
            </a>
        </div>

    </div>
</div>

@endsection
