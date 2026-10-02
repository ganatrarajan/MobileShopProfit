<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\PurchaseResource;
use App\Models\Purchase;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminPurchaseController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Purchase::with(['vendor', 'shop', 'items.inventoryItem']);

        if ($request->filled('shop_id')) {
            $query->where('shop_id', $request->input('shop_id'));
        }

        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('purchase_number', 'like', "%{$search}%")
                  ->orWhereHas('vendor', function ($vq) use ($search) {
                      $vq->where('name', 'like', "%{$search}%");
                  });
            });
        }

        if ($request->filled('payment_status')) {
            $query->where('payment_status', $request->input('payment_status'));
        }

        $perPage = (int) $request->input('per_page', 15);
        $purchases = $query->orderBy('purchase_date', 'desc')->paginate($perPage);

        return response()->json([
            'success' => true,
            'message' => 'Admin purchases list retrieved.',
            'data' => PurchaseResource::collection($purchases),
            'meta' => [
                'current_page' => $purchases->currentPage(),
                'last_page' => $purchases->lastPage(),
                'per_page' => $purchases->perPage(),
                'total' => $purchases->total(),
            ],
        ]);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $purchase = Purchase::with(['vendor', 'shop', 'items.inventoryItem', 'payments'])->find($id);

        if (!$purchase) {
            return response()->json(['success' => false, 'message' => 'Purchase not found.'], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Purchase details retrieved.',
            'data' => new PurchaseResource($purchase),
        ]);
    }
}
