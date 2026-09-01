<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Models\SupportRequest;
use App\Models\SystemSetting;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminSupportController extends Controller
{
    use ApiResponse;

    /**
     * Get official support contact details (Public / Mobile App / Admin).
     */
    public function getContactInfo(): JsonResponse
    {
        $email = SystemSetting::getByKey('support_email', 'support@mobileprofits.com');
        $phone = SystemSetting::getByKey('support_phone', '+91 98765 43210');
        $hours = SystemSetting::getByKey('support_hours', 'Mon - Sat: 9:00 AM - 8:00 PM IST');

        return $this->successResponse([
            'support_email' => $email,
            'support_phone' => $phone,
            'support_hours' => $hours,
        ], 'Support contact information retrieved successfully');
    }

    /**
     * Save official support contact details (Admin Panel).
     */
    public function saveContactInfo(Request $request): JsonResponse
    {
        $request->validate([
            'support_email' => 'required|string|email',
            'support_phone' => 'required|string',
            'support_hours' => 'required|string',
        ]);

        SystemSetting::setKey('support_email', $request->support_email);
        SystemSetting::setKey('support_phone', $request->support_phone);
        SystemSetting::setKey('support_hours', $request->support_hours);

        if ($request->user()) {
            AdminAuditLog::create([
                'admin_id'    => $request->user()->id,
                'action'      => 'UPDATE_SUPPORT_CONTACT_INFO',
                'target_type' => 'SystemSetting',
                'target_id'   => null,
                'details'     => "Updated support contact details (Email: {$request->support_email}, Phone: {$request->support_phone}, Hours: {$request->support_hours})",
                'ip_address'  => $request->ip(),
            ]);
        }

        return $this->successResponse([
            'support_email' => $request->support_email,
            'support_phone' => $request->support_phone,
            'support_hours' => $request->support_hours,
        ], 'Support contact details updated successfully');
    }

    /**
     * Submit a support request / problem report / feedback (Shop Owner API).
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'type'     => 'required|string|in:contact,problem,feedback',
            'subject'  => 'nullable|string|max:255',
            'message'  => 'required|string',
            'rating'   => 'nullable|integer|min:1|max:5',
            'metadata' => 'nullable|array',
        ]);

        $user = $request->user();

        $support = SupportRequest::create([
            'shop_id'  => $user ? $user->shop_id : null,
            'user_id'  => $user ? $user->id : null,
            'type'     => $request->type,
            'subject'  => $request->subject,
            'message'  => $request->message,
            'rating'   => $request->rating,
            'metadata' => $request->metadata,
            'status'   => 'open',
        ]);

        return $this->successResponse($support, 'Support request submitted successfully', 201);
    }

    /**
     * Get paginated support tickets list for Admin.
     */
    public function index(Request $request): JsonResponse
    {
        $query = SupportRequest::with(['shop', 'user']);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('subject', 'like', "%{$search}%")
                  ->orWhere('message', 'like', "%{$search}%")
                  ->orWhereHas('shop', function ($sq) use ($search) {
                      $sq->where('name', 'like', "%{$search}%");
                  });
            });
        }

        $perPage = (int) $request->input('per_page', 15);
        $tickets = $query->latest()->paginate($perPage);

        return $this->successResponse($tickets, 'Support requests retrieved');
    }

    /**
     * Update support ticket status.
     */
    public function updateStatus(Request $request, $id): JsonResponse
    {
        $request->validate([
            'status' => 'required|string|in:open,in_progress,resolved',
        ]);

        $ticket = SupportRequest::find($id);

        if (! $ticket) {
            return $this->errorResponse('Support request not found', 404);
        }

        $oldStatus = $ticket->status;
        $ticket->update(['status' => $request->status]);

        // Audit Log
        AdminAuditLog::create([
            'admin_id'    => $request->user()->id,
            'action'      => 'UPDATE_SUPPORT_STATUS',
            'target_type' => 'SupportRequest',
            'target_id'   => $ticket->id,
            'details'     => "Updated ticket #{$ticket->id} status from {$oldStatus} to {$request->status}.",
            'ip_address'  => $request->ip(),
        ]);

        return $this->successResponse($ticket->fresh(['shop', 'user']), 'Support ticket status updated');
    }
}