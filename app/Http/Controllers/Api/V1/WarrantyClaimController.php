<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreWarrantyClaimRequest;
use App\Http\Requests\UpdateWarrantyClaimStatusRequest;
use App\Http\Resources\WarrantyClaimResource;
use App\Models\Warranty;
use App\Models\WarrantyClaim;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class WarrantyClaimController extends Controller
{
    /**
     * Display listing of warranty claims for a shop or specific warranty.
     */
    public function index(Request $request, ?int $warrantyId = null): JsonResponse
    {
        $user = $request->user();
        if (!$user->shop_id) {
            return response()->json([
                'success' => false,
                'message' => 'User is not associated with any shop.',
            ], 403);
        }

        $query = WarrantyClaim::forShop($user->shop_id)
            ->with(['warranty', 'customer', 'device', 'creator']);

        if ($warrantyId) {
            $query->where('warranty_id', $warrantyId);
        }

        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('claim_number', 'like', "%{$search}%")
                  ->orWhere('complaint', 'like', "%{$search}%")
                  ->orWhereHas('customer', function ($cq) use ($search) {
                      $cq->where('name', 'like', "%{$search}%")
                         ->orWhere('mobile', 'like', "%{$search}%");
                  })
                  ->orWhereHas('device', function ($dq) use ($search) {
                      $dq->where('model', 'like', "%{$search}%")
                         ->orWhere('brand', 'like', "%{$search}%")
                         ->orWhere('imei_1', 'like', "%{$search}%");
                  });
            });
        }

        if ($request->filled('claim_status') && $request->input('claim_status') !== 'all') {
            $query->where('claim_status', $request->input('claim_status'));
        }

        $claims = $query->orderBy('id', 'desc')->paginate($request->input('per_page', 15));

        return response()->json([
            'success' => true,
            'data' => WarrantyClaimResource::collection($claims),
            'meta' => [
                'current_page' => $claims->currentPage(),
                'last_page' => $claims->lastPage(),
                'per_page' => $claims->perPage(),
                'total' => $claims->total(),
            ],
        ]);
    }

    /**
     * File a new warranty claim against a warranty.
     */
    public function store(StoreWarrantyClaimRequest $request, int $warrantyId): JsonResponse
    {
        $user = $request->user();
        $warranty = Warranty::forShop($user->shop_id)->find($warrantyId);

        if (!$warranty) {
            return response()->json([
                'success' => false,
                'message' => 'Warranty record not found or unauthorized.',
            ], 404);
        }

        $validated = $request->validated();

        try {
            $claim = DB::transaction(function () use ($user, $warranty, $validated) {
                $count = WarrantyClaim::forShop($user->shop_id)->lockForUpdate()->count();
                $claimNumber = 'CLM-' . str_pad($count + 1, 6, '0', STR_PAD_LEFT);

                return WarrantyClaim::create([
                    'shop_id' => $user->shop_id,
                    'warranty_id' => $warranty->id,
                    'customer_id' => $warranty->customer_id,
                    'device_id' => $warranty->device_id,
                    'claim_number' => $claimNumber,
                    'claim_date' => $validated['claim_date'] ?? now()->toDateString(),
                    'complaint' => $validated['complaint'],
                    'claim_status' => 'open',
                    'notes' => $validated['notes'] ?? null,
                    'created_by' => $user->id,
                ]);
            });

            return response()->json([
                'success' => true,
                'message' => 'Warranty claim registered successfully.',
                'data' => new WarrantyClaimResource($claim->load(['warranty', 'customer', 'device', 'creator'])),
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to register warranty claim: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Display details of a specific warranty claim.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $claim = WarrantyClaim::forShop($user->shop_id)
            ->with(['warranty.customer', 'warranty.device', 'customer', 'device', 'creator'])
            ->find($id);

        if (!$claim) {
            return response()->json([
                'success' => false,
                'message' => 'Warranty claim record not found or unauthorized.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => new WarrantyClaimResource($claim),
        ]);
    }

    /**
     * Update claim status and resolution.
     */
    public function update(UpdateWarrantyClaimStatusRequest $request, int $id): JsonResponse
    {
        $user = $request->user();
        $claim = WarrantyClaim::forShop($user->shop_id)->find($id);

        if (!$claim) {
            return response()->json([
                'success' => false,
                'message' => 'Warranty claim record not found or unauthorized.',
            ], 404);
        }

        $validated = $request->validated();
        $newStatus = $validated['claim_status'];

        $updateData = ['claim_status' => $newStatus];

        if (isset($validated['complaint'])) {
            $updateData['complaint'] = $validated['complaint'];
        }

        if (isset($validated['resolution'])) {
            $updateData['resolution'] = $validated['resolution'];
        }

        if (isset($validated['notes'])) {
            $updateData['notes'] = $validated['notes'];
        }

        if (in_array($newStatus, ['resolved', 'closed']) && !$claim->resolved_at) {
            $updateData['resolved_at'] = now();
        }

        $claim->update($updateData);

        return response()->json([
            'success' => true,
            'message' => "Warranty claim updated to {$newStatus}.",
            'data' => new WarrantyClaimResource($claim->load(['warranty', 'customer', 'device', 'creator'])),
        ]);
    }

    /**
     * Delete warranty claim.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $claim = WarrantyClaim::forShop($user->shop_id)->find($id);

        if (!$claim) {
            return response()->json([
                'success' => false,
                'message' => 'Warranty claim record not found or unauthorized.',
            ], 404);
        }

        $claim->delete();

        return response()->json([
            'success' => true,
            'message' => 'Warranty claim deleted successfully.',
        ]);
    }
}