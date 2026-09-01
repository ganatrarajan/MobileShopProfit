<?php

use App\Http\Controllers\Api\V1\Admin\AdminAuditLogController;
use App\Http\Controllers\Api\V1\Admin\AdminAuthController;
use App\Http\Controllers\Api\V1\Admin\AdminDashboardController;
use App\Http\Controllers\Api\V1\Admin\AdminPaymentController;
use App\Http\Controllers\Api\V1\Admin\AdminPaymentGatewayController;
use App\Http\Controllers\Api\V1\Admin\AdminPlanController;
use App\Http\Controllers\Api\V1\Admin\AdminRevenueController;
use App\Http\Controllers\Api\V1\Admin\AdminShopController;
use App\Http\Controllers\Api\V1\Admin\AdminSubscriptionController;
use App\Http\Controllers\Api\V1\Admin\AdminSupportController;
use App\Http\Controllers\Api\V1\Admin\AdminUserController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CustomerController;
use App\Http\Controllers\Api\V1\DashboardController;
use App\Http\Controllers\Api\V1\DeviceController;
use App\Http\Controllers\Api\V1\ExpenseCategoryController;
use App\Http\Controllers\Api\V1\ExpenseController;
use App\Http\Controllers\Api\V1\InventoryItemController;
use App\Http\Controllers\Api\V1\ProfitIntelligenceController;
use App\Http\Controllers\Api\V1\RepairController;
use App\Http\Controllers\Api\V1\RepairPartController;
use App\Http\Controllers\Api\V1\RepairPaymentController;
use App\Http\Controllers\Api\V1\ReportController;
use App\Http\Controllers\Api\V1\SaleController;
use App\Http\Controllers\Api\V1\SalePaymentController;
use App\Http\Controllers\Api\V1\ShopController;
use App\Http\Controllers\Api\V1\SubscriptionController;
use App\Http\Controllers\Api\V1\TechnicianController;
use App\Http\Controllers\Api\V1\TechnicianPaymentController;
use App\Http\Controllers\Api\V1\WarrantyClaimController;
use App\Http\Controllers\Api\V1\WarrantyController;
use App\Http\Controllers\Api\V1\WebhookController;
use App\Http\Middleware\EnsureUserIsAdmin;
use App\Http\Middleware\EnsureShopIsActive;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes - Mobile Profits SaaS Platform
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

    // Public Razorpay Webhook Callback Endpoint
    Route::post('/webhooks/razorpay', [WebhookController::class, 'handleRazorpay']);

    // Admin Auth Public Route (Rate Limited)
    Route::post('/admin/auth/login', [AdminAuthController::class, 'login'])->middleware('throttle:10,1');

    // Admin Protected Routes (Sanctum Auth + Admin Role Middleware)
    Route::prefix('admin')->middleware(['auth:sanctum', EnsureUserIsAdmin::class])->group(function () {
        // Admin Profile & Credentials
        Route::get('/auth/me', [AdminAuthController::class, 'me']);
        Route::post('/auth/change-password', [AdminAuthController::class, 'changePassword']);
        Route::post('/auth/logout', [AdminAuthController::class, 'logout']);

        // Admin Dashboard Overview
        Route::get('/dashboard', [AdminDashboardController::class, 'index']);

        // Admin Shop Management
        Route::get('/shops', [AdminShopController::class, 'index']);
        Route::get('/shops/{id}', [AdminShopController::class, 'show']);
        Route::post('/shops/{id}/toggle-status', [AdminShopController::class, 'toggleStatus']);

        // Admin User Management
        Route::get('/users', [AdminUserController::class, 'index']);
        Route::get('/users/{id}', [AdminUserController::class, 'show']);

        // Admin Subscription & Plans Management
        Route::get('/subscriptions', [AdminSubscriptionController::class, 'index']);
        Route::put('/subscriptions/{id}/status', [AdminSubscriptionController::class, 'updateStatus']);

        Route::get('/plans', [AdminPlanController::class, 'index']);
        Route::post('/plans', [AdminPlanController::class, 'store']);
        Route::put('/plans/{id}', [AdminPlanController::class, 'update']);
        Route::post('/plans/{id}/toggle-status', [AdminPlanController::class, 'toggleStatus']);

        // Admin Payment Gateway Settings & Connection Test
        Route::get('/settings/payment-gateway', [AdminPaymentGatewayController::class, 'getSettings']);
        Route::post('/settings/payment-gateway', [AdminPaymentGatewayController::class, 'saveSettings']);
        Route::post('/settings/payment-gateway/test', [AdminPaymentGatewayController::class, 'testConnection']);

        // Admin Real Payments Log
        Route::get('/payments', [AdminPaymentController::class, 'index']);

        // Admin Revenue Analytics
        Route::get('/revenue', [AdminRevenueController::class, 'index']);

        // Admin Support Tickets & Problem Reports
        Route::get('/support', [AdminSupportController::class, 'index']);
        Route::put('/support/{id}/status', [AdminSupportController::class, 'updateStatus']);
        Route::get('/support/contact-info', [AdminSupportController::class, 'getContactInfo']);
        Route::post('/support/contact-info', [AdminSupportController::class, 'saveContactInfo']);

        // Admin Audit Action Logs
        Route::get('/audit-logs', [AdminAuditLogController::class, 'index']);
    });

    // Authentication Routes (Public & Rate Limited)
    Route::post('/auth/register', [AuthController::class, 'register'])->middleware('throttle:10,1');
    Route::post('/auth/login', [AuthController::class, 'login'])->middleware('throttle:10,1');
    Route::post('/auth/forgot-password', [AuthController::class, 'forgotPassword'])->middleware('throttle:10,1');
    Route::post('/auth/reset-password', [AuthController::class, 'resetPassword'])->middleware('throttle:10,1');

    // Protected Shop Owner Routes (Sanctum Auth)
    Route::middleware(['auth:sanctum', EnsureShopIsActive::class])->group(function () {
        // Dashboard Endpoint
        Route::get('/dashboard', [DashboardController::class, 'index']);

        // Auth User Profile & Password Change
        Route::get('/auth/me', [AuthController::class, 'me']);
        Route::post('/auth/change-password', [AuthController::class, 'changePassword']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);

        // Subscription & Payments (Shop Owner - Rate Limited)
        Route::get('/subscription/status', [SubscriptionController::class, 'status']);
        Route::post('/subscription/create-order', [SubscriptionController::class, 'createOrder'])->middleware('throttle:15,1');
        Route::post('/subscription/verify-payment', [SubscriptionController::class, 'verifyPayment'])->middleware('throttle:15,1');
        Route::get('/subscription/history', [SubscriptionController::class, 'history']);
        Route::get('/plans', [AdminPlanController::class, 'index']);

        // Support Requests (App Submissions)
        Route::get('/support/contact-info', [AdminSupportController::class, 'getContactInfo']);
        Route::post('/support-requests', [AdminSupportController::class, 'store']);

        // Profit Intelligence USP module routes
        Route::get('/profit-intelligence', [ProfitIntelligenceController::class, 'index']);
        Route::get('/profit-intelligence/summary', [ProfitIntelligenceController::class, 'index']);
        Route::get('/profit-intelligence/details/{category}', [ProfitIntelligenceController::class, 'details']);

        // Shop Settings
        Route::get('/shop', [ShopController::class, 'show']);
        Route::post('/shop', [ShopController::class, 'store']);
        Route::put('/shop', [ShopController::class, 'update']);
        Route::post('/shop/logo', [ShopController::class, 'uploadLogo']);

        // Customers Module
        Route::apiResource('customers', CustomerController::class);

        // Customer Devices Module
        Route::get('/devices', [DeviceController::class, 'indexGlobal']);
        Route::get('/devices/search', [DeviceController::class, 'search']);
        Route::get('/device-brands', [DeviceController::class, 'getBrands']);
        Route::get('/device-models', [DeviceController::class, 'getModels']);
        Route::apiResource('customers.devices', DeviceController::class)->shallow();

        // Sales & Invoicing Module
        Route::apiResource('sales', SaleController::class);
        Route::post('/sales/{sale}/payments', [SalePaymentController::class, 'store']);

        // Repairs Module
        Route::apiResource('repairs', RepairController::class);
        Route::match(['post', 'patch', 'put'], '/repairs/{repair}/status', [RepairController::class, 'updateStatus']);
        Route::post('/repairs/{repair}/parts', [RepairPartController::class, 'store']);
        Route::delete('/repairs/{repair}/parts/{part}', [RepairPartController::class, 'destroy']);
        Route::match(['post', 'delete'], '/repair-parts/{part}', [RepairPartController::class, 'destroy']);
        Route::post('/repairs/{repair}/payments', [RepairPaymentController::class, 'store']);

        // Warranties Module
        Route::apiResource('warranties', WarrantyController::class);
        Route::get('/warranties/{warranty}/claims', [WarrantyClaimController::class, 'index']);
        Route::post('/warranties/{warranty}/claims', [WarrantyClaimController::class, 'store']);
        Route::apiResource('warranty-claims', WarrantyClaimController::class);

        // Inventory Module
        Route::apiResource('inventory', InventoryItemController::class);

        // Expense Management
        Route::apiResource('expense-categories', ExpenseCategoryController::class);
        Route::apiResource('expenses', ExpenseController::class);

        // Technicians Module
        Route::apiResource('technicians', TechnicianController::class);
        Route::get('/technicians/{technician}/payments', [TechnicianPaymentController::class, 'index']);
        Route::post('/technicians/{technician}/payments', [TechnicianPaymentController::class, 'store']);
        Route::post('/technician-payments', [TechnicianPaymentController::class, 'store']);
        Route::delete('/technician-payments/{payment}', [TechnicianPaymentController::class, 'destroy']);
        Route::delete('/technicians/{technician}/payments/{payment}', [TechnicianPaymentController::class, 'destroy']);

        // Reports Module
        Route::get('/reports/sales', [ReportController::class, 'sales']);
        Route::get('/reports/repairs', [ReportController::class, 'repairs']);
        Route::get('/reports/inventory', [ReportController::class, 'inventory']);
        Route::get('/reports/expenses', [ReportController::class, 'expenses']);
        Route::get('/reports/payments', [ReportController::class, 'payments']);
        Route::get('/reports/customers', [ReportController::class, 'customers']);
        Route::get('/reports/warranties', [ReportController::class, 'warranties']);
    });
});
