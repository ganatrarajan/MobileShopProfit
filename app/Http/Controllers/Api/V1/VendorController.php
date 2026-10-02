<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreVendorRequest;
use App\Http\Requests\UpdateVendorRequest;
use App\Http\Resources\VendorResource;
use App\Http\Resources\PurchaseResource;
use App\Models\Vendor;
use App\Models\Purchase;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VendorController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        if (!$shopId) {
            return response()->json(['message' => 'No active shop associated with user.'], 400);
        }

        $query = Vendor::forShop($shopId)->withCount('purchases');

        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('gst_number', 'like', "%{$search}%");
            });
        }

        $allVendors = (clone $query)->get();
        $totalVendors = $allVendors->count();
        $totalPurchases = (float) $allVendors->sum('total_purchase');
        $totalPaid = (float) $allVendors->sum('total_paid');
        $totalOutstanding = (float) $allVendors->sum('outstanding_amount');

        $perPage = (int) $request->input('per_page', 15);
        $vendors = $query->orderBy('name', 'asc')->paginate($perPage);

        return response()->json([
            'success' => true,
            'message' => 'Vendors retrieved successfully.',
            'metrics' => [
                'total_vendors' => $totalVendors,
                'total_purchases' => round($totalPurchases, 2),
                'total_paid' => round($totalPaid, 2),
                'total_outstanding' => round($totalOutstanding, 2),
            ],
            'data' => VendorResource::collection($vendors),
            'meta' => [
                'current_page' => $vendors->currentPage(),
                'last_page' => $vendors->lastPage(),
                'per_page' => $vendors->perPage(),
                'total' => $vendors->total(),
            ],
        ]);
    }

    public function store(StoreVendorRequest $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        if (!$shopId) {
            return response()->json(['message' => 'No active shop associated with user.'], 400);
        }

        $validated = $request->validated();
        $validated['shop_id'] = $shopId;

        $vendor = Vendor::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Vendor created successfully.',
            'data' => new VendorResource($vendor),
        ], 201);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        $vendor = Vendor::forShop($shopId)->with(['purchases.items.inventoryItem', 'payments'])->find($id);

        if (!$vendor) {
            return response()->json(['success' => false, 'message' => 'Vendor not found.'], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Vendor details retrieved.',
            'data' => new VendorResource($vendor),
            'purchases' => PurchaseResource::collection($vendor->purchases),
        ]);
    }

    public function update(UpdateVendorRequest $request, int $id): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        $vendor = Vendor::forShop($shopId)->find($id);

        if (!$vendor) {
            return response()->json(['success' => false, 'message' => 'Vendor not found.'], 404);
        }

        $vendor->update($request->validated());

        return response()->json([
            'success' => true,
            'message' => 'Vendor updated successfully.',
            'data' => new VendorResource($vendor->fresh()),
        ]);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        $vendor = Vendor::forShop($shopId)->find($id);

        if (!$vendor) {
            return response()->json(['success' => false, 'message' => 'Vendor not found.'], 404);
        }

        $vendor->delete();

        return response()->json([
            'success' => true,
            'message' => 'Vendor deleted successfully.',
        ]);
    }
}
