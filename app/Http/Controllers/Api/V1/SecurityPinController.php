<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class SecurityPinController extends Controller
{
    /**
     * Get current user's security PIN status.
     */
    public function status(Request $request): JsonResponse
    {
        $user = $request->user();
        return response()->json([
            'success' => true,
            'data' => [
                'has_security_pin' => !empty($user->security_pin),
            ],
        ]);
    }

    /**
     * First time setup of Security PIN.
     * Requires login password + new 4-digit PIN + confirmation.
     */
    public function setup(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->role !== 'owner') {
            return response()->json([
                'success' => false,
                'message' => 'Only the shop owner can configure a security PIN.',
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'password' => ['required', 'string'],
            'pin' => ['required', 'digits:4'],
            'pin_confirmation' => ['required', 'same:pin'],
        ], [
            'password.required' => 'Login password is required to set security PIN.',
            'pin.digits' => 'Security PIN must be exactly 4 digits.',
            'pin_confirmation.same' => 'PIN confirmation does not match.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
                'errors' => $validator->errors(),
            ], 422);
        }

        if (!Hash::check($request->input('password'), $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Current login password is incorrect.',
            ], 422);
        }

        $user->security_pin = Hash::make($request->input('pin'));
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Security PIN created successfully.',
            'data' => [
                'has_security_pin' => true,
            ],
        ]);
    }

    /**
     * Update existing Security PIN.
     * Requires old PIN + new 4-digit PIN + confirmation.
     */
    public function update(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->role !== 'owner') {
            return response()->json([
                'success' => false,
                'message' => 'Only the shop owner can manage the security PIN.',
            ], 403);
        }

        if (empty($user->security_pin)) {
            return response()->json([
                'success' => false,
                'message' => 'No security PIN has been set yet. Please use setup instead.',
            ], 422);
        }

        $validator = Validator::make($request->all(), [
            'current_pin' => ['required', 'digits:4'],
            'pin' => ['required', 'digits:4'],
            'pin_confirmation' => ['required', 'same:pin'],
        ], [
            'current_pin.required' => 'Current security PIN is required.',
            'current_pin.digits' => 'Current security PIN must be 4 digits.',
            'pin.digits' => 'New security PIN must be exactly 4 digits.',
            'pin_confirmation.same' => 'PIN confirmation does not match.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
                'errors' => $validator->errors(),
            ], 422);
        }

        if (!Hash::check($request->input('current_pin'), $user->security_pin)) {
            return response()->json([
                'success' => false,
                'message' => 'Current security PIN is incorrect.',
            ], 422);
        }

        $user->security_pin = Hash::make($request->input('pin'));
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Security PIN updated successfully.',
            'data' => [
                'has_security_pin' => true,
            ],
        ]);
    }

    /**
     * Forgot PIN reset.
     * Requires login password + new 4-digit PIN + confirmation.
     */
    public function forgot(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->role !== 'owner') {
            return response()->json([
                'success' => false,
                'message' => 'Only the shop owner can manage the security PIN.',
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'password' => ['required', 'string'],
            'pin' => ['required', 'digits:4'],
            'pin_confirmation' => ['required', 'same:pin'],
        ], [
            'password.required' => 'Login password is required to reset security PIN.',
            'pin.digits' => 'Security PIN must be exactly 4 digits.',
            'pin_confirmation.same' => 'PIN confirmation does not match.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
                'errors' => $validator->errors(),
            ], 422);
        }

        if (!Hash::check($request->input('password'), $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Login password is incorrect.',
            ], 422);
        }

        $user->security_pin = Hash::make($request->input('pin'));
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Security PIN reset successfully.',
            'data' => [
                'has_security_pin' => true,
            ],
        ]);
    }

    /**
     * Verify security PIN without performing an action.
     */
    public function verify(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->role !== 'owner') {
            return response()->json([
                'success' => false,
                'message' => 'Only shop admin can use security PIN.',
            ], 403);
        }

        if (empty($user->security_pin)) {
            return response()->json([
                'success' => false,
                'message' => 'No security PIN has been set yet.',
                'requires_pin_setup' => true,
            ], 422);
        }

        $pin = $request->input('pin');
        if (empty($pin)) {
            return response()->json([
                'success' => false,
                'message' => 'PIN is required.',
            ], 422);
        }

        if (!Hash::check($pin, $user->security_pin)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid Security PIN.',
            ], 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Security PIN verified successfully.',
            'data' => [
                'valid' => true,
            ],
        ]);
    }
}
