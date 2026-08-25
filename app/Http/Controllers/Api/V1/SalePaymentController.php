<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreSalePaymentRequest;
use App\Http\Resources\SalePaymentResource;
use App\Http\Resources\SaleResource;
use App\Models\Sale;
use App\Models\SalePayment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SalePaymentController extends Controller
{
    /**
     * Display payments for a sale.
     */
    public function index(Request $request, int $saleId): JsonResponse
    {
        $user = $request->user();
        $sale = Sale::forShop($user->shop_id)->find($saleId);

        if (!$sale) {
            return response()->json([
                'success' => false,
                'message' => 'Sale invoice not found or unauthorized.',
            ], 404);
        }

        $payments = $sale->payments()->with('creator')->get();

        return response()->json([
            'success' => true,
            'data' => SalePaymentResource::collection($payments),
        ]);
    }

    /**
     * Collect a payment for a sale.
     */
    public function store(StoreSalePaymentRequest $request, int $saleId): JsonResponse
    {
        $user = $request->user();
        $sale = Sale::forShop($user->shop_id)->find($saleId);

        if (!$sale) {
            return response()->json([
                'success' => false,
                'message' => 'Sale invoice not found or unauthorized.',
            ], 404);
        }

        if ($sale->amount_due <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'This invoice is already fully paid.',
            ], 422);
        }

        $validated = $request->validated();
        $amount = (float) $validated['amount'];

        if ($amount > $sale->amount_due) {
            return response()->json([
                'success' => false,
                'message' => "Payment amount (₹{$amount}) exceeds remaining due amount (₹{$sale->amount_due}).",
            ], 422);
        }

        try {
            DB::transaction(function () use ($user, $sale, $validated, $amount) {
                SalePayment::create([
                    'shop_id' => $user->shop_id,
                    'sale_id' => $sale->id,
                    'amount' => $amount,
                    'payment_method' => $validated['payment_method'],
                    'payment_date' => $validated['payment_date'] ?? now(),
                    'notes' => $validated['notes'] ?? null,
                    'created_by' => $user->id,
                ]);

                $sale->recalculatePaymentStatus();
            });

            $freshSale = $sale->fresh(['customer', 'device', 'items', 'payments.creator', 'creator']);

            return response()->json([
                'success' => true,
                'message' => 'Payment collected successfully.',
                'data' => new SaleResource($freshSale),
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to record payment: ' . $e->getMessage(),
            ], 500);
        }
    }
}