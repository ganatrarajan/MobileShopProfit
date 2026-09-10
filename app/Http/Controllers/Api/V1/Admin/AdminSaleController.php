<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Sale;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminSaleController extends Controller
{
    use ApiResponse;

    /**
     * Get paginated sales list across all shops with search and filters.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Sale::withoutGlobalScope('shop')->with(['shop', 'customer', 'items']);

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('invoice_number', 'like', "%{$search}%")
                  ->orWhere('customer_name', 'like', "%{$search}%")
                  ->orWhere('customer_mobile', 'like', "%{$search}%")
                  ->orWhereHas('shop', function ($sq) use ($search) {
                      $sq->where('name', 'like', "%{$search}%");
                  });
            });
        }

        if ($request->filled('shop_id')) {
            $query->where('shop_id', $request->shop_id);
        }

        if ($request->filled('payment_status')) {
            $query->where('payment_status', $request->payment_status);
        }

        if ($request->filled('date_from')) {
            $query->whereDate('sale_date', '>=', $request->date_from);
        }

        if ($request->filled('date_to')) {
            $query->whereDate('sale_date', '<=', $request->date_to);
        }

        // Compute overall summary metrics for the filtered query before pagination
        $totalSalesAmount = (float) (clone $query)->sum('grand_total');
        $totalPaidAmount = (float) (clone $query)->sum('amount_paid');
        $totalDueAmount = (float) (clone $query)->sum('amount_due');
        $totalInvoicesCount = (clone $query)->count();

        $perPage = (int) $request->input('per_page', 15);
        $sales = $query->latest('sale_date')->paginate($perPage);

        $responseData = $sales->toArray();
        $responseData['summary'] = [
            'total_sales_amount'   => round($totalSalesAmount, 2),
            'total_paid_amount'    => round($totalPaidAmount, 2),
            'total_due_amount'     => round($totalDueAmount, 2),
            'total_invoices_count' => $totalInvoicesCount,
        ];

        return $this->successResponse($responseData, 'Sales list retrieved');
    }

    /**
     * Get single sale invoice details.
     */
    public function show($id): JsonResponse
    {
        $sale = Sale::withoutGlobalScope('shop')
            ->with(['shop', 'customer', 'device', 'items', 'payments', 'creator'])
            ->find($id);

        if (! $sale) {
            return $this->errorResponse('Sale invoice not found', 404);
        }

        return $this->successResponse($sale, 'Sale invoice details retrieved');
    }
}
