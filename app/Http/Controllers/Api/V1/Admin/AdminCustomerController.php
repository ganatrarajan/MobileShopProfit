<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\Repair;
use App\Models\Sale;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminCustomerController extends Controller
{
    use ApiResponse;

    /**
     * Get paginated customers list across all shops with search and filters.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Customer::withoutGlobalScope('shop')->with(['shop']);

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('mobile', 'like', "%{$search}%")
                  ->orWhere('alternate_mobile', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhereHas('shop', function ($sq) use ($search) {
                      $sq->where('name', 'like', "%{$search}%");
                  });
            });
        }

        if ($request->filled('shop_id')) {
            $query->where('shop_id', $request->shop_id);
        }

        $perPage = (int) $request->input('per_page', 15);
        $customers = $query->latest()->paginate($perPage);

        // Enhance items with sales & repairs counts and total spent
        $customers->getCollection()->transform(function ($customer) {
            $salesCount = Sale::withoutGlobalScope('shop')->where('customer_id', $customer->id)->count();
            $repairsCount = Repair::withoutGlobalScope('shop')->where('customer_id', $customer->id)->count();
            $salesSpent = (float) Sale::withoutGlobalScope('shop')->where('customer_id', $customer->id)->sum('grand_total');
            $repairsSpent = (float) Repair::withoutGlobalScope('shop')->where('customer_id', $customer->id)->sum('amount_paid');

            $data = $customer->toArray();
            $data['sales_count'] = $salesCount;
            $data['repairs_count'] = $repairsCount;
            $data['total_spent'] = round($salesSpent + $repairsSpent, 2);
            return $data;
        });

        return $this->successResponse($customers, 'Customers list retrieved');
    }

    /**
     * Get single customer details with full sales, repairs, and device records.
     */
    public function show($id): JsonResponse
    {
        $customer = Customer::withoutGlobalScope('shop')->with(['shop', 'devices'])->find($id);

        if (! $customer) {
            return $this->errorResponse('Customer not found', 404);
        }

        $sales = Sale::withoutGlobalScope('shop')
            ->where('customer_id', $id)
            ->with(['items', 'payments'])
            ->latest()
            ->get();

        $repairs = Repair::withoutGlobalScope('shop')
            ->where('customer_id', $id)
            ->with(['device', 'technician', 'parts', 'payments'])
            ->latest()
            ->get();

        $data = $customer->toArray();
        $data['sales'] = $sales;
        $data['repairs'] = $repairs;
        $data['total_sales_amount'] = (float) $sales->sum('grand_total');
        $data['total_repairs_amount'] = (float) $repairs->sum('amount_paid');
        $data['total_spent'] = round($data['total_sales_amount'] + $data['total_repairs_amount'], 2);

        return $this->successResponse($data, 'Customer details retrieved');
    }
}
