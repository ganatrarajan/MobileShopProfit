<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Warranty;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminWarrantyController extends Controller
{
    use ApiResponse;

    /**
     * Get paginated warranties across all shops with search and filters.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Warranty::withoutGlobalScope('shop')
            ->whereNull('warranties.deleted_at')
            ->with(['shop', 'customer', 'device', 'claims']);

        if ($request->boolean('with_trashed')) {
            $query->withTrashed();
        }

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('warranty_number', 'like', "%{$search}%")
                  ->orWhereHas('customer', function ($cq) use ($search) {
                      $cq->where('name', 'like', "%{$search}%")
                         ->orWhere('mobile', 'like', "%{$search}%");
                  })
                  ->orWhereHas('shop', function ($sq) use ($search) {
                      $sq->where('name', 'like', "%{$search}%");
                  });
            });
        }

        if ($request->filled('shop_id')) {
            $query->where('shop_id', $request->shop_id);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $totalCount = (clone $query)->count();
        $activeCount = (clone $query)->where('status', 'active')->count();

        $perPage = (int) $request->input('per_page', 15);
        $warranties = $query->latest()->paginate($perPage);

        $responseData = $warranties->toArray();
        $responseData['summary'] = [
            'total_count'  => $totalCount,
            'active_count' => $activeCount,
        ];

        return $this->successResponse($responseData, 'Warranties list retrieved');
    }
}
