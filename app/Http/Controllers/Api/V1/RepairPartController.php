<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreRepairPartRequest;
use App\Http\Resources\RepairPartResource;
use App\Http\Resources\RepairResource;
use App\Models\Repair;
use App\Models\RepairPart;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RepairPartController extends Controller
{
    /**
     * Add a part to a repair.
     */
    public function store(StoreRepairPartRequest $request, int $repairId): JsonResponse
    {
        $user = $request->user();
        $repair = Repair::forShop($user->shop_id)->find($repairId);

        if (!$repair) {
            return response()->json([
                'success' => false,
                'message' => 'Repair job card not found or unauthorized.',
            ], 404);
        }

        $validated = $request->validated();

        $part = $repair->parts()->create([
            'part_name' => $validated['part_name'],
            'quantity' => (int) ($validated['quantity'] ?? 1),
            'cost_price' => isset($validated['cost_price']) ? (float) $validated['cost_price'] : null,
            'selling_price' => (float) ($validated['selling_price'] ?? 0),
            'notes' => $validated['notes'] ?? null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Repair part added successfully.',
            'data' => new RepairResource($repair->fresh(['customer', 'device', 'parts', 'payments', 'creator'])),
        ], 201);
    }

    /**
     * Update a repair part.
     */
    public function update(StoreRepairPartRequest $request, int $partId): JsonResponse
    {
        $user = $request->user();
        $part = RepairPart::whereHas('repair', function ($q) use ($user) {
            $q->where('shop_id', $user->shop_id);
        })->find($partId);

        if (!$part) {
            return response()->json([
                'success' => false,
                'message' => 'Repair part not found or unauthorized.',
            ], 404);
        }

        $validated = $request->validated();
        $part->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Repair part updated successfully.',
            'data' => new RepairResource($part->repair->fresh(['customer', 'device', 'parts', 'payments', 'creator'])),
        ]);
    }

    /**
     * Delete a repair part.
     */
    public function destroy(Request $request, int $partId): JsonResponse
    {
        $user = $request->user();
        $part = RepairPart::whereHas('repair', function ($q) use ($user) {
            $q->where('shop_id', $user->shop_id);
        })->find($partId);

        if (!$part) {
            return response()->json([
                'success' => false,
                'message' => 'Repair part not found or unauthorized.',
            ], 404);
        }

        $repair = $part->repair;
        $part->delete();

        return response()->json([
            'success' => true,
            'message' => 'Repair part deleted successfully.',
            'data' => new RepairResource($repair->fresh(['customer', 'device', 'parts', 'payments', 'creator'])),
        ]);
    }
}