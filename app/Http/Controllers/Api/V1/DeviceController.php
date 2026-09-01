<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Device\CreateDeviceRequest;
use App\Http\Requests\Device\UpdateDeviceRequest;
use App\Http\Resources\DeviceResource;
use App\Models\Customer;
use App\Models\Device;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeviceController extends Controller
{
    use ApiResponse;

    /**
     * Get all devices belonging to a specific customer.
     */
    public function index(Request $request, Customer $customer): JsonResponse
    {
        $shopId = $request->user()->shop_id;
        if ($customer->shop_id !== $shopId) {
            return $this->errorResponse('Unauthorized access to customer devices.', 403);
        }

        $devices = $customer->devices()->where('shop_id', $shopId)->orderBy('created_at', 'desc')->get();

        return $this->successResponse(
            DeviceResource::collection($devices),
            'Customer devices retrieved successfully'
        );
    }

    public function indexForCustomer(Request $request, Customer $customer): JsonResponse
    {
        return $this->index($request, $customer);
    }

    /**
     * Store a new device for a specific customer.
     */
    public function store(CreateDeviceRequest $request, Customer $customer): JsonResponse
    {
        $shopId = $request->user()->shop_id;

        if (! $shopId) {
            return $this->errorResponse('No shop profile found for this owner', 400);
        }

        if ($customer->shop_id !== $shopId) {
            return $this->errorResponse('Unauthorized access to customer record.', 403);
        }

        // 1. Check IMEI 1 duplicate in current shop
        if ($request->filled('imei_1')) {
            $duplicate = Device::where('shop_id', $shopId)->where(function ($q) use ($request) {
                $q->where('imei_1', $request->imei_1)
                  ->orWhere('imei_2', $request->imei_1);
            })->first();

            if ($duplicate) {
                return response()->json([
                    'success' => false,
                    'message' => 'A device with IMEI ' . $request->imei_1 . ' already exists in your shop.',
                    'errors'  => [
                        'existing_device' => new DeviceResource($duplicate->load('customer')),
                    ],
                ], 409);
            }
        }

        // 2. Check IMEI 2 duplicate in current shop
        if ($request->filled('imei_2')) {
            $duplicate = Device::where('shop_id', $shopId)->where(function ($q) use ($request) {
                $q->where('imei_1', $request->imei_2)
                  ->orWhere('imei_2', $request->imei_2);
            })->first();

            if ($duplicate) {
                return response()->json([
                    'success' => false,
                    'message' => 'A device with IMEI ' . $request->imei_2 . ' already exists in your shop.',
                    'errors'  => [
                        'existing_device' => new DeviceResource($duplicate->load('customer')),
                    ],
                ], 409);
            }
        }

        $device = Device::create([
            'shop_id'       => $shopId,
            'customer_id'   => $customer->id,
            'device_type'   => $request->device_type,
            'brand'         => $request->brand,
            'model'         => $request->model,
            'variant'       => $request->variant,
            'color'         => $request->color,
            'imei_1'        => $request->imei_1,
            'imei_2'        => $request->imei_2,
            'serial_number' => $request->serial_number,
            'purchase_date' => $request->purchase_date,
            'notes'         => $request->notes,
        ]);

        return $this->successResponse(
            new DeviceResource($device->load('customer')),
            'Device registered successfully',
            201
        );
    }

    public function storeForCustomer(CreateDeviceRequest $request, Customer $customer): JsonResponse
    {
        return $this->store($request, $customer);
    }

    /**
     * Alias for search endpoint.
     */
    public function search(Request $request): JsonResponse
    {
        return $this->indexGlobal($request);
    }

    /**
     * Global device search (by IMEI, serial number, brand, model, customer name/mobile).
     */
    public function indexGlobal(Request $request): JsonResponse
    {
        $shopId = $request->user()->shop_id;
        $query = Device::where('shop_id', $shopId)->with('customer');

        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('imei_1', 'like', "%{$search}%")
                  ->orWhere('imei_2', 'like', "%{$search}%")
                  ->orWhere('serial_number', 'like', "%{$search}%")
                  ->orWhere('brand', 'like', "%{$search}%")
                  ->orWhere('model', 'like', "%{$search}%")
                  ->orWhereHas('customer', function ($cq) use ($search) {
                      $cq->where('name', 'like', "%{$search}%")
                        ->orWhere('mobile', 'like', "%{$search}%");
                  });
            });
        }

        $devices = $query->orderBy('created_at', 'desc')->paginate($request->input('per_page', 15));

        return response()->json([
            'success' => true,
            'message' => 'Devices retrieved successfully',
            'data'    => DeviceResource::collection($devices->items()),
            'meta'    => [
                'current_page' => $devices->currentPage(),
                'last_page'    => $devices->lastPage(),
                'per_page'     => $devices->perPage(),
                'total'        => $devices->total(),
            ],
        ]);
    }

    /**
     * Display single device details.
     */
    public function show(Request $request, Device $device): JsonResponse
    {
        $shopId = $request->user()->shop_id;
        if ($device->shop_id !== $shopId) {
            return $this->errorResponse('Unauthorized access to device record.', 403);
        }

        return $this->successResponse(
            new DeviceResource($device->load('customer')),
            'Device details retrieved successfully'
        );
    }

    /**
     * Update device details.
     */
    public function update(UpdateDeviceRequest $request, Device $device): JsonResponse
    {
        $shopId = $request->user()->shop_id;
        if ($device->shop_id !== $shopId) {
            return $this->errorResponse('Unauthorized access to device record.', 403);
        }

        // Check IMEI 1 duplicate
        if ($request->filled('imei_1') && $request->imei_1 !== $device->imei_1) {
            $duplicate = Device::where('shop_id', $shopId)
                ->where('id', '!=', $device->id)
                ->where(function ($q) use ($request) {
                    $q->where('imei_1', $request->imei_1)
                      ->orWhere('imei_2', $request->imei_1);
                })->first();

            if ($duplicate) {
                return response()->json([
                    'success' => false,
                    'message' => 'Another device in your shop already uses IMEI ' . $request->imei_1 . '.',
                    'errors'  => [
                        'existing_device' => new DeviceResource($duplicate->load('customer')),
                    ],
                ], 409);
            }
        }

        // Check IMEI 2 duplicate
        if ($request->filled('imei_2') && $request->imei_2 !== $device->imei_2) {
            $duplicate = Device::where('shop_id', $shopId)
                ->where('id', '!=', $device->id)
                ->where(function ($q) use ($request) {
                    $q->where('imei_1', $request->imei_2)
                      ->orWhere('imei_2', $request->imei_2);
                })->first();

            if ($duplicate) {
                return response()->json([
                    'success' => false,
                    'message' => 'Another device in your shop already uses IMEI ' . $request->imei_2 . '.',
                    'errors'  => [
                        'existing_device' => new DeviceResource($duplicate->load('customer')),
                    ],
                ], 409);
            }
        }

        $device->update($request->only([
            'device_type',
            'brand',
            'model',
            'variant',
            'color',
            'imei_1',
            'imei_2',
            'serial_number',
            'purchase_date',
            'notes',
        ]));

        return $this->successResponse(
            new DeviceResource($device->fresh()->load('customer')),
            'Device details updated successfully'
        );
    }

    /**
     * Delete device.
     */
    public function destroy(Request $request, Device $device): JsonResponse
    {
        $shopId = $request->user()->shop_id;
        if ($device->shop_id !== $shopId) {
            return $this->errorResponse('Unauthorized access to device record.', 403);
        }

        $device->delete();

        return $this->successResponse(null, 'Device deleted successfully');
    }

    /**
     * Get unique device brands from storage/app/public/device/devices.json
     */
    /**
     * Get unique device brands from storage/app/public/device/devices.json
     */
    public function getBrands(Request $request): JsonResponse
    {
        $jsonPath = storage_path('app/public/device/devices.json');

        if (! \Illuminate\Support\Facades\File::exists($jsonPath)) {
            return response()->json([
                'success' => false,
                'message' => 'devices.json not found',
                'data'    => [],
            ], 404);
        }

        $brands = \Illuminate\Support\Facades\Cache::remember('device_brands_list_v2', 86400, function () use ($jsonPath) {
            $content = \Illuminate\Support\Facades\File::get($jsonPath);
            $devices = json_decode($content, true) ?? [];

            $brandList = [];
            foreach ($devices as $key => $item) {
                if (is_array($item) && ! empty($item['brand'])) {
                    $brandList[] = trim($item['brand']);
                }
            }

            sort($brandList);
            return array_values(array_unique($brandList));
        });

        return response()->json([
            'success' => true,
            'message' => 'Brands retrieved successfully',
            'data'    => $brands,
        ]);
    }

    /**
     * Get device models for a specific brand from storage/app/public/device/devices.json
     */
    public function getModels(Request $request): JsonResponse
    {
        $brandName = $request->query('brand');

        if (! $brandName) {
            return response()->json([
                'success' => false,
                'message' => 'Brand parameter is required',
                'data'    => [],
            ], 400);
        }

        $jsonPath = storage_path('app/public/device/devices.json');

        if (! \Illuminate\Support\Facades\File::exists($jsonPath)) {
            return response()->json([
                'success' => false,
                'message' => 'devices.json not found',
                'data'    => [],
            ], 404);
        }

        $cacheKey = 'device_models_v2_' . md5(strtolower(trim($brandName)));

        $models = \Illuminate\Support\Facades\Cache::remember($cacheKey, 86400, function () use ($jsonPath, $brandName) {
            $content = \Illuminate\Support\Facades\File::get($jsonPath);
            $devices = json_decode($content, true) ?? [];

            $modelList = [];
            foreach ($devices as $key => $item) {
                if (is_array($item) && ! empty($item['brand']) && strcasecmp(trim($item['brand']), trim($brandName)) === 0) {
                    $modelVal = ! empty($item['name']) ? $item['name'] : (! empty($item['model']) ? $item['model'] : $key);
                    if (! empty($modelVal)) {
                        $modelList[] = trim($modelVal);
                    }
                }
            }

            sort($modelList);
            return array_values(array_unique($modelList));
        });

        return response()->json([
            'success' => true,
            'message' => 'Models retrieved successfully',
            'data'    => $models,
        ]);
    }
}