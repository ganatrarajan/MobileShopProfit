<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AdminAuthController extends Controller
{
    use ApiResponse;

    /**
     * Authenticate admin user.
     */
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'login'    => 'required|string',
            'password' => 'required|string',
        ]);

        $loginInput = $request->login;
        $fieldType = filter_var($loginInput, FILTER_VALIDATE_EMAIL) ? 'email' : 'mobile';

        $user = User::where($fieldType, $loginInput)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return $this->errorResponse('Invalid admin credentials', 401);
        }

        if (! in_array($user->role, ['admin', 'super_admin'])) {
            return $this->errorResponse('Access denied. Mobile shop user accounts cannot access the admin panel.', 403);
        }

        $token = $user->createToken('admin_token')->plainTextToken;

        return $this->successResponse([
            'token' => $token,
            'user'  => $user,
        ], 'Admin authenticated successfully');
    }

    /**
     * Get current admin profile.
     */
    public function me(Request $request): JsonResponse
    {
        return $this->successResponse([
            'user' => $request->user(),
        ], 'Admin profile retrieved');
    }

    /**
     * Change admin password.
     */
    public function changePassword(Request $request): JsonResponse
    {
        $request->validate([
            'current_password' => 'required|string',
            'password'         => 'required|string|min:6|confirmed',
        ]);

        $user = $request->user();

        if (! Hash::check($request->current_password, $user->password)) {
            return $this->errorResponse('Current password is incorrect', 422);
        }

        $user->update([
            'password' => Hash::make($request->password),
        ]);

        return $this->successResponse(null, 'Admin password changed successfully');
    }

    /**
     * Logout admin.
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return $this->successResponse(null, 'Admin logged out successfully');
    }
}
