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

        return $this->successResponse(new ShopResource($shop), 'Shop profile retrieved successfully');
    }

    /**
     * Update the authenticated user's shop profile.
     */
    public function update(UpdateShopRequest $request): JsonResponse
    {
        $user = $request->user();
        $shop = $user->shop;

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
            'gst_number',
            'currency',
        ]);

        // Map 'mobile' to database column 'phone' if 'phone' was not provided
        if (empty($data['phone']) && $request->filled('mobile')) {
            $data['phone'] = $request->input('mobile');
        }

        // Guard: filter out null/empty values for core identity attributes so partial updates never overwrite existing shop data
        $data = array_filter($data, function ($value, $key) {
            $requiredCore = ['name', 'owner_name', 'phone', 'address', 'city', 'state', 'pincode'];
            if (in_array($key, $requiredCore, true)) {
                return $value !== null && trim((string)$value) !== '';
            }
            return $value !== null;
        }, ARRAY_FILTER_USE_BOTH);

        $shop->update($data);

        return $this->successResponse(new ShopResource($shop->fresh()), 'Shop profile updated successfully');
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
}
