<?php

namespace App\Http\Controllers;

use App\Models\Page;
use App\Models\SystemSetting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class PublicPageController extends Controller
{
    /**
     * Homepage - /
     */
    public function home()
    {
        $settings = Cache::remember('system_settings_map', 86400, function () {
            return SystemSetting::getAllAsMap();
        });

        $plans = Cache::remember('public_plans_list', 86400, function () {
            return DB::table('plans')
                ->where('status', 'active')
                ->orderBy('sort_order', 'asc')
                ->orderBy('price', 'asc')
                ->get();
        });

        $page = Cache::remember('page_home', 86400, function () {
            return Page::where('slug', 'home')->where('status', 'published')->first();
        });

        return view('public.home', compact('settings', 'plans', 'page'));
    }

    /**
     * Privacy Policy - /privacy-policy
     */
    public function privacyPolicy()
    {
        return $this->renderDynamicPage('privacy-policy', 'Privacy Policy');
    }

    /**
     * Terms & Conditions - /terms-and-conditions
     */
    public function termsAndConditions()
    {
        return $this->renderDynamicPage('terms-and-conditions', 'Terms & Conditions');
    }

    /**
     * Refund Policy - /refund-policy
     */
    public function refundPolicy()
    {
        return $this->renderDynamicPage('refund-policy', 'Refund & Cancellation Policy');
    }

    /**
     * Delete Account - /delete-account
     */
    public function deleteAccount()
    {
        $settings = Cache::remember('system_settings_map', 86400, function () {
            return SystemSetting::getAllAsMap();
        });

        $page = Cache::remember('page_delete-account', 86400, function () {
            return Page::where('slug', 'delete-account')->first();
        });

        return view('public.delete_account', compact('page', 'settings'));
    }

    /**
     * Contact Support Page - /contact
     */
    public function contact()
    {
        $settings = Cache::remember('system_settings_map', 86400, function () {
            return SystemSetting::getAllAsMap();
        });

        $page = Cache::remember('page_contact', 86400, function () {
            return Page::where('slug', 'contact')->first();
        });

        return view('public.contact', compact('settings', 'page'));
    }

    /**
     * Helper method to render dynamic pages
     */
    private function renderDynamicPage(string $slug, string $fallbackTitle)
    {
        $settings = Cache::remember('system_settings_map', 86400, function () {
            return SystemSetting::getAllAsMap();
        });

        $page = Cache::remember('page_' . $slug, 86400, function () use ($slug) {
            return Page::where('slug', $slug)->first();
        });

        if (!$page) {
            abort(404, 'Page not found.');
        }

        return view('public.page', compact('page', 'settings', 'fallbackTitle'));
    }
}
