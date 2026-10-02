<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\PurchasePaymentResource;
use App\Http\Resources\PurchaseResource;
use App\Models\Purchase;
use App\Models\PurchasePayment;
use App\Models\Vendor;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PurchasePaymentController extends Controller
{
    /**
     * Record payment against a specific purchase
     */
    public function store(Request $request, int $purchaseId): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        if (!$shopId) {
            return response()->json(['message' => 'No active shop associated with user.'], 400);
        }

        $purchase = Purchase::forShop($shopId)->find($purchaseId);

        if (!$purchase) {
            return response()->json(['success' => false, 'message' => 'Purchase record not found.'], 404);
        }

        $request->validate([
            'amount' => ['required', 'numeric', 'gt:0'],
            'payment_date' => ['required', 'date'],
            'payment_method' => ['nullable', 'string', 'max:50'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ], [
            'amount.required' => 'Please enter the payment amount.',
            'amount.gt' => 'Payment amount must be greater than 0.',
            'payment_date.required' => 'Please select the payment date.',
        ]);

        $amount = (float) $request->input('amount');
        $currentOutstanding = (float) $purchase->outstanding_amount;

        if ($amount > $currentOutstanding) {
            return response()->json([
                'success' => false,
                'message' => "Payment amount (₹" . number_format($amount, 2) . ") cannot exceed the outstanding balance (₹" . number_format($currentOutstanding, 2) . ").",
            ], 422);
        }

        return DB::transaction(function () use ($shopId, $purchase, $amount, $request) {
            $payment = PurchasePayment::create([
                'shop_id' => $shopId,
                'purchase_id' => $purchase->id,
                'vendor_id' => $purchase->vendor_id,
                'amount' => $amount,
                'payment_date' => $request->input('payment_date'),
                'payment_method' => $request->input('payment_method', 'cash'),
                'notes' => $request->input('notes'),
            ]);

            $newPaid = (float) $purchase->amount_paid + $amount;
            $purchase->amount_paid = $newPaid;
            $purchase->updatePaymentTotals();

            return response()->json([
                'success' => true,
                'message' => "✓ Payment Recorded. ₹" . number_format($amount, 2) . " payment recorded successfully.",
                'data' => new PurchasePaymentResource($payment),
                'purchase' => new PurchaseResource($purchase->fresh(['vendor', 'items.inventoryItem', 'payments'])),
            ]);
        });
    }

    /**
     * Record payment against a vendor (auto-distributes to oldest unpaid purchases)
     */
    public function storeForVendor(Request $request, int $vendorId): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        if (!$shopId) {
            return response()->json(['message' => 'No active shop associated with user.'], 400);
        }

        $vendor = Vendor::forShop($shopId)->find($vendorId);

        if (!$vendor) {
            return response()->json(['success' => false, 'message' => 'Vendor not found.'], 404);
        }

        $request->validate([
            'amount' => ['required', 'numeric', 'gt:0'],
            'payment_date' => ['required', 'date'],
            'payment_method' => ['nullable', 'string', 'max:50'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ], [
            'amount.required' => 'Please enter the payment amount.',
            'amount.gt' => 'Payment amount must be greater than 0.',
        ]);

        $amount = (float) $request->input('amount');
        $vendorOutstanding = $vendor->outstanding_amount;

        if ($amount > $vendorOutstanding && $vendorOutstanding > 0) {
            return response()->json([
                'success' => false,
                'message' => "Payment amount (₹" . number_format($amount, 2) . ") exceeds vendor total outstanding balance (₹" . number_format($vendorOutstanding, 2) . ").",
            ], 422);
        }

        return DB::transaction(function () use ($shopId, $vendor, $amount, $request) {
            $remaining = $amount;

            // Distribute across pending/partial purchases of vendor ordered by date
            $unpaidPurchases = Purchase::forShop($shopId)
                ->where('vendor_id', $vendor->id)
                ->whereIn('payment_status', ['pending', 'partial'])
                ->orderBy('purchase_date', 'asc')
                ->get();

            foreach ($unpaidPurchases as $purchase) {
                if ($remaining <= 0) break;

                $due = (float) $purchase->outstanding_amount;
                $apply = min($remaining, $due);

                PurchasePayment::create([
                    'shop_id' => $shopId,
                    'purchase_id' => $purchase->id,
                    'vendor_id' => $vendor->id,
                    'amount' => $apply,
                    'payment_date' => $request->input('payment_date'),
                    'payment_method' => $request->input('payment_method', 'cash'),
                    'notes' => $request->input('notes') ?? 'Vendor payment distribution',
                ]);

                $purchase->amount_paid = (float) $purchase->amount_paid + $apply;
                $purchase->updatePaymentTotals();

                $remaining -= $apply;
            }

            // If any remaining amount (e.g. no unpaid purchases left), record standalone vendor payment
            if ($remaining > 0) {
                PurchasePayment::create([
                    'shop_id' => $shopId,
                    'purchase_id' => null,
                    'vendor_id' => $vendor->id,
                    'amount' => $remaining,
                    'payment_date' => $request->input('payment_date'),
                    'payment_method' => $request->input('payment_method', 'cash'),
                    'notes' => $request->input('notes'),
                ]);
            }

            return response()->json([
                'success' => true,
                'message' => "✓ Payment Recorded. ₹" . number_format($amount, 2) . " vendor payment recorded successfully.",
            ]);
        });
    }
}
