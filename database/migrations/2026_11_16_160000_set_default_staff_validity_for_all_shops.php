<?php

use App\Models\Plan;
use App\Models\Shop;
use App\Models\Subscription;
use Carbon\Carbon;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    public function up(): void
    {
        $shops = Shop::with('latestSubscription')->get();
        $defaultPlan = Plan::where('slug', 'monthly')->first() ?? Plan::first();

        foreach ($shops as $shop) {
            $sub = $shop->latestSubscription;
            $expiry = null;

            if ($sub && $sub->expiry_date) {
                $expiry = Carbon::parse($sub->expiry_date);
            } elseif ($shop->created_at) {
                $expiry = Carbon::parse($shop->created_at)->addDays(30);
            } else {
                $expiry = now()->addDays(30);
            }

            // Ensure trial subscription exists
            if (!$sub) {
                Subscription::create([
                    'shop_id'        => $shop->id,
                    'plan_id'        => $defaultPlan ? $defaultPlan->id : null,
                    'status'         => 'trial',
                    'start_date'     => $shop->created_at ?? now(),
                    'expiry_date'    => $expiry,
                    'payment_status' => 'free',
                ]);
            }

            // Set default staff limit and expiry date if not already set
            if (!$shop->custom_staff_valid_until) {
                $shop->update([
                    'custom_max_staff'         => $shop->custom_max_staff ?? 1,
                    'custom_staff_valid_until' => $expiry->format('Y-m-d'),
                    'custom_staff_note'        => $shop->custom_staff_note ?: 'Free Trial (1 Staff Login Included)',
                ]);
            }
        }
    }

    public function down(): void
    {
        // No down migration needed
    }
};

