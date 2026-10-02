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

    /**
     * Get App Version & Force Update Config in Admin Panel
     * GET /api/v1/admin/app-version
     */
    public function getAppVersion()
    {
        $settings = SystemSetting::getAllAsMap();

        return response()->json([
            'success' => true,
            'data'    => [
                'min_version'    => $settings['app_min_version'] ?? '1.0.0',
                'latest_version' => $settings['app_latest_version'] ?? '1.0.4',
                'force_update'   => filter_var($settings['app_force_update'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'update_url'     => $settings['app_update_url'] ?? 'https://play.google.com/store/apps',
                'update_title'   => $settings['app_update_title'] ?? 'Update Required',
                'update_message' => $settings['app_update_message'] ?? 'A critical update is available. Please update your app to continue using Mobile Shop Profit.',
            ],
        ]);
    }

    /**
     * Update App Version & Force Update Config in Admin Panel
     * POST /api/v1/admin/app-version
     */
    public function saveAppVersion(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'min_version'    => 'required|string|max:20',
            'latest_version' => 'required|string|max:20',
            'force_update'   => 'required',
            'update_url'     => 'nullable|string|max:500',
            'update_title'   => 'nullable|string|max:255',
            'update_message' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors'  => $validator->errors(),
            ], 422);
        }

        SystemSetting::setByKey('app_min_version', $request->input('min_version'));
        SystemSetting::setByKey('app_latest_version', $request->input('latest_version'));
        SystemSetting::setByKey('app_force_update', filter_var($request->input('force_update'), FILTER_VALIDATE_BOOLEAN) ? '1' : '0');
        SystemSetting::setByKey('app_update_url', $request->input('update_url', 'https://play.google.com/store/apps'));
        SystemSetting::setByKey('app_update_title', $request->input('update_title', 'Update Required'));
        SystemSetting::setByKey('app_update_message', $request->input('update_message', 'A critical update is available. Please update your app to continue.'));

        Cache::forget('public_app_version');
        Cache::forget('system_settings_map');

        return response()->json([
            'success' => true,
            'message' => 'App version & force update settings saved successfully!',
            'data'    => [
                'min_version'    => SystemSetting::getByKey('app_min_version', '1.0.0'),
                'latest_version' => SystemSetting::getByKey('app_latest_version', '1.0.4'),
                'force_update'   => filter_var(SystemSetting::getByKey('app_force_update', '0'), FILTER_VALIDATE_BOOLEAN),
                'update_url'     => SystemSetting::getByKey('app_update_url', 'https://play.google.com/store/apps'),
                'update_title'   => SystemSetting::getByKey('app_update_title', 'Update Required'),
                'update_message' => SystemSetting::getByKey('app_update_message', 'A critical update is available.'),
            ],
        ]);
    }
}

