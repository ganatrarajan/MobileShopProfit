<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreRepairRequest;
use App\Http\Requests\UpdateRepairRequest;
use App\Http\Requests\UpdateRepairStatusRequest;
use App\Http\Resources\RepairResource;
use App\Models\Customer;
use App\Models\Device;
use App\Models\Repair;
use App\Models\RepairPayment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RepairController extends Controller
{
    /**
     * Display a paginated listing of repairs for the authenticated user's shop.
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

        $query = Repair::forShop($user->shop_id)
            ->with(['customer', 'device', 'parts', 'payments', 'creator']);

        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('job_number', 'like', "%{$search}%")
                  ->orWhere('problem_description', 'like', "%{$search}%")
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

        if ($request->filled('repair_status') && $request->input('repair_status') !== 'all') {
            $query->where('repair_status', $request->input('repair_status'));
        }

        if ($request->filled('customer_id')) {
            $query->where('customer_id', $request->input('customer_id'));
        }

        if ($request->filled('date_from')) {
            $query->whereDate('date_received', '>=', $request->input('date_from'));
        }

        if ($request->filled('date_to')) {
            $query->whereDate('date_received', '<=', $request->input('date_to'));
        }

        $repairs = $query->orderBy('id', 'desc')
            ->paginate($request->input('per_page', 15));

        return response()->json([
            'success' => true,
            'data' => RepairResource::collection($repairs),
            'meta' => [
                'current_page' => $repairs->currentPage(),
                'last_page' => $repairs->lastPage(),
                'per_page' => $repairs->perPage(),
                'total' => $repairs->total(),
            ],
        ]);
    }

    /**
     * Store a new repair job card.
     */
    public function store(StoreRepairRequest $request): JsonResponse
    {
        $user = $request->user();
        if (!$user->shop_id) {
            return response()->json([
                'success' => false,
                'message' => 'User is not associated with any shop.',
            ], 403);
        }

        $validated = $request->validated();

        // Validate customer ownership
        $customer = Customer::where('shop_id', $user->shop_id)->find($validated['customer_id']);
        if (!$customer) {
            return response()->json([
                'success' => false,
                'message' => 'Selected customer does not belong to your shop.',
            ], 422);
        }

        // Validate device ownership and customer relation
        $device = Device::where('shop_id', $user->shop_id)
            ->where('customer_id', $customer->id)
            ->find($validated['device_id']);

        if (!$device) {
            return response()->json([
                'success' => false,
                'message' => 'Selected device does not belong to this customer or shop.',
            ], 422);
        }

        try {
            $repair = DB::transaction(function () use ($user, $validated) {
                // Generate per-shop unique job card number collision-safely
                $lastJob = Repair::withTrashed()->forShop($user->shop_id)
                    ->where('job_number', 'like', 'JOB-%')
                    ->orderBy('id', 'desc')
                    ->value('job_number');

                $seq = 1;
                if ($lastJob && preg_match('/JOB-(\d+)/', $lastJob, $m)) {
                    $seq = ((int) $m[1]) + 1;
                }

                do {
                    $jobNumber = 'JOB-' . str_pad($seq, 6, '0', STR_PAD_LEFT);
                    $exists = Repair::withTrashed()->forShop($user->shop_id)->where('job_number', $jobNumber)->exists();
                    if ($exists) {
                        $seq++;
                    }
                } while ($exists);

                $estimatedCost = (float) ($validated['estimated_cost'] ?? 0);
                $finalCost = (float) ($validated['final_cost'] ?? 0);
                $costToUse = $finalCost > 0 ? $finalCost : $estimatedCost;

                $repair = Repair::create([
                    'shop_id' => $user->shop_id,
                    'customer_id' => $validated['customer_id'],
                    'device_id' => $validated['device_id'],
                    'job_number' => $jobNumber,
                    'date_received' => $validated['date_received'] ?? now()->toDateString(),
                    'expected_delivery_date' => $validated['expected_delivery_date'] ?? null,
                    'problem_description' => $validated['problem_description'],
                    'device_condition' => $validated['device_condition'] ?? [],
                    'condition_notes' => $validated['condition_notes'] ?? null,
                    'accessories_received' => $validated['accessories_received'] ?? [],
                    'accessories_notes' => $validated['accessories_notes'] ?? null,
                    'pin_passcode' => $validated['pin_passcode'] ?? null,
                    'estimated_cost' => $estimatedCost,
                    'final_cost' => $finalCost,
                    'labour_cost' => (float) ($validated['labour_cost'] ?? 0),
                    'amount_paid' => 0,
                    'amount_due' => $costToUse,
                    'repair_status' => 'received',
                    'customer_notes' => $validated['customer_notes'] ?? null,
                    'internal_notes' => $validated['internal_notes'] ?? null,
                    'created_by' => $user->id,
                ]);

                // Record advance / initial payment if provided
                $initialPayment = (float) ($validated['payment_amount'] ?? 0);
                if ($initialPayment > 0) {
                    $paymentAmount = min($initialPayment, $costToUse);
                    RepairPayment::create([
                        'shop_id' => $user->shop_id,
                        'repair_id' => $repair->id,
                        'amount' => $paymentAmount,
                        'payment_method' => $validated['payment_method'] ?? 'cash',
                        'payment_date' => now(),
                        'notes' => $validated['payment_notes'] ?? 'Advance payment',
                        'created_by' => $user->id,
                    ]);

                    $repair->recalculatePaymentStatus();
                }

                if (!empty($validated['parts']) && is_array($validated['parts'])) {
                    foreach ($validated['parts'] as $partData) {
                        $invItemId = $partData['inventory_item_id'] ?? null;
                        $qty = (int) ($partData['quantity'] ?? 1);
                        if ($invItemId) {
                            $invItem = \App\Models\InventoryItem::forShop($user->shop_id)->lockForUpdate()->find($invItemId);
                            if (!$invItem) {
                                throw new \Exception("Inventory part ID {$invItemId} not found.");
                            }
                            if ($invItem->current_stock < $qty) {
                                throw new \Exception("Insufficient stock for part '{$invItem->name}'. Current stock: {$invItem->current_stock}, requested: {$qty}.");
                            }

                            $invItem->decrement('current_stock', $qty);

                            \App\Models\StockMovement::create([
                                'shop_id' => $user->shop_id,
                                'inventory_item_id' => $invItem->id,
                                'movement_type' => 'repair_usage',
                                'quantity' => -$qty,
                                'unit_cost' => $invItem->purchase_price,
                                'reference_type' => 'repair',
                                'reference_id' => $repair->id,
                                'notes' => "Used in Repair Job Card #{$repair->job_number}",
                            ]);
                        }

                        $repair->parts()->create([
                            'shop_id' => $user->shop_id,
                            'inventory_item_id' => $invItemId,
                            'part_name' => $partData['part_name'] ?? ($invItem->name ?? 'Part'),
                            'part_number' => $partData['part_number'] ?? null,
                            'cost_price' => $partData['cost_price'] ?? ($invItem->purchase_price ?? 0),
                            'selling_price' => $partData['selling_price'] ?? ($invItem->selling_price ?? 0),
                            'quantity' => $qty,
                        ]);
                    }
                }

                return $repair->load(['customer', 'device', 'parts', 'payments', 'creator']);
            });

            return response()->json([
                'success' => true,
                'message' => 'Repair job card created successfully.',
                'data' => new RepairResource($repair),
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to create repair job card: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Display details of a specific repair.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $repair = Repair::forShop($user->shop_id)
            ->with(['customer', 'device', 'parts', 'payments.creator', 'creator'])
            ->find($id);

        if (!$repair) {
            return response()->json([
                'success' => false,
                'message' => 'Repair job card not found or unauthorized.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => new RepairResource($repair),
        ]);
    }

    /**
     * Update repair job card details.
     */
    public function update(UpdateRepairRequest $request, int $id): JsonResponse
    {
        $user = $request->user();
        $repair = Repair::forShop($user->shop_id)->find($id);

        if (!$repair) {
            return response()->json([
                'success' => false,
                'message' => 'Repair job card not found or unauthorized.',
            ], 404);
        }

        $validated = $request->validated();
        $repair->update($validated);
        $repair->recalculatePaymentStatus();

        return response()->json([
            'success' => true,
            'message' => 'Repair job card updated successfully.',
            'data' => new RepairResource($repair->load(['customer', 'device', 'parts', 'payments', 'creator'])),
        ]);
    }

    /**
     * Update repair status.
     */
    public function updateStatus(UpdateRepairStatusRequest $request, int $id): JsonResponse
    {
        $user = $request->user();
        $repair = Repair::forShop($user->shop_id)->find($id);

        if (!$repair) {
            return response()->json([
                'success' => false,
                'message' => 'Repair job card not found or unauthorized.',
            ], 404);
        }

        $validated = $request->validated();
        $newStatus = $validated['repair_status'];

        $updateData = ['repair_status' => $newStatus];
        if ($newStatus === 'delivered' && !$repair->delivered_date) {
            $updateData['delivered_date'] = now();
        }

        if (!empty($validated['notes'])) {
            $updateData['internal_notes'] = ($repair->internal_notes ? $repair->internal_notes . "\n" : '') .
                "[" . now()->toDateTimeString() . " Status: $newStatus] " . $validated['notes'];
        }

        $repair->update($updateData);

        return response()->json([
            'success' => true,
            'message' => "Repair status updated to {$newStatus}.",
            'data' => new RepairResource($repair->load(['customer', 'device', 'parts', 'payments', 'creator'])),
        ]);
    }

    /**
     * Delete repair job card.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $repair = Repair::forShop($user->shop_id)->find($id);

        if (!$repair) {
            return response()->json([
                'success' => false,
                'message' => 'Repair job card not found or unauthorized.',
            ], 404);
        }

        DB::transaction(function () use ($repair) {
            $repair->parts()->delete();
            $repair->payments()->delete();
            $repair->delete();
        });

        return response()->json([
            'success' => true,
            'message' => 'Repair job card deleted successfully.',
        ]);
    }
}