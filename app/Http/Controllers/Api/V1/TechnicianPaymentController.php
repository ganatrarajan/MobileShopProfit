<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Technician;
use App\Models\TechnicianPayment;
use App\Models\Repair;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TechnicianPaymentController extends Controller
{
    /**
     * Get payment history for a specific technician.
     */
    public function index(Request $request, int $technicianId): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        $technician = Technician::forShop($shopId)->findOrFail($technicianId);

        $payments = TechnicianPayment::where('shop_id', $shopId)
            ->where('technician_id', $technicianId)
            ->with(['repair:id,job_number,problem_description'])
            ->orderBy('payment_date', 'desc')
            ->orderBy('id', 'desc')
            ->paginate(20);

        return response()->json([
            'success' => true,
            'message' => 'Technician payment history retrieved successfully.',
            'summary' => [
                'total_earnings' => $technician->total_earnings,
                'total_paid' => $technician->total_paid,
                'total_payable' => $technician->total_payable,
            ],
            'data' => $payments,
        ]);
    }

    /**
     * Record a new payout to a technician.
     */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        if (!$shopId) {
            return response()->json(['message' => 'No active shop associated with user.'], 400);
        }

        $validated = $request->validate([
            'technician_id' => 'required|integer|exists:technicians,id',
            'repair_id' => 'nullable|integer|exists:repairs,id',
            'amount' => 'required|numeric|min:0.01',
            'payment_date' => 'required|date',
            'payment_method' => 'nullable|string|in:cash,upi,bank_transfer,card,other',
            'notes' => 'nullable|string|max:1000',
        ]);

        $technician = Technician::forShop($shopId)->findOrFail($validated['technician_id']);

        if (!empty($validated['repair_id'])) {
            $repair = Repair::forShop($shopId)->findOrFail($validated['repair_id']);
            if ($repair->technician_id !== $technician->id) {
                return response()->json(['message' => 'The specified repair job is not assigned to this technician.'], 422);
            }
        }

        $payment = DB::transaction(function () use ($shopId, $user, $validated, $technician) {
            $payout = TechnicianPayment::create([
                'shop_id' => $shopId,
                'technician_id' => $technician->id,
                'repair_id' => $validated['repair_id'] ?? null,
                'amount' => $validated['amount'],
                'payment_date' => $validated['payment_date'],
                'payment_method' => $validated['payment_method'] ?? 'cash',
                'notes' => $validated['notes'] ?? null,
                'created_by' => $user->id,
            ]);

            // If linked to a specific repair, update that repair's paid amount
            if (!empty($validated['repair_id'])) {
                $repair = Repair::find($validated['repair_id']);
                if ($repair) {
                    $directPaid = (float) $repair->technicianPayments()->sum('amount');
                    $repair->update([
                        'technician_paid_amount' => max((float) $repair->technician_paid_amount, $directPaid),
                    ]);
                }
            } else {
                // Allocate payout across technician's unpaid repair jobs starting from oldest
                $remainingPayout = (float) $validated['amount'];
                $unpaidRepairs = Repair::forShop($shopId)
                    ->where('technician_id', $technician->id)
                    ->where('technician_earning', '>', 0)
                    ->orderBy('created_at', 'asc')
                    ->get();

                foreach ($unpaidRepairs as $r) {
                    if ($remainingPayout <= 0) break;
                    $earning = (float) $r->technician_earning;
                    $currentPaid = (float) $r->technician_paid_amount;
                    $dueOnRepair = max(0.0, $earning - $currentPaid);

                    if ($dueOnRepair > 0) {
                        $allocated = min($dueOnRepair, $remainingPayout);
                        $r->update([
                            'technician_paid_amount' => round($currentPaid + $allocated, 2),
                        ]);
                        $remainingPayout -= $allocated;
                    }
                }
            }

            return $payout;
        });

        // Refresh technician model accessors
        $technician->refresh();

        return response()->json([
            'success' => true,
            'message' => 'Technician payment recorded successfully.',
            'summary' => [
                'total_earnings' => $technician->total_earnings,
                'total_paid' => $technician->total_paid,
                'total_payable' => $technician->total_payable,
            ],
            'data' => $payment,
        ], 201);
    }

    /**
     * Delete/void a technician payment record.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        $payment = TechnicianPayment::where('shop_id', $shopId)->findOrFail($id);
        $technicianId = $payment->technician_id;

        DB::transaction(function () use ($payment, $technicianId, $shopId) {
            $payment->delete();

            // Re-sync all repair technician_paid_amount for this technician
            $repairs = Repair::forShop($shopId)->where('technician_id', $technicianId)->get();
            foreach ($repairs as $r) {
                $directPaid = (float) $r->technicianPayments()->sum('amount');
                $r->update(['technician_paid_amount' => $directPaid]);
            }

            // Re-allocate remaining general payouts (payments with repair_id == null)
            $generalPayouts = TechnicianPayment::where('shop_id', $shopId)
                ->where('technician_id', $technicianId)
                ->whereNull('repair_id')
                ->orderBy('created_at', 'asc')
                ->get();

            foreach ($generalPayouts as $payout) {
                $rem = (float) $payout->amount;
                $unpaid = Repair::forShop($shopId)
                    ->where('technician_id', $technicianId)
                    ->where('technician_earning', '>', 0)
                    ->orderBy('created_at', 'asc')
                    ->get();

                foreach ($unpaid as $r) {
                    if ($rem <= 0) break;
                    $earning = (float) $r->technician_earning;
                    $currPaid = (float) $r->technician_paid_amount;
                    $dueOnRepair = max(0.0, $earning - $currPaid);
                    if ($dueOnRepair > 0) {
                        $alloc = min($dueOnRepair, $rem);
                        $r->update(['technician_paid_amount' => round($currPaid + $alloc, 2)]);
                        $rem -= $alloc;
                    }
                }
            }
        });

        $technician = Technician::forShop($shopId)->find($technicianId);

        return response()->json([
            'success' => true,
            'message' => 'Technician payment deleted successfully.',
            'summary' => $technician ? [
                'total_earnings' => $technician->total_earnings,
                'total_paid' => $technician->total_paid,
                'total_payable' => $technician->total_payable,
            ] : null,
        ]);
    }
}