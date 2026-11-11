<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Staff;
use App\Models\User;
use App\Models\Shop;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class StaffController extends Controller
{
    /**
     * Check how many staff accounts are allowed on this shop's subscription.
     */
    protected function checkStaffLimit(int $shopId, ?int $ignoreStaffId = null): array
    {
        $shop = Shop::with('latestSubscription.plan')->find($shopId);
        $maxStaff = $shop ? $shop->effective_max_staff : 0;
        $planName = 'Solo Owner';

        if ($shop && $shop->hasActiveCustomStaffOverride()) {
            $validUntil = $shop->custom_staff_valid_until ? " until " . Carbon::parse($shop->custom_staff_valid_until)->format('d M Y') : '';
            $planName = "Staff Addon ({$maxStaff} Staff{$validUntil})";
        } elseif ($shop && $shop->latestSubscription) {
            $sub = $shop->latestSubscription;
            if ($sub->status === 'trial') {
                $planName = 'Free Trial';
            } elseif ($sub->plan) {
                $planName = $sub->plan->name;
            }
        }

        $query = Staff::forShop($shopId)
            ->where('is_active', true)
            ->whereNotNull('user_id');

        if ($ignoreStaffId) {
            $query->where('id', '!=', $ignoreStaffId);
        }

        $currentStaffCount = $query->count();

        if ($currentStaffCount >= $maxStaff) {
            $msg = $maxStaff === 0
                ? "Staff app login is not active for your shop. Please add staff logins (@ ₹2/day) to enable staff accounts."
                : "Staff login limit reached ({$currentStaffCount}/{$maxStaff} active). Your shop currently allows maximum {$maxStaff} active staff login(s). Please deactivate another staff member's login or add more staff logins (@ ₹2/day) to activate login for this staff.";

            return [
                'allowed'       => false,
                'current_count' => $currentStaffCount,
                'max_allowed'   => $maxStaff,
                'plan_name'     => $planName,
                'message'       => $msg,
            ];
        }

        return [
            'allowed'       => true,
            'current_count' => $currentStaffCount,
            'max_allowed'   => $maxStaff,
            'plan_name'     => $planName,
        ];
    }

    /**
     * Display a listing of staff for the shop.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        if (!$shopId) {
            return response()->json(['success' => false, 'message' => 'No active shop associated with user.'], 400);
        }

        $query = Staff::forShop($shopId)->with('user');

        // Search by name, mobile, designation
        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('mobile', 'like', "%{$search}%")
                  ->orWhere('designation', 'like', "%{$search}%");
            });
        }

        // Filter by status (active / inactive / all)
        if ($request->filled('status') && $request->input('status') !== 'all') {
            $status = $request->input('status');
            if ($status === 'active') {
                $query->where('is_active', true);
            } elseif ($status === 'inactive') {
                $query->where('is_active', false);
            }
        }

        $staffList = $query->orderBy('name', 'asc')->get();

        $shop = Shop::with('latestSubscription.plan')->find($shopId);
        $maxStaff = $shop ? $shop->effective_max_staff : 0;
        $staffLoginCount = Staff::forShop($shopId)->where('is_active', true)->whereNotNull('user_id')->count();

        $staffDaysRemaining = 0;
        $staffValidUntil = null;
        $isStaffExpired = false;

        if ($shop) {
            $now = Carbon::now();
            $targetExp = null;
            if ($shop->custom_staff_valid_until) {
                $targetExp = Carbon::parse($shop->custom_staff_valid_until)->endOfDay();
            } elseif ($shop->latestSubscription && $shop->latestSubscription->expires_at) {
                $targetExp = Carbon::parse($shop->latestSubscription->expires_at)->endOfDay();
            }

            if ($targetExp) {
                $staffValidUntil = $targetExp->format('d M Y');
                $staffDaysRemaining = max(0, (int) ceil($now->diffInDays($targetExp, false)));
                if ($now->greaterThan($targetExp) || $maxStaff <= 0) {
                    $isStaffExpired = true;
                }
            } else {
                $isStaffExpired = ($maxStaff <= 0);
            }
        }

        $isOwner = ($user->role === 'owner' || empty($user->role));

        $data = $staffList->map(function ($s) use ($isOwner) {
            return [
                'id'             => $s->id,
                'shop_id'        => $s->shop_id,
                'user_id'        => $s->user_id,
                'name'           => $s->name,
                'mobile'         => $s->mobile,
                'email'          => $s->email,
                'designation'    => $s->designation,
                'salary'         => $s->salary ? (float) $s->salary : null,
                'joining_date'   => $s->joining_date ? $s->joining_date->format('Y-m-d') : null,
                'address'        => $s->address,
                'notes'          => $s->notes,
                'is_active'      => (bool) $s->is_active,
                'login_password' => $isOwner ? $s->user?->plain_password : null,
                'permissions'    => $s->user?->permissions ?? [
                    'sales'        => true,
                    'repairs'      => true,
                    'purchases'    => false,
                    'expenses'     => false,
                    'used_mobiles' => false,
                ],
                'created_at'     => $s->created_at?->toIso8601String(),
                'updated_at'     => $s->updated_at?->toIso8601String(),
            ];
        });

        return response()->json([
            'success' => true,
            'data'    => $data,
            'summary' => [
                'total_staff'          => Staff::forShop($shopId)->count(),
                'active_staff'         => Staff::forShop($shopId)->where('is_active', true)->count(),
                'staff_accounts_used'  => $staffLoginCount,
                'max_staff_allowed'    => $maxStaff,
                'staff_valid_until'    => $staffValidUntil,
                'staff_days_remaining' => $staffDaysRemaining,
                'is_staff_expired'     => $isStaffExpired,
                'staff_price_per_day'  => $shop ? $shop->getEffectiveStaffPricePerDay() : 2.00,
            ],
        ]);
    }

    /**
     * Store a newly created staff member with app login credentials.
     */
    public function store(Request $request): JsonResponse
    {
        $owner = $request->user();
        $shopId = $owner->shop_id ?? $owner->shop?->id;

        if (!$shopId) {
            return response()->json(['success' => false, 'message' => 'No active shop associated with user.'], 400);
        }

        $isActive = filter_var($request->input('is_active', true), FILTER_VALIDATE_BOOLEAN);

        // 1. Check shop staff subscription limit ONLY if creating an ACTIVE login
        if ($isActive) {
            $limitCheck = $this->checkStaffLimit($shopId);
            if (!$limitCheck['allowed']) {
                return response()->json([
                    'success' => false,
                    'message' => $limitCheck['message'],
                    'code'    => 'STAFF_LIMIT_REACHED',
                    'data'    => [
                        'limit_reached'       => true,
                        'current_staff_count' => $limitCheck['current_count'],
                        'max_staff_allowed'   => $limitCheck['max_allowed'],
                        'plan_name'           => $limitCheck['plan_name'],
                    ],
                ], 422);
            }
        }

        // 2. Validate request
        $validated = $request->validate([
            'name'         => 'required|string|max:100',
            'mobile'       => 'required|string|max:20',
            'email'        => 'nullable|email|max:100',
            'password'     => $isActive ? 'required|string|min:4|max:50' : 'nullable|string|min:4|max:50',
            'designation'  => 'nullable|string|max:100',
            'salary'       => 'nullable|numeric|min:0',
            'joining_date' => 'nullable|date',
            'address'      => 'nullable|string|max:255',
            'notes'        => 'nullable|string|max:500',
            'is_active'    => 'boolean',
            'permissions'  => 'nullable|array',
        ]);

        $mobile = trim($validated['mobile']);

        // Check if user already exists with this mobile or email
        $existingUserQuery = User::where(function ($q) use ($mobile, $validated) {
            $q->where('mobile', $mobile)
              ->orWhere('phone', $mobile);
            if (!empty($validated['email'])) {
                $q->orWhere('email', $validated['email']);
            }
        });

        if ($existingUserQuery->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'A user with this mobile number or email already exists in the system.',
            ], 422);
        }

        $plainPassword = !empty($validated['password']) ? $validated['password'] : '123456';

        $defaultPermissions = [
            'sales'        => true,
            'repairs'      => true,
            'purchases'    => false,
            'expenses'     => false,
            'used_mobiles' => false,
        ];
        $permissions = isset($validated['permissions']) && is_array($validated['permissions'])
            ? array_merge($defaultPermissions, $validated['permissions'])
            : $defaultPermissions;

        $staff = null;
        $user = null;

        DB::transaction(function () use ($shopId, $validated, $mobile, $plainPassword, $permissions, &$staff, &$user) {
            $email = !empty($validated['email'])
                ? trim($validated['email'])
                : "staff_{$mobile}_{$shopId}@myrepairhub.local";

            $user = User::create([
                'shop_id'        => $shopId,
                'name'           => $validated['name'],
                'mobile'         => $mobile,
                'phone'          => $mobile,
                'email'          => $email,
                'password'       => Hash::make($plainPassword),
                'plain_password' => $plainPassword,
                'role'           => 'staff',
                'permissions'    => $permissions,
            ]);

            $staff = Staff::create([
                'shop_id'      => $shopId,
                'user_id'      => $user->id,
                'name'         => $validated['name'],
                'mobile'       => $mobile,
                'email'        => !empty($validated['email']) ? trim($validated['email']) : null,
                'designation'  => $validated['designation'] ?? 'Staff',
                'salary'       => $validated['salary'] ?? null,
                'joining_date' => $validated['joining_date'] ?? null,
                'address'      => $validated['address'] ?? null,
                'notes'        => $validated['notes'] ?? null,
                'is_active'    => $validated['is_active'] ?? true,
            ]);
        });

        return response()->json([
            'success' => true,
            'message' => 'Staff member created successfully with login credentials.',
            'data'    => [
                'id'             => $staff->id,
                'shop_id'        => $staff->shop_id,
                'user_id'        => $staff->user_id,
                'name'           => $staff->name,
                'mobile'         => $staff->mobile,
                'email'          => $staff->email,
                'designation'    => $staff->designation,
                'salary'         => $staff->salary ? (float) $staff->salary : null,
                'joining_date'   => $staff->joining_date ? $staff->joining_date->format('Y-m-d') : null,
                'address'        => $staff->address,
                'notes'          => $staff->notes,
                'is_active'      => (bool) $staff->is_active,
                'login_password' => $plainPassword,
                'permissions'    => $permissions,
                'created_at'     => $staff->created_at?->toIso8601String(),
                'updated_at'     => $staff->updated_at?->toIso8601String(),
            ],
        ], 201);
    }

    /**
     * Display the specified staff member.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        $staff = Staff::forShop($shopId)->with('user')->find($id);
        if (!$staff) {
            return response()->json(['success' => false, 'message' => 'Staff member not found.'], 404);
        }

        $isOwner = ($user->role === 'owner' || empty($user->role));

        return response()->json([
            'success' => true,
            'data'    => [
                'id'             => $staff->id,
                'shop_id'        => $staff->shop_id,
                'user_id'        => $staff->user_id,
                'name'           => $staff->name,
                'mobile'         => $staff->mobile,
                'email'          => $staff->email,
                'designation'    => $staff->designation,
                'salary'         => $staff->salary ? (float) $staff->salary : null,
                'joining_date'   => $staff->joining_date ? $staff->joining_date->format('Y-m-d') : null,
                'address'        => $staff->address,
                'notes'          => $staff->notes,
                'is_active'      => (bool) $staff->is_active,
                'login_password' => $isOwner ? $staff->user?->plain_password : null,
                'permissions'    => $staff->user?->permissions ?? [],
                'created_at'     => $staff->created_at?->toIso8601String(),
                'updated_at'     => $staff->updated_at?->toIso8601String(),
            ],
        ]);
    }

    /**
     * Update the specified staff member.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $owner = $request->user();
        $shopId = $owner->shop_id ?? $owner->shop?->id;

        $staff = Staff::forShop($shopId)->with('user')->find($id);
        if (!$staff) {
            return response()->json(['success' => false, 'message' => 'Staff member not found.'], 404);
        }

        $validated = $request->validate([
            'name'         => 'required|string|max:100',
            'mobile'       => 'required|string|max:20',
            'email'        => 'nullable|email|max:100',
            'password'     => 'nullable|string|min:4|max:50',
            'designation'  => 'nullable|string|max:100',
            'salary'       => 'nullable|numeric|min:0',
            'joining_date' => 'nullable|date',
            'address'      => 'nullable|string|max:255',
            'notes'        => 'nullable|string|max:500',
            'is_active'    => 'boolean',
            'permissions'  => 'nullable|array',
        ]);

        $mobile = trim($validated['mobile']);

        // Check duplicate mobile for other users
        $existingUser = User::where(function ($q) use ($mobile, $validated) {
            $q->where('mobile', $mobile)
              ->orWhere('phone', $mobile);
            if (!empty($validated['email'])) {
                $q->orWhere('email', $validated['email']);
            }
        })
        ->where('id', '!=', $staff->user_id)
        ->first();

        if ($existingUser) {
            return response()->json([
                'success' => false,
                'message' => 'Another user with this mobile number or email already exists.',
            ], 422);
        }

        $wantsActive = isset($validated['is_active']) ? (bool) $validated['is_active'] : (bool) $staff->is_active;

        // If toggling from inactive to active, check quota!
        if ($wantsActive && !$staff->is_active) {
            $limitCheck = $this->checkStaffLimit($shopId, $staff->id);
            if (!$limitCheck['allowed']) {
                return response()->json([
                    'success' => false,
                    'message' => $limitCheck['message'],
                    'code'    => 'STAFF_LIMIT_REACHED',
                    'data'    => [
                        'limit_reached'       => true,
                        'current_staff_count' => $limitCheck['current_count'],
                        'max_staff_allowed'   => $limitCheck['max_allowed'],
                        'plan_name'           => $limitCheck['plan_name'],
                    ],
                ], 422);
            }
        }

        DB::transaction(function () use ($staff, $validated, $mobile) {
            $staff->name = $validated['name'];
            $staff->mobile = $mobile;
            $staff->email = !empty($validated['email']) ? trim($validated['email']) : null;
            $staff->designation = $validated['designation'] ?? $staff->designation;
            $staff->salary = array_key_exists('salary', $validated) ? $validated['salary'] : $staff->salary;
            $staff->joining_date = array_key_exists('joining_date', $validated) ? $validated['joining_date'] : $staff->joining_date;
            $staff->address = array_key_exists('address', $validated) ? $validated['address'] : $staff->address;
            $staff->notes = array_key_exists('notes', $validated) ? $validated['notes'] : $staff->notes;
            if (isset($validated['is_active'])) {
                $staff->is_active = (bool) $validated['is_active'];
            }
            $staff->save();

            // Update user credentials & permissions
            if ($staff->user) {
                $user = $staff->user;
                $user->name = $validated['name'];
                $user->mobile = $mobile;
                $user->phone = $mobile;
                if (!empty($validated['email'])) {
                    $user->email = trim($validated['email']);
                }

                if (!empty($validated['password'])) {
                    $user->password = Hash::make($validated['password']);
                    $user->plain_password = $validated['password'];
                }

                if (isset($validated['permissions']) && is_array($validated['permissions'])) {
                    $user->permissions = $validated['permissions'];
                }

                $user->save();
            } elseif (!empty($validated['password'])) {
                // If user didn't exist previously, create user
                $user = User::create([
                    'shop_id'        => $staff->shop_id,
                    'name'           => $validated['name'],
                    'mobile'         => $mobile,
                    'phone'          => $mobile,
                    'email'          => !empty($validated['email']) ? trim($validated['email']) : "staff_{$mobile}_{$staff->shop_id}@myrepairhub.local",
                    'password'       => Hash::make($validated['password']),
                    'plain_password' => $validated['password'],
                    'role'           => 'staff',
                    'permissions'    => $validated['permissions'] ?? [],
                ]);
                $staff->user_id = $user->id;
                $staff->save();
            }
        });

        $staff->refresh()->load('user');

        return response()->json([
            'success' => true,
            'message' => 'Staff member updated successfully.',
            'data'    => [
                'id'             => $staff->id,
                'shop_id'        => $staff->shop_id,
                'user_id'        => $staff->user_id,
                'name'           => $staff->name,
                'mobile'         => $staff->mobile,
                'email'          => $staff->email,
                'designation'    => $staff->designation,
                'salary'         => $staff->salary ? (float) $staff->salary : null,
                'joining_date'   => $staff->joining_date ? $staff->joining_date->format('Y-m-d') : null,
                'address'        => $staff->address,
                'notes'          => $staff->notes,
                'is_active'      => (bool) $staff->is_active,
                'login_password' => $staff->user?->plain_password,
                'permissions'    => $staff->user?->permissions ?? [],
                'created_at'     => $staff->created_at?->toIso8601String(),
                'updated_at'     => $staff->updated_at?->toIso8601String(),
            ],
        ]);
    }

    /**
     * Remove the specified staff member.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $owner = $request->user();
        $shopId = $owner->shop_id ?? $owner->shop?->id;

        $staff = Staff::forShop($shopId)->with('user')->find($id);
        if (!$staff) {
            return response()->json(['success' => false, 'message' => 'Staff member not found.'], 404);
        }

        DB::transaction(function () use ($staff) {
            if ($staff->user) {
                // Delete auth tokens immediately to log them out
                $staff->user->tokens()->delete();
                $staff->user->delete();
            }
            $staff->delete();
        });

        return response()->json([
            'success' => true,
            'message' => 'Staff member and associated login deleted successfully.',
        ]);
    }

    /**
     * Toggle the active status of a staff member directly from the list.
     */
    public function toggleStatus(Request $request, int $id): JsonResponse
    {
        $owner = $request->user();
        $shopId = $owner->shop_id ?? $owner->shop?->id;

        $staff = Staff::forShop($shopId)->with('user')->find($id);
        if (!$staff) {
            return response()->json(['success' => false, 'message' => 'Staff member not found.'], 404);
        }

        $wantsActive = !$staff->is_active;

        if ($wantsActive) {
            $limitCheck = $this->checkStaffLimit($shopId, $staff->id);
            if (!$limitCheck['allowed']) {
                return response()->json([
                    'success' => false,
                    'message' => $limitCheck['message'],
                    'code'    => 'STAFF_LIMIT_REACHED',
                    'data'    => [
                        'limit_reached'       => true,
                        'current_staff_count' => $limitCheck['current_count'],
                        'max_staff_allowed'   => $limitCheck['max_allowed'],
                        'plan_name'           => $limitCheck['plan_name'],
                    ],
                ], 422);
            }
        }

        DB::transaction(function () use ($staff, $wantsActive) {
            $staff->is_active = $wantsActive;
            $staff->save();

            if ($staff->user) {
                // If deactivated, revoke all active sessions immediately
                if (!$wantsActive) {
                    $staff->user->tokens()->delete();
                }
            }
        });

        $statusText = $wantsActive ? 'activated' : 'deactivated';

        return response()->json([
            'success' => true,
            'message' => "Staff login for {$staff->name} {$statusText} successfully.",
            'data'    => [
                'id'        => $staff->id,
                'name'      => $staff->name,
                'is_active' => (bool) $staff->is_active,
            ],
        ]);
    }
}

