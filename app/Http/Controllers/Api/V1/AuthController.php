<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\ForgotPasswordRequest;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Requests\Auth\ResetPasswordRequest;
use App\Http\Requests\Auth\UpdateProfileRequest;
use App\Models\Shop;
use App\Models\User;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    use ApiResponse;

    /**
     * Register a new shop owner and shop profile.
     */
    public function register(RegisterRequest $request): JsonResponse
    {
        return DB::transaction(function () use ($request) {
            // 1. Create Shop Record
            $shop = Shop::create([
                'name'       => $request->shop_name,
                'owner_name' => $request->name,
                'phone'      => $request->mobile,
                'currency'   => 'INR',
                'status'     => 'active',
            ]);

            // 2. Create Owner User Record
            $user = User::create([
                'shop_id'  => $shop->id,
                'name'     => $request->name,
                'mobile'   => $request->mobile,
                'email'    => $request->email,
                'phone'    => $request->mobile,
                'role'     => 'owner',
                'password' => Hash::make($request->password),
            ]);

            // 3. Issue Sanctum Bearer Token
            $token = $user->createToken('auth_token')->plainTextToken;

            return $this->successResponse([
                'token' => $token,
                'user'  => $user->fresh(),
                'shop'  => $shop,
            ], 'Shop and owner registered successfully', 201);
        });
    }

    /**
     * Authenticate shop owner via mobile number or email.
     */
    public function login(LoginRequest $request): JsonResponse
    {
        $loginInput = $request->login;

        // Determine if login input is email or mobile number
        $fieldType = filter_var($loginInput, FILTER_VALIDATE_EMAIL) ? 'email' : 'mobile';

        $user = User::where($fieldType, $loginInput)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return $this->errorResponse('Invalid mobile/email or password', 401);
        }

        // Check if shop account has been deactivated by SaaS Admin
        if (! in_array($user->role, ['admin', 'super_admin'])) {
            if ($user->shop && in_array(strtolower($user->shop->status), ['deactivated', 'inactive', 'suspended'])) {
                return $this->errorResponse('Your shop account has been deactivated. Please contact support.', 403);
            }
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return $this->successResponse([
            'token' => $token,
            'user'  => $user,
            'shop'  => $user->shop,
        ], 'Logged in successfully');
    }

    /**
     * Get authenticated owner profile and shop details.
     */
    public function me(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->load('shop');

        return $this->successResponse([
            'user' => $user,
            'shop' => $user->shop,
        ], 'Profile retrieved successfully');
    }

    /**
     * Update basic owner profile details.
     */
    public function updateProfile(UpdateProfileRequest $request): JsonResponse
    {
        $user = $request->user();

        $user->update($request->only([
            'name',
            'mobile',
            'email',
            'phone',
        ]));

        return $this->successResponse($user->fresh(), 'Profile updated successfully');
    }

    /**
     * Request password reset token.
     */
    public function forgotPassword(ForgotPasswordRequest $request): JsonResponse
    {
        $loginInput = $request->login;
        $fieldType = filter_var($loginInput, FILTER_VALIDATE_EMAIL) ? 'email' : 'mobile';

        $user = User::where($fieldType, $loginInput)
            ->orWhere('mobile', $loginInput)
            ->orWhere('phone', $loginInput)
            ->first();

        if (! $user) {
            return $this->errorResponse('No account found matching this mobile number or email', 404);
        }

        if ($request->filled('password')) {
            $user->update([
                'password' => Hash::make($request->password),
            ]);
            $user->tokens()->delete();

            return $this->successResponse(null, 'Password updated successfully. Please log in with your new password.');
        }

        return $this->successResponse(null, 'Mobile/email account verified. Please enter new password.');
    }

    /**
     * Reset password using reset token.
     */
    public function resetPassword(ResetPasswordRequest $request): JsonResponse
    {
        $loginInput = $request->login;

        $record = DB::table('password_reset_tokens')
            ->where('email_or_mobile', $loginInput)
            ->first();

        if (! $record || ! Hash::check($request->token, $record->token)) {
            return $this->errorResponse('Invalid or expired password reset token', 400);
        }

        $fieldType = filter_var($loginInput, FILTER_VALIDATE_EMAIL) ? 'email' : 'mobile';
        $user = User::where($fieldType, $loginInput)->first();

        if (! $user) {
            return $this->errorResponse('User not found', 404);
        }

        $user->update([
            'password' => Hash::make($request->password),
        ]);

        // Delete reset token record
        DB::table('password_reset_tokens')->where('email_or_mobile', $loginInput)->delete();

        // Revoke existing API tokens
        $user->tokens()->delete();

        return $this->successResponse(null, 'Password reset successfully. Please log in with your new password.');
    }

    /**
     * Revoke current API token.
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return $this->successResponse(null, 'Logged out successfully');
    }

    /**
     * Change password for the authenticated shop owner.
     */
    public function changePassword(Request $request): JsonResponse
    {
        $request->validate([
            'current_password'      => 'required|string',
            'password'              => 'required|string|min:6|confirmed',
        ]);

        $user = $request->user();

        if (! Hash::check($request->current_password, $user->password)) {
            return $this->errorResponse('Current password is incorrect', 422);
        }

        $user->update([
            'password' => Hash::make($request->password),
        ]);

        return $this->successResponse(null, 'Password updated successfully');
    }
}

