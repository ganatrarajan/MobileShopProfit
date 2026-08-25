<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreExpenseRequest;
use App\Http\Requests\UpdateExpenseRequest;
use App\Http\Resources\ExpenseResource;
use App\Models\Expense;
use App\Models\ExpenseCategory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ExpenseController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        if (!$shopId) {
            return response()->json(['message' => 'No active shop associated with user.'], 400);
        }

        $query = Expense::forShop($shopId)->with(['category', 'creator']);

        // Search by title, notes, or reference_number
        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('notes', 'like', "%{$search}%")
                  ->orWhere('reference_number', 'like', "%{$search}%");
            });
        }

        // Category filter
        if ($request->filled('category_id') && $request->input('category_id') !== 'all') {
            $query->where('category_id', $request->input('category_id'));
        }

        // Date range filters
        if ($request->filled('date_from')) {
            $query->whereDate('expense_date', '>=', $request->input('date_from'));
        }
        if ($request->filled('date_to')) {
            $query->whereDate('expense_date', '<=', $request->input('date_to'));
        }

        // Metrics calculation for shop
        $totalSum = (float) (clone $query)->sum('amount');

        $perPage = (int) $request->input('per_page', 15);
        $expenses = $query->orderBy('expense_date', 'desc')
            ->orderBy('id', 'desc')
            ->paginate($perPage);

        return response()->json([
            'success' => true,
            'metrics' => [
                'total_expenses_sum' => round($totalSum, 2),
                'total_count' => $expenses->total(),
            ],
            'data' => ExpenseResource::collection($expenses),
            'meta' => [
                'current_page' => $expenses->currentPage(),
                'last_page' => $expenses->lastPage(),
                'per_page' => $expenses->perPage(),
                'total' => $expenses->total(),
            ],
        ]);
    }

    public function store(StoreExpenseRequest $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        if (!$shopId) {
            return response()->json(['message' => 'No active shop associated with user.'], 400);
        }

        $validated = $request->validated();

        // Validate category belongs to shop or is system default
        $category = ExpenseCategory::forShop($shopId)->find($validated['category_id']);
        if (!$category) {
            return response()->json(['message' => 'Invalid expense category.'], 422);
        }

        $expense = Expense::create([
            'shop_id' => $shopId,
            'category_id' => $validated['category_id'],
            'title' => $validated['title'],
            'amount' => $validated['amount'],
            'expense_date' => $validated['expense_date'],
            'payment_method' => $validated['payment_method'] ?? 'cash',
            'notes' => $validated['notes'] ?? null,
            'reference_number' => $validated['reference_number'] ?? null,
            'is_recurring' => $validated['is_recurring'] ?? false,
            'recurrence_type' => $validated['recurrence_type'] ?? null,
            'created_by' => $user->id,
        ]);

        $expense->load(['category', 'creator']);

        return response()->json([
            'success' => true,
            'message' => 'Expense recorded successfully.',
            'data' => new ExpenseResource($expense),
        ], 201);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        $expense = Expense::forShop($shopId)->with(['category', 'creator'])->find($id);
        if (!$expense) {
            return response()->json(['message' => 'Expense record not found.'], 404);
        }

        return response()->json([
            'success' => true,
            'data' => new ExpenseResource($expense),
        ]);
    }

    public function update(UpdateExpenseRequest $request, int $id): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        $expense = Expense::forShop($shopId)->find($id);
        if (!$expense) {
            return response()->json(['message' => 'Expense record not found.'], 404);
        }

        $validated = $request->validated();

        if (isset($validated['category_id'])) {
            $category = ExpenseCategory::forShop($shopId)->find($validated['category_id']);
            if (!$category) {
                return response()->json(['message' => 'Invalid expense category.'], 422);
            }
        }

        $expense->update($validated);
        $expense->load(['category', 'creator']);

        return response()->json([
            'success' => true,
            'message' => 'Expense record updated successfully.',
            'data' => new ExpenseResource($expense),
        ]);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        $expense = Expense::forShop($shopId)->find($id);
        if (!$expense) {
            return response()->json(['message' => 'Expense record not found.'], 404);
        }

        $expense->delete();

        return response()->json([
            'success' => true,
            'message' => 'Expense record deleted successfully.',
        ]);
    }
}