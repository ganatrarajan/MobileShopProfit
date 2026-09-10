<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Repair;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminRepairController extends Controller
{
    use ApiResponse;

    /**
     * Get paginated repair jobs list across all shops with search and filters.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Repair::withoutGlobalScope('shop')->with(['shop', 'customer', 'device', 'technician']);

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('job_number', 'like', "%{$search}%")
                  ->orWhere('problem_description', 'like', "%{$search}%")
                  ->orWhereHas('customer', function ($cq) use ($search) {
                      $cq->where('name', 'like', "%{$search}%")
                         ->orWhere('mobile', 'like', "%{$search}%");
                  })
                  ->orWhereHas('device', function ($dq) use ($search) {
                      $dq->where('brand', 'like', "%{$search}%")
                        ->orWhere('model', 'like', "%{$search}%");
                  })
                  ->orWhereHas('shop', function ($sq) use ($search) {
                      $sq->where('name', 'like', "%{$search}%");
                  });
            });
        }

        if ($request->filled('shop_id')) {
            $query->where('shop_id', $request->shop_id);
        }

        if ($request->filled('status')) {
            $query->where('repair_status', $request->status);
        }

        if ($request->filled('date_from')) {
            $query->whereDate('date_received', '>=', $request->date_from);
        }

        if ($request->filled('date_to')) {
            $query->whereDate('date_received', '<=', $request->date_to);
        }

        // Summary stats for filtered repairs
        $totalCount = (clone $query)->count();
        $pendingCount = (clone $query)->whereIn('repair_status', ['received', 'diagnosing', 'waiting_customer', 'waiting_parts', 'pending_approval'])->count();
        $inProgressCount = (clone $query)->whereIn('repair_status', ['repairing', 'in_progress'])->count();
        $completedCount = (clone $query)->whereIn('repair_status', ['ready', 'delivered'])->count();
        $totalCost = (float) (clone $query)->selectRaw('SUM(CASE WHEN final_cost > 0 THEN final_cost ELSE estimated_cost END) as total_val')->value('total_val');
        $totalPaid = (float) (clone $query)->sum('amount_paid');

        $perPage = (int) $request->input('per_page', 15);
        $repairs = $query->latest('date_received')->paginate($perPage);

        $responseData = $repairs->toArray();
        $responseData['summary'] = [
            'total_count'       => $totalCount,
            'pending_count'     => $pendingCount,
            'in_progress_count' => $inProgressCount,
            'completed_count'   => $completedCount,
            'total_cost'        => round($totalCost, 2),
            'total_paid'        => round($totalPaid, 2),
        ];

        return $this->successResponse($responseData, 'Repairs list retrieved');
    }

    /**
     * Get single repair job details.
     */
    public function show($id): JsonResponse
    {
        $repair = Repair::withoutGlobalScope('shop')
            ->with(['shop', 'customer', 'device', 'technician', 'parts', 'payments', 'creator'])
            ->find($id);

        if (! $repair) {
            return $this->errorResponse('Repair job card not found', 404);
        }

        return $this->successResponse($repair, 'Repair job details retrieved');
    }
}
