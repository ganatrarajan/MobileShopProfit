<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Page;
use App\Models\SystemSetting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class AdminPageController extends Controller
{
    /**
     * List all pages in Admin Panel
     * GET /api/v1/admin/pages
     */
    public function index()
    {
        $pages = Page::orderBy('updated_at', 'desc')->get();

        return response()->json([
            'success' => true,
            'data'    => $pages,
        ]);
    }

    /**
     * Get single page by slug in Admin Panel
     * GET /api/v1/admin/pages/{slug}
     */
    public function show(string $slug)
    {
        $page = Page::where('slug', $slug)->first();

        if (!$page) {
            return response()->json([
                'success' => false,
                'message' => 'Page not found.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data'    => $page,
        ]);
    }

    /**
     * Update page content & status in Admin Panel
     * PUT /api/v1/admin/pages/{slug}
     */
    public function update(Request $request, string $slug)
    {
        $page = Page::where('slug', $slug)->first();

        if (!$page) {
            return response()->json([
                'success' => false,
                'message' => 'Page not found.',
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'title'            => 'required|string|max:255',
            'content'          => 'required|string',
            'meta_description' => 'nullable|string|max:500',
            'status'           => 'required|in:published,draft',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $page->update([
            'title'            => $request->input('title'),
            'content'          => $request->input('content'),
            'meta_description' => $request->input('meta_description'),
            'status'           => $request->input('status'),
        ]);

        // Invalidate Cache immediately so website & Flutter app get new content instantly
        Cache::forget('page_' . $slug);
        Cache::forget('public_pages_list');
        Cache::forget('page_home');

        return response()->json([
            'success' => true,
            'message' => 'Page updated and published successfully!',
            'data'    => $page,
        ]);
    }

    /**
     * Get System Settings in Admin Panel
     * GET /api/v1/admin/settings
     */
    public function getSettings()
    {
        $settings = SystemSetting::getAllAsMap();

        return response()->json([
            'success' => true,
            'data'    => $settings,
        ]);
    }

    /**
     * Update System Settings in Admin Panel
     * POST /api/v1/admin/settings
     */
    public function saveSettings(Request $request)
    {
        $data = $request->only([
            'app_name',
            'support_email',
            'support_phone',
            'whatsapp_number',
            'support_hours',
            'android_app_url',
            'ios_app_url',
            'copyright_text',
        ]);

        foreach ($data as $key => $value) {
            SystemSetting::setByKey($key, $value);
        }

        // Clear settings cache
        Cache::forget('system_settings_map');

        return response()->json([
            'success' => true,
            'message' => 'System settings updated successfully!',
            'data'    => SystemSetting::getAllAsMap(),
        ]);
    }
}
