<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\AddStockRequest;
use App\Http\Requests\StockAdjustmentRequest;
use App\Http\Requests\StoreInventoryItemRequest;
use App\Http\Requests\UpdateInventoryItemRequest;
use App\Http\Resources\InventoryItemResource;
use App\Http\Resources\StockMovementResource;
use App\Models\InventoryItem;
use App\Models\InventorySerial;
use App\Models\StockMovement;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class InventoryItemController extends Controller
{
    /**
     * Get inventory listing with metrics
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop->id ?? null;

        if (!$shopId) {
            return response()->json(['message' => 'No active shop associated with user.'], 400);
        }

        $query = InventoryItem::forShop($shopId)->where('is_active', true);

        // Search by name, SKU, brand, model, or serial/IMEI
        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('sku', 'like', "%{$search}%")
                  ->orWhere('brand', 'like', "%{$search}%")
                  ->orWhere('model', 'like', "%{$search}%")
                  ->orWhereHas('serials', function ($sq) use ($search) {
                      $sq->where('imei1', 'like', "%{$search}%")
                        ->orWhere('imei2', 'like', "%{$search}%")
                        ->orWhere('serial_number', 'like', "%{$search}%");
                  });
            });
        }

        // Filter by item_type (mobile, spare_part, accessory, other)
        if ($request->filled('item_type') && $request->input('item_type') !== 'all') {
            $query->where('item_type', $request->input('item_type'));
        }

        // Filter by stock status
        if ($request->filled('stock_status')) {
            $status = $request->input('stock_status');
            if ($status === 'low_stock') {
                $query->whereRaw('current_stock <= minimum_stock AND current_stock > 0');
            } elseif ($status === 'out_of_stock') {
                $query->where('current_stock', '<=', 0);
            } elseif ($status === 'in_stock') {
                $query->where('current_stock', '>', 0);
            }
        }

        // Calculate summary metrics for the shop
        $totalItems = InventoryItem::forShop($shopId)->where('is_active', true)->count();
        $lowStockCount = InventoryItem::forShop($shopId)->where('is_active', true)->whereRaw('current_stock <= minimum_stock AND current_stock > 0')->count();
        $outOfStockCount = InventoryItem::forShop($shopId)->where('is_active', true)->where('current_stock', '<=', 0)->count();
        $totalStockValue = (float) InventoryItem::forShop($shopId)->where('is_active', true)->selectRaw('SUM(current_stock * purchase_price) as total_val')->value('total_val');

        $perPage = (int) $request->input('per_page', 15);
        $items = $query->orderBy('name', 'asc')->paginate($perPage);

        return response()->json([
            'success' => true,
            'message' => 'Inventory items retrieved successfully.',
            'metrics' => [
                'total_items' => $totalItems,
                'low_stock_count' => $lowStockCount,
                'out_of_stock_count' => $outOfStockCount,
                'total_stock_value' => round($totalStockValue, 2),
            ],
            'data' => InventoryItemResource::collection($items->items()),
            'meta' => [
                'current_page' => $items->currentPage(),
                'last_page' => $items->lastPage(),
                'per_page' => $items->perPage(),
                'total' => $items->total(),
            ],
        ]);
    }

    /**
     * Store a new inventory item
     */
    public function store(StoreInventoryItemRequest $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop->id ?? null;

        if (!$shopId) {
            return response()->json(['message' => 'No active shop associated with user.'], 400);
        }

        $validated = $request->validated();

        // Duplicate IMEI check for mobile items
        if (!empty($validated['imei1'])) {
            $exists = InventorySerial::forShop($shopId)->where('imei1', $validated['imei1'])->exists();
            if ($exists) {
                return response()->json(['message' => 'IMEI 1 already exists in this shop inventory.'], 422);
            }
        }

        $item = DB::transaction(function () use ($shopId, $validated) {
            $openingStock = isset($validated['opening_stock']) ? (int)$validated['opening_stock'] : (isset($validated['current_stock']) ? (int)$validated['current_stock'] : 0);

            $item = InventoryItem::create([
                'shop_id' => $shopId,
                'name' => $validated['name'],
                'category' => $validated['category'] ?? 'General',
                'brand' => $validated['brand'] ?? null,
                'model' => $validated['model'] ?? null,
                'sku' => $validated['sku'] ?? null,
                'item_type' => $validated['item_type'],
                'purchase_price' => $validated['purchase_price'],
                'selling_price' => $validated['selling_price'],
                'opening_stock' => $openingStock,
                'current_stock' => $openingStock,
                'minimum_stock' => $validated['minimum_stock'] ?? 2,
                'unit' => $validated['unit'] ?? 'pcs',
                'description' => $validated['description'] ?? null,
                'is_active' => true,
            ]);

            // Save IMEI / Serial if provided
            if (!empty($validated['imei1']) || !empty($validated['serial_number'])) {
                InventorySerial::create([
                    'shop_id' => $shopId,
                    'inventory_item_id' => $item->id,
                    'imei1' => $validated['imei1'] ?? null,
                    'imei2' => $validated['imei2'] ?? null,
                    'serial_number' => $validated['serial_number'] ?? null,
                    'status' => 'available',
                ]);
            }

            // Create Opening Stock Movement if opening stock > 0
            if ($openingStock > 0) {
                StockMovement::create([
                    'shop_id' => $shopId,
                    'inventory_item_id' => $item->id,
                    'movement_type' => 'opening_stock',
                    'quantity' => $openingStock,
                    'unit_cost' => $validated['purchase_price'],
                    'notes' => 'Initial opening stock upon creation',
                ]);
            }

            return $item;
        });

        $item->load(['serials', 'stockMovements']);

        return response()->json([
            'success' => true,
            'message' => 'Inventory item created successfully.',
            'data' => new InventoryItemResource($item),
        ], 201);
    }

    /**
     * Get single inventory item details
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop->id ?? null;

        $item = InventoryItem::forShop($shopId)->with(['serials', 'stockMovements'])->find($id);

        if (!$item) {
            return response()->json(['message' => 'Inventory item not found.'], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Inventory item retrieved successfully.',
            'data' => new InventoryItemResource($item),
        ]);
    }

    /**
     * Update an inventory item
     */
    public function update(UpdateInventoryItemRequest $request, int $id): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop->id ?? null;

        $item = InventoryItem::forShop($shopId)->find($id);

        if (!$item) {
            return response()->json(['message' => 'Inventory item not found.'], 404);
        }

        $item->update($request->validated());
        $item->load(['serials', 'stockMovements']);

        return response()->json([
            'success' => true,
            'message' => 'Inventory item updated successfully.',
            'data' => new InventoryItemResource($item),
        ]);
    }

    /**
     * Delete an inventory item
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop->id ?? null;

        $item = InventoryItem::forShop($shopId)->find($id);

        if (!$item) {
            return response()->json(['message' => 'Inventory item not found.'], 404);
        }

        $item->delete();

        return response()->json([
            'success' => true,
            'message' => 'Inventory item deleted successfully.',
        ]);
    }

    /**
     * Add stock to an item (Purchase/Incoming)
     */
    public function addStock(AddStockRequest $request, int $id): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop->id ?? null;

        $item = InventoryItem::forShop($shopId)->find($id);

        if (!$item) {
            return response()->json(['message' => 'Inventory item not found.'], 404);
        }

        $validated = $request->validated();
        $qty = (int) $validated['quantity'];
        $unitCost = isset($validated['unit_cost']) ? (float) $validated['unit_cost'] : (float) $item->purchase_price;

        DB::transaction(function () use ($shopId, $item, $qty, $unitCost, $validated) {
            $item->increment('current_stock', $qty);
            if ($item->opening_stock === null) { $item->update(['opening_stock' => max(0, $item->current_stock - $qty)]); }

            if (isset($validated['unit_cost'])) {
                $item->update(['purchase_price' => $unitCost]);
            }

            StockMovement::create([
                'shop_id' => $shopId,
                'inventory_item_id' => $item->id,
                'movement_type' => 'purchase',
                'quantity' => $qty,
                'unit_cost' => $unitCost,
                'notes' => $validated['notes'] ?? 'Added stock purchase',
            ]);

            if (!empty($validated['imei1']) || !empty($validated['serial_number'])) {
                InventorySerial::create([
                    'shop_id' => $shopId,
                    'inventory_item_id' => $item->id,
                    'imei1' => $validated['imei1'] ?? null,
                    'imei2' => $validated['imei2'] ?? null,
                    'serial_number' => $validated['serial_number'] ?? null,
                    'status' => 'available',
                ]);
            }
        });

        $item->refresh();
        $item->load(['serials', 'stockMovements']);

        return response()->json([
            'success' => true,
            'message' => "Successfully added {$qty} stock to {$item->name}.",
            'data' => new InventoryItemResource($item),
        ]);
    }

    /**
     * Adjust stock (Damaged, Return, Lost, Correction)
     */
    public function adjustStock(StockAdjustmentRequest $request, int $id): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop->id ?? null;

        $item = InventoryItem::forShop($shopId)->find($id);

        if (!$item) {
            return response()->json(['message' => 'Inventory item not found.'], 404);
        }

        $validated = $request->validated();
        $qty = (int) $validated['quantity'];
        $adjType = $validated['adjustment_type'];

        // Determine stock direction: damaged/lost are deductions (negative), return is addition (positive), correction uses quantity sign
        $changeQty = $qty;
        if (in_array($adjType, ['damaged', 'lost']) && $qty > 0) {
            $changeQty = -$qty;
        }

        // Prevent negative stock
        if ($item->current_stock + $changeQty < 0) {
            return response()->json(['message' => "Insufficient stock. Cannot adjust below 0. Current stock: {$item->current_stock}."], 422);
        }

        DB::transaction(function () use ($shopId, $item, $changeQty, $adjType, $validated) {
            if ($changeQty > 0) {
                $item->increment('current_stock', $changeQty);
            } else {
                $item->decrement('current_stock', abs($changeQty));
            }

            StockMovement::create([
                'shop_id' => $shopId,
                'inventory_item_id' => $item->id,
                'movement_type' => $adjType,
                'quantity' => $changeQty,
                'unit_cost' => $item->purchase_price,
                'notes' => $validated['notes'],
            ]);
        });

        $item->refresh();
        $item->load(['serials', 'stockMovements']);

        return response()->json([
            'success' => true,
            'message' => "Stock adjusted successfully. Current stock: {$item->current_stock}.",
            'data' => new InventoryItemResource($item),
        ]);
    }

    /**
     * Get stock movements history for an item
     */
    public function movements(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop->id ?? null;

        $item = InventoryItem::forShop($shopId)->find($id);

        if (!$item) {
            return response()->json(['message' => 'Inventory item not found.'], 404);
        }

        $movements = StockMovement::forShop($shopId)
            ->where('inventory_item_id', $id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Stock movements retrieved successfully.',
            'data' => StockMovementResource::collection($movements),
        ]);
    }
}