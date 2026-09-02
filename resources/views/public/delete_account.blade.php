@extends('layouts.public')

@section('title', 'Request Account Deletion — Mobile Profits')
@section('meta_description', 'Account Deletion instructions and request form for Mobile Profits users.')

@section('content')

<div class="py-12 sm:py-20 bg-slate-950 min-h-screen">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        
        <!-- Header -->
        <div class="mb-8">
            <a href="{{ route('home') }}" class="inline-flex items-center text-xs font-semibold text-indigo-400 hover:text-indigo-300 gap-1 mb-4">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>
                <span>Back to Home</span>
            </a>
            <h1 class="text-3xl sm:text-5xl font-black text-white tracking-tight">
                Request Account Deletion
            </h1>
            <p class="text-slate-400 mt-2 text-sm sm:text-base">
                Mobile Profits respects your privacy rights. You may submit an account deletion request below.
            </p>
        </div>

        <!-- Deletion Policy Info Card -->
        <div class="card-glass p-8 rounded-2xl text-slate-300 text-sm leading-relaxed mb-8 [&_h1]:text-2xl [&_h1]:font-bold [&_h1]:text-white [&_h1]:mb-3 [&_h2]:text-xl [&_h2]:font-bold [&_h2]:text-white [&_h2]:mt-6 [&_h2]:mb-3 [&_ul]:list-disc [&_ul]:pl-6 [&_ul]:space-y-2 [&_p]:mb-3">
            @if($page && $page->content)
                {!! $page->content !!}
            @else
                <h2>How to Delete Your Mobile Profits Account</h2>
                <p>If you no longer wish to use Mobile Profits, you can request the permanent deletion of your account and associated shop data.</p>
                <h2>What Information is Deleted?</h2>
                <ul>
                    <li>User Account Credentials & Login Tokens</li>
                    <li>Shop Configuration & Staff Accounts</li>
                    <li>Attached Customer Repair Photos & Notes</li>
                </ul>
                <h2>Processing Time</h2>
                <p>All verified requests are completed within 7 business days.</p>
            @endif
        </div>

        <!-- Interactive Account Deletion Form -->
        <div class="card-glass p-8 rounded-2xl border-rose-500/30">
            <h3 class="text-xl font-bold text-white mb-2 flex items-center gap-2">
                <svg class="w-5 h-5 text-rose-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                <span>Submit Deletion Request</span>
            </h3>
            <p class="text-xs text-slate-400 mb-6">
                Enter your registered Email or Mobile Number. Our support team will verify your identity before finalizing deletion.
            </p>

            <div id="alertBox" class="hidden mb-6 p-4 rounded-xl text-xs font-semibold"></div>

            <form id="deletionForm" class="space-y-5">
                @csrf
                <div>
                    <label class="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-2">Registered Email or Mobile Number *</label>
                    <input type="text" id="identifier" name="identifier" required placeholder="e.g. shopowner@gmail.com or 9876543210" class="w-full px-4 py-3 rounded-xl bg-slate-900 border border-slate-700 text-white placeholder-slate-500 text-sm focus:outline-none focus:border-rose-500">
                </div>

                <div>
                    <label class="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-2">Reason for Deletion (Optional)</label>
                    <textarea id="reason" name="reason" rows="3" placeholder="Tell us why you are leaving Mobile Profits..." class="w-full px-4 py-3 rounded-xl bg-slate-900 border border-slate-700 text-white placeholder-slate-500 text-sm focus:outline-none focus:border-rose-500"></textarea>
                </div>

                <button type="submit" id="submitBtn" class="w-full py-3.5 rounded-xl font-bold text-sm text-white bg-rose-600 hover:bg-rose-500 transition-all shadow-lg shadow-rose-600/25">
                    Submit Request Account Deletion
                </button>
            </form>
        </div>

    </div>
</div>

<script>
    document.getElementById('deletionForm').addEventListener('submit', async function(e) {
        e.preventDefault();
        const btn = document.getElementById('submitBtn');
        const alertBox = document.getElementById('alertBox');
        const identifier = document.getElementById('identifier').value;
        const reason = document.getElementById('reason').value;

        btn.disabled = true;
        btn.innerHTML = 'Submitting Request...';
        alertBox.className = 'hidden';

        try {
            const res = await fetch('/api/v1/public/delete-account-request', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                body: JSON.stringify({ identifier, reason })
            });

            const data = await res.json();
            alertBox.classList.remove('hidden');

            if (data.success) {
                alertBox.className = 'mb-6 p-4 rounded-xl text-xs font-semibold bg-emerald-950/80 border border-emerald-500/40 text-emerald-300';
                alertBox.innerText = data.message;
                document.getElementById('deletionForm').reset();
            } else {
                alertBox.className = 'mb-6 p-4 rounded-xl text-xs font-semibold bg-rose-950/80 border border-rose-500/40 text-rose-300';
                alertBox.innerText = data.message || 'Error submitting request.';
            }
        } catch (err) {
            alertBox.classList.remove('hidden');
            alertBox.className = 'mb-6 p-4 rounded-xl text-xs font-semibold bg-rose-950/80 border border-rose-500/40 text-rose-300';
            alertBox.innerText = 'Network error. Please try again or email support@mobileprofits.com.';
        } finally {
            btn.disabled = false;
            btn.innerHTML = 'Submit Request Account Deletion';
        }
    });
</script>

@endsection
