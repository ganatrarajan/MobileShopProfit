<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\TechnicianResource;
use App\Models\Technician;
use App\Models\Repair;
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
                'total_technicians' => $totalCount,
                'active_technicians' => $activeCount,
                'in_progress_jobs' => $inProgressJobs,
                'pending_jobs' => $pendingJobs,
                'completed_jobs' => $completedJobs,
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
        ]);

        $technician = Technician::create([
            'shop_id' => $shopId,
            'name' => $validated['name'],
            'mobile' => $validated['mobile'] ?? null,
            'specialization' => $validated['specialization'] ?? null,
            'is_active' => isset($validated['is_active']) ? (bool)$validated['is_active'] : true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Technician created successfully.',
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

        $technician = Technician::forShop($shopId)->findOrFail($id);

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

        $technician = Technician::forShop($shopId)->findOrFail($id);

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'mobile' => 'nullable|string|max:20',
            'specialization' => 'nullable|string|max:255',
            'is_active' => 'sometimes|boolean',
        ]);

        $technician->update($validated);

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

        $technician->delete();

        return response()->json([
            'success' => true,
            'message' => 'Technician deleted successfully.',
        ]);
    }
}
