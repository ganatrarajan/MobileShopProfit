<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminAuditLogController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $perPage = (int) $request->input('per_page', 20);
        $logs = AdminAuditLog::with('admin')->latest()->paginate($perPage);

        return $this->successResponse($logs, 'Admin audit logs retrieved');
    }
}
