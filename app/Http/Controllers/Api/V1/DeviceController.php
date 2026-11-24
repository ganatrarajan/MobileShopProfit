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
        $query = Device::where('shop_id', $shopId)
            ->with('customer')
            ->withCount(['repairs', 'sales', 'warranties']);

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

        $devices = $query->orderBy('created_at', 'desc')->paginate($request->input('per_page', 25));

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

        $device->load([
            'customer',
            'repairs' => fn($q) => $q->orderBy('created_at', 'desc')->with('technician'),
            'sales' => fn($q) => $q->orderBy('sale_date', 'desc'),
            'warranties' => fn($q) => $q->orderBy('created_at', 'desc'),
        ])->loadCount(['repairs', 'sales', 'warranties']);

        return $this->successResponse(
            new DeviceResource($device),
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
     * Resolve master_catalog.json path across common server/cPanel deployment paths.
     */
    private function resolveMasterCatalogPath(): ?string
    {
        $candidates = [
            storage_path('app/public/device/master_catalog.json'),
            storage_path('app/public/Device/master_catalog.json'),
            public_path('storage/device/master_catalog.json'),
            public_path('storage/Device/master_catalog.json'),
            base_path('storage/app/public/device/master_catalog.json'),
            storage_path('app/device/master_catalog.json'),
            base_path('public_html/storage/device/master_catalog.json'),
        ];

        foreach ($candidates as $path) {
            if (\Illuminate\Support\Facades\File::exists($path)) {
                return $path;
            }
        }
        return null;
    }

    /**
     * Resolve legacy devices.json path across common server/cPanel deployment paths.
     */
    private function resolveLegacyDevicesPath(): ?string
    {
        $candidates = [
            storage_path('app/public/device/devices.json'),
            storage_path('app/public/Device/devices.json'),
            public_path('storage/device/devices.json'),
            public_path('storage/Device/devices.json'),
            base_path('storage/app/public/device/devices.json'),
            storage_path('app/device/devices.json'),
        ];

        foreach ($candidates as $path) {
            if (\Illuminate\Support\Facades\File::exists($path)) {
                return $path;
            }
        }
        return null;
    }

    /**
     * Get unique device brands from master catalog & devices.json.
     * Supports optional category filtering (e.g. ?category=watch, ?category=tablet, etc.)
     */
    public function getBrands(Request $request): JsonResponse
    {
        $rawCategory = strtolower(trim((string) $request->query('category', 'all')));
        $category = $rawCategory;
        if (in_array($category, ['phone', 'smartphone', 'mobiles'])) $category = 'mobile';
        if (in_array($category, ['watches', 'smartwatch', 'smartwatches', 'watch'])) $category = 'watch';
        if (in_array($category, ['tablets', 'ipad', 'ipads', 'tablet'])) $category = 'tablet';
        if (in_array($category, ['audio', 'earbuds', 'headphone', 'headphones', 'accessories'])) $category = 'audio';
        if (in_array($category, ['laptop', 'laptops', 'mac', 'macbook'])) $category = 'laptop';

        $cacheKey = 'device_brands_master_catalog_v6_' . md5($category);

        $loadBrands = function () use ($category) {
            $masterPath = $this->resolveMasterCatalogPath();
            $legacyPath = $this->resolveLegacyDevicesPath();

            $masterJson = [];
            $masterBrands = [];
            if ($masterPath && \Illuminate\Support\Facades\File::exists($masterPath)) {
                $masterJson = json_decode(\Illuminate\Support\Facades\File::get($masterPath), true) ?? [];
                if (! empty($masterJson['brands'])) {
                    foreach ($masterJson['brands'] as $bName => $bData) {
                        if ($category === 'all' || in_array($category, $bData['categories'] ?? [])) {
                            $masterBrands[] = $bName;
                        }
                    }
                }
            }

            // For phone/mobile/all, also merge in legacy brands from devices.json
            $legacyBrands = [];
            if (($category === 'all' || $category === 'mobile') && $legacyPath && \Illuminate\Support\Facades\File::exists($legacyPath)) {
                $content = \Illuminate\Support\Facades\File::get($legacyPath);
                $devices = json_decode($content, true) ?? [];
                foreach ($devices as $key => $item) {
                    if (is_array($item) && ! empty($item['brand'])) {
                        $legacyBrands[] = trim($item['brand']);
                    }
                }
            }

            // Read popular priority brands dynamically from master_catalog.json
            $popularOrder = [];
            if (! empty($masterJson['popular_brands'])) {
                $catKey = ($category === 'all') ? 'mobile' : $category;
                $popularOrder = $masterJson['popular_brands'][$catKey] ?? ($masterJson['popular_brands']['mobile'] ?? []);
            }

            $allBrands = array_merge($masterBrands, $legacyBrands);
            $uniqueMap = [];
            foreach ($allBrands as $b) {
                $lower = strtolower($b);
                if (! isset($uniqueMap[$lower])) {
                    $uniqueMap[$lower] = $b;
                }
            }

            // Order with popular brands first if they exist in catalog
            $orderedList = [];
            foreach ($popularOrder as $pop) {
                $lowerPop = strtolower($pop);
                if (isset($uniqueMap[$lowerPop])) {
                    $orderedList[] = $uniqueMap[$lowerPop];
                    unset($uniqueMap[$lowerPop]);
                }
            }

            $remaining = array_values($uniqueMap);
            sort($remaining, SORT_NATURAL | SORT_FLAG_CASE);

            return array_merge($orderedList, $remaining);
        };

        try {
            $brands = \Illuminate\Support\Facades\Cache::store('file')->remember($cacheKey, 86400, $loadBrands);
        } catch (\Throwable $e) {
            $brands = $loadBrands();
        }

        return response()->json([
            'success' => true,
            'message' => 'Brands retrieved successfully',
            'data'    => $brands,
        ]);
    }

    /**
     * Get device models for a specific brand from master catalog & devices.json.
     * Supports optional category filtering (e.g. ?brand=Apple&category=watch).
     */
    public function getModels(Request $request): JsonResponse
    {
        $brandName = trim((string) $request->query('brand'));
        $rawCategory = strtolower(trim((string) $request->query('category', 'all')));
        $category = $rawCategory;
        if (in_array($category, ['phone', 'smartphone', 'mobiles'])) $category = 'mobile';
        if (in_array($category, ['watches', 'smartwatch', 'smartwatches', 'watch'])) $category = 'watch';
        if (in_array($category, ['tablets', 'ipad', 'ipads', 'tablet'])) $category = 'tablet';
        if (in_array($category, ['audio', 'earbuds', 'headphone', 'headphones', 'accessories'])) $category = 'audio';
        if (in_array($category, ['laptop', 'laptops', 'mac', 'macbook'])) $category = 'laptop';

        if (! $brandName) {
            return response()->json([
                'success' => false,
                'message' => 'Brand parameter is required',
                'data'    => [],
            ], 400);
        }

        $cacheKey = 'device_models_master_catalog_v6_' . md5(strtolower($brandName) . '_' . $category);

        $loadModels = function () use ($brandName, $category) {
            $masterPath = $this->resolveMasterCatalogPath();
            $legacyPath = $this->resolveLegacyDevicesPath();

            $modelList = [];

            // 1. Check curated master catalog first
            if ($masterPath && \Illuminate\Support\Facades\File::exists($masterPath)) {
                $masterJson = json_decode(\Illuminate\Support\Facades\File::get($masterPath), true) ?? [];
                if (! empty($masterJson['brands'])) {
                    foreach ($masterJson['brands'] as $bName => $bData) {
                        if (strcasecmp($bName, $brandName) === 0 && ! empty($bData['models'])) {
                            if ($category !== 'all' && isset($bData['models'][$category])) {
                                $modelList = array_merge($modelList, $bData['models'][$category]);
                            } elseif ($category === 'all') {
                                foreach ($bData['models'] as $catList) {
                                    $modelList = array_merge($modelList, $catList);
                                }
                            }
                        }
                    }
                }
            }

            // 2. Also merge with legacy devices.json for broad Android compatibility (if category is all or mobile)
            if (($category === 'all' || $category === 'mobile') && $legacyPath && \Illuminate\Support\Facades\File::exists($legacyPath)) {
                $content = \Illuminate\Support\Facades\File::get($legacyPath);
                $devices = json_decode($content, true) ?? [];
                foreach ($devices as $key => $item) {
                    if (is_array($item) && ! empty($item['brand']) && strcasecmp(trim($item['brand']), $brandName) === 0) {
                        $modelVal = ! empty($item['name']) ? $item['name'] : (! empty($item['model']) ? $item['model'] : $key);
                        if (! empty($modelVal)) {
                            $modelList[] = trim($modelVal);
                        }
                    }
                }
            }

            // Deduplicate maintaining casing
            $uniqueMap = [];
            foreach ($modelList as $m) {
                $lower = strtolower($m);
                if (! isset($uniqueMap[$lower])) {
                    $uniqueMap[$lower] = $m;
                }
            }
            return array_values($uniqueMap);
        };

        try {
            $models = \Illuminate\Support\Facades\Cache::store('file')->remember($cacheKey, 86400, $loadModels);
        } catch (\Throwable $e) {
            $models = $loadModels();
        }

        return response()->json([
            'success' => true,
            'message' => 'Models retrieved successfully',
            'data'    => $models,
        ]);
    }
}