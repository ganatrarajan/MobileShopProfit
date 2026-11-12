<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Shop;
use App\Models\UsedMobile;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminUsedMobileController extends Controller
{
    use ApiResponse;

    /**
     * Get aggregated metrics showing which shops / users use the Used Mobile feature.
     */
    public function usersUsage(Request $request): JsonResponse
    {
        // 1. Overall platform summary for Used Mobiles
        $totalDevices = UsedMobile::count();
        $totalShopsUsing = UsedMobile::distinct('shop_id')->count('shop_id');
        $totalInStock = UsedMobile::where('status', 'in_stock')->count();
        $totalSold = UsedMobile::where('status', 'sold')->count();
        $totalInvested = (float) UsedMobile::sum('total_cost');
        $totalProfit = (float) UsedMobile::where('status', 'sold')->sum('profit');

        // 2. Query shops that have at least one used mobile record
        $shopIdsWithUsedMobiles = UsedMobile::select('shop_id')
            ->distinct()
            ->pluck('shop_id');

        $query = Shop::with('user')
            ->whereIn('id', $shopIdsWithUsedMobiles);

        if ($request->filled('search')) {
            $search = trim($request->search);
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('owner_name', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('city', 'like', "%{$search}%")
                  ->orWhereHas('user', function ($uq) use ($search) {
                      $uq->where('name', 'like', "%{$search}%")
                         ->orWhere('email', 'like', "%{$search}%")
                         ->orWhere('mobile', 'like', "%{$search}%")
                         ->orWhere('phone', 'like', "%{$search}%");
                  });
            });
        }

        $perPage = (int) $request->input('per_page', 15);
        $shops = $query->paginate($perPage);

        // Fetch aggregated used mobile metrics per shop for the current page
        $pageShopIds = $shops->pluck('id')->toArray();
        $metrics = [];
        if (!empty($pageShopIds)) {
            $rawMetrics = UsedMobile::whereIn('shop_id', $pageShopIds)
                ->select(
                    'shop_id',
                    DB::raw('COUNT(*) as total_purchased'),
                    DB::raw('SUM(CASE WHEN status = "in_stock" THEN 1 ELSE 0 END) as in_stock_count'),
                    DB::raw('SUM(CASE WHEN status = "sold" THEN 1 ELSE 0 END) as sold_count'),
                    DB::raw('COALESCE(SUM(total_cost), 0) as total_invested'),
                    DB::raw('COALESCE(SUM(CASE WHEN status = "sold" THEN selling_price ELSE 0 END), 0) as total_sales_amount'),
                    DB::raw('COALESCE(SUM(CASE WHEN status = "sold" THEN profit ELSE 0 END), 0) as total_profit'),
                    DB::raw('MIN(created_at) as first_activity_at'),
                    DB::raw('MAX(updated_at) as last_activity_at')
                )
                ->groupBy('shop_id')
                ->get()
                ->keyBy('shop_id');

            foreach ($rawMetrics as $shopId => $m) {
                $metrics[$shopId] = [
                    'total_purchased'    => (int) $m->total_purchased,
                    'in_stock_count'     => (int) $m->in_stock_count,
                    'sold_count'         => (int) $m->sold_count,
                    'total_invested'     => (float) $m->total_invested,
                    'total_sales_amount' => (float) $m->total_sales_amount,
                    'total_profit'       => (float) $m->total_profit,
                    'first_activity_at'  => $m->first_activity_at,
                    'last_activity_at'   => $m->last_activity_at,
                ];
            }
        }

        // Transform shops with their metrics
        $transformed = $shops->getCollection()->map(function ($shop) use ($metrics) {
            $m = $metrics[$shop->id] ?? [
                'total_purchased'    => 0,
                'in_stock_count'     => 0,
                'sold_count'         => 0,
                'total_invested'     => 0.0,
                'total_sales_amount' => 0.0,
                'total_profit'       => 0.0,
                'first_activity_at'  => null,
                'last_activity_at'   => null,
            ];

            return [
                'shop_id'            => $shop->id,
                'shop_name'          => $shop->name,
                'owner_name'         => $shop->owner_name ?? ($shop->user->name ?? 'N/A'),
                'email'              => $shop->email ?? ($shop->user->email ?? 'N/A'),
                'mobile'             => $shop->mobile ?? $shop->phone ?? ($shop->user->mobile ?? $shop->user->phone ?? 'N/A'),
                'city'               => $shop->city ?? 'N/A',
                'state'              => $shop->state ?? '',
                'status'             => $shop->status,
                'user'               => $shop->user ? [
                    'id'                 => $shop->user->id,
                    'name'               => $shop->user->name,
                    'email'              => $shop->user->email,
                    'mobile'             => $shop->user->mobile ?? $shop->user->phone,
                    'role'               => $shop->user->role,
                    'last_app_opened_at' => $shop->user->last_app_opened_at,
                ] : null,
                'metrics'            => $m,
            ];
        });

        // Sort collection by total_purchased descending
        $sorted = $transformed->sortByDesc(fn($item) => $item['metrics']['total_purchased'])->values();
        $shops->setCollection($sorted);

        $responseData = $shops->toArray();
        $responseData['summary'] = [
            'total_shops_using' => $totalShopsUsing,
            'total_devices'     => $totalDevices,
            'total_in_stock'    => $totalInStock,
            'total_sold'        => $totalSold,
            'total_invested'    => round($totalInvested, 2),
            'total_profit'      => round($totalProfit, 2),
        ];

        return $this->successResponse($responseData, 'Used mobile users usage retrieved successfully');
    }

    /**
     * Get paginated used mobiles across all shops with filters.
     */
    public function index(Request $request): JsonResponse
    {
        $query = UsedMobile::with(['shop', 'creator', 'seller']);

        if ($request->filled('shop_id')) {
            $query->where('shop_id', $request->shop_id);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('search')) {
            $search = trim($request->search);
            $query->where(function ($q) use ($search) {
                $q->where('brand', 'like', "%{$search}%")
                  ->orWhere('model', 'like', "%{$search}%")
                  ->orWhere('imei1', 'like', "%{$search}%")
                  ->orWhere('imei2', 'like', "%{$search}%")
                  ->orWhere('purchase_ref_number', 'like', "%{$search}%")
                  ->orWhere('sale_invoice_number', 'like', "%{$search}%")
                  ->orWhere('seller_name', 'like', "%{$search}%")
                  ->orWhere('seller_phone', 'like', "%{$search}%")
                  ->orWhere('buyer_name', 'like', "%{$search}%")
                  ->orWhere('buyer_phone', 'like', "%{$search}%")
                  ->orWhereHas('shop', function ($sq) use ($search) {
                      $sq->where('name', 'like', "%{$search}%");
                  });
            });
        }

        if ($request->filled('date_from')) {
            $query->whereDate('purchase_date', '>=', $request->date_from);
        }

        if ($request->filled('date_to')) {
            $query->whereDate('purchase_date', '<=', $request->date_to);
        }

        // Summary metrics before pagination
        $totalDevices = (clone $query)->count();
        $totalInStock = (clone $query)->where('status', 'in_stock')->count();
        $totalSold = (clone $query)->where('status', 'sold')->count();
        $totalInvested = (float) (clone $query)->sum('total_cost');
        $totalProfit = (float) (clone $query)->where('status', 'sold')->sum('profit');

        $perPage = (int) $request->input('per_page', 15);
        $mobiles = $query->orderBy('created_at', 'desc')->paginate($perPage);

        $responseData = $mobiles->toArray();
        $responseData['summary'] = [
            'total_devices'  => $totalDevices,
            'total_in_stock' => $totalInStock,
            'total_sold'     => $totalSold,
            'total_invested' => round($totalInvested, 2),
            'total_profit'   => round($totalProfit, 2),
        ];

        return $this->successResponse($responseData, 'Used mobiles retrieved successfully');
    }

    /**
     * Get single used mobile record with full details.
     */
    public function show($id): JsonResponse
    {
        $mobile = UsedMobile::with(['shop.user', 'creator', 'seller'])->find($id);

        if (!$mobile) {
            return $this->errorResponse('Used mobile record not found', 404);
        }

        return $this->successResponse($mobile, 'Used mobile record details retrieved');
    }
}

