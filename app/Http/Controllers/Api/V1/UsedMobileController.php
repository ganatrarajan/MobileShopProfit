<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\UsedMobile;
use App\Models\UsedMobilePayment;
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

        if ($user->role !== 'owner' && !$user->hasPermission('used_mobiles')) {
            return response()->json([
                'success' => false,
                'message' => 'You do not have permission to access the Used Mobiles module.',
            ], 403);
        }

        $query = UsedMobile::forShop($user->shop_id)->with(['creator', 'seller']);

        // Status Filter
        if ($request->filled('status') && $request->input('status') !== 'all') {
            $st = $request->input('status');
            if ($st === 'due' || $st === 'partial') {
                $query->where(function ($q) {
                    $q->where('payment_status', 'partially_paid')
                      ->orWhere('payment_status', 'due')
                      ->orWhere('amount_due', '>', 0);
                });
            } else {
                $query->where('status', $st);
            }
        }

        // Payment Status Filter (e.g. 'due', 'partially_paid', 'paid')
        if ($request->filled('payment_status') && $request->input('payment_status') !== 'all') {
            $ps = $request->input('payment_status');
            if ($ps === 'due') {
                $query->where(function ($q) {
                    $q->where('payment_status', 'due')
                      ->orWhere('payment_status', 'partially_paid')
                      ->orWhere('amount_due', '>', 0);
                });
            } else {
                $query->where('payment_status', $ps);
            }
        }

        // Search Filter
        if ($request->filled('search')) {
            $search = trim($request->input('search'));
            $query->where(function ($q) use ($search) {
                $q->where('brand', 'like', "%{$search}%")
                  ->orWhere('model', 'like', "%{$search}%")
                  ->orWhere('imei1', 'like', "%{$search}%")
                  ->orWhere('imei2', 'like', "%{$search}%")
                  ->orWhere('serial_number', 'like', "%{$search}%")
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
            $status = $request->input('status');

            if ($status === 'sold') {
                if ($request->filled('date_from')) {
                    $query->whereDate('sale_date', '>=', $request->input('date_from'));
                }
                if ($request->filled('date_to')) {
                    $query->whereDate('sale_date', '<=', $request->input('date_to'));
                }
            } elseif ($status === 'in_stock' || $status === 'due' || $status === 'partial') {
                // In-Stock phones and Payment Due phones are active open items currently outstanding in the shop.
                // They must ALWAYS remain visible in the active showroom / due collection list
                // regardless of what month they were acquired or sold in, so the owner can view, sell, and collect pending payments!
            } else {
                // Status is 'all' or not specified:
                // If a mobile is not sold (status == 'in_stock') or has pending due payment, keep it visible in the listing!
                // For fully settled sold mobiles, only include if sale_date / purchase_date matches the filtered period.
                $query->where(function ($q) use ($request) {
                    $q->where('status', 'in_stock')
                      ->orWhere(function ($dueQ) {
                          $dueQ->where(function ($sub) {
                              $sub->where('payment_status', 'partially_paid')
                                  ->orWhere('payment_status', 'due')
                                  ->orWhere('amount_due', '>', 0);
                          });
                      })
                      ->orWhere(function ($subQ) use ($request) {
                          if ($request->filled('date_from')) {
                              $subQ->whereDate('sale_date', '>=', $request->input('date_from'));
                          }
                          if ($request->filled('date_to')) {
                              $subQ->whereDate('sale_date', '<=', $request->input('date_to'));
                          }
                      });
                });
            }
        }

        // Active In-Stock devices currently in shop (lifetime unsold inventory)
        $inStockCount = UsedMobile::forShop($user->shop_id)->where('status', 'in_stock')->count();
        $inStockInvestment = UsedMobile::forShop($user->shop_id)->where('status', 'in_stock')->sum('total_cost');

        // Purchased devices: includes all unsold in-stock inventory + devices purchased in the date range
        $purchasedQuery = UsedMobile::forShop($user->shop_id);
        if ($request->filled('date_from') || $request->filled('date_to')) {
            $purchasedQuery->where(function ($q) use ($request) {
                $q->where('status', 'in_stock')
                  ->orWhere(function ($subQ) use ($request) {
                      if ($request->filled('date_from')) {
                          $subQ->whereDate('purchase_date', '>=', $request->input('date_from'));
                      }
                      if ($request->filled('date_to')) {
                          $subQ->whereDate('purchase_date', '<=', $request->input('date_to'));
                      }
                  });
            });
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
        $sort = $request->input('sort', 'newest');
        switch ($sort) {
            case 'oldest':
                $query->orderBy('id', 'asc');
                break;
            case 'price_high':
                $query->orderBy('purchase_price', 'desc');
                break;
            case 'price_low':
                $query->orderBy('purchase_price', 'asc');
                break;
            case 'newest':
            default:
                $query->orderByDesc('id');
                break;
        }

        $paginated = $query->paginate($perPage);

        $activeDueQuery = UsedMobile::forShop($user->shop_id)
            ->where(function ($q) {
                $q->where('payment_status', 'partially_paid')
                  ->orWhere('payment_status', 'due')
                  ->orWhere('amount_due', '>', 0);
            });
        $allDueCount = (clone $activeDueQuery)->count();
        $allTotalDueAmount = (clone $activeDueQuery)->sum('amount_due');

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
                'total_paid_amount' => round((float) (clone $soldQuery)->sum('amount_paid'), 2),
                'total_due_amount' => round((float) $allTotalDueAmount, 2),
                'due_count' => $allDueCount,
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
        $totalDue = (clone $all)->where('status', 'sold')->sum('amount_due');
        $totalProfit = (clone $all)->where('status', 'sold')->sum('profit');
        $totalPurchased = (clone $all)->count();

        return response()->json([
            'success' => true,
            'data' => [
                'in_stock_count' => $inStockCount,
                'in_stock_investment' => round((float) $inStockInvestment, 2),
                'sold_count' => $soldCount,
                'total_revenue' => round((float) $totalRevenue, 2),
                'total_due' => round((float) $totalDue, 2),
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
            'imei1' => 'nullable|string|max:30',
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
            'purchase_tax_rate' => 'nullable|numeric|min:0|max:100',
            'purchase_tax_type' => 'nullable|string|in:inclusive,exclusive',
            'purchase_tax_amount' => 'nullable|numeric|min:0',
            'purchase_cgst_amount' => 'nullable|numeric|min:0',
            'purchase_sgst_amount' => 'nullable|numeric|min:0',
            'purchase_igst_amount' => 'nullable|numeric|min:0',
            'purchase_is_inter_state' => 'nullable|boolean',
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
            'imei1' => !empty($validated['imei1']) ? trim($validated['imei1']) : null,
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

            'purchase_tax_rate' => $validated['purchase_tax_rate'] ?? 0,
            'purchase_tax_type' => $validated['purchase_tax_type'] ?? 'inclusive',
            'purchase_tax_amount' => $validated['purchase_tax_amount'] ?? 0,
            'purchase_cgst_amount' => $validated['purchase_cgst_amount'] ?? 0,
            'purchase_sgst_amount' => $validated['purchase_sgst_amount'] ?? 0,
            'purchase_igst_amount' => $validated['purchase_igst_amount'] ?? 0,
            'purchase_is_inter_state' => $validated['purchase_is_inter_state'] ?? false,
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
            ->with(['creator', 'seller', 'shop', 'payments.creator'])
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
            'imei1' => 'nullable|string|max:30',
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
            'purchase_tax_rate' => 'nullable|numeric|min:0|max:100',
            'purchase_tax_type' => 'nullable|string|in:inclusive,exclusive',
            'purchase_tax_amount' => 'nullable|numeric|min:0',
            'purchase_cgst_amount' => 'nullable|numeric|min:0',
            'purchase_sgst_amount' => 'nullable|numeric|min:0',
            'purchase_igst_amount' => 'nullable|numeric|min:0',
            'purchase_is_inter_state' => 'nullable|boolean',
            'tax_rate' => 'nullable|numeric|min:0|max:100',
            'tax_type' => 'nullable|string|in:inclusive,exclusive',
            'tax_amount' => 'nullable|numeric|min:0',
            'cgst_amount' => 'nullable|numeric|min:0',
            'sgst_amount' => 'nullable|numeric|min:0',
            'igst_amount' => 'nullable|numeric|min:0',
            'is_inter_state' => 'nullable|boolean',
        ]);

        $purchasePrice = isset($validated['purchase_price']) ? (float) $validated['purchase_price'] : (float) $usedMobile->purchase_price;
        $repairCost = isset($validated['repair_cost']) ? (float) $validated['repair_cost'] : (float) $usedMobile->repair_cost;
        $totalCost = $purchasePrice + $repairCost;
        $validated['total_cost'] = $totalCost;

        if ($usedMobile->status === 'sold' || (isset($validated['status']) && $validated['status'] === 'sold')) {
            $sellingPrice = isset($validated['selling_price']) ? (float) $validated['selling_price'] : (float) ($usedMobile->selling_price ?? 0);
            $taxRate = (float) (isset($validated['tax_rate']) ? $validated['tax_rate'] : ($usedMobile->tax_rate ?? 0));
            $taxType = isset($validated['tax_type']) ? $validated['tax_type'] : ($usedMobile->tax_type ?? 'inclusive');
            $taxAmount = (float) (isset($validated['tax_amount']) ? $validated['tax_amount'] : ($usedMobile->tax_amount ?? 0));
            $netSellingRevenue = ($taxRate > 0 && $taxType === 'inclusive') ? max(0, $sellingPrice - $taxAmount) : $sellingPrice;
            $validated['profit'] = round($netSellingRevenue - $totalCost, 2);
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

        if (array_key_exists('imei1', $validated)) {
            $validated['imei1'] = !empty($validated['imei1']) ? trim($validated['imei1']) : null;
        }
        if (array_key_exists('id_proof_number', $validated)) {
            $validated['id_proof_number'] = !empty($validated['id_proof_number']) ? trim($validated['id_proof_number']) : null;
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
            'purchase_tax_rate' => 'nullable|numeric|min:0|max:100',
            'purchase_tax_type' => 'nullable|string|in:inclusive,exclusive',
            'purchase_tax_amount' => 'nullable|numeric|min:0',
            'purchase_cgst_amount' => 'nullable|numeric|min:0',
            'purchase_sgst_amount' => 'nullable|numeric|min:0',
            'purchase_igst_amount' => 'nullable|numeric|min:0',
            'purchase_is_inter_state' => 'nullable|boolean',
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
            $taxRate = (float) ($usedMobile->tax_rate ?? 0);
            $taxType = $usedMobile->tax_type ?? 'inclusive';
            $taxAmount = (float) ($usedMobile->tax_amount ?? 0);
            $sellingPrice = (float) $usedMobile->selling_price;
            $netSellingRevenue = ($taxRate > 0 && $taxType === 'inclusive') ? max(0, $sellingPrice - $taxAmount) : $sellingPrice;
            $updateData['profit'] = round($netSellingRevenue - $totalCost, 2);
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
            'amount_paid' => 'nullable|numeric|min:0',
            'sale_payment_mode' => 'nullable|string|max:30',
            'warranty_days' => 'nullable|integer|min:0',
            'warranty_terms' => 'nullable|string|max:500',
            'sale_notes' => 'nullable|string|max:1000',
            'tax_rate' => 'nullable|numeric|min:0|max:100',
            'tax_type' => 'nullable|string|in:inclusive,exclusive',
            'tax_amount' => 'nullable|numeric|min:0',
            'cgst_amount' => 'nullable|numeric|min:0',
            'sgst_amount' => 'nullable|numeric|min:0',
            'igst_amount' => 'nullable|numeric|min:0',
            'is_inter_state' => 'nullable|boolean',
        ]);

        $sellingPrice = (float) $validated['selling_price'];
        $amountPaid = isset($validated['amount_paid']) && $validated['amount_paid'] !== ''
            ? min($sellingPrice, max(0, (float) $validated['amount_paid']))
            : $sellingPrice;
        $amountDue = max(0, round($sellingPrice - $amountPaid, 2));

        $paymentStatus = 'due';
        if ($amountPaid >= $sellingPrice && $sellingPrice > 0) {
            $paymentStatus = 'paid';
        } elseif ($amountPaid > 0) {
            $paymentStatus = 'partially_paid';
        }

        $totalCost = (float) $usedMobile->total_cost;
        $taxRate = (float) ($validated['tax_rate'] ?? 0);
        $taxType = $validated['tax_type'] ?? 'inclusive';
        $taxAmount = (float) ($validated['tax_amount'] ?? 0);

        // Net revenue of shopkeeper (excluding GST tax payable to govt)
        $netSellingRevenue = ($taxRate > 0 && $taxType === 'inclusive') 
            ? max(0, $sellingPrice - $taxAmount) 
            : $sellingPrice;

        $profit = round($netSellingRevenue - $totalCost, 2);

        $warrantyDays = (int) ($validated['warranty_days'] ?? 0);
        $warrantyExpiry = $warrantyDays > 0 ? Carbon::parse($validated['sale_date'])->addDays($warrantyDays)->toDateString() : null;

        $saleInvoiceNumber = UsedMobile::generateSaleInvoiceNumber($user->shop_id);

        $usedMobile->update([
            'buyer_name' => trim($validated['buyer_name']),
            'buyer_phone' => trim($validated['buyer_phone']),
            'buyer_address' => $validated['buyer_address'] ?? null,
            'sale_date' => $validated['sale_date'],
            'selling_price' => $sellingPrice,
            'amount_paid' => $amountPaid,
            'amount_due' => $amountDue,
            'payment_status' => $paymentStatus,
            'sale_payment_mode' => $validated['sale_payment_mode'] ?? 'cash',
            'warranty_days' => $warrantyDays,
            'warranty_expiry_date' => $warrantyExpiry,
            'warranty_terms' => $validated['warranty_terms'] ?? null,
            'sale_notes' => $validated['sale_notes'] ?? null,
            'sale_invoice_number' => $saleInvoiceNumber,
            'profit' => $profit,
            'tax_rate' => $validated['tax_rate'] ?? 0,
            'tax_type' => $validated['tax_type'] ?? 'inclusive',
            'tax_amount' => $validated['tax_amount'] ?? 0,
            'cgst_amount' => $validated['cgst_amount'] ?? 0,
            'sgst_amount' => $validated['sgst_amount'] ?? 0,
            'igst_amount' => $validated['igst_amount'] ?? 0,
            'is_inter_state' => $validated['is_inter_state'] ?? false,
            'status' => 'sold',
            'sold_by' => $user->id,
        ]);

        if ($amountPaid > 0) {
            UsedMobilePayment::create([
                'shop_id' => $user->shop_id,
                'used_mobile_id' => $usedMobile->id,
                'amount' => $amountPaid,
                'payment_method' => $validated['sale_payment_mode'] ?? 'cash',
                'payment_date' => $validated['sale_date'] ?? now(),
                'notes' => 'Payment received upon sale',
                'created_by' => $user->id,
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => "Used phone sold successfully with Invoice #{$saleInvoiceNumber}! Net profit: ₹{$profit}.",
            'data' => $usedMobile->fresh()->load(['creator', 'seller', 'payments.creator']),
        ]);
    }

    /**
     * Collect / add partial payment towards pending due of sold used mobile.
     */
    public function addPayment(Request $request, $id): JsonResponse
    {
        $user = $request->user();
        $usedMobile = UsedMobile::forShop($user->shop_id)->findOrFail($id);

        if ($usedMobile->status !== 'sold') {
            return response()->json([
                'success' => false,
                'message' => 'Cannot record payment on a phone that is not marked as sold.',
            ], 422);
        }

        $due = (float) ($usedMobile->amount_due ?? 0);
        if ($due <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'This device is already fully paid. No pending due amount.',
            ], 422);
        }

        $validated = $request->validate([
            'amount' => 'required|numeric|min:0.01|max:' . ($due + 0.01),
            'payment_method' => 'nullable|string|max:50',
            'payment_date' => 'nullable|date',
            'notes' => 'nullable|string|max:500',
        ]);

        $paymentAmount = (float) $validated['amount'];

        UsedMobilePayment::create([
            'shop_id' => $user->shop_id,
            'used_mobile_id' => $usedMobile->id,
            'amount' => $paymentAmount,
            'payment_method' => $validated['payment_method'] ?? 'cash',
            'payment_date' => $validated['payment_date'] ?? now(),
            'notes' => $validated['notes'] ?? 'Installment payment',
            'created_by' => $user->id,
        ]);

        $usedMobile->recalculatePayments();

        return response()->json([
            'success' => true,
            'message' => "Payment of ₹" . number_format($paymentAmount, 2) . " collected successfully.",
            'data' => $usedMobile->fresh()->load(['creator', 'seller', 'payments.creator']),
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

