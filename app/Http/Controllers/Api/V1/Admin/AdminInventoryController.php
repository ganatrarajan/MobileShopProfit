<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\InventoryItem;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminInventoryController extends Controller
{
    use ApiResponse;

    /**
     * Get paginated inventory items across all shops with search and filters.
     */
    public function index(Request $request): JsonResponse
    {
        $query = InventoryItem::withoutGlobalScope('shop')->with(['shop']);

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('sku', 'like', "%{$search}%")
                  ->orWhere('category', 'like', "%{$search}%")
                  ->orWhere('brand', 'like', "%{$search}%")
                  ->orWhere('model', 'like', "%{$search}%")
                  ->orWhereHas('shop', function ($sq) use ($search) {
                      $sq->where('name', 'like', "%{$search}%");
                  });
            });
        }

        if ($request->filled('shop_id')) {
            $query->where('shop_id', $request->shop_id);
        }

        if ($request->boolean('low_stock')) {
            $query->whereRaw('current_stock <= minimum_stock AND current_stock > 0');
        }

        if ($request->boolean('out_of_stock')) {
            $query->where('current_stock', '<=', 0);
        }

        // Summary metrics
        $totalItemsCount = (clone $query)->count();
        $lowStockCount = (clone $query)->whereRaw('current_stock <= minimum_stock AND current_stock > 0')->count();
        $outOfStockCount = (clone $query)->where('current_stock', '<=', 0)->count();
        $totalStockValue = (float) (clone $query)->selectRaw('SUM(current_stock * purchase_price) as val')->value('val');
        $totalSellingValue = (float) (clone $query)->selectRaw('SUM(current_stock * selling_price) as val')->value('val');

        $perPage = (int) $request->input('per_page', 15);
        $items = $query->latest()->paginate($perPage);

        $responseData = $items->toArray();
        $responseData['summary'] = [
            'total_items_count'   => $totalItemsCount,
            'low_stock_count'     => $lowStockCount,
            'out_of_stock_count'  => $outOfStockCount,
            'total_stock_value'   => round($totalStockValue, 2),
            'total_selling_value' => round($totalSellingValue, 2),
        ];

        return $this->successResponse($responseData, 'Inventory stock list retrieved');
    }

    /**
     * Get single inventory item details with stock movement history.
     */
    public function show($id): JsonResponse
    {
        $item = InventoryItem::withoutGlobalScope('shop')
            ->with(['shop', 'stockMovements', 'serials'])
            ->find($id);

        if (! $item) {
            return $this->errorResponse('Inventory item not found', 404);
        }

        return $this->successResponse($item, 'Inventory item details retrieved');
    }
}
