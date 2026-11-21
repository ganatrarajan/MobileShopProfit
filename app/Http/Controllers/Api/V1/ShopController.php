<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Shop\CreateShopRequest;
use App\Http\Requests\Shop\UpdateShopRequest;
use App\Http\Requests\Shop\UploadLogoRequest;
use App\Http\Resources\ShopResource;
use App\Models\Plan;
use App\Models\Shop;
use App\Models\Subscription;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class ShopController extends Controller
{
    use ApiResponse;

    /**
     * Create a new shop profile for the authenticated owner.
     */
    public function store(CreateShopRequest $request): JsonResponse
    {
        $user = $request->user();

        return DB::transaction(function () use ($request, $user) {
            $logoPath = null;
            if ($request->hasFile('logo')) {
                $logoPath = $request->file('logo')->store('logos', 'public');
            }

            $trialExpiry = now()->addDays(30);

            $shop = Shop::create([
                'user_id'                  => $user->id,
                'name'                     => $request->name,
                'owner_name'               => $request->owner_name,
                'phone'                    => $request->mobile,
                'mobile'                   => $request->mobile,
                'email'                    => $request->email,
                'address'                  => $request->address,
                'city'                     => $request->city,
                'state'                    => $request->state,
                'pincode'                  => $request->pincode,
                'google_maps_url'          => $request->google_maps_url,
                'latitude'                 => $request->latitude,
                'longitude'                => $request->longitude,
                'upi_id'                   => $request->upi_id,
                'tagline'                  => $request->tagline,
                'gst_number'               => $request->gst_number,
                'logo'                     => $logoPath,
                'currency'                 => 'INR',
                'status'                   => 'active',
                'custom_max_staff'         => 1,
                'custom_staff_valid_until' => $trialExpiry->format('Y-m-d'),
                'custom_staff_note'        => 'Free Trial (1 Staff Login Included)',
            ]);

            $defaultPlan = Plan::where('slug', 'monthly')->first() ?? Plan::first();
            Subscription::create([
                'shop_id'        => $shop->id,
                'plan_id'        => $defaultPlan ? $defaultPlan->id : null,
                'status'         => 'trial',
                'start_date'     => now(),
                'expiry_date'    => $trialExpiry,
                'payment_status' => 'free',
            ]);

            // Link user to shop
            $user->update(['shop_id' => $shop->id]);

            return $this->successResponse(new ShopResource($shop), 'Shop created successfully', 201);
        });
    }

    /**
     * Display the authenticated user's shop profile.
     */
    public function show(Request $request): JsonResponse
    {
        $user = $request->user();
        $shop = $user->shop;

        if (! $shop && $user->shop_id) {
            $shop = Shop::find($user->shop_id);
        }

        if (! $shop) {
            return $this->errorResponse('No shop associated with this owner account', 404);
        }

        if (! $shop->user_id && $user->id) {
            $shop->user_id = $user->id;
            $shop->save();
        }
        $shop->loadMissing('user');

        return $this->successResponse(new ShopResource($shop), 'Shop profile retrieved successfully');
    }

    /**
     * Update the authenticated user's shop profile.
     */
    public function update(UpdateShopRequest $request): JsonResponse
    {
        $user = $request->user();
        $shop = $user->shop;

        if (! $shop && $user->shop_id) {
            $shop = Shop::find($user->shop_id);
        }

        if (! $shop) {
            return $this->errorResponse('Shop profile not found', 404);
        }

        $data = $request->only([
            'name',
            'owner_name',
            'phone',
            'email',
            'address',
            'city',
            'state',
            'pincode',
            'google_maps_url',
            'latitude',
            'longitude',
            'upi_id',
            'tagline',
            'terms_and_conditions',
            'gst_number',
            'currency',
        ]);

        // Support shop_phone or phone explicitly for shop contact number
        if ($request->filled('shop_phone')) {
            $data['phone'] = $request->input('shop_phone');
        } elseif ($request->filled('phone')) {
            $data['phone'] = $request->input('phone');
        }

        // Handle owner login mobile update directly
        $ownerMobile = $request->input('owner_mobile') ?? $request->input('mobile');
        if (!empty($ownerMobile) && trim((string)$ownerMobile) !== '') {
            $cleanedMobile = trim((string)$ownerMobile);
            $isOtpEnabled = filter_var(\App\Models\SystemSetting::getByKey('otp_verification_enabled', '1'), FILTER_VALIDATE_BOOLEAN);

            // If OTP is disabled or user already verified (or mobile unchanged), update user mobile
            if (! $isOtpEnabled || $user->mobile === $cleanedMobile) {
                $user->mobile = $cleanedMobile;
                $user->phone = $cleanedMobile;
                $user->save();
            }

            // If shop public phone is still empty, fallback to owner mobile
            if (empty($data['phone']) && empty($shop->phone)) {
                $data['phone'] = $cleanedMobile;
            }
        }

        // Sync user name with owner_name if provided
        if (!empty($data['owner_name'])) {
            $user->name = $data['owner_name'];
            $user->save();
        }

        // Process and save signature if provided
        if ($request->has('signature') || $request->has('signature_path') || $request->hasFile('signature')) {
            $data['signature_path'] = $this->processShopSignature($request, $request->input('signature') ?? $request->input('signature_path'));
        }

        // Ensure shop is linked to user
        if (! $shop->user_id) {
            $data['user_id'] = $user->id;
        }

        // Guard: filter out null values
        $data = array_filter($data, function ($value) {
            return $value !== null;
        });

        $shop->update($data);

        return $this->successResponse(new ShopResource($shop->fresh(['user'])), 'Shop profile updated successfully');
    }

    /**
     * Upload or update the shop logo image.
     */
    public function uploadLogo(UploadLogoRequest $request): JsonResponse
    {
        $user = $request->user();
        $shop = $user->shop;

        if (! $shop) {
            return $this->errorResponse('Shop profile not found', 404);
        }

        // Delete old logo if exists
        if ($shop->logo && Storage::disk('public')->exists($shop->logo)) {
            Storage::disk('public')->delete($shop->logo);
        }

        $logoPath = $request->file('logo')->store('logos', 'public');
        $shop->update(['logo' => $logoPath]);

        return $this->successResponse(new ShopResource($shop->fresh()), 'Shop logo uploaded successfully');
    }

    /**
     * Upload or update the shop signature image.
     */
    public function uploadSignature(Request $request): JsonResponse
    {
        $user = $request->user();
        $shop = $user->shop;

        if (! $shop) {
            return $this->errorResponse('Shop profile not found', 404);
        }

        if ($shop->signature_path && Storage::disk('public')->exists($shop->signature_path)) {
            Storage::disk('public')->delete($shop->signature_path);
        }

        $path = $this->processShopSignature($request, $request->input('signature'));
        $shop->update(['signature_path' => $path]);

        return $this->successResponse(new ShopResource($shop->fresh()), 'Shop signature uploaded successfully');
    }

    /**
     * Process shop signature from file upload or base64 data URL.
     */
    private function processShopSignature(Request $request, ?string $signatureInput): ?string
    {
        if ($request->hasFile('signature')) {
            return $request->file('signature')->store('signatures/shop', 'public');
        }

        if (!empty($signatureInput) && str_starts_with($signatureInput, 'data:image')) {
            try {
                $imageParts = explode(';base64,', $signatureInput);
                if (count($imageParts) === 2) {
                    $imageTypeAux = explode('image/', $imageParts[0]);
                    $imageType = $imageTypeAux[1] ?? 'png';
                    if (str_contains($imageType, '+')) {
                        $imageType = explode('+', $imageType)[0];
                    }
                    $imageBase64 = base64_decode($imageParts[1]);
                    $fileName = 'signatures/shop/shop_sig_' . uniqid() . '.' . $imageType;
                    Storage::disk('public')->put($fileName, $imageBase64);
                    return $fileName;
                }
            } catch (\Exception $e) {
                \Illuminate\Support\Facades\Log::warning('Shop signature save failed: ' . $e->getMessage());
            }
        }

        return $signatureInput;
    }
}
