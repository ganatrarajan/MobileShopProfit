<?php

use App\Http\Controllers\PublicPageController;
use Illuminate\Support\Facades\Route;

// Public Website & Dynamic Legal Pages
Route::get('/', [PublicPageController::class, 'home'])->name('home');
Route::get('/privacy-policy', [PublicPageController::class, 'privacyPolicy'])->name('privacy-policy');
Route::get('/terms-and-conditions', [PublicPageController::class, 'termsAndConditions'])->name('terms-and-conditions');
Route::get('/refund-policy', [PublicPageController::class, 'refundPolicy'])->name('refund-policy');
Route::get('/delete-account', [PublicPageController::class, 'deleteAccount'])->name('delete-account');
Route::get('/contact', [PublicPageController::class, 'contact'])->name('contact');

// Admin Panel Web Application SPA
Route::get('/admin/{any?}', function () {
    return view('admin');
})->where('any', '.*');
