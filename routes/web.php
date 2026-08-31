<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// Admin Panel Web Application
Route::get('/admin/{any?}', function () {
    return view('admin');
})->where('any', '.*');
