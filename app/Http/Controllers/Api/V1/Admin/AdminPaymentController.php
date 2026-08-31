<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\PaymentTransaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminPaymentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = PaymentTransaction::with(['shop', 'user', 'plan']);

        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        if ($request->filled('shop_id')) {
            $query->where('shop_id', $request->input('shop_id'));
        }

        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('order_id', 'like', "%{$search}%")
                  ->orWhere('payment_id', 'like', "%{$search}%")
                  ->orWhereHas('shop', function ($sq) use ($search) {
                      $sq->where('name', 'like', "%{$search}%");
                  });
            });
        }

        $perPage = (int) $request->input('per_page', 15);
        $transactions = $query->orderBy('created_at', 'desc')->paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data'   => $transactions,
        ]);
    }
}
