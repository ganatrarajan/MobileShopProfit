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
                  ->orWhere('mobile', 'like', "%{$search}%");
            });
        }

        $customers = $query->orderBy('name', 'asc')
            ->paginate($request->input('per_page', 15));

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

        $customer = Customer::create([
            'shop_id'          => $shopId,
            'name'             => $request->name,
            'mobile'           => $request->mobile,
            'alternate_mobile' => $request->alternate_mobile,
            'email'            => $request->email,
            'address'          => $request->address,
            'city'             => $request->city,
            'notes'            => $request->notes,
        ]);

        return $this->successResponse(new CustomerResource($customer), 'Customer created successfully', 201);
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

        $customer->update($request->only([
            'name',
            'mobile',
            'alternate_mobile',
            'email',
            'address',
            'city',
            'notes',
        ]));

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
