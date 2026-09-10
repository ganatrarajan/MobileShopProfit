<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Expense;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminExpenseController extends Controller
{
    use ApiResponse;

    /**
     * Get paginated shop expenses across all shops with search and filters.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Expense::withoutGlobalScope('shop')->with(['shop', 'category']);

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('reference_number', 'like', "%{$search}%")
                  ->orWhere('notes', 'like', "%{$search}%")
                  ->orWhereHas('category', function ($cq) use ($search) {
                      $cq->where('name', 'like', "%{$search}%");
                  })
                  ->orWhereHas('shop', function ($sq) use ($search) {
                      $sq->where('name', 'like', "%{$search}%");
                  });
            });
        }

        if ($request->filled('shop_id')) {
            $query->where('shop_id', $request->shop_id);
        }

        if ($request->filled('category_id')) {
            $query->where('category_id', $request->category_id);
        }

        if ($request->filled('date_from')) {
            $query->whereDate('expense_date', '>=', $request->date_from);
        }

        if ($request->filled('date_to')) {
            $query->whereDate('expense_date', '<=', $request->date_to);
        }

        // Summary stats
        $totalExpenseAmount = (float) (clone $query)->sum('amount');
        $expensesCount = (clone $query)->count();

        $perPage = (int) $request->input('per_page', 15);
        $expenses = $query->latest('expense_date')->paginate($perPage);

        $responseData = $expenses->toArray();
        $responseData['summary'] = [
            'total_expense_amount' => round($totalExpenseAmount, 2),
            'expenses_count'       => $expensesCount,
        ];

        return $this->successResponse($responseData, 'Shop expenses list retrieved');
    }
}
