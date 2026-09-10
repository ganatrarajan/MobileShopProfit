<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Technician;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminTechnicianController extends Controller
{
    use ApiResponse;

    /**
     * Get paginated technicians across all shops with search and filters.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Technician::withoutGlobalScope('shop')->with(['shop']);

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('mobile', 'like', "%{$search}%")
                  ->orWhere('specialization', 'like', "%{$search}%")
                  ->orWhereHas('shop', function ($sq) use ($search) {
                      $sq->where('name', 'like', "%{$search}%");
                  });
            });
        }

        if ($request->filled('shop_id')) {
            $query->where('shop_id', $request->shop_id);
        }

        $perPage = (int) $request->input('per_page', 15);
        $technicians = $query->latest()->paginate($perPage);

        // Attach computed metrics
        $technicians->getCollection()->transform(function ($tech) {
            $data = $tech->toArray();
            $data['total_jobs_count'] = $tech->total_jobs_count;
            $data['completed_jobs_count'] = $tech->completed_jobs_count;
            $data['total_earnings'] = $tech->total_earnings;
            $data['total_paid'] = $tech->total_paid;
            $data['total_payable'] = $tech->total_payable;
            return $data;
        });

        return $this->successResponse($technicians, 'Technicians list retrieved');
    }
}
