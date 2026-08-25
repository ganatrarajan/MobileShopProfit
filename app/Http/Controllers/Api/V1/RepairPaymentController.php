<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreRepairPaymentRequest;
use App\Http\Resources\RepairPaymentResource;
use App\Http\Resources\RepairResource;
use App\Models\Repair;
use App\Models\RepairPayment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RepairPaymentController extends Controller
{
    /**
     * Display payments for a repair.
     */
    public function index(Request $request, int $repairId): JsonResponse
    {
        $user = $request->user();
        $repair = Repair::forShop($user->shop_id)->find($repairId);

        if (!$repair) {
            return response()->json([
                'success' => false,
                'message' => 'Repair job card not found or unauthorized.',
            ], 404);
        }

        $payments = $repair->payments()->with('creator')->orderBy('id', 'desc')->get();

        return response()->json([
            'success' => true,
            'data' => RepairPaymentResource::collection($payments),
        ]);
    }

    /**
     * Store a payment / advance against a repair.
     */
    public function store(StoreRepairPaymentRequest $request, int $repairId): JsonResponse
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

        $payment = RepairPayment::create([
            'shop_id' => $user->shop_id,
            'repair_id' => $repair->id,
            'amount' => (float) $validated['amount'],
            'payment_method' => $validated['payment_method'],
            'payment_date' => $validated['payment_date'] ?? now(),
            'notes' => $validated['notes'] ?? null,
            'created_by' => $user->id,
        ]);

        $repair->recalculatePaymentStatus();

        return response()->json([
            'success' => true,
            'message' => 'Payment recorded successfully.',
            'data' => new RepairResource($repair->fresh(['customer', 'device', 'parts', 'payments.creator', 'creator'])),
        ], 201);
    }
}