<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreWarrantyRequest;
use App\Http\Requests\UpdateWarrantyRequest;
use App\Http\Resources\WarrantyResource;
use App\Models\Customer;
use App\Models\Device;
use App\Models\Repair;
use App\Models\Sale;
use App\Models\Warranty;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class WarrantyController extends Controller
{
    /**
     * Display paginated listing of warranties for the authenticated shop.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user->shop_id) {
            return response()->json([
                'success' => false,
                'message' => 'User is not associated with any shop.',
            ], 403);
        }

        $query = Warranty::withTrashed()->forShop($user->shop_id)
            ->with(['customer', 'device', 'sale', 'repair', 'creator'])
            ->withCount('claims');

        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('warranty_number', 'like', "%{$search}%")
                  ->orWhere('warranty_terms', 'like', "%{$search}%")
                  ->orWhereHas('customer', function ($cq) use ($search) {
                      $cq->where('name', 'like', "%{$search}%")
                         ->orWhere('mobile', 'like', "%{$search}%");
                  })
                  ->orWhereHas('device', function ($dq) use ($search) {
                      $dq->where('model', 'like', "%{$search}%")
                         ->orWhere('brand', 'like', "%{$search}%")
                         ->orWhere('imei_1', 'like', "%{$search}%")
                         ->orWhere('imei_2', 'like', "%{$search}%");
                  });
            });
        }

        if ($request->filled('warranty_type') && $request->input('warranty_type') !== 'all') {
            $query->where('warranty_type', $request->input('warranty_type'));
        }

        if ($request->filled('customer_id')) {
            $query->where('customer_id', $request->input('customer_id'));
        }

        if ($request->filled('device_id')) {
            $query->where('device_id', $request->input('device_id'));
        }

        $warranties = $query->orderBy('id', 'desc')->get();

        // Dynamic status filter in PHP since status is dynamically calculated
        if ($request->filled('status') && $request->input('status') !== 'all') {
            $statusFilter = $request->input('status');
            $warranties = $warranties->filter(function ($w) use ($statusFilter) {
                return $w->computed_status === $statusFilter;
            })->values();
        }

        // Manual pagination if filtered or standard paginator
        $page = (int) $request->input('page', 1);
        $perPage = (int) $request->input('per_page', 15);
        $total = $warranties->count();
        $pagedData = $warranties->slice(($page - 1) * $perPage, $perPage)->values();

        return response()->json([
            'success' => true,
            'data' => WarrantyResource::collection($pagedData),
            'meta' => [
                'current_page' => $page,
                'last_page' => max(1, (int) ceil($total / $perPage)),
                'per_page' => $perPage,
                'total' => $total,
            ],
        ]);
    }

    /**
     * Store a new warranty.
     */
    public function store(StoreWarrantyRequest $request): JsonResponse
    {
        $user = $request->user();
        if (!$user->shop_id) {
            return response()->json([
                'success' => false,
                'message' => 'User is not associated with any shop.',
            ], 403);
        }

        $validated = $request->validated();

        // Validate customer & device ownership
        $customer = Customer::where('shop_id', $user->shop_id)->find($validated['customer_id']);
        if (!$customer) {
            return response()->json([
                'success' => false,
                'message' => 'Selected customer does not belong to your shop.',
            ], 422);
        }

        $device = Device::where('shop_id', $user->shop_id)
            ->where('customer_id', $customer->id)
            ->find($validated['device_id']);

        if (!$device) {
            return response()->json([
                'success' => false,
                'message' => 'Selected device does not belong to this customer or shop.',
            ], 422);
        }

        if (!empty($validated['sale_id'])) {
            $sale = Sale::where('shop_id', $user->shop_id)->find($validated['sale_id']);
            if (!$sale) {
                return response()->json([
                    'success' => false,
                    'message' => 'Selected sale invoice does not belong to your shop.',
                ], 422);
            }
        }

        if (!empty($validated['repair_id'])) {
            $repair = Repair::where('shop_id', $user->shop_id)->find($validated['repair_id']);
            if (!$repair) {
                return response()->json([
                    'success' => false,
                    'message' => 'Selected repair job card does not belong to your shop.',
                ], 422);
            }
        }

        try {
            $warranty = DB::transaction(function () use ($user, $validated) {
                $count = Warranty::withTrashed()->forShop($user->shop_id)->lockForUpdate()->count();
                $warrantyNumber = 'WAR-' . str_pad($count + 1, 6, '0', STR_PAD_LEFT);

                $startDate = isset($validated['warranty_start_date'])
                    ? Carbon::parse($validated['warranty_start_date'])
                    : Carbon::today();

                $durationDays = (int) $validated['duration_days'];
                $endDate = (clone $startDate)->addDays($durationDays);

                $warranty = Warranty::create([
                    'shop_id' => $user->shop_id,
                    'customer_id' => $validated['customer_id'],
                    'device_id' => $validated['device_id'],
                    'sale_id' => $validated['sale_id'] ?? null,
                    'repair_id' => $validated['repair_id'] ?? null,
                    'warranty_number' => $warrantyNumber,
                    'warranty_type' => $validated['warranty_type'],
                    'warranty_start_date' => $startDate->toDateString(),
                    'warranty_end_date' => $endDate->toDateString(),
                    'duration_days' => $durationDays,
                    'warranty_terms' => $validated['warranty_terms'] ?? null,
                    'status' => 'active',
                    'notes' => $validated['notes'] ?? null,
                    'created_by' => $user->id,
                ]);

                return $warranty->load(['customer', 'device', 'sale', 'repair', 'creator']);
            });

            return response()->json([
                'success' => true,
                'message' => 'Warranty created successfully.',
                'data' => new WarrantyResource($warranty),
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to create warranty: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Display details of a specific warranty.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $warranty = Warranty::withTrashed()->forShop($user->shop_id)
            ->with(['customer', 'device', 'sale', 'repair', 'claims.creator', 'creator'])
            ->find($id);

        if (!$warranty) {
            return response()->json([
                'success' => false,
                'message' => 'Warranty record not found or unauthorized.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => new WarrantyResource($warranty),
        ]);
    }

    /**
     * Update warranty details.
     */
    public function update(UpdateWarrantyRequest $request, int $id): JsonResponse
    {
        $user = $request->user();
        $warranty = Warranty::withTrashed()->forShop($user->shop_id)->find($id);

        if (!$warranty) {
            return response()->json([
                'success' => false,
                'message' => 'Warranty record not found or unauthorized.',
            ], 404);
        }

        $validated = $request->validated();
        $updateData = [];

        if (isset($validated['warranty_terms'])) {
            $updateData['warranty_terms'] = $validated['warranty_terms'];
        }

        if (isset($validated['status'])) {
            $updateData['status'] = $validated['status'];
        }

        if (isset($validated['notes'])) {
            $updateData['notes'] = $validated['notes'];
        }

        $startDate = isset($validated['warranty_start_date'])
            ? Carbon::parse($validated['warranty_start_date'])
            : Carbon::parse($warranty->warranty_start_date);

        $durationDays = isset($validated['duration_days'])
            ? (int) $validated['duration_days']
            : (int) $warranty->duration_days;

        if (isset($validated['warranty_start_date']) || isset($validated['duration_days'])) {
            $updateData['warranty_start_date'] = $startDate->toDateString();
            $updateData['duration_days'] = $durationDays;
            $updateData['warranty_end_date'] = (clone $startDate)->addDays($durationDays)->toDateString();
        }

        $warranty->update($updateData);

        return response()->json([
            'success' => true,
            'message' => 'Warranty updated successfully.',
            'data' => new WarrantyResource($warranty->load(['customer', 'device', 'sale', 'repair', 'claims', 'creator'])),
        ]);
    }

    /**
     * Delete warranty record.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $warranty = Warranty::withTrashed()->forShop($user->shop_id)->find($id);

        if (!$warranty) {
            return response()->json([
                'success' => false,
                'message' => 'Warranty record not found or unauthorized.',
            ], 404);
        }

        DB::transaction(function () use ($warranty) {
            $warranty->claims()->delete();
            $warranty->delete();
        });

        return response()->json([
            'success' => true,
            'message' => 'Warranty record deleted successfully.',
        ]);
    }
}