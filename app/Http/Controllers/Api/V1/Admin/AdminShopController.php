<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Models\Customer;
use App\Models\Device;
use App\Models\InventoryItem;
use App\Models\Repair;
use App\Models\Sale;
use App\Models\Shop;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminShopController extends Controller
{
    use ApiResponse;

    /**
     * Get paginated shops list with search and filters.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Shop::with(['user', 'latestSubscription.plan']);

        // Search by shop name, owner name, phone, mobile, email
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('owner_name', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%")
                  ->orWhere('mobile', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        // Filter by account status
        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        // Filter by subscription status
        if ($request->filled('subscription_status')) {
            $subStatus = $request->subscription_status;
            $query->whereHas('latestSubscription', function ($q) use ($subStatus) {
                $q->where('status', $subStatus);
            });
        }

        $perPage = (int) $request->input('per_page', 15);
        $shops = $query->latest()->paginate($perPage);

        return $this->successResponse($shops, 'Shops list retrieved');
    }

    /**
     * Get single shop details and usage summary.
     */
    public function show($id): JsonResponse
    {
        $shop = Shop::with([
            'user',
            'users',
            'latestSubscription.plan',
            'subscriptions.plan',
        ])->find($id);

        if (! $shop) {
            return $this->errorResponse('Shop not found', 404);
        }

        // Calculate counts without global shop scope
        $customersCount = Customer::withoutGlobalScope('shop')->where('shop_id', $id)->count();
        $repairsCount = Repair::withoutGlobalScope('shop')->where('shop_id', $id)->count();
        $salesCount = Sale::withoutGlobalScope('shop')->where('shop_id', $id)->count();
        $devicesCount = Device::withoutGlobalScope('shop')->where('shop_id', $id)->count();
        $inventoryCount = InventoryItem::withoutGlobalScope('shop')->where('shop_id', $id)->count();

        $shopData = $shop->toArray();
        $shopData['customers_count'] = $customersCount;
        $shopData['repairs_count'] = $repairsCount;
        $shopData['sales_count'] = $salesCount;
        $shopData['devices_count'] = $devicesCount;
        $shopData['inventory_items_count'] = $inventoryCount;

        // Fallback for mobile and email from shop phone or owner user record
        $shopData['contact_mobile'] = $shop->phone ?: ($shop->mobile ?: ($shop->user ? ($shop->user->mobile ?: $shop->user->phone) : null));
        $shopData['contact_email'] = $shop->email ?: ($shop->user ? $shop->user->email : null);

        return $this->successResponse($shopData, 'Shop details retrieved');
    }

    /**
     * Activate or Deactivate shop account.
     */
    public function toggleStatus(Request $request, $id): JsonResponse
    {
        $request->validate([
            'status' => 'required|string|in:active,deactivated',
            'reason' => 'nullable|string',
        ]);

        $shop = Shop::find($id);

        if (! $shop) {
            return $this->errorResponse('Shop not found', 404);
        }

        $oldStatus = $shop->status;
        $newStatus = $request->status;

        $shop->update(['status' => $newStatus]);

        // Record Audit Log
        AdminAuditLog::create([
            'admin_id'    => $request->user()->id,
            'action'      => $newStatus === 'active' ? 'ACTIVATE_SHOP' : 'DEACTIVATE_SHOP',
            'target_type' => 'Shop',
            'target_id'   => $shop->id,
            'details'     => "Changed shop status from {$oldStatus} to {$newStatus}. Reason: " . ($request->reason ?? 'N/A'),
            'ip_address'  => $request->ip(),
        ]);

        return $this->successResponse($shop->fresh(['user', 'latestSubscription.plan']), "Shop has been {$newStatus} successfully");
    }
}
