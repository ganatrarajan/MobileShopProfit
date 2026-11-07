<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Models\Customer;
use App\Models\Device;
use App\Models\InventoryItem;
use App\Models\PushNotification;
use App\Models\Repair;
use App\Models\Sale;
use App\Models\Shop;
use App\Models\Technician;
use App\Models\TechnicianPayment;
use App\Models\User;
use App\Models\UserNotification;
use App\Traits\ApiResponse;
use Carbon\Carbon;
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
        $query = Shop::with(['user', 'latestSubscription.plan'])
            ->withCount([
                'technicians',
                'users as staff_logins_count' => function ($q) {
                    $q->where('role', '!=', 'owner');
                }
            ]);

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

        // Fetch technicians and their app login details for this shop
        $technicians = Technician::withoutGlobalScope('shop')
            ->where('shop_id', $id)
            ->with('user')
            ->orderByDesc('id')
            ->get()
            ->map(function ($tech) {
                $user = $tech->user;
                return [
                    'id' => $tech->id,
                    'name' => $tech->name,
                    'mobile' => $tech->mobile,
                    'specialization' => $tech->specialization,
                    'is_active' => (bool) $tech->is_active,
                    'has_login' => (bool) ($tech->user_id && $user),
                    'login_mobile' => $user ? ($user->mobile ?: $user->phone) : null,
                    'plain_password' => $user ? $user->plain_password : null,
                    'role' => $user ? $user->role : null,
                    'permissions' => $user ? ($user->permissions ?: ['repairs' => true]) : null,
                    'created_at' => $tech->created_at ? $tech->created_at->toIso8601String() : null,
                    'repairs_count' => Repair::withoutGlobalScope('shop')->where('technician_id', $tech->id)->count(),
                    'total_earnings' => (float) Repair::withoutGlobalScope('shop')->where('technician_id', $tech->id)->sum('technician_earning'),
                    'total_paid' => (float) TechnicianPayment::withoutGlobalScope('shop')->where('technician_id', $tech->id)->sum('amount'),
                ];
            });

        $shopData['technicians'] = $technicians;
        $shopData['technicians_count'] = $technicians->count();
        $shopData['technicians_with_login_count'] = $technicians->where('has_login', true)->count();

        // Also fetch any staff accounts in this shop (in case some staff aren't linked to technician record)
        $allStaffUsers = User::where('shop_id', $id)
            ->where('role', '!=', 'owner')
            ->with('technician')
            ->orderByDesc('id')
            ->get()
            ->map(function ($staff) {
                return [
                    'id' => $staff->id,
                    'name' => $staff->name,
                    'mobile' => $staff->mobile ?: $staff->phone,
                    'role' => $staff->role,
                    'plain_password' => $staff->plain_password,
                    'permissions' => $staff->permissions,
                    'is_technician' => (bool) $staff->technician,
                    'technician_id' => $staff->technician ? $staff->technician->id : null,
                    'created_at' => $staff->created_at ? $staff->created_at->toIso8601String() : null,
                ];
            });
        $shopData['all_staff_users'] = $allStaffUsers;
        $shopData['staff_logins_count'] = $allStaffUsers->count();

        // Fetch recent records for deep-dive tabs
        $shopData['recent_sales'] = Sale::withoutGlobalScope('shop')
            ->where('shop_id', $id)
            ->with(['customer' => fn($q) => $q->withoutGlobalScope('shop')->withTrashed(), 'items'])
            ->orderByDesc('id')
            ->take(15)
            ->get();

        $shopData['recent_repairs'] = Repair::withoutGlobalScope('shop')
            ->where('shop_id', $id)
            ->with([
                'customer' => fn($q) => $q->withoutGlobalScope('shop')->withTrashed(),
                'device' => fn($q) => $q->withoutGlobalScope('shop')->withTrashed(),
                'technician',
            ])
            ->orderByDesc('id')
            ->take(15)
            ->get();

        $shopData['recent_customers'] = Customer::withoutGlobalScope('shop')
            ->where('shop_id', $id)
            ->latest()
            ->take(10)
            ->get();

        $shopData['recent_inventory'] = InventoryItem::withoutGlobalScope('shop')
            ->where('shop_id', $id)
            ->latest()
            ->take(10)
            ->get();

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

    /**
     * Update custom technician / staff limit override for a specific shop.
     */
    public function updateStaffLimit(Request $request, $id): JsonResponse
    {
        $request->validate([
            'custom_max_staff'         => 'nullable|integer|min:0|max:100',
            'custom_staff_valid_until' => 'nullable|date',
            'custom_staff_note'        => 'nullable|string|max:255',
        ]);

        $shop = Shop::find($id);

        if (! $shop) {
            return $this->errorResponse('Shop not found', 404);
        }

        $oldLimit = $shop->custom_max_staff;
        $shop->update([
            'custom_max_staff'         => $request->filled('custom_max_staff') ? (int) $request->custom_max_staff : ($request->has('custom_max_staff') ? null : $shop->custom_max_staff),
            'custom_staff_valid_until' => $request->custom_staff_valid_until ?: null,
            'custom_staff_note'        => $request->custom_staff_note ?: null,
        ]);

        // Audit Log
        AdminAuditLog::create([
            'admin_id'    => $request->user()->id,
            'action'      => 'UPDATE_SHOP_STAFF_LIMIT',
            'target_type' => 'Shop',
            'target_id'   => $shop->id,
            'details'     => "Updated shop #{$shop->id} ({$shop->name}) staff limit from " . ($oldLimit ?? 'plan') . " to " . ($shop->custom_max_staff ?? 'plan') . ". Valid until: " . ($shop->custom_staff_valid_until ?? 'Indefinite') . ". Note: " . ($shop->custom_staff_note ?? 'None'),
            'ip_address'  => $request->ip(),
        ]);

        return $this->successResponse($shop->fresh(['user', 'latestSubscription.plan']), 'Shop staff limit updated successfully');
    }

    /**
     * Update custom pricing, discounts, and plan overrides for a specific shop.
     */
    public function updateCustomPricing(Request $request, $id): JsonResponse
    {
        $request->validate([
            'custom_discount_percent'     => 'nullable|numeric|min:0|max:99',
            'custom_plan_prices'          => 'nullable|array',
            'custom_staff_price_per_day'  => 'nullable|numeric|min:0|max:1000',
            'custom_discount_valid_until' => 'nullable|date',
            'custom_discount_note'        => 'nullable|string|max:255',
            'custom_discount_is_one_time' => 'nullable|boolean',
        ]);

        $shop = Shop::find($id);
        if (!$shop) {
            return $this->errorResponse('Shop not found', 404);
        }

        $shop->update([
            'custom_discount_percent'     => $request->filled('custom_discount_percent') ? (float) $request->custom_discount_percent : null,
            'custom_plan_prices'          => $request->has('custom_plan_prices') ? $request->custom_plan_prices : null,
            'custom_staff_price_per_day'  => $request->filled('custom_staff_price_per_day') ? (float) $request->custom_staff_price_per_day : null,
            'custom_discount_valid_until' => $request->filled('custom_discount_valid_until') ? $request->custom_discount_valid_until : null,
            'custom_discount_note'        => $request->filled('custom_discount_note') ? $request->custom_discount_note : null,
            'custom_discount_is_one_time' => filter_var($request->input('custom_discount_is_one_time', false), FILTER_VALIDATE_BOOLEAN),
        ]);

        // Audit Log
        AdminAuditLog::create([
            'admin_id'    => $request->user()->id,
            'action'      => 'UPDATE_SHOP_CUSTOM_PRICING',
            'target_type' => 'Shop',
            'target_id'   => $shop->id,
            'details'     => "Updated custom pricing for shop #{$shop->id} ({$shop->name}). Discount: " . ($shop->custom_discount_percent ? "{$shop->custom_discount_percent}%" : 'None') . ", One-time: " . ($shop->custom_discount_is_one_time ? 'Yes' : 'No') . ", Staff/Day: ₹" . ($shop->custom_staff_price_per_day ?? 'Default') . ", Valid until: " . ($shop->custom_discount_valid_until ?? 'Indefinite'),
            'ip_address'  => $request->ip(),
        ]);

        // Automatically dispatch in-app notification to the shop owner
        if ($shop->custom_discount_percent > 0) {
            try {
                $percent = (int) $shop->custom_discount_percent;
                $notifTitle = "🎉 Special {$percent}% Discount for Your Shop!";
                $notifDesc = ($shop->custom_discount_note ?: "A special {$percent}% discount has been configured for your shop!") .
                    ($shop->custom_discount_is_one_time ? " Valid for your next purchase." : "") .
                    ($shop->custom_discount_valid_until ? " Valid until " . Carbon::parse($shop->custom_discount_valid_until)->format('d M Y') . "." : "");

                $ownerUser = $shop->user ?: User::where('shop_id', $shop->id)->where('role', 'owner')->first();
                if ($ownerUser) {
                    UserNotification::create([
                        'user_id'     => $ownerUser->id,
                        'title'       => $notifTitle,
                        'description' => $notifDesc,
                        'is_read'     => false,
                    ]);
                }
            } catch (\Exception $e) {
                \Illuminate\Support\Facades\Log::warning("Failed to auto-create shop discount notification: " . $e->getMessage());
            }
        }

        return $this->successResponse($shop->fresh(['user', 'latestSubscription.plan']), 'Custom pricing and discounts updated successfully');
    }

    /**
     * Apply a discount percentage across ALL shops simultaneously.
     * Can be configured as a one-time purchase discount per shop.
     */
    public function applyBulkDiscount(Request $request): JsonResponse
    {
        $request->validate([
            'discount_percent' => 'required|numeric|min:1|max:99',
            'is_one_time'      => 'nullable|boolean',
            'valid_until'      => 'nullable|date',
            'note'             => 'nullable|string|max:255',
        ]);

        $percent = (float) $request->discount_percent;
        $isOneTime = filter_var($request->input('is_one_time', true), FILTER_VALIDATE_BOOLEAN);
        $validUntil = $request->filled('valid_until') ? $request->valid_until : null;
        $note = $request->filled('note') ? $request->note : "Platform-wide {$percent}% OFF Offer";

        $count = Shop::query()->update([
            'custom_discount_percent'     => $percent,
            'custom_discount_is_one_time' => $isOneTime,
            'custom_discount_valid_until' => $validUntil,
            'custom_discount_note'        => $note,
        ]);

        AdminAuditLog::create([
            'admin_id'    => $request->user()->id,
            'action'      => 'APPLY_BULK_DISCOUNT',
            'target_type' => 'Shop',
            'target_id'   => null,
            'details'     => "Applied {$percent}% discount across all {$count} shops. One-time use: " . ($isOneTime ? 'Yes' : 'No') . ", Valid until: " . ($validUntil ?? 'Indefinite'),
            'ip_address'  => $request->ip(),
        ]);

        // Automatically dispatch broadcast notification to all shop owners
        try {
            $notifTitle = "🎉 Special Offer: {$percent}% OFF Subscription Plans!";
            $notifDesc = ($note ?: "A special {$percent}% discount has been unlocked for your shop!") .
                ($isOneTime ? " Valid for your next subscription purchase." : "") .
                ($validUntil ? " Offer ends on " . Carbon::parse($validUntil)->format('d M Y') . "." : " Claim your offer now in Subscription & Payments.");

            $push = PushNotification::create([
                'title'            => $notifTitle,
                'description'      => $notifDesc,
                'target_type'      => 'all',
                'target_user_ids'  => null,
                'recipients_count' => $count,
                'created_by'       => $request->user()?->id,
                'sent_at'          => now(),
            ]);

            $owners = User::whereNotNull('shop_id')->get();
            $userNotifs = [];
            $nowTime = now();
            foreach ($owners as $owner) {
                $userNotifs[] = [
                    'user_id'              => $owner->id,
                    'push_notification_id' => $push->id,
                    'title'                => $notifTitle,
                    'description'          => $notifDesc,
                    'image_url'            => null,
                    'is_read'              => false,
                    'created_at'           => $nowTime,
                    'updated_at'           => $nowTime,
                ];
            }
            foreach (array_chunk($userNotifs, 500) as $chunk) {
                UserNotification::insert($chunk);
            }
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::warning("Failed to auto-generate bulk discount notification: " . $e->getMessage());
        }

        return $this->successResponse([
            'shops_updated'    => $count,
            'discount_percent' => $percent,
            'is_one_time'      => $isOneTime,
            'valid_until'      => $validUntil,
        ], "Successfully applied {$percent}% discount across all {$count} shops!");
    }

    /**
     * Clear all custom discounts across ALL shops.
     */
    public function clearBulkDiscount(Request $request): JsonResponse
    {
        $count = Shop::query()->update([
            'custom_discount_percent'     => null,
            'custom_discount_is_one_time' => false,
            'custom_discount_valid_until' => null,
            'custom_discount_note'        => null,
        ]);

        AdminAuditLog::create([
            'admin_id'    => $request->user()->id,
            'action'      => 'CLEAR_BULK_DISCOUNT',
            'target_type' => 'Shop',
            'target_id'   => null,
            'details'     => "Cleared custom discounts across all {$count} shops.",
            'ip_address'  => $request->ip(),
        ]);

        return $this->successResponse(['shops_updated' => $count], "Custom discounts cleared for all {$count} shops.");
    }
}
