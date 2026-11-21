<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Customer\CreateCustomerRequest;
use App\Http\Requests\Customer\UpdateCustomerRequest;
use App\Http\Resources\CustomerResource;
use App\Models\Customer;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CustomerController extends Controller
{
    use ApiResponse;

    /**
     * List & search customers for the authenticated owner's shop.
     */
    public function index(Request $request): JsonResponse
    {
        $shopId = $request->user()->shop_id;

        if (! $shopId) {
            return $this->errorResponse('Owner does not have a shop registered yet', 400);
        }

        $query = Customer::where('shop_id', $shopId);

        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('mobile', 'like', "%{$search}%")
                  ->orWhere('alternate_mobile', 'like', "%{$search}%")
                  ->orWhere('city', 'like', "%{$search}%")
                  ->orWhere('address', 'like', "%{$search}%");
            });
        }

        $query->withCount(['repairs', 'sales', 'devices'])
            ->withSum('sales as sales_total', 'grand_total')
            ->withSum('sales as sales_due', 'amount_due')
            ->withSum('repairs as repairs_total', 'final_cost')
            ->withSum('repairs as repairs_due', 'amount_due');

        $sort = $request->input('sort', 'newest');
        switch ($sort) {
            case 'oldest':
                $query->orderBy('created_at', 'asc')->orderBy('id', 'asc');
                break;
            case 'name_asc':
                $query->orderBy('name', 'asc');
                break;
            case 'name_desc':
                $query->orderBy('name', 'desc');
                break;
            case 'newest':
            default:
                $query->orderBy('created_at', 'desc')->orderBy('id', 'desc');
                break;
        }

        $customers = $query->paginate($request->input('per_page', 15));

        return response()->json([
            'success' => true,
            'message' => 'Customers retrieved successfully',
            'data'    => CustomerResource::collection($customers->items()),
            'meta'    => [
                'current_page' => $customers->currentPage(),
                'last_page'    => $customers->lastPage(),
                'per_page'     => $customers->perPage(),
                'total'        => $customers->total(),
            ],
        ]);
    }

    /**
     * Store a new customer. Check duplicate mobile number per shop.
     */
    public function store(CreateCustomerRequest $request): JsonResponse
    {
        $shopId = $request->user()->shop_id;

        if (! $shopId) {
            return $this->errorResponse('No shop profile found for this owner', 400);
        }

        // Duplicate check within current shop
        $existingCustomer = Customer::where('shop_id', $shopId)->where('mobile', $request->mobile)->first();

        if ($existingCustomer) {
            return response()->json([
                'success' => false,
                'message' => 'Customer with this mobile number already exists in your shop.',
                'errors'  => [
                    'existing_customer' => new CustomerResource($existingCustomer),
                ],
            ], 409);
        }

        $signaturePath = $this->processSignature($request, $request->input('signature') ?? $request->input('signature_path'));

        $customer = Customer::create([
            'shop_id'          => $shopId,
            'name'             => $request->name,
            'mobile'           => $request->mobile,
            'alternate_mobile' => $request->alternate_mobile,
            'email'            => $request->email,
            'address'          => $request->address,
            'city'             => $request->city,
            'notes'            => $request->notes,
            'signature_path'   => $signaturePath,
        ]);

        return $this->successResponse(new CustomerResource($customer), 'Customer created successfully', 201);
    }

    /**
     * Process and store signature from file upload or base64 data URL.
     */
    private function processSignature(Request $request, $signatureInput = null): ?string
    {
        if ($request->hasFile('signature')) {
            return $request->file('signature')->store('signatures/customers', 'public');
        }

        if (!empty($signatureInput) && is_string($signatureInput) && str_starts_with($signatureInput, 'data:image')) {
            try {
                $imageParts = explode(';base64,', $signatureInput);
                if (count($imageParts) === 2) {
                    $imageTypeAux = explode('image/', $imageParts[0]);
                    $imageType = $imageTypeAux[1] ?? 'png';
                    if (str_contains($imageType, '+')) {
                        $imageType = explode('+', $imageType)[0];
                    }
                    $imageBase64 = base64_decode($imageParts[1]);
                    $fileName = 'signatures/customers/cust_sig_' . uniqid() . '.' . $imageType;
                    \Illuminate\Support\Facades\Storage::disk('public')->put($fileName, $imageBase64);
                    return $fileName;
                }
            } catch (\Exception $e) {
                \Illuminate\Support\Facades\Log::warning('Customer signature save failed: ' . $e->getMessage());
            }
        }

        return is_string($signatureInput) ? $signatureInput : null;
    }

    /**
     * Display customer details.
     */
    public function show(Request $request, Customer $customer): JsonResponse
    {
        $shopId = $request->user()->shop_id;
        if ($customer->shop_id !== $shopId) {
            return $this->errorResponse('Unauthorized access to customer record.', 403);
        }

        $customer->loadCount(['repairs', 'sales', 'devices']);
        $customer->load([
            'repairs' => fn($q) => $q->latest()->take(50),
            'sales' => fn($q) => $q->latest()->take(50),
            'devices' => fn($q) => $q->latest()->take(50),
            'warranties' => fn($q) => $q->latest()->take(50),
        ]);

        return $this->successResponse(new CustomerResource($customer), 'Customer details retrieved successfully');
    }

    /**
     * Update customer details.
     */
    public function update(UpdateCustomerRequest $request, Customer $customer): JsonResponse
    {
        $shopId = $request->user()->shop_id;
        if ($customer->shop_id !== $shopId) {
            return $this->errorResponse('Unauthorized access to customer record.', 403);
        }

        // If mobile is being updated, check duplicate in same shop
        if ($request->has('mobile') && $request->mobile !== $customer->mobile) {
            $duplicate = Customer::where('shop_id', $shopId)
                ->where('mobile', $request->mobile)
                ->where('id', '!=', $customer->id)
                ->first();

            if ($duplicate) {
                return response()->json([
                    'success' => false,
                    'message' => 'Another customer in your shop already uses this mobile number.',
                    'data'    => [
                        'existing_customer' => new CustomerResource($duplicate),
                    ],
                ], 409);
            }
        }

        $updateData = $request->only([
            'name',
            'mobile',
            'alternate_mobile',
            'email',
            'address',
            'city',
            'notes',
        ]);

        if ($request->has('signature') || $request->has('signature_path') || $request->hasFile('signature')) {
            $updateData['signature_path'] = $this->processSignature($request, $request->input('signature') ?? $request->input('signature_path'));
        }

        $customer->update($updateData);

        return $this->successResponse(new CustomerResource($customer->fresh()), 'Customer details updated successfully');
    }

    /**
     * Delete customer.
     */
    public function destroy(Request $request, Customer $customer): JsonResponse
    {
        $shopId = $request->user()->shop_id;
        if ($customer->shop_id !== $shopId) {
            return $this->errorResponse('Unauthorized access to customer record.', 403);
        }

        $customer->delete();

        return $this->successResponse(null, 'Customer deleted successfully');
    }
}
