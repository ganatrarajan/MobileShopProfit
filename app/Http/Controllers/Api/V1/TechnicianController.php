<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\TechnicianResource;
use App\Models\Technician;
use App\Models\TechnicianPayment;
use App\Models\Repair;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TechnicianController extends Controller
{
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

        $query = Technician::forShop($shopId);

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

        return response()->json([
            'success' => true,
            'message' => 'Technicians retrieved successfully.',
            'summary' => [
                'total_technicians'  => $totalCount,
                'active_technicians' => $activeCount,
                'in_progress_jobs'   => $inProgressJobs,
                'pending_jobs'       => $pendingJobs,
                'completed_jobs'     => $completedJobs,
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
            'name'           => 'required|string|max:255',
            'mobile'         => 'nullable|string|max:20',
            'specialization' => 'nullable|string|max:255',
            'is_active'      => 'nullable|boolean',
        ]);

        $technician = Technician::create([
            'shop_id'        => $shopId,
            'name'           => $validated['name'],
            'mobile'         => $validated['mobile'] ?? null,
            'specialization' => $validated['specialization'] ?? null,
            'is_active'      => isset($validated['is_active']) ? (bool) $validated['is_active'] : true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Technician created successfully.',
            'data'    => new TechnicianResource($technician),
        ], 201);
    }

    /**
     * Display the specified technician details along with recent repair jobs.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        $technician = Technician::forShop($shopId)->findOrFail($id);

        $technician->load(['repairs' => function ($q) {
            $q->with(['customer', 'device'])->latest()->take(20);
        }]);

        return response()->json([
            'success' => true,
            'message' => 'Technician details retrieved successfully.',
            'data'    => new TechnicianResource($technician),
        ]);
    }

    /**
     * Update the specified technician.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        $technician = Technician::forShop($shopId)->findOrFail($id);

        $validated = $request->validate([
            'name'           => 'sometimes|required|string|max:255',
            'mobile'         => 'nullable|string|max:20',
            'specialization' => 'nullable|string|max:255',
            'is_active'      => 'sometimes|boolean',
        ]);

        $technician->update([
            'name'           => $validated['name'] ?? $technician->name,
            'mobile'         => $validated['mobile'] ?? $technician->mobile,
            'specialization' => $validated['specialization'] ?? $technician->specialization,
            'is_active'      => isset($validated['is_active']) ? (bool) $validated['is_active'] : $technician->is_active,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Technician updated successfully.',
            'data'    => new TechnicianResource($technician),
        ]);
    }

    /**
     * Remove the specified technician.
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

        $technician->delete();

        return response()->json([
            'success' => true,
            'message' => 'Technician deleted successfully.',
        ]);
    }

    /**
     * Fetch work summary for the authenticated user/staff/technician.
     */
    public function getMyWorkSummary(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        if (!$shopId) {
            return response()->json([
                'success' => false,
                'message' => 'No active shop associated with user.',
            ], 400);
        }

        $technician = null;

        // 1. Explicit technician_id in query if provided
        if ($request->filled('technician_id')) {
            $technician = Technician::forShop($shopId)->find($request->input('technician_id'));
        }

        // 2. Match by user_id
        if (!$technician) {
            $technician = Technician::forShop($shopId)->where('user_id', $user->id)->first();
        }

        // 3. Match by mobile
        if (!$technician && !empty($user->mobile)) {
            $technician = Technician::forShop($shopId)->where('mobile', $user->mobile)->first();
        }

        // 4. Match by name
        if (!$technician && !empty($user->name)) {
            $technician = Technician::forShop($shopId)->where('name', $user->name)->first();
        }

        if ($technician) {
            return $this->getWorkSummary($request, $technician->id);
        }

        // If no technician record exists (e.g. staff member without repair technician profile)
        $rawMonth = $request->input('month', 'this_month');
        $statusFilter = $request->input('status', 'all');
        $currentYm = now()->format('Y-m');

        return response()->json([
            'success' => true,
            'message' => 'Work summary retrieved successfully.',
            'data'    => [
                'technician' => [
                    'id'             => 0,
                    'name'           => $user->name ?? 'Staff Member',
                    'mobile'         => $user->mobile ?? '',
                    'specialization' => $user->designation ?? 'Staff Member',
                    'is_active'      => true,
                ],
                'filters' => [
                    'month'  => $rawMonth,
                    'status' => $statusFilter,
                ],
                'metrics' => [
                    'period_earnings'    => 0.0,
                    'period_jobs'        => 0,
                    'period_completed'   => 0,
                    'period_in_progress' => 0,
                    'period_pending'     => 0,
                    'all_time_earnings'  => 0.0,
                    'all_time_paid'      => 0.0,
                    'balance_due'        => 0.0,
                ],
                'available_months' => [
                    [
                        'key'   => $currentYm,
                        'label' => now()->format('F Y'),
                    ],
                ],
                'repairs' => [],
            ],
        ]);
    }

    /**
     * Fetch work and earnings summary for a specific technician.
     */
    public function getWorkSummary(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        $technician = Technician::forShop($shopId)->findOrFail($id);

        $rawMonth = $request->input('month', 'this_month');
        $statusFilter = $request->input('status', 'all');

        $baseRepairsQuery = Repair::forShop($shopId)->where('technician_id', $technician->id);

        $filteredQuery = clone $baseRepairsQuery;

        if ($rawMonth === 'this_month') {
            $monthFilter = now()->format('Y-m');
            $filteredQuery->where('created_at', 'like', "{$monthFilter}%");
        } elseif (!empty($rawMonth) && $rawMonth !== 'all') {
            $filteredQuery->where('created_at', 'like', "{$rawMonth}%");
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

        $repairs = (clone $filteredQuery)
            ->with(['customer', 'device'])
            ->orderByDesc('id')
            ->limit(100)
            ->get();

        $periodEarnings = (float) (clone $filteredQuery)->sum('technician_earning');
        $periodJobsCount = (clone $filteredQuery)->count();
        $periodCompletedCount = (clone $filteredQuery)->whereIn('repair_status', ['ready', 'delivered', 'completed'])->count();
        $periodInProgressCount = (clone $filteredQuery)->whereIn('repair_status', ['repairing', 'in_progress'])->count();
        $periodPendingCount = (clone $filteredQuery)->whereIn('repair_status', ['received', 'diagnosing', 'waiting_customer', 'waiting_parts', 'pending_approval'])->count();

        $allTimeEarnings = (float) (clone $baseRepairsQuery)->sum('technician_earning');
        $allTimePaid = (float) TechnicianPayment::forShop($shopId)->where('technician_id', $technician->id)->sum('amount');
        $balanceDue = max(0.0, round($allTimeEarnings - $allTimePaid, 2));

        $distinctDates = (clone $baseRepairsQuery)
            ->selectRaw('DATE_FORMAT(created_at, "%Y-%m") as ym')
            ->distinct()
            ->orderByDesc('ym')
            ->pluck('ym')
            ->toArray();

        $distinctDates = array_values(array_filter($distinctDates));

        $currentYm = now()->format('Y-m');
        if (!in_array($currentYm, $distinctDates)) {
            array_unshift($distinctDates, $currentYm);
        }

        $availableMonths = array_map(function ($ym) {
            try {
                $dt = Carbon::parse($ym . '-01');
                return [
                    'key'   => $ym,
                    'label' => $dt->format('F Y'),
                ];
            } catch (\Exception $e) {
                return [
                    'key'   => $ym,
                    'label' => $ym,
                ];
            }
        }, $distinctDates);

        return response()->json([
            'success' => true,
            'message' => 'Technician work and profit summary retrieved successfully.',
            'data'    => [
                'technician' => [
                    'id'             => $technician->id,
                    'name'           => $technician->name,
                    'mobile'         => $technician->mobile,
                    'specialization' => $technician->specialization,
                    'is_active'      => (bool) $technician->is_active,
                ],
                'filters' => [
                    'month'  => $rawMonth,
                    'status' => $statusFilter,
                ],
                'metrics' => [
                    'period_earnings'       => $periodEarnings,
                    'period_jobs'           => $periodJobsCount,
                    'period_completed'      => $periodCompletedCount,
                    'period_in_progress'    => $periodInProgressCount,
                    'period_pending'        => $periodPendingCount,
                    'all_time_earnings'     => $allTimeEarnings,
                    'all_time_paid'         => $allTimePaid,
                    'balance_due'           => $balanceDue,
                ],
                'available_months' => $availableMonths,
                'repairs'          => $repairs->map(function ($r) {
                    $devBrand = $r->device->brand ?? '';
                    $devModel = $r->device->model ?? '';
                    $devName = trim("{$devBrand} {$devModel}");
                    if (empty($devName)) $devName = 'Device';

                    return [
                        'id'                  => $r->id,
                        'job_number'          => $r->job_number ?: ('JOB-' . $r->id),
                        'customer_name'       => $r->customer ? $r->customer->name : ($r->customer_name ?: 'Walk-in Customer'),
                        'customer_mobile'     => $r->customer ? ($r->customer->mobile ?: $r->customer->phone) : null,
                        'device_name'         => $devName,
                        'problem_description' => $r->problem_description ?: 'No issue specified',
                        'repair_status'       => $r->repair_status ?: 'received',
                        'technician_earning'  => (float) ($r->technician_earning ?? 0),
                        'technician_payable'  => (float) ($r->technician_payable ?? 0),
                        'final_cost'          => (float) ($r->final_cost > 0 ? $r->final_cost : ($r->estimated_cost ?? 0)),
                        'created_at'          => $r->created_at ? $r->created_at->toIso8601String() : null,
                        'completed_at'        => $r->completed_at ? $r->completed_at->toIso8601String() : null,
                    ];
                }),
            ],
        ]);
    }
}
