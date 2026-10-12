<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminUserController extends Controller
{
    use ApiResponse;

    /**
     * Get cross-shop users list.
     */
    public function index(Request $request): JsonResponse
    {
        $query = User::with('shop');

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('mobile', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%")
                  ->orWhereHas('shop', function ($sq) use ($search) {
                      $sq->where('name', 'like', "%{$search}%");
                  });
            });
        }

        if ($request->filled('role')) {
            $query->where('role', $request->role);
        }

        if ($request->boolean('today_opened') || $request->input('opened_filter') === 'today') {
            $query->whereDate('last_app_opened_at', today());
            $query->orderBy('last_app_opened_at', 'desc');
        } elseif ($request->input('opened_filter') === 'never') {
            $query->whereNull('last_app_opened_at');
            $query->latest();
        } else {
            $query->orderByRaw('CASE WHEN last_app_opened_at IS NULL THEN 1 ELSE 0 END, last_app_opened_at DESC, id DESC');
        }

        $perPage = (int) $request->input('per_page', 15);
        $users = $query->paginate($perPage);

        return $this->successResponse($users, 'Users list retrieved');
    }

    /**
     * Get user details.
     */
    public function show($id): JsonResponse
    {
        $user = User::with('shop')->find($id);

        if (! $user) {
            return $this->errorResponse('User not found', 404);
        }

        return $this->successResponse($user, 'User details retrieved');
    }
}
