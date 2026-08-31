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
                  ->orWhere('mobile', 'like', "%{$search}%");
            });
        }

        if ($request->filled('role')) {
            $query->where('role', $request->role);
        }

        $perPage = (int) $request->input('per_page', 15);
        $users = $query->latest()->paginate($perPage);

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
