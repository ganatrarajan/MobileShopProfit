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

        $filter = $request->input('filter', 'all');
        if ($filter === 'with_due') {
            $query->where(function ($q) {
                $q->whereHas('sales', fn($s) => $s->where('amount_due', '>', 0))
                  ->orWhereHas('repairs', fn($r) => $r->where('amount_due', '>', 0));
            });
        } elseif ($filter === 'has_repairs') {
            $query->has('repairs');
        } elseif ($filter === 'has_sales') {
            $query->has('sales');
        }

        if ($city = $request->input('city')) {
            $query->where('city', 'like', "%{$city}%");
        }

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
            case 'due_desc':
                $query->orderByRaw('(COALESCE(sales_due, 0) + COALESCE(repairs_due, 0)) desc')->orderBy('name', 'asc');
                break;
            case 'newest':
            default:
                $query->orderBy('created_at', 'desc')->orderBy('id', 'desc');
                break;
        }

        if ($request->boolean('all') || $request->input('per_page') === 'all') {
            $allCustomers = $query->take(5000)->get();
            return response()->json([
                'success' => true,
                'message' => 'Customers retrieved successfully',
                'data'    => CustomerResource::collection($allCustomers),
                'meta'    => [
                    'current_page' => 1,
                    'last_page'    => 1,
                    'per_page'     => $allCustomers->count(),
                    'total'        => $allCustomers->count(),
                ],
            ]);
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

    /**
     * Download or retrieve sample CSV for importing customers.
     */
    public function sampleImport(Request $request)
    {
        $headers = [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename="customers_sample.csv"',
        ];

        $columns = ['Name', 'Mobile', 'Alternate_Mobile', 'Email', 'Address', 'City', 'Notes'];
        $dummyRows = [
            ['Rajesh Patel', '9876543210', '9876543211', 'rajesh.patel@example.com', 'Shop 4, Market Complex', 'Ahmedabad', 'Regular VIP customer'],
            ['Priya Sharma', '9123456780', '', 'priya.s@example.com', 'Flat 201, Royal Heights', 'Surat', 'Screen replacement inquiry'],
            ['Amit Kumar', '9988776655', '', '', 'Station Road, Near Tower', 'Vadodara', 'Walk-in customer'],
            ['Suresh Verma', '9822334455', '9822334456', 'suresh@verma.in', 'Plot 12, GIDC Phase 2', 'Rajkot', 'Corporate billing'],
        ];

        $callback = function () use ($columns, $dummyRows) {
            $file = fopen('php://output', 'w');
            fprintf($file, chr(0xEF).chr(0xBB).chr(0xBF)); // UTF-8 BOM
            fputcsv($file, $columns);
            foreach ($dummyRows as $row) {
                fputcsv($file, $row);
            }
            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }

    /**
     * Import customers via CSV file or JSON array.
     */
    public function import(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id;

        if (!$shopId) {
            return $this->errorResponse('No shop profile found for this owner', 400);
        }

        $rows = [];

        if ($request->hasFile('file')) {
            $file = $request->file('file');
            $handle = fopen($file->getRealPath(), 'r');
            if ($handle === false) {
                return $this->errorResponse('Unable to read uploaded file', 422);
            }

            // Remove BOM if present
            $bom = fread($handle, 3);
            if ($bom !== "\xEF\xBB\xBF") {
                rewind($handle);
            }

            $header = fgetcsv($handle);
            if (!$header) {
                fclose($handle);
                return $this->errorResponse('Uploaded file is empty', 422);
            }

            $normalizedHeader = array_map(function ($col) {
                return strtolower(trim(str_replace([' ', '-', '_'], '', $col)));
            }, $header);

            while (($data = fgetcsv($handle)) !== false) {
                if (empty(array_filter($data))) continue;
                $row = [];
                foreach ($normalizedHeader as $idx => $key) {
                    $val = isset($data[$idx]) ? trim($data[$idx]) : '';
                    if (in_array($key, ['name', 'customername'])) $row['name'] = $val;
                    elseif (in_array($key, ['mobile', 'phone', 'contact', 'mobilenumber', 'phonenumber'])) $row['mobile'] = $val;
                    elseif (in_array($key, ['alternatemobile', 'altmobile', 'alternatephone', 'secondmobile'])) $row['alternate_mobile'] = $val;
                    elseif (in_array($key, ['email', 'emailaddress'])) $row['email'] = $val;
                    elseif (in_array($key, ['address', 'customeraddress'])) $row['address'] = $val;
                    elseif (in_array($key, ['city'])) $row['city'] = $val;
                    elseif (in_array($key, ['notes', 'note', 'remark', 'remarks'])) $row['notes'] = $val;
                }
                if (!empty($row['name']) || !empty($row['mobile'])) {
                    $rows[] = $row;
                }
            }
            fclose($handle);
        } elseif ($request->has('customers') && is_array($request->input('customers'))) {
            $rows = $request->input('customers');
        }

        if (empty($rows)) {
            return $this->errorResponse('No valid customer rows found in the uploaded file.', 422);
        }

        $imported = 0;
        $updated = 0;
        $skipped = 0;
        $errors = [];

        foreach ($rows as $index => $row) {
            $lineNum = $index + 2;
            $name = trim($row['name'] ?? '');
            $rawMobile = trim($row['mobile'] ?? '');
            $cleanMobile = preg_replace('/\D/', '', $rawMobile);

            if (empty($name)) {
                $skipped++;
                $errors[] = "Row #$lineNum: Customer name is required.";
                continue;
            }

            if (empty($cleanMobile) || strlen($cleanMobile) < 10) {
                $skipped++;
                $errors[] = "Row #$lineNum ($name): Valid 10-digit mobile number required (got '$rawMobile').";
                continue;
            }

            $cleanAltMobile = !empty($row['alternate_mobile']) ? preg_replace('/\D/', '', $row['alternate_mobile']) : null;
            $email = !empty($row['email']) && filter_var($row['email'], FILTER_VALIDATE_EMAIL) ? $row['email'] : null;
            $address = !empty($row['address']) ? trim($row['address']) : null;
            $city = !empty($row['city']) ? trim($row['city']) : null;
            $notes = !empty($row['notes']) ? trim($row['notes']) : null;

            $existing = Customer::where('shop_id', $shopId)->where('mobile', $cleanMobile)->first();

            if ($existing) {
                $existing->update(array_filter([
                    'alternate_mobile' => $existing->alternate_mobile ?: $cleanAltMobile,
                    'email' => $existing->email ?: $email,
                    'address' => $existing->address ?: $address,
                    'city' => $existing->city ?: $city,
                    'notes' => $existing->notes ?: $notes,
                ]));
                $updated++;
            } else {
                Customer::create([
                    'shop_id' => $shopId,
                    'name' => $name,
                    'mobile' => $cleanMobile,
                    'alternate_mobile' => $cleanAltMobile,
                    'email' => $email,
                    'address' => $address,
                    'city' => $city,
                    'notes' => $notes,
                ]);
                $imported++;
            }
        }

        $total = count($rows);
        $message = "Import completed: $imported new added, $updated existing updated";
        if ($skipped > 0) {
            $message .= ", $skipped skipped.";
        } else {
            $message .= ".";
        }

        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => [
                'total' => $total,
                'imported' => $imported,
                'updated' => $updated,
                'skipped' => $skipped,
                'errors' => array_slice($errors, 0, 10),
            ],
        ]);
    }
}
