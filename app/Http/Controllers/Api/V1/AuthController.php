<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\ForgotPasswordRequest;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Requests\Auth\ResetPasswordRequest;
use App\Http\Requests\Auth\UpdateProfileRequest;
use App\Http\Requests\Auth\VerifyOtpRequest;
use App\Models\PendingRegistration;
use App\Models\Shop;
use App\Models\User;
use App\Services\Msg91Service;
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
     * Initiate registration by storing payload and sending MSG91 OTP.
     */
    public function sendRegisterOtp(RegisterRequest $request, Msg91Service $msg91Service): JsonResponse
    {
        // 1. Generate 4-digit random OTP
        $otp = (string) random_int(1000, 9999);
        $expirySeconds = (int) config('services.msg91.otp_expiry', 300);

        // 2. Clear any previous pending registration for this mobile number
        PendingRegistration::where('mobile', $request->mobile)->delete();

        // 3. Create pending registration record
        $pending = PendingRegistration::create([
            'id'         => (string) Str::uuid(),
            'mobile'     => $request->mobile,
            'payload'    => [
                'name'      => $request->name,
                'mobile'    => $request->mobile,
                'email'     => $request->email,
                'shop_name' => $request->shop_name,
                'password'  => $request->password,
            ],
            'otp_code'   => Hash::make($otp),
            'expires_at' => now()->addSeconds($expirySeconds),
            'attempts'   => 0,
        ]);

        // 4. Send OTP via MSG91
        $smsResult = $msg91Service->sendOtp($request->mobile, $otp);

        if (! $smsResult['success']) {
            return $this->errorResponse($smsResult['message'], 500);
        }

        // Store req_id from MSG91 response for widget verification
        $payload = $pending->payload ?? [];
        $payload['req_id'] = $smsResult['req_id'] ?? null;
        $pending->update(['payload' => $payload]);

        return $this->successResponse([
            'verification_id'  => $pending->id,
            'mobile'           => $request->mobile,
            'cooldown_seconds' => (int) config('services.msg91.resend_cooldown', 60),
            'otp_debug'        => null,
        ], 'OTP sent successfully. Please check your mobile SMS.');
    }

    /**
     * Verify OTP and complete registration process (creating Shop & User).
     */
    public function verifyRegisterOtp(VerifyOtpRequest $request, Msg91Service $msg91Service): JsonResponse
    {
        $pending = PendingRegistration::find($request->verification_id);

        if (! $pending) {
            return $this->errorResponse('Registration session expired or invalid. Please submit signup again.', 422);
        }

        if ($pending->isExpired()) {
            return $this->errorResponse('OTP has expired. Please request a new OTP.', 422);
        }

        $maxAttempts = (int) config('services.msg91.max_attempts', 5);
        if ($pending->attempts >= $maxAttempts) {
            return $this->errorResponse('Maximum OTP attempts exceeded. Please request a new OTP.', 422);
        }

        $localValid = Hash::check($request->otp, $pending->otp_code);
        $reqId = $pending->payload['req_id'] ?? null;
        $msg91Result = $msg91Service->verifyOtp($pending->mobile, $request->otp, $reqId);

        if (! $localValid && ! $msg91Result['success']) {
            $pending->increment('attempts');
            $remaining = $maxAttempts - $pending->attempts;
            return $this->errorResponse("Invalid OTP. {$remaining} attempts remaining.", 422);
        }

        // OTP is valid! Execute existing DB Transaction to create Shop & User
        $payload = $pending->payload;

        return DB::transaction(function () use ($payload, $pending) {
            // 1. Create Shop Record
            $shop = Shop::create([
                'name'       => $payload['shop_name'],
                'owner_name' => $payload['name'],
                'phone'      => $payload['mobile'],
                'currency'   => 'INR',
                'status'     => 'active',
            ]);

            // 2. Create Owner User Record
            $user = User::create([
                'shop_id'  => $shop->id,
                'name'     => $payload['name'],
                'mobile'   => $payload['mobile'],
                'email'    => $payload['email'] ?? null,
                'phone'    => $payload['mobile'],
                'role'     => 'owner',
                'password' => Hash::make($payload['password']),
            ]);

            // 3. Issue Sanctum Bearer Token
            $token = $user->createToken('auth_token')->plainTextToken;

            // Delete pending registration after successful creation
            $pending->delete();

            return $this->successResponse([
                'token' => $token,
                'user'  => $user->fresh(),
                'shop'  => $shop,
            ], 'Shop and owner registered successfully via OTP verification', 201);
        });
    }

    /**
     * Resend OTP for pending registration.
     */
    public function resendRegisterOtp(Request $request, Msg91Service $msg91Service): JsonResponse
    {
        $request->validate([
            'verification_id' => 'required|string|uuid|exists:pending_registrations,id',
        ]);

        $pending = PendingRegistration::find($request->verification_id);

        if (! $pending) {
            return $this->errorResponse('Registration session expired. Please register again.', 422);
        }

        $cooldown = (int) config('services.msg91.resend_cooldown', 60);

        if ($pending->updated_at && $pending->updated_at->addSeconds($cooldown)->isFuture()) {
            $secondsRemaining = $pending->updated_at->addSeconds($cooldown)->diffInSeconds(now());
            return $this->errorResponse("Please wait {$secondsRemaining} seconds before requesting a new OTP.", 429);
        }

        // Generate new 4-digit OTP
        $otp = (string) random_int(1000, 9999);
        $expirySeconds = (int) config('services.msg91.otp_expiry', 300);

        $pending->update([
            'otp_code'   => Hash::make($otp),
            'expires_at' => now()->addSeconds($expirySeconds),
            'attempts'   => 0,
        ]);

        $smsResult = $msg91Service->sendOtp($pending->mobile, $otp);

        if (! $smsResult['success']) {
            return $this->errorResponse($smsResult['message'], 500);
        }

        $payload = $pending->payload ?? [];
        $payload['req_id'] = $smsResult['req_id'] ?? null;
        $pending->update(['payload' => $payload]);

        return $this->successResponse([
            'verification_id'  => $pending->id,
            'mobile'           => $pending->mobile,
            'cooldown_seconds' => $cooldown,
            'otp_debug'        => null,
        ], 'A new OTP has been sent to your mobile SMS.');
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
     * Send OTP for profile update when mobile number is changed.
     */
    public function sendProfileUpdateOtp(Request $request, Msg91Service $msg91Service): JsonResponse
    {
        $request->validate([
            'name'   => 'required|string|max:255',
            'mobile' => 'required|string|digits:10',
            'email'  => 'nullable|email|max:255',
        ]);

        $user = $request->user();

        // Check if mobile number is already taken by another user
        $existing = User::where(function ($q) use ($request) {
            $q->where('mobile', $request->mobile)
              ->orWhere('phone', $request->mobile);
        })->where('id', '!=', $user->id)->first();

        if ($existing) {
            return $this->errorResponse('This mobile number is already registered by another account.', 422);
        }

        // Generate 4-digit OTP
        $otp = (string) random_int(1000, 9999);
        $expirySeconds = (int) config('services.msg91.otp_expiry', 300);

        // Send OTP via MSG91
        $smsResult = $msg91Service->sendOtp($request->mobile, $otp);

        if (! $smsResult['success']) {
            return $this->errorResponse($smsResult['message'], 500);
        }

        // Store in pending_registrations
        PendingRegistration::where('mobile', $request->mobile)->delete();

        $pending = PendingRegistration::create([
            'id'         => (string) Str::uuid(),
            'mobile'     => $request->mobile,
            'payload'    => [
                'type'       => 'profile_update',
                'user_id'    => $user->id,
                'name'       => $request->name,
                'mobile'     => $request->mobile,
                'email'      => $request->email,
                'req_id'     => $smsResult['req_id'] ?? null,
            ],
            'otp_code'   => Hash::make($otp),
            'expires_at' => now()->addSeconds($expirySeconds),
            'attempts'   => 0,
        ]);

        return $this->successResponse([
            'verification_id'  => $pending->id,
            'mobile'           => $request->mobile,
            'cooldown_seconds' => (int) config('services.msg91.resend_cooldown', 60),
            'otp_debug'        => null,
        ], 'OTP sent successfully to your new mobile number.');
    }

    /**
     * Verify OTP and apply profile update (mobile, name, email).
     */
    public function verifyProfileUpdateOtp(VerifyOtpRequest $request, Msg91Service $msg91Service): JsonResponse
    {
        $pending = PendingRegistration::find($request->verification_id);

        if (! $pending) {
            return $this->errorResponse('Verification session expired or invalid. Please request OTP again.', 422);
        }

        if ($pending->isExpired()) {
            return $this->errorResponse('OTP has expired. Please request a new OTP.', 422);
        }

        $maxAttempts = (int) config('services.msg91.max_attempts', 5);
        if ($pending->attempts >= $maxAttempts) {
            return $this->errorResponse('Maximum OTP attempts exceeded. Please request a new OTP.', 422);
        }

        $localValid = Hash::check($request->otp, $pending->otp_code);
        $reqId = $pending->payload['req_id'] ?? null;
        $msg91Result = $msg91Service->verifyOtp($pending->mobile, $request->otp, $reqId);

        if (! $localValid && ! $msg91Result['success']) {
            $pending->increment('attempts');
            $remaining = $maxAttempts - $pending->attempts;
            return $this->errorResponse("Invalid OTP. {$remaining} attempts remaining.", 422);
        }

        $payload = $pending->payload;
        $user = $request->user();

        // Ensure user owns this profile update
        if (isset($payload['user_id']) && (string) $payload['user_id'] !== (string) $user->id) {
            return $this->errorResponse('Unauthorized profile verification session.', 403);
        }

        $newMobile = $payload['mobile'];

        // Update User & Shop records
        $user->update([
            'name'   => $payload['name'] ?? $user->name,
            'email'  => $payload['email'] ?? $user->email,
            'mobile' => $newMobile,
            'phone'  => $newMobile,
        ]);

        if ($user->shop) {
            $user->shop->update([
                'owner_name' => $payload['name'] ?? $user->shop->owner_name,
                'phone'      => $newMobile,
            ]);
        }

        $pending->delete();
        $user->load('shop');

        return $this->successResponse([
            'user' => $user,
            'shop' => $user->shop,
        ], 'Profile and mobile number updated successfully!');
    }

    /**
     * Send OTP for Forgot Password flow.
     */
    public function sendForgotPasswordOtp(Request $request, Msg91Service $msg91Service): JsonResponse
    {
        $request->validate([
            'mobile' => 'required|string',
        ]);

        $inputMobile = preg_replace('/[^0-9]/', '', $request->mobile);
        if (strlen($inputMobile) === 12 && str_starts_with($inputMobile, '91')) {
            $inputMobile = substr($inputMobile, 2);
        }

        $user = User::where('mobile', $inputMobile)
            ->orWhere('phone', $inputMobile)
            ->first();

        if (! $user) {
            return $this->errorResponse('No account found matching this mobile number.', 404);
        }

        $otp = (string) random_int(1000, 9999);
        $expirySeconds = (int) config('services.msg91.otp_expiry', 300);

        $smsResult = $msg91Service->sendOtp($user->mobile, $otp);

        if (! $smsResult['success']) {
            return $this->errorResponse($smsResult['message'], 500);
        }

        PendingRegistration::where('mobile', $user->mobile)->delete();

        $pending = PendingRegistration::create([
            'id'         => (string) Str::uuid(),
            'mobile'     => $user->mobile,
            'payload'    => [
                'type'    => 'forgot_password',
                'user_id' => $user->id,
                'req_id'  => $smsResult['req_id'] ?? null,
            ],
            'otp_code'   => Hash::make($otp),
            'expires_at' => now()->addSeconds($expirySeconds),
            'attempts'   => 0,
        ]);

        return $this->successResponse([
            'verification_id'  => $pending->id,
            'mobile'           => $user->mobile,
            'cooldown_seconds' => (int) config('services.msg91.resend_cooldown', 60),
            'otp_debug'        => null,
        ], 'OTP sent successfully. Please check your mobile SMS.');
    }

    /**
     * Verify OTP for Forgot Password flow.
     */
    public function verifyForgotPasswordOtp(VerifyOtpRequest $request, Msg91Service $msg91Service): JsonResponse
    {
        $pending = PendingRegistration::find($request->verification_id);

        if (! $pending) {
            return $this->errorResponse('Verification session expired or invalid. Please request OTP again.', 422);
        }

        if ($pending->isExpired()) {
            return $this->errorResponse('OTP has expired. Please request a new OTP.', 422);
        }

        $maxAttempts = (int) config('services.msg91.max_attempts', 5);
        if ($pending->attempts >= $maxAttempts) {
            return $this->errorResponse('Maximum OTP attempts exceeded. Please request a new OTP.', 422);
        }

        $localValid = Hash::check($request->otp, $pending->otp_code);
        $reqId = $pending->payload['req_id'] ?? null;
        $msg91Result = $msg91Service->verifyOtp($pending->mobile, $request->otp, $reqId);

        if (! $localValid && ! $msg91Result['success']) {
            $pending->increment('attempts');
            $remaining = $maxAttempts - $pending->attempts;
            return $this->errorResponse("Invalid OTP. {$remaining} attempts remaining.", 422);
        }

        // Mark session verified
        $pending->update(['verified_at' => now()]);

        return $this->successResponse([
            'verification_id' => $pending->id,
        ], 'OTP verified successfully! You may now set your new password.');
    }

    /**
     * Reset password using verified OTP verification_id.
     */
    public function resetPasswordWithOtp(Request $request): JsonResponse
    {
        $request->validate([
            'verification_id'       => 'required|string|uuid|exists:pending_registrations,id',
            'password'              => 'required|string|min:6|confirmed',
        ]);

        $pending = PendingRegistration::find($request->verification_id);

        if (! $pending || ! $pending->verified_at) {
            return $this->errorResponse('OTP verification session invalid or unverified. Please verify OTP first.', 422);
        }

        if ($pending->isExpired()) {
            return $this->errorResponse('Session has expired. Please request a new OTP.', 422);
        }

        $userId = $pending->payload['user_id'] ?? null;
        $user = User::find($userId);

        if (! $user) {
            return $this->errorResponse('User account not found.', 404);
        }

        $user->update([
            'password' => Hash::make($request->password),
        ]);

        // Revoke tokens & clear pending record
        $user->tokens()->delete();
        $pending->delete();

        return $this->successResponse(null, 'Password updated successfully. Please log in with your new password.');
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

