<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\TechnicianResource;
use App\Models\Technician;
use App\Models\TechnicianPayment;
use App\Models\Repair;
use App\Models\User;
use App\Models\Subscription;
use App\Models\Plan;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class TechnicianController extends Controller
{
    /**
     * Check how many staff accounts are allowed on this shop's subscription.
     */
    protected function checkStaffLimit(int $shopId, ?int $ignoreUserId = null): array
    {
        $shop = \App\Models\Shop::with('latestSubscription.plan')->find($shopId);
        $maxStaff = $shop ? $shop->effective_max_staff : 0;
        $planName = 'Solo Owner';

        if ($shop && $shop->hasActiveCustomStaffOverride()) {
            $validUntil = $shop->custom_staff_valid_until ? " until " . \Illuminate\Support\Carbon::parse($shop->custom_staff_valid_until)->format('d M Y') : '';
            $planName = "Admin Custom Grant ({$maxStaff} Staff{$validUntil})";
        } elseif ($shop && $shop->latestSubscription) {
            $sub = $shop->latestSubscription;
            if ($sub->status === 'trial') {
                $planName = 'Free Trial';
            } elseif ($sub->plan) {
                $planName = $sub->plan->name;
            }
        }

        $query = User::where('shop_id', $shopId)
            ->where('role', '!=', 'owner');

        if ($ignoreUserId) {
            $query->where('id', '!=', $ignoreUserId);
        }

        $currentStaffCount = $query->count();

        if ($currentStaffCount >= $maxStaff) {
            $msg = $maxStaff === 0
                ? "Staff app login is not included in your current plan ({$planName}). Please upgrade your subscription or add a staff plan to enable staff logins."
                : "Staff login limit reached ({$currentStaffCount}/{$maxStaff}). Your current plan ({$planName}) allows maximum {$maxStaff} staff account(s). Please upgrade your subscription or add a staff plan to enable more staff logins.";

            return [
                'allowed' => false,
                'current_count' => $currentStaffCount,
                'max_allowed' => $maxStaff,
                'plan_name' => $planName,
                'message' => $msg,
            ];
        }

        return [
            'allowed' => true,
            'current_count' => $currentStaffCount,
            'max_allowed' => $maxStaff,
            'plan_name' => $planName,
        ];
    }

    /**
     * Display a listing of technicians for the shop.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        if (!$shopId) {
            return response()->json(['message' => 'No active shop associated with user.'], 400);
        }

        $query = Technician::forShop($shopId)->with('user');

        // Search by name, mobile, or specialization
        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('mobile', 'like', "%{$search}%")
                  ->orWhere('specialization', 'like', "%{$search}%");
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

        $technicians = $query->orderBy('name', 'asc')->get();

        // Calculate summary overview for shop
        $totalCount = Technician::forShop($shopId)->count();
        $activeCount = Technician::forShop($shopId)->where('is_active', true)->count();
        $inProgressJobs = Repair::forShop($shopId)->whereIn('repair_status', ['repairing', 'in_progress'])->whereNotNull('technician_id')->count();
        $pendingJobs = Repair::forShop($shopId)->whereIn('repair_status', ['received', 'diagnosing', 'waiting_customer', 'waiting_parts', 'pending_approval'])->whereNotNull('technician_id')->count();
        $completedJobs = Repair::forShop($shopId)->whereIn('repair_status', ['ready', 'delivered'])->whereNotNull('technician_id')->count();

        $shop = \App\Models\Shop::with('latestSubscription.plan')->find($shopId);
        $maxStaff = $shop ? $shop->effective_max_staff : 0;
        $staffLoginCount = User::where('shop_id', $shopId)->where('role', '!=', 'owner')->count();

        $staffDaysRemaining = 0;
        $staffValidUntil = null;
        if ($shop && $shop->custom_staff_valid_until) {
            $staffExp = \Carbon\Carbon::parse($shop->custom_staff_valid_until)->endOfDay();
            $staffValidUntil = $staffExp->format('d M Y');
            $staffDaysRemaining = max(0, (int) ceil(now()->diffInDays($staffExp, false)));
        }

        return response()->json([
            'success' => true,
            'message' => 'Technicians retrieved successfully.',
            'summary' => [
                'total_technicians'    => $totalCount,
                'active_technicians'   => $activeCount,
                'in_progress_jobs'     => $inProgressJobs,
                'pending_jobs'         => $pendingJobs,
                'completed_jobs'       => $completedJobs,
                'staff_accounts_used'  => $staffLoginCount,
                'max_staff_allowed'    => $maxStaff,
                'staff_valid_until'    => $staffValidUntil,
                'staff_days_remaining' => $staffDaysRemaining,
                'is_staff_expired'     => ($staffLoginCount > 0 && $maxStaff <= 0),
            ],
            'data' => TechnicianResource::collection($technicians),
        ]);
    }

    /**
     * Store a newly created technician.
     */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        if (!$shopId) {
            return response()->json(['message' => 'No active shop associated with user.'], 400);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'mobile' => 'nullable|string|max:20',
            'specialization' => 'nullable|string|max:255',
            'is_active' => 'nullable|boolean',
            'enable_login' => 'nullable|boolean',
            'password' => 'nullable|string|min:6',
            'permissions' => 'nullable|array',
        ]);

        $enableLogin = filter_var($validated['enable_login'] ?? false, FILTER_VALIDATE_BOOLEAN);
        $userAccountId = null;

        if ($enableLogin) {
            if (empty($validated['mobile'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Mobile number is required to enable staff login.',
                ], 422);
            }
            if (empty($validated['password'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Password is required to enable staff login.',
                ], 422);
            }

            // Check staff limit
            $limitCheck = $this->checkStaffLimit($shopId);
            if (!$limitCheck['allowed']) {
                return response()->json([
                    'success' => false,
                    'code' => 'STAFF_LIMIT_REACHED',
                    'error_code' => 'STAFF_LIMIT_REACHED',
                    'message' => $limitCheck['message'],
                    'current_count' => $limitCheck['current_count'],
                    'max_allowed' => $limitCheck['max_allowed'],
                    'plan_name' => $limitCheck['plan_name'],
                ], 403);
            }

            $cleanMobile = preg_replace('/\D/', '', $validated['mobile']);
            $existingUser = User::where('mobile', $cleanMobile)->orWhere('phone', $cleanMobile)->first();
            if ($existingUser) {
                return response()->json([
                    'success' => false,
                    'message' => 'This mobile number is already registered for an account.',
                ], 422);
            }

            $defaultPerms = [
                'repairs' => true,
                'sales' => false,
                'purchases' => false,
                'used_mobiles' => false,
            ];
            $perms = !empty($validated['permissions']) ? array_merge($defaultPerms, $validated['permissions']) : $defaultPerms;

            $newUser = User::create([
                'shop_id' => $shopId,
                'name' => $validated['name'],
                'mobile' => $cleanMobile,
                'phone' => $cleanMobile,
                'role' => 'technician',
                'password' => Hash::make($validated['password']),
                'plain_password' => $validated['password'],
                'permissions' => $perms,
            ]);

            $userAccountId = $newUser->id;
        }

        $technician = Technician::create([
            'shop_id' => $shopId,
            'user_id' => $userAccountId,
            'name' => $validated['name'],
            'mobile' => $validated['mobile'] ?? null,
            'specialization' => $validated['specialization'] ?? null,
            'is_active' => isset($validated['is_active']) ? (bool)$validated['is_active'] : true,
        ]);

        $technician->load('user');

        return response()->json([
            'success' => true,
            'message' => $enableLogin ? 'Staff account created with login access successfully.' : 'Technician created successfully.',
            'data' => new TechnicianResource($technician),
        ], 201);
    }

    /**
     * Display the specified technician details along with recent repair jobs.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        $technician = Technician::forShop($shopId)->with('user')->findOrFail($id);

        // Load recent assigned repair jobs with customer & device info
        $technician->load(['repairs' => function ($q) {
            $q->with(['customer', 'device'])->latest()->take(20);
        }]);

        return response()->json([
            'success' => true,
            'message' => 'Technician details retrieved successfully.',
            'data' => new TechnicianResource($technician),
        ]);
    }

    /**
     * Update the specified technician.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        $technician = Technician::forShop($shopId)->with('user')->findOrFail($id);

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'mobile' => 'nullable|string|max:20',
            'specialization' => 'nullable|string|max:255',
            'is_active' => 'sometimes|boolean',
            'enable_login' => 'nullable|boolean',
            'password' => 'nullable|string|min:6',
            'permissions' => 'nullable|array',
        ]);

        $cleanMobile = !empty($validated['mobile']) ? preg_replace('/\D/', '', $validated['mobile']) : null;

        // If enable_login is explicitly passed in request
        if ($request->has('enable_login')) {
            $enableLogin = filter_var($validated['enable_login'], FILTER_VALIDATE_BOOLEAN);

            if ($enableLogin) {
                if (empty($cleanMobile)) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Mobile number is required to enable staff login.',
                    ], 422);
                }

                if ($technician->user_id) {
                    // Update existing User account
                    $existingUser = User::find($technician->user_id);
                    if ($existingUser) {
                        // Check if mobile changed and taken
                        $conflict = User::where(function ($q) use ($cleanMobile) {
                            $q->where('mobile', $cleanMobile)->orWhere('phone', $cleanMobile);
                        })->where('id', '!=', $existingUser->id)->first();

                        if ($conflict) {
                            return response()->json([
                                'success' => false,
                                'message' => 'This mobile number is already taken by another user.',
                            ], 422);
                        }

                        $existingUser->name = $validated['name'] ?? $existingUser->name;
                        $existingUser->mobile = $cleanMobile;
                        $existingUser->phone = $cleanMobile;
                        if (!empty($validated['password'])) {
                            $existingUser->password = Hash::make($validated['password']);
                            $existingUser->plain_password = $validated['password'];
                        }
                        if (isset($validated['permissions'])) {
                            $existingUser->permissions = $validated['permissions'];
                        }
                        $existingUser->save();
                    }
                } else {
                    // Creating new login account for this technician -> check staff limit
                    $limitCheck = $this->checkStaffLimit($shopId);
                    if (!$limitCheck['allowed']) {
                        return response()->json([
                            'success' => false,
                            'code' => 'STAFF_LIMIT_REACHED',
                            'error_code' => 'STAFF_LIMIT_REACHED',
                            'message' => $limitCheck['message'],
                            'current_count' => $limitCheck['current_count'],
                            'max_allowed' => $limitCheck['max_allowed'],
                            'plan_name' => $limitCheck['plan_name'],
                        ], 403);
                    }

                    if (empty($validated['password'])) {
                        return response()->json([
                            'success' => false,
                            'message' => 'Password is required to set up staff login.',
                        ], 422);
                    }

                    $conflict = User::where('mobile', $cleanMobile)->orWhere('phone', $cleanMobile)->first();
                    if ($conflict) {
                        return response()->json([
                            'success' => false,
                            'message' => 'This mobile number is already registered for an account.',
                        ], 422);
                    }

                    $defaultPerms = [
                        'repairs' => true,
                        'sales' => false,
                        'purchases' => false,
                        'used_mobiles' => false,
                    ];
                    $perms = !empty($validated['permissions']) ? array_merge($defaultPerms, $validated['permissions']) : $defaultPerms;

                    $newUser = User::create([
                        'shop_id' => $shopId,
                        'name' => $validated['name'] ?? $technician->name,
                        'mobile' => $cleanMobile,
                        'phone' => $cleanMobile,
                        'role' => 'technician',
                        'password' => Hash::make($validated['password']),
                        'plain_password' => $validated['password'],
                        'permissions' => $perms,
                    ]);

                    $technician->user_id = $newUser->id;
                }
            } else {
                // Owner disabled login: delete user account
                if ($technician->user_id) {
                    User::where('id', $technician->user_id)->delete();
                    $technician->user_id = null;
                }
            }
        } elseif ($technician->user_id) {
            // enable_login not in request, but technician has user_id, update profile/permissions if passed
            $existingUser = User::find($technician->user_id);
            if ($existingUser) {
                if (isset($validated['name'])) $existingUser->name = $validated['name'];
                if ($cleanMobile) {
                    $existingUser->mobile = $cleanMobile;
                    $existingUser->phone = $cleanMobile;
                }
                if (!empty($validated['password'])) {
                    $existingUser->password = Hash::make($validated['password']);
                    $existingUser->plain_password = $validated['password'];
                }
                if (isset($validated['permissions'])) {
                    $existingUser->permissions = $validated['permissions'];
                }
                $existingUser->save();
            }
        }

        $technician->update([
            'name' => $validated['name'] ?? $technician->name,
            'mobile' => $validated['mobile'] ?? $technician->mobile,
            'specialization' => $validated['specialization'] ?? $technician->specialization,
            'is_active' => isset($validated['is_active']) ? (bool)$validated['is_active'] : $technician->is_active,
        ]);

        $technician->load('user');

        return response()->json([
            'success' => true,
            'message' => 'Technician updated successfully.',
            'data' => new TechnicianResource($technician),
        ]);
    }

    /**
     * Remove the specified technician.
     * Deletion is disallowed if active or pending repair jobs exist.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        $technician = Technician::forShop($shopId)->findOrFail($id);

        // Check if there are active or pending jobs assigned to this technician
        $activePendingCount = $technician->repairs()
            ->whereNotIn('repair_status', ['delivered', 'cancelled'])
            ->count();

        if ($activePendingCount > 0) {
            return response()->json([
                'success' => false,
                'message' => "Cannot delete technician with {$activePendingCount} active/pending repair job(s). Please reassign their jobs or deactivate the technician instead.",
            ], 422);
        }

        if ($technician->user_id) {
            User::where('id', $technician->user_id)->delete();
        }

        $technician->delete();

        return response()->json([
            'success' => true,
            'message' => 'Technician deleted successfully.',
        ]);
    }

    /**
     * Get the logged-in technician's own work and profit summary.
     * Supports month filter (e.g. '2026-11', 'this_month', 'all')
     * and status filter (e.g. 'all', 'completed', 'in_progress', 'pending', 'cancelled').
     */
    public function getMyWorkSummary(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        // Resolve technician record for this logged in user
        $technician = Technician::forShop($shopId)
            ->where(function ($q) use ($user) {
                $q->where('user_id', $user->id);
                if ($user->mobile) {
                    $q->orWhere('mobile', $user->mobile);
                }
                if ($user->phone) {
                    $q->orWhere('mobile', $user->phone);
                }
            })
            ->first();

        // If user is owner and passes technician_id, allow them to view that technician's summary
        if (!$technician && $user->role === 'owner' && $request->filled('technician_id')) {
            $technician = Technician::forShop($shopId)->find($request->technician_id);
        }

        if (!$technician) {
            return response()->json([
                'success' => false,
                'message' => 'Technician profile not found for this account.',
            ], 404);
        }

        $monthFilter = $request->input('month', 'this_month');
        $statusFilter = $request->input('status', 'all');

        // Base query for repairs assigned to this technician
        $baseRepairsQuery = Repair::forShop($shopId)->where('technician_id', $technician->id);

        // Filtered query for the specific month/status
        $filteredQuery = clone $baseRepairsQuery;

        if ($monthFilter === 'this_month') {
            $filteredQuery->whereYear('created_at', now()->year)
                          ->whereMonth('created_at', now()->month);
        } elseif ($monthFilter !== 'all' && preg_match('/^\d{4}-\d{2}$/', $monthFilter)) {
            [$year, $month] = explode('-', $monthFilter);
            $filteredQuery->whereYear('created_at', (int) $year)
                          ->whereMonth('created_at', (int) $month);
        }

        if ($statusFilter === 'completed') {
            $filteredQuery->whereIn('repair_status', ['ready', 'delivered', 'completed']);
        } elseif ($statusFilter === 'in_progress') {
            $filteredQuery->whereIn('repair_status', ['repairing', 'in_progress']);
        } elseif ($statusFilter === 'pending') {
            $filteredQuery->whereIn('repair_status', ['received', 'diagnosing', 'waiting_customer', 'waiting_parts', 'pending_approval']);
        } elseif ($statusFilter === 'cancelled') {
            $filteredQuery->whereIn('repair_status', ['cancelled', 'unrepairable', 'cannot_repair']);
        }

        // Fetch the filtered repairs list
        $repairs = (clone $filteredQuery)
            ->with(['customer', 'device'])
            ->orderByDesc('id')
            ->limit(100)
            ->get();

        // Calculate period metrics
        $periodEarnings = (float) (clone $filteredQuery)->sum('technician_earning');
        $periodJobsCount = (clone $filteredQuery)->count();
        $periodCompletedCount = (clone $filteredQuery)->whereIn('repair_status', ['ready', 'delivered', 'completed'])->count();
        $periodInProgressCount = (clone $filteredQuery)->whereIn('repair_status', ['repairing', 'in_progress'])->count();
        $periodPendingCount = (clone $filteredQuery)->whereIn('repair_status', ['received', 'diagnosing', 'waiting_customer', 'waiting_parts', 'pending_approval'])->count();

        // All-time financial totals for this technician
        $allTimeEarnings = (float) (clone $baseRepairsQuery)->sum('technician_earning');
        $allTimePaid = (float) TechnicianPayment::forShop($shopId)->where('technician_id', $technician->id)->sum('amount');
        $balanceDue = max(0.0, round($allTimeEarnings - $allTimePaid, 2));

        // Get available months where technician has repair jobs
        $distinctDates = (clone $baseRepairsQuery)
            ->selectRaw('DATE_FORMAT(created_at, "%Y-%m") as ym')
            ->distinct()
            ->orderByDesc('ym')
            ->pluck('ym')
            ->toArray();

        $currentYm = now()->format('Y-m');
        if (!in_array($currentYm, $distinctDates)) {
            array_unshift($distinctDates, $currentYm);
        }

        $availableMonths = array_map(function ($ym) {
            $dt = Carbon::createFromFormat('Y-m', $ym);
            return [
                'key' => $ym,
                'label' => $dt ? $dt->format('F Y') : $ym,
            ];
        }, $distinctDates);

        return response()->json([
            'success' => true,
            'message' => 'Technician work and profit summary retrieved successfully.',
            'data' => [
                'technician' => [
                    'id' => $technician->id,
                    'name' => $technician->name,
                    'mobile' => $technician->mobile,
                    'specialization' => $technician->specialization,
                    'is_active' => (bool) $technician->is_active,
                ],
                'filters' => [
                    'month' => $monthFilter,
                    'status' => $statusFilter,
                ],
                'metrics' => [
                    'period_earnings' => $periodEarnings,
                    'period_jobs' => $periodJobsCount,
                    'period_completed' => $periodCompletedCount,
                    'period_in_progress' => $periodInProgressCount,
                    'period_pending' => $periodPendingCount,
                    'all_time_earnings' => $allTimeEarnings,
                    'all_time_paid' => $allTimePaid,
                    'balance_due' => $balanceDue,
                ],
                'available_months' => $availableMonths,
                'repairs' => $repairs->map(function ($r) {
                    $devBrand = $r->device->brand ?? '';
                    $devModel = $r->device->model ?? '';
                    $devName = trim("{$devBrand} {$devModel}");
                    if (empty($devName)) $devName = 'Device';

                    return [
                        'id' => $r->id,
                        'job_number' => $r->job_number ?: ('JOB-' . $r->id),
                        'customer_name' => $r->customer ? $r->customer->name : ($r->customer_name ?: 'Walk-in Customer'),
                        'customer_mobile' => $r->customer ? ($r->customer->mobile ?: $r->customer->phone) : null,
                        'device_name' => $devName,
                        'problem_description' => $r->problem_description ?: 'No issue specified',
                        'repair_status' => $r->repair_status ?: 'received',
                        'technician_earning' => (float) ($r->technician_earning ?? 0),
                        'technician_payable' => (float) ($r->technician_payable ?? 0),
                        'final_cost' => (float) ($r->final_cost > 0 ? $r->final_cost : ($r->estimated_cost ?? 0)),
                        'created_at' => $r->created_at ? $r->created_at->toIso8601String() : null,
                        'completed_at' => $r->completed_at ? $r->completed_at->toIso8601String() : null,
                    ];
                }),
            ],
        ]);
    }
}
