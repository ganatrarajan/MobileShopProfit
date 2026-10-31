<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\UsedMobile;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Storage;

class UsedMobileController extends Controller
{
    /**
     * Display a listing of used mobiles with search, filters, and financial metrics.
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

        $query = UsedMobile::forShop($user->shop_id)->with(['creator', 'seller']);

        // Status Filter
        if ($request->filled('status') && $request->input('status') !== 'all') {
            $query->where('status', $request->input('status'));
        }

        // Search Filter
        if ($request->filled('search')) {
            $search = trim($request->input('search'));
            $query->where(function ($q) use ($search) {
                $q->where('brand', 'like', "%{$search}%")
                  ->orWhere('model', 'like', "%{$search}%")
                  ->orWhere('imei1', 'like', "%{$search}%")
                  ->orWhere('imei2', 'like', "%{$search}%")
                  ->orWhere('seller_name', 'like', "%{$search}%")
                  ->orWhere('seller_phone', 'like', "%{$search}%")
                  ->orWhere('buyer_name', 'like', "%{$search}%")
                  ->orWhere('buyer_phone', 'like', "%{$search}%")
                  ->orWhere('purchase_ref_number', 'like', "%{$search}%")
                  ->orWhere('sale_invoice_number', 'like', "%{$search}%");
            });
        }

        // Date Filters
        if ($request->filled('date_from') || $request->filled('date_to')) {
            $dateField = ($request->input('status') === 'sold') ? 'sale_date' : 'purchase_date';
            if ($request->filled('date_from')) {
                $query->whereDate($dateField, '>=', $request->input('date_from'));
            }
            if ($request->filled('date_to')) {
                $query->whereDate($dateField, '<=', $request->input('date_to'));
            }
        }

        // Active In-Stock devices currently in shop
        $inStockCount = UsedMobile::forShop($user->shop_id)->where('status', 'in_stock')->count();
        $inStockInvestment = UsedMobile::forShop($user->shop_id)->where('status', 'in_stock')->sum('total_cost');

        // Purchased devices in the filtered date range (or all-time if not specified)
        $purchasedQuery = UsedMobile::forShop($user->shop_id);
        if ($request->filled('date_from')) {
            $purchasedQuery->whereDate('purchase_date', '>=', $request->input('date_from'));
        }
        if ($request->filled('date_to')) {
            $purchasedQuery->whereDate('purchase_date', '<=', $request->input('date_to'));
        }
        $totalPurchasedCount = (clone $purchasedQuery)->count();
        $totalPurchasedAmount = (clone $purchasedQuery)->sum('purchase_price');

        // Sold devices in the filtered date range (or all-time if not specified)
        $soldQuery = UsedMobile::forShop($user->shop_id)->where('status', 'sold');
        if ($request->filled('date_from')) {
            $soldQuery->whereDate('sale_date', '>=', $request->input('date_from'));
        }
        if ($request->filled('date_to')) {
            $soldQuery->whereDate('sale_date', '<=', $request->input('date_to'));
        }
        $soldCount = (clone $soldQuery)->count();
        $totalSaleRevenue = (clone $soldQuery)->sum('selling_price');
        $totalProfitEarned = (clone $soldQuery)->sum('profit');

        $perPage = min((int) $request->input('per_page', 20), 1000);
        $paginated = $query->orderByDesc('id')->paginate($perPage);

        return response()->json([
            'success' => true,
            'message' => 'Used mobiles retrieved successfully.',
            'data' => $paginated->items(),
            'pagination' => [
                'current_page' => $paginated->currentPage(),
                'last_page' => $paginated->lastPage(),
                'per_page' => $paginated->perPage(),
                'total' => $paginated->total(),
            ],
            'summary' => [
                'total_purchased_count' => $totalPurchasedCount,
                'total_purchased_amount' => round((float) $totalPurchasedAmount, 2),
                'in_stock_count' => $inStockCount,
                'in_stock_investment' => round((float) $inStockInvestment, 2),
                'sold_count' => $soldCount,
                'total_sale_revenue' => round((float) $totalSaleRevenue, 2),
                'total_profit_earned' => round((float) $totalProfitEarned, 2),
            ],
        ]);
    }

    /**
     * Get quick KPI statistics for dashboard cards.
     */
    public function stats(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user->shop_id) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 403);
        }

        $all = UsedMobile::forShop($user->shop_id);

        $inStockCount = (clone $all)->where('status', 'in_stock')->count();
        $inStockInvestment = (clone $all)->where('status', 'in_stock')->sum('total_cost');

        $soldCount = (clone $all)->where('status', 'sold')->count();
        $totalRevenue = (clone $all)->where('status', 'sold')->sum('selling_price');
        $totalProfit = (clone $all)->where('status', 'sold')->sum('profit');
        $totalPurchased = (clone $all)->count();

        return response()->json([
            'success' => true,
            'data' => [
                'in_stock_count' => $inStockCount,
                'in_stock_investment' => round((float) $inStockInvestment, 2),
                'sold_count' => $soldCount,
                'total_revenue' => round((float) $totalRevenue, 2),
                'total_profit' => round((float) $totalProfit, 2),
                'total_purchased' => $totalPurchased,
            ],
        ]);
    }

    /**
     * Store (Buy) an old / used phone from a seller.
     */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user->shop_id) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'seller_name' => 'required|string|max:191',
            'seller_phone' => 'required|string|max:25',
            'seller_address' => 'nullable|string|max:500',
            'id_proof_type' => 'nullable|string|max:50',
            'id_proof_number' => 'nullable|string|max:100',
            'id_proof_photo' => 'nullable|string',
            'id_proof_back_photo' => 'nullable|string',
            'id_proof_photo' => 'nullable|string', // URL or base64 or path
            'id_proof_back_photo' => 'nullable|string',
            'seller_photo' => 'nullable|string',

            'brand' => 'required|string|max:100',
            'model' => 'required|string|max:100',
            'imei1' => 'required|string|max:30',
            'imei2' => 'nullable|string|max:30',
            'serial_number' => 'nullable|string|max:100',
            'color' => 'nullable|string|max:50',
            'ram' => 'nullable|string|max:20',
            'storage' => 'nullable|string|max:20',
            'battery_health' => 'nullable|string|max:50',

            'device_condition' => 'nullable|string|in:mint,good,fair,damaged',
            'condition_notes' => 'nullable|string|max:1000',
            'accessories_included' => 'nullable|array',

            'purchase_date' => 'required|date',
            'purchase_price' => 'required|numeric|min:0',
            'payment_mode' => 'nullable|string|max:30',
            'purchase_notes' => 'nullable|string|max:1000',
            'repair_cost' => 'nullable|numeric|min:0',
            'repair_details' => 'nullable|string|max:500',
        ]);

        $purchasePrice = (float) $validated['purchase_price'];
        $repairCost = (float) ($validated['repair_cost'] ?? 0);
        $totalCost = $purchasePrice + $repairCost;

        $refNumber = UsedMobile::generatePurchaseRefNumber($user->shop_id);

        $idProofPhoto = $validated['id_proof_photo'] ?? null;
        if ($request->hasFile('id_proof_photo')) {
            $path = $request->file('id_proof_photo')->store('used_mobiles/id_proofs', 'public');
            $idProofPhoto = asset('storage/' . $path);
        } elseif (!empty($idProofPhoto) && str_starts_with($idProofPhoto, 'data:image')) {
            try {
                $imageParts = explode(';base64,', $idProofPhoto);
                $imageTypeAux = explode('image/', $imageParts[0]);
                $imageType = $imageTypeAux[1] ?? 'jpeg';
                $imageBase64 = base64_decode($imageParts[1]);
                $fileName = 'id_proof_' . uniqid() . '.' . $imageType;
                Storage::disk('public')->put('used_mobiles/id_proofs/' . $fileName, $imageBase64);
                $idProofPhoto = asset('storage/used_mobiles/id_proofs/' . $fileName);
            } catch (\Exception $e) {}
        }

        $idProofBackPhoto = $validated['id_proof_back_photo'] ?? null;
        if ($request->hasFile('id_proof_back_photo')) {
            $path = $request->file('id_proof_back_photo')->store('used_mobiles/id_proofs', 'public');
            $idProofBackPhoto = asset('storage/' . $path);
        } elseif (!empty($idProofBackPhoto) && str_starts_with($idProofBackPhoto, 'data:image')) {
            try {
                $imageParts = explode(';base64,', $idProofBackPhoto);
                $imageTypeAux = explode('image/', $imageParts[0]);
                $imageType = $imageTypeAux[1] ?? 'jpeg';
                $imageBase64 = base64_decode($imageParts[1]);
                $fileName = 'id_proof_back_' . uniqid() . '.' . $imageType;
                Storage::disk('public')->put('used_mobiles/id_proofs/' . $fileName, $imageBase64);
                $idProofBackPhoto = asset('storage/used_mobiles/id_proofs/' . $fileName);
            } catch (\Exception $e) {}
        }

        $usedMobile = UsedMobile::create([
            'shop_id' => $user->shop_id,
            'purchase_ref_number' => $refNumber,
            'seller_name' => trim($validated['seller_name']),
            'seller_phone' => trim($validated['seller_phone']),
            'seller_address' => $validated['seller_address'] ?? null,
            'id_proof_type' => $validated['id_proof_type'] ?? null,
            'id_proof_number' => $validated['id_proof_number'] ?? null,
            'id_proof_photo' => $idProofPhoto,
            'id_proof_back_photo' => $idProofBackPhoto,
            'seller_photo' => $validated['seller_photo'] ?? null,

            'brand' => trim($validated['brand']),
            'model' => trim($validated['model']),
            'imei1' => trim($validated['imei1']),
            'imei2' => isset($validated['imei2']) ? trim($validated['imei2']) : null,
            'serial_number' => $validated['serial_number'] ?? null,
            'color' => $validated['color'] ?? null,
            'ram' => $validated['ram'] ?? null,
            'storage' => $validated['storage'] ?? null,
            'battery_health' => $validated['battery_health'] ?? null,

            'device_condition' => $validated['device_condition'] ?? 'good',
            'condition_notes' => $validated['condition_notes'] ?? null,
            'accessories_included' => $validated['accessories_included'] ?? [],

            'purchase_date' => $validated['purchase_date'],
            'purchase_price' => $purchasePrice,
            'payment_mode' => $validated['payment_mode'] ?? 'cash',
            'purchase_notes' => $validated['purchase_notes'] ?? null,

            'repair_cost' => $repairCost,
            'repair_details' => $validated['repair_details'] ?? null,
            'total_cost' => $totalCost,

            'status' => 'in_stock',
            'created_by' => $user->id,
        ]);

        return response()->json([
            'success' => true,
            'message' => "Old phone registered successfully with Ref #{$refNumber}.",
            'data' => $usedMobile->load(['creator']),
        ], 201);
    }

    /**
     * Show single used mobile details.
     */
    public function show(Request $request, $id): JsonResponse
    {
        $user = $request->user();
        $usedMobile = UsedMobile::forShop($user->shop_id)
            ->with(['creator', 'seller', 'shop'])
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $usedMobile,
        ]);
    }

    /**
     * Update details of an existing used mobile entry.
     */
    public function update(Request $request, $id): JsonResponse
    {
        $user = $request->user();
        $usedMobile = UsedMobile::forShop($user->shop_id)->findOrFail($id);

        if ($usedMobile->status === 'sold') {
            return response()->json([
                'success' => false,
                'message' => 'This device is already sold and its purchase/specs details cannot be edited.',
            ], 422);
        }

        $validated = $request->validate([
            'seller_name' => 'sometimes|required|string|max:191',
            'seller_phone' => 'sometimes|required|string|max:25',
            'seller_address' => 'nullable|string|max:500',
            'id_proof_type' => 'nullable|string|max:50',
            'id_proof_number' => 'nullable|string|max:100',
            'id_proof_photo' => 'nullable|string',
            'id_proof_back_photo' => 'nullable|string',

            'brand' => 'sometimes|required|string|max:100',
            'model' => 'sometimes|required|string|max:100',
            'imei1' => 'sometimes|required|string|max:30',
            'imei2' => 'nullable|string|max:30',
            'serial_number' => 'nullable|string|max:100',
            'color' => 'nullable|string|max:50',
            'ram' => 'nullable|string|max:20',
            'storage' => 'nullable|string|max:20',
            'battery_health' => 'nullable|string|max:50',

            'device_condition' => 'nullable|string|in:mint,good,fair,damaged',
            'condition_notes' => 'nullable|string|max:1000',
            'accessories_included' => 'nullable|array',

            'purchase_date' => 'sometimes|required|date',
            'purchase_price' => 'sometimes|required|numeric|min:0',
            'payment_mode' => 'nullable|string|max:30',
            'purchase_notes' => 'nullable|string|max:1000',

            'repair_cost' => 'nullable|numeric|min:0',
            'repair_details' => 'nullable|string|max:500',

            // Sale updates if already sold
            'buyer_name' => 'nullable|string|max:191',
            'buyer_phone' => 'nullable|string|max:25',
            'buyer_address' => 'nullable|string|max:500',
            'sale_date' => 'nullable|date',
            'selling_price' => 'nullable|numeric|min:0',
            'sale_payment_mode' => 'nullable|string|max:30',
            'warranty_days' => 'nullable|integer|min:0',
            'warranty_terms' => 'nullable|string|max:500',
            'sale_notes' => 'nullable|string|max:1000',
            'status' => 'nullable|string|in:in_stock,sold,returned,scrapped',
        ]);

        $purchasePrice = isset($validated['purchase_price']) ? (float) $validated['purchase_price'] : (float) $usedMobile->purchase_price;
        $repairCost = isset($validated['repair_cost']) ? (float) $validated['repair_cost'] : (float) $usedMobile->repair_cost;
        $totalCost = $purchasePrice + $repairCost;
        $validated['total_cost'] = $totalCost;

        if ($usedMobile->status === 'sold' || (isset($validated['status']) && $validated['status'] === 'sold')) {
            $sellingPrice = isset($validated['selling_price']) ? (float) $validated['selling_price'] : (float) ($usedMobile->selling_price ?? 0);
            $validated['profit'] = $sellingPrice - $totalCost;
        }

        if ($request->hasFile('id_proof_photo')) {
            $path = $request->file('id_proof_photo')->store('used_mobiles/id_proofs', 'public');
            $validated['id_proof_photo'] = asset('storage/' . $path);
        } elseif (isset($validated['id_proof_photo']) && str_starts_with($validated['id_proof_photo'], 'data:image')) {
            try {
                $imageParts = explode(';base64,', $validated['id_proof_photo']);
                $imageTypeAux = explode('image/', $imageParts[0]);
                $imageType = $imageTypeAux[1] ?? 'jpeg';
                $imageBase64 = base64_decode($imageParts[1]);
                $fileName = 'id_proof_' . uniqid() . '.' . $imageType;
                Storage::disk('public')->put('used_mobiles/id_proofs/' . $fileName, $imageBase64);
                $validated['id_proof_photo'] = asset('storage/used_mobiles/id_proofs/' . $fileName);
            } catch (\Exception $e) {}
        }

        if ($request->hasFile('id_proof_back_photo')) {
            $path = $request->file('id_proof_back_photo')->store('used_mobiles/id_proofs', 'public');
            $validated['id_proof_back_photo'] = asset('storage/' . $path);
        } elseif (isset($validated['id_proof_back_photo']) && str_starts_with($validated['id_proof_back_photo'], 'data:image')) {
            try {
                $imageParts = explode(';base64,', $validated['id_proof_back_photo']);
                $imageTypeAux = explode('image/', $imageParts[0]);
                $imageType = $imageTypeAux[1] ?? 'jpeg';
                $imageBase64 = base64_decode($imageParts[1]);
                $fileName = 'id_proof_back_' . uniqid() . '.' . $imageType;
                Storage::disk('public')->put('used_mobiles/id_proofs/' . $fileName, $imageBase64);
                $validated['id_proof_back_photo'] = asset('storage/used_mobiles/id_proofs/' . $fileName);
            } catch (\Exception $e) {}
        }

        $usedMobile->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Used mobile updated successfully.',
            'data' => $usedMobile->fresh(),
        ]);
    }

    /**
     * Add or update repair/refurbishment expense for an in-stock phone.
     */
    public function addRepairExpense(Request $request, $id): JsonResponse
    {
        $user = $request->user();
        $usedMobile = UsedMobile::forShop($user->shop_id)->findOrFail($id);

        $validated = $request->validate([
            'repair_cost' => 'required|numeric|min:0',
            'repair_details' => 'nullable|string|max:500',
        ]);

        $newRepairCost = (float) $validated['repair_cost'];
        $totalCost = (float) $usedMobile->purchase_price + $newRepairCost;

        $updateData = [
            'repair_cost' => $newRepairCost,
            'repair_details' => $validated['repair_details'] ?? $usedMobile->repair_details,
            'total_cost' => $totalCost,
        ];

        // Recalculate profit if already sold
        if ($usedMobile->status === 'sold' && $usedMobile->selling_price !== null) {
            $updateData['profit'] = (float) $usedMobile->selling_price - $totalCost;
        }

        $usedMobile->update($updateData);

        return response()->json([
            'success' => true,
            'message' => "Repair cost of ₹{$newRepairCost} logged. Total investment is now ₹{$totalCost}.",
            'data' => $usedMobile->fresh(),
        ]);
    }

    /**
     * Sell an in-stock used mobile to a customer.
     */
    public function sell(Request $request, $id): JsonResponse
    {
        $user = $request->user();
        $usedMobile = UsedMobile::forShop($user->shop_id)->findOrFail($id);

        if ($usedMobile->status === 'sold') {
            return response()->json([
                'success' => false,
                'message' => "This mobile is already marked as SOLD (#{$usedMobile->sale_invoice_number}).",
            ], 422);
        }

        $validated = $request->validate([
            'buyer_name' => 'required|string|max:191',
            'buyer_phone' => 'required|string|max:25',
            'buyer_address' => 'nullable|string|max:500',
            'sale_date' => 'required|date',
            'selling_price' => 'required|numeric|min:0',
            'sale_payment_mode' => 'nullable|string|max:30',
            'warranty_days' => 'nullable|integer|min:0',
            'warranty_terms' => 'nullable|string|max:500',
            'sale_notes' => 'nullable|string|max:1000',
        ]);

        $sellingPrice = (float) $validated['selling_price'];
        $totalCost = (float) $usedMobile->total_cost;
        $profit = $sellingPrice - $totalCost;

        $warrantyDays = (int) ($validated['warranty_days'] ?? 0);
        $warrantyExpiry = $warrantyDays > 0 ? Carbon::parse($validated['sale_date'])->addDays($warrantyDays)->toDateString() : null;

        $saleInvoiceNumber = UsedMobile::generateSaleInvoiceNumber($user->shop_id);

        $usedMobile->update([
            'buyer_name' => trim($validated['buyer_name']),
            'buyer_phone' => trim($validated['buyer_phone']),
            'buyer_address' => $validated['buyer_address'] ?? null,
            'sale_date' => $validated['sale_date'],
            'selling_price' => $sellingPrice,
            'sale_payment_mode' => $validated['sale_payment_mode'] ?? 'cash',
            'warranty_days' => $warrantyDays,
            'warranty_expiry_date' => $warrantyExpiry,
            'warranty_terms' => $validated['warranty_terms'] ?? null,
            'sale_notes' => $validated['sale_notes'] ?? null,
            'sale_invoice_number' => $saleInvoiceNumber,
            'profit' => $profit,
            'status' => 'sold',
            'sold_by' => $user->id,
        ]);

        return response()->json([
            'success' => true,
            'message' => "Used phone sold successfully with Invoice #{$saleInvoiceNumber}! Net profit: ₹{$profit}.",
            'data' => $usedMobile->fresh()->load(['creator', 'seller']),
        ]);
    }

    /**
     * Delete (soft-delete) an entry.
     */
    public function destroy(Request $request, $id): JsonResponse
    {
        $user = $request->user();
        $usedMobile = UsedMobile::forShop($user->shop_id)->findOrFail($id);
        $usedMobile->delete();

        return response()->json([
            'success' => true,
            'message' => 'Used mobile record removed successfully.',
        ]);
    }
}

