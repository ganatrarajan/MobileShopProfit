<?php

use App\Http\Controllers\PublicPageController;
use Illuminate\Support\Facades\Route;

// Shop Owner Vue.js Web Portal SPA
Route::any('/portal/{any?}', function () {
    $indexPath = public_path('portal-assets/index.html');
    if (file_exists($indexPath)) {
        return response(file_get_contents($indexPath), 200, [
            'Content-Type' => 'text/html; charset=UTF-8',
            'Cache-Control' => 'no-cache, no-store, must-revalidate',
            'Pragma' => 'no-cache',
            'Expires' => '0',
        ]);
    }
    return response('Web portal building... Please wait.', 503);
})->where('any', '.*');


// Public Website & Dynamic Legal Pages

Route::get('/', [PublicPageController::class, 'home'])->name('home');
Route::get('/privacy-policy', [PublicPageController::class, 'privacyPolicy'])->name('privacy-policy');
Route::get('/terms-and-conditions', [PublicPageController::class, 'termsAndConditions'])->name('terms-and-conditions');
Route::get('/refund-policy', [PublicPageController::class, 'refundPolicy'])->name('refund-policy');
Route::get('/delete-account', [PublicPageController::class, 'deleteAccount'])->name('delete-account');
Route::get('/contact', [PublicPageController::class, 'contact'])->name('contact');

// Admin Panel Web Application SPA
Route::get('/admin_login/{any?}', function () {
    return view('admin');
})->where('any', '.*');




