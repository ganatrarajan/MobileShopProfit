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
use App\Models\Staff;
use App\Models\Technician;
use App\Models\TechnicianPayment;
use App\Models\User;
use App\Models\UserNotification;
use App\Traits\ApiResponse;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

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
                    $q->where('role', 'staff')
                      ->where(function ($sq) {
                          $sq->whereDoesntHave('staff')
                             ->orWhereHas('staff', fn($st) => $st->where('is_active', true));
                      });
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

        // Fetch repair technicians for this shop (repair specialist metrics only, no logins)
        $technicians = Technician::withoutGlobalScope('shop')
            ->where('shop_id', $id)
            ->orderByDesc('id')
            ->get()
            ->map(function ($tech) {
                return [
                    'id' => $tech->id,
                    'name' => $tech->name,
                    'mobile' => $tech->mobile,
                    'specialization' => $tech->specialization,
                    'is_active' => (bool) $tech->is_active,
                    'created_at' => $tech->created_at ? $tech->created_at->toIso8601String() : null,
                    'repairs_count' => Repair::withoutGlobalScope('shop')->where('technician_id', $tech->id)->count(),
                    'total_earnings' => (float) Repair::withoutGlobalScope('shop')->where('technician_id', $tech->id)->sum('technician_earning'),
                    'total_paid' => (float) TechnicianPayment::withoutGlobalScope('shop')->where('technician_id', $tech->id)->sum('amount'),
                ];
            });

        $shopData['technicians'] = $technicians;
        $shopData['technicians_count'] = $technicians->count();

        // Fetch staff members (app login accounts with role, credentials, and permissions)
        $staffMembers = Staff::withoutGlobalScope('shop')
            ->where('shop_id', $id)
            ->with('user')
            ->orderByDesc('id')
            ->get()
            ->map(function ($st) {
                $user = $st->user;
                return [
                    'id' => $st->id,
                    'user_id' => $st->user_id,
                    'name' => $st->name,
                    'mobile' => $st->mobile,
                    'email' => $st->email,
                    'designation' => $st->designation,
                    'salary' => $st->salary !== null ? (float) $st->salary : null,
                    'salary_type' => $st->salary_type ?: 'monthly',
                    'address' => $st->address,
                    'joining_date' => $st->joining_date ? Carbon::parse($st->joining_date)->format('Y-m-d') : null,
                    'is_active' => (bool) $st->is_active,
                    'login_mobile' => $user ? ($user->mobile ?: $user->phone) : $st->mobile,
                    'plain_password' => $user ? $user->plain_password : null,
                    'permissions' => $st->permissions ?: ($user ? $user->permissions : []),
                    'created_at' => $st->created_at ? $st->created_at->toIso8601String() : null,
                ];
            });

        // Also check if there are legacy staff Users in this shop without Staff row
        $existingStaffUserIds = $staffMembers->pluck('user_id')->filter()->toArray();
        $standaloneStaffUsers = User::where('shop_id', $id)
            ->where('role', 'staff')
            ->whereNotIn('id', $existingStaffUserIds)
            ->get()
            ->map(function ($u) {
                return [
                    'id' => null,
                    'user_id' => $u->id,
                    'name' => $u->name,
                    'mobile' => $u->mobile ?: $u->phone,
                    'email' => $u->email,
                    'designation' => 'Staff',
                    'salary' => null,
                    'salary_type' => 'monthly',
                    'address' => null,
                    'joining_date' => null,
                    'is_active' => true,
                    'login_mobile' => $u->mobile ?: $u->phone,
                    'plain_password' => $u->plain_password,
                    'permissions' => $u->permissions ?: [],
                    'created_at' => $u->created_at ? $u->created_at->toIso8601String() : null,
                ];
            });

        $allStaff = $staffMembers->concat($standaloneStaffUsers)->values();
        $shopData['staff'] = $allStaff;
        $shopData['staff_count'] = $allStaff->count();
        $shopData['staff_logins_count'] = Staff::forShop($id)->where('is_active', true)->whereNotNull('user_id')->count();
        $shopData['all_staff_users'] = $allStaff;

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

        $customMaxStaff = $request->input('custom_max_staff');
        if ($customMaxStaff !== null && $customMaxStaff !== '') {
            $customMaxStaff = (int) $customMaxStaff;
        } else {
            $customMaxStaff = null;
        }

        $validUntil = $request->input('custom_staff_valid_until');
        $validUntil = !empty($validUntil) ? Carbon::parse($validUntil)->format('Y-m-d') : null;

        $note = $request->input('custom_staff_note');
        $note = !empty($note) ? trim($note) : null;

        $shop->update([
            'custom_max_staff'         => $customMaxStaff,
            'custom_staff_valid_until' => $validUntil,
            'custom_staff_note'        => $note,
        ]);

        // Audit Log
        AdminAuditLog::create([
            'admin_id'    => $request->user()->id,
            'action'      => 'UPDATE_SHOP_STAFF_LIMIT',
            'target_type' => 'Shop',
            'target_id'   => $shop->id,
            'details'     => "Updated shop #{$shop->id} ({$shop->name}) staff limit from " . ($oldLimit ?? 'plan') . " to " . ($customMaxStaff ?? 'plan') . ". Valid until: " . ($validUntil ?? 'Indefinite') . ". Note: " . ($note ?? 'None'),
            'ip_address'  => $request->ip(),
        ]);

        return $this->successResponse($shop->fresh(['user', 'latestSubscription.plan']), 'Shop staff limit updated successfully');
    }

    /**
     * Create a staff member for a specific shop directly from Admin Panel.
     */
    public function addStaff(Request $request, $id): JsonResponse
    {
        $shop = Shop::find($id);
        if (!$shop) {
            return $this->errorResponse('Shop not found', 404);
        }

        $validated = $request->validate([
            'name'         => 'required|string|max:100',
            'mobile'       => 'required|string|max:20',
            'password'     => 'required|string|min:4',
            'designation'  => 'nullable|string|max:100',
            'salary'       => 'nullable|numeric|min:0',
            'email'        => 'nullable|email|max:150',
            'address'      => 'nullable|string|max:255',
            'joining_date' => 'nullable|date',
            'is_active'    => 'nullable|boolean',
            'permissions'  => 'nullable|array',
        ]);

        // Check if mobile already exists
        if (User::where('mobile', $validated['mobile'])->orWhere('phone', $validated['mobile'])->exists()) {
            return $this->errorResponse('A user account with this mobile number already exists.', 422);
        }

        $defaultPerms = [
            'sales'        => true,
            'repairs'      => true,
            'purchases'    => false,
            'expenses'     => false,
            'used_mobiles' => false,
            'customers'    => true,
        ];

        $perms = $validated['permissions'] ?? $defaultPerms;

        $staffUser = User::create([
            'name'           => $validated['name'],
            'mobile'         => $validated['mobile'],
            'phone'          => $validated['mobile'],
            'email'          => $validated['email'] ?? null,
            'password'       => Hash::make($validated['password']),
            'plain_password' => $validated['password'],
            'role'           => 'staff',
            'permissions'    => $perms,
            'shop_id'        => $shop->id,
        ]);

        $staff = Staff::create([
            'shop_id'      => $shop->id,
            'user_id'      => $staffUser->id,
            'name'         => $validated['name'],
            'mobile'       => $validated['mobile'],
            'email'        => $validated['email'] ?? null,
            'designation'  => $validated['designation'] ?? 'Staff',
            'salary'       => $validated['salary'] ?? null,
            'salary_type'  => 'monthly',
            'address'      => $validated['address'] ?? null,
            'joining_date' => $validated['joining_date'] ?? null,
            'permissions'  => $perms,
            'is_active'    => $validated['is_active'] ?? true,
        ]);

        AdminAuditLog::create([
            'admin_id'    => $request->user()->id,
            'action'      => 'ADMIN_CREATE_STAFF',
            'target_type' => 'Staff',
            'target_id'   => $staff->id,
            'details'     => "Admin created staff #{$staff->id} ({$staff->name}, {$staff->mobile}) for shop #{$shop->id} ({$shop->name})",
            'ip_address'  => $request->ip(),
        ]);

        return $this->successResponse($staff, 'Staff member created successfully');
    }

    /**
     * Update a staff member for a specific shop from Admin Panel.
     */
    public function updateStaff(Request $request, $id, $staffId): JsonResponse
    {
        $shop = Shop::find($id);
        if (!$shop) {
            return $this->errorResponse('Shop not found', 404);
        }

        $staff = Staff::withoutGlobalScope('shop')->where('shop_id', $id)->find($staffId);
        if (!$staff) {
            return $this->errorResponse('Staff record not found', 404);
        }

        $validated = $request->validate([
            'name'         => 'sometimes|required|string|max:100',
            'mobile'       => 'sometimes|required|string|max:20',
            'password'     => 'nullable|string|min:4',
            'designation'  => 'nullable|string|max:100',
            'salary'       => 'nullable|numeric|min:0',
            'email'        => 'nullable|email|max:150',
            'address'      => 'nullable|string|max:255',
            'joining_date' => 'nullable|date',
            'is_active'    => 'nullable|boolean',
            'permissions'  => 'nullable|array',
        ]);

        $user = $staff->user ?: User::find($staff->user_id);

        if (isset($validated['mobile']) && $validated['mobile'] !== $staff->mobile) {
            $mobileExists = User::where(function ($q) use ($validated) {
                $q->where('mobile', $validated['mobile'])->orWhere('phone', $validated['mobile']);
            })->when($user, fn($q) => $q->where('id', '!=', $user->id))->exists();

            if ($mobileExists) {
                return $this->errorResponse('A user account with this mobile number already exists.', 422);
            }
        }

        $staff->fill(array_filter([
            'name'         => $validated['name'] ?? $staff->name,
            'mobile'       => $validated['mobile'] ?? $staff->mobile,
            'email'        => array_key_exists('email', $validated) ? $validated['email'] : $staff->email,
            'designation'  => array_key_exists('designation', $validated) ? $validated['designation'] : $staff->designation,
            'salary'       => array_key_exists('salary', $validated) ? $validated['salary'] : $staff->salary,
            'address'      => array_key_exists('address', $validated) ? $validated['address'] : $staff->address,
            'joining_date' => array_key_exists('joining_date', $validated) ? $validated['joining_date'] : $staff->joining_date,
            'is_active'    => array_key_exists('is_active', $validated) ? $validated['is_active'] : $staff->is_active,
            'permissions'  => $validated['permissions'] ?? $staff->permissions,
        ], fn($v) => !is_null($v)));
        $staff->save();

        if ($user) {
            $user->name = $staff->name;
            $user->mobile = $staff->mobile;
            $user->phone = $staff->mobile;
            if (array_key_exists('email', $validated)) {
                $user->email = $validated['email'];
            }
            if (!empty($validated['password'])) {
                $user->password = Hash::make($validated['password']);
                $user->plain_password = $validated['password'];
            }
            if (isset($validated['permissions'])) {
                $user->permissions = $validated['permissions'];
            }
            $user->save();
        }

        return $this->successResponse($staff, 'Staff member updated successfully');
    }

    /**
     * Delete a staff member from Admin Panel.
     */
    public function deleteStaff(Request $request, $id, $staffId): JsonResponse
    {
        $staff = Staff::withoutGlobalScope('shop')->where('shop_id', $id)->find($staffId);
        if (!$staff) {
            return $this->errorResponse('Staff record not found', 404);
        }

        $user = $staff->user ?: User::find($staff->user_id);
        if ($user) {
            $user->tokens()->delete();
            $user->delete();
        }

        $staffName = $staff->name;
        $staff->delete();

        AdminAuditLog::create([
            'admin_id'    => $request->user()->id,
            'action'      => 'ADMIN_DELETE_STAFF',
            'target_type' => 'Staff',
            'target_id'   => $staffId,
            'details'     => "Admin deleted staff {$staffName} (#{$staffId}) from shop #{$id}",
            'ip_address'  => $request->ip(),
        ]);

        return $this->successResponse(null, 'Staff member deleted successfully');
    }

    /**
     * Toggle staff status (active / inactive) from Admin Panel.
     */
    public function toggleStaffStatus(Request $request, $id, $staffId): JsonResponse
    {
        $staff = Staff::withoutGlobalScope('shop')->where('shop_id', $id)->find($staffId);
        if (!$staff) {
            return $this->errorResponse('Staff record not found', 404);
        }

        $staff->is_active = !$staff->is_active;
        $staff->save();

        $user = $staff->user ?: User::find($staff->user_id);
        if ($user && !$staff->is_active) {
            $user->tokens()->delete();
        }

        return $this->successResponse($staff, 'Staff status toggled successfully');
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
