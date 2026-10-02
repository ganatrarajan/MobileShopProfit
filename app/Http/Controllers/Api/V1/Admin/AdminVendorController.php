<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\VendorResource;
use App\Models\Vendor;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminVendorController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Vendor::with('shop')->withCount('purchases');

        if ($request->filled('shop_id')) {
            $query->where('shop_id', $request->input('shop_id'));
        }

        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $perPage = (int) $request->input('per_page', 15);
        $vendors = $query->orderBy('name', 'asc')->paginate($perPage);

        return response()->json([
            'success' => true,
            'message' => 'Admin vendors list retrieved.',
            'data' => VendorResource::collection($vendors),
            'meta' => [
                'current_page' => $vendors->currentPage(),
                'last_page' => $vendors->lastPage(),
                'per_page' => $vendors->perPage(),
                'total' => $vendors->total(),
            ],
        ]);
    }
}
