<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Page;
use App\Models\SystemSetting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class PublicPageApiController extends Controller
{
    /**
     * Get Dynamic Legal / Content Page by Slug
     * GET /api/v1/public/pages/{slug}
     */
    public function getPage(string $slug)
    {
        $page = Cache::remember('page_' . $slug, 86400, function () use ($slug) {
            return Page::where('slug', $slug)->first();
        });

        if (!$page || $page->status !== 'published') {
            return response()->json([
                'success' => false,
                'message' => 'Page not found or unavailable.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data'    => [
                'id'               => $page->id,
                'slug'             => $page->slug,
                'title'            => $page->title,
                'meta_description' => $page->meta_description,
                'content'          => $page->content,
                'updated_at'       => $page->updated_at ? $page->updated_at->toIso8601String() : null,
            ],
        ]);
    }

    /**
     * Get All Public Pages List
     * GET /api/v1/public/pages
     */
    public function index()
    {
        $pages = Cache::remember('public_pages_list', 86400, function () {
            return Page::where('status', 'published')
                ->select(['id', 'slug', 'title', 'meta_description', 'updated_at'])
                ->get();
        });

        return response()->json([
            'success' => true,
            'data'    => $pages,
        ]);
    }

    /**
     * Get System Contact / Branding Settings
     * GET /api/v1/public/settings
     */
    public function getSettings()
    {
        $settings = Cache::remember('system_settings_map', 86400, function () {
            return SystemSetting::getAllAsMap();
        });

        return response()->json([
            'success' => true,
            'data'    => [
                'app_name'        => $settings['app_name'] ?? 'Mobile Profits',
                'support_email'   => $settings['support_email'] ?? 'support@mobileprofits.com',
                'support_phone'   => $settings['support_phone'] ?? '+91 98765 43210',
                'whatsapp_number' => $settings['whatsapp_number'] ?? '+91 98765 43210',
                'support_hours'   => $settings['support_hours'] ?? 'Mon - Sat: 9:00 AM - 8:00 PM IST',
                'android_app_url' => $settings['android_app_url'] ?? '#',
                'ios_app_url'     => $settings['ios_app_url'] ?? '#',
                'copyright_text'  => $settings['copyright_text'] ?? '© 2026 Mobile Profits. All rights reserved.',
            ],
        ]);
    }

    /**
     * Handle Public Account Deletion Request
     * POST /api/v1/public/delete-account-request
     */
    public function requestAccountDeletion(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'identifier' => 'required|string', // email or mobile
            'reason'     => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors'  => $validator->errors(),
            ], 422);
        }

        // Store request in support_requests table for admin review
        DB::table('support_requests')->insert([
            'type'       => 'account_deletion',
            'subject'    => 'Account Deletion Request: ' . $request->input('identifier'),
            'message'    => 'Account deletion requested for identifier: ' . $request->input('identifier') . "\nReason: " . ($request->input('reason') ?? 'N/A'),
            'status'     => 'open',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Your account deletion request has been registered. Our support team will process your request within 7 business days.',
        ]);
    }
}
