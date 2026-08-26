<?php

use App\Http\Controllers\Api\V1\ProfitIntelligenceController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\DashboardController;
use App\Http\Controllers\Api\V1\ReportController;

use App\Http\Controllers\Api\V1\CustomerController;
use App\Http\Controllers\Api\V1\DeviceController;
use App\Http\Controllers\Api\V1\ShopController;
use App\Http\Controllers\Api\V1\SaleController;
use App\Http\Controllers\Api\V1\SalePaymentController;
use App\Http\Controllers\Api\V1\RepairController;
use App\Http\Controllers\Api\V1\RepairPaymentController;
use App\Http\Controllers\Api\V1\RepairPartController;
use App\Http\Controllers\Api\V1\WarrantyController;
use App\Http\Controllers\Api\V1\WarrantyClaimController;
use App\Http\Controllers\Api\V1\InventoryItemController;
use App\Http\Controllers\Api\V1\ExpenseCategoryController;
use App\Http\Controllers\Api\V1\ExpenseController;
use App\Http\Controllers\Api\V1\TechnicianController;



use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes - V1
|--------------------------------------------------------------------------
*/

Route::prefix('v1')->group(function () {

    // Health check endpoint
    Route::get('/health', function () {
        return response()->json([
            'success'   => true,
            'message'   => 'Mobile Shop Profit API V1 Operational',
            'timestamp' => now()->toIso8601String(),
        ]);
    });

    // Authentication Routes (Public)
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/auth/login', [AuthController::class, 'login']);
    Route::post('/auth/forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('/auth/reset-password', [AuthController::class, 'resetPassword']);

    // Protected Routes (Sanctum Auth)
    Route::middleware('auth:sanctum')->group(function () {
                // Dashboard Endpoint
        Route::get('/dashboard', [DashboardController::class, 'index']);
    // Profit Intelligence USP module routes
    Route::get('/profit-intelligence', [ProfitIntelligenceController::class, 'index']);
    Route::get('/profit-intelligence/details/{category}', [ProfitIntelligenceController::class, 'details']);


        // Reports & Analytics Management
        Route::get('/reports/sales', [ReportController::class, 'sales']);
        Route::get('/reports/repairs', [ReportController::class, 'repairs']);
        Route::get('/reports/inventory', [ReportController::class, 'inventory']);
        Route::get('/reports/expenses', [ReportController::class, 'expenses']);
        Route::get('/reports/payments', [ReportController::class, 'payments']);
        Route::get('/reports/customers', [ReportController::class, 'customers']);
        Route::get('/reports/warranties', [ReportController::class, 'warranties']);
        Route::get('/reports/export', [ReportController::class, 'export']);

        // Owner User & Auth
        Route::get('/auth/me', [AuthController::class, 'me']);
        Route::put('/auth/profile', [AuthController::class, 'updateProfile']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);

        // Shop Profile & Onboarding
        Route::post('/shop', [ShopController::class, 'store']);
        Route::get('/shop', [ShopController::class, 'show']);
        Route::put('/shop', [ShopController::class, 'update']);
        Route::post('/shop/logo', [ShopController::class, 'uploadLogo']);

        // Customer Management
        Route::apiResource('/customers', CustomerController::class);

        // Device Management
        Route::get('/customers/{customer}/devices', [DeviceController::class, 'indexForCustomer']);
        Route::post('/customers/{customer}/devices', [DeviceController::class, 'storeForCustomer']);
        Route::get('/devices', [DeviceController::class, 'indexGlobal']);
        Route::get('/devices/{device}', [DeviceController::class, 'show']);
        Route::put('/devices/{device}', [DeviceController::class, 'update']);
        Route::delete('/devices/{device}', [DeviceController::class, 'destroy']);

        // Sales & Billing Management
        Route::get('/sales', [SaleController::class, 'index']);
        Route::post('/sales', [SaleController::class, 'store']);
        Route::get('/sales/{sale}', [SaleController::class, 'show']);
        Route::put('/sales/{sale}', [SaleController::class, 'update']);
        Route::delete('/sales/{sale}', [SaleController::class, 'destroy']);

        // Repair & Job Card Management
        Route::get('/repairs', [RepairController::class, 'index']);
        Route::post('/repairs', [RepairController::class, 'store']);
        Route::get('/repairs/{repair}', [RepairController::class, 'show']);
        Route::put('/repairs/{repair}', [RepairController::class, 'update']);
        Route::delete('/repairs/{repair}', [RepairController::class, 'destroy']);
        Route::patch('/repairs/{repair}/status', [RepairController::class, 'updateStatus']);

        Route::get('/repairs/{repair}/payments', [RepairPaymentController::class, 'index']);
        Route::post('/repairs/{repair}/payments', [RepairPaymentController::class, 'store']);

        Route::post('/repairs/{repair}/parts', [RepairPartController::class, 'store']);
        Route::put('/repair-parts/{part}', [RepairPartController::class, 'update']);
        Route::delete('/repair-parts/{part}', [RepairPartController::class, 'destroy']);

        // Warranty & Claims Management
        Route::get('/warranties', [WarrantyController::class, 'index']);
        Route::post('/warranties', [WarrantyController::class, 'store']);
        Route::get('/warranties/{warranty}', [WarrantyController::class, 'show']);
        Route::put('/warranties/{warranty}', [WarrantyController::class, 'update']);
        Route::delete('/warranties/{warranty}', [WarrantyController::class, 'destroy']);

        Route::get('/warranties/{warranty}/claims', [WarrantyClaimController::class, 'index']);
        Route::post('/warranties/{warranty}/claims', [WarrantyClaimController::class, 'store']);

        Route::get('/warranty-claims', [WarrantyClaimController::class, 'index']);
        Route::get('/warranty-claims/{claim}', [WarrantyClaimController::class, 'show']);
        Route::put('/warranty-claims/{claim}', [WarrantyClaimController::class, 'update']);
        Route::delete('/warranty-claims/{claim}', [WarrantyClaimController::class, 'destroy']);

                // Expense Categories
        Route::get('/expense-categories', [ExpenseCategoryController::class, 'index']);
        Route::post('/expense-categories', [ExpenseCategoryController::class, 'store']);

        // Expenses
        Route::apiResource('expenses', ExpenseController::class);

        // Technicians
            // Technician Management & Payouts
    Route::get('technicians/{id}/payments', [\App\Http\Controllers\Api\V1\TechnicianPaymentController::class, 'index']);
    Route::post('technician-payments', [\App\Http\Controllers\Api\V1\TechnicianPaymentController::class, 'store']);
    Route::delete('technician-payments/{id}', [\App\Http\Controllers\Api\V1\TechnicianPaymentController::class, 'destroy']);
        // Technician Management & Payouts
    Route::get('technicians/{id}/payments', [\App\Http\Controllers\Api\V1\TechnicianPaymentController::class, 'index']);
    Route::post('technician-payments', [\App\Http\Controllers\Api\V1\TechnicianPaymentController::class, 'store']);
    Route::delete('technician-payments/{id}', [\App\Http\Controllers\Api\V1\TechnicianPaymentController::class, 'destroy']);
    Route::apiResource('technicians', \App\Http\Controllers\Api\V1\TechnicianController::class);

        // Inventory Management
        Route::get('/inventory', [InventoryItemController::class, 'index']);
        Route::post('/inventory', [InventoryItemController::class, 'store']);
        Route::get('/inventory/{id}', [InventoryItemController::class, 'show']);
        Route::put('/inventory/{id}', [InventoryItemController::class, 'update']);
        Route::delete('/inventory/{id}', [InventoryItemController::class, 'destroy']);
        Route::post('/inventory/{id}/stock', [InventoryItemController::class, 'addStock']);
        Route::post('/inventory/{id}/adjustment', [InventoryItemController::class, 'adjustStock']);
        Route::get('/inventory/{id}/movements', [InventoryItemController::class, 'movements']);
        Route::get('/sales/{sale}/payments', [SalePaymentController::class, 'index']);
        Route::post('/sales/{sale}/payments', [SalePaymentController::class, 'store']);
    });
});
