<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (!Schema::hasTable('plans')) {
            return;
        }

        // 1. Deactivate old legacy / unwanted plans on Live
        DB::table('plans')
            ->where(function ($q) {
                $q->where('name', 'like', '%Annual%')
                  ->orWhere('name', 'like', '%Mobile Profits%')
                  ->orWhere('price', 200.00)
                  ->orWhere('price', 250.00)
                  ->orWhere('price', 800.00)
                  ->orWhere('price', 999.00);
            })
            ->update([
                'status'     => 'inactive',
                'updated_at' => now(),
            ]);

        // 2. Update existing "Monthly Plan" (₹99) on Live to "Solo Owner (1 Month)"
        $monthlyPlan = DB::table('plans')
            ->where('billing_period', 'monthly')
            ->where('price', 99.00)
            ->first();

        if ($monthlyPlan) {
            DB::table('plans')->where('id', $monthlyPlan->id)->update([
                'name'               => 'Solo Owner (1 Month)',
                'price'              => 99.00,
                'billing_period'     => 'monthly',
                'max_staff_accounts' => 0,
                'sort_order'         => 1,
                'status'             => 'active',
                'updated_at'         => now(),
            ]);
        } else {
            DB::table('plans')->updateOrInsert(
                ['slug' => 'monthly-plan-monthly'],
                [
                    'name'               => 'Solo Owner (1 Month)',
                    'slug'               => 'monthly-plan-monthly',
                    'price'              => 99.00,
                    'billing_period'     => 'monthly',
                    'max_staff_accounts' => 0,
                    'sort_order'         => 1,
                    'status'             => 'active',
                    'created_at'         => now(),
                    'updated_at'         => now(),
                ]
            );
        }

        // 3. Update existing "3 Month Plan" (₹249) on Live to "Solo Owner (3 Months)"
        $threeMonthPlan = DB::table('plans')
            ->where('billing_period', '3_months')
            ->where('price', 249.00)
            ->first();

        if ($threeMonthPlan) {
            DB::table('plans')->where('id', $threeMonthPlan->id)->update([
                'name'               => 'Solo Owner (3 Months)',
                'price'              => 249.00,
                'billing_period'     => '3_months',
                'max_staff_accounts' => 0,
                'sort_order'         => 2,
                'status'             => 'active',
                'updated_at'         => now(),
            ]);
        } else {
            DB::table('plans')->updateOrInsert(
                ['slug' => '3-month-plan-3-months'],
                [
                    'name'               => 'Solo Owner (3 Months)',
                    'slug'               => '3-month-plan-3-months',
                    'price'              => 249.00,
                    'billing_period'     => '3_months',
                    'max_staff_accounts' => 0,
                    'sort_order'         => 2,
                    'status'             => 'active',
                    'created_at'         => now(),
                    'updated_at'         => now(),
                ]
            );
        }

        // 4. Update existing "6 Months Package" (₹499) on Live to "Solo Owner (6 Months)"
        $sixMonthPlan = DB::table('plans')
            ->where('billing_period', '6_months')
            ->where('price', 499.00)
            ->first();

        if ($sixMonthPlan) {
            DB::table('plans')->where('id', $sixMonthPlan->id)->update([
                'name'               => 'Solo Owner (6 Months)',
                'price'              => 499.00,
                'billing_period'     => '6_months',
                'max_staff_accounts' => 0,
                'sort_order'         => 3,
                'status'             => 'active',
                'updated_at'         => now(),
            ]);
        } else {
            DB::table('plans')->updateOrInsert(
                ['slug' => '6-months-package-6-months'],
                [
                    'name'               => 'Solo Owner (6 Months)',
                    'slug'               => '6-months-package-6-months',
                    'price'              => 499.00,
                    'billing_period'     => '6_months',
                    'max_staff_accounts' => 0,
                    'sort_order'         => 3,
                    'status'             => 'active',
                    'created_at'         => now(),
                    'updated_at'         => now(),
                ]
            );
        }

        // 5. Add / Ensure the 3 Staff & Technician Plans
        $staffPlans = [
            [
                'name'               => '1 Staff / Technician Plan',
                'slug'               => '1-technician-monthly',
                'price'              => 149.00,
                'max_staff_accounts' => 1,
                'billing_period'     => 'monthly',
                'sort_order'         => 4,
                'status'             => 'active',
            ],
            [
                'name'               => '2 Staff / Technicians Plan',
                'slug'               => '2-technicians-monthly',
                'price'              => 199.00,
                'max_staff_accounts' => 2,
                'billing_period'     => 'monthly',
                'sort_order'         => 5,
                'status'             => 'active',
            ],
            [
                'name'               => 'Pro Team Plan (Up to 5 Staff)',
                'slug'               => '5-technicians-monthly',
                'price'              => 249.00,
                'max_staff_accounts' => 5,
                'billing_period'     => 'monthly',
                'sort_order'         => 6,
                'status'             => 'active',
            ],
        ];

        foreach ($staffPlans as $sp) {
            DB::table('plans')->updateOrInsert(
                ['slug' => $sp['slug']],
                array_merge($sp, [
                    'created_at' => now(),
                    'updated_at' => now(),
                ])
            );
        }

        // 6. Ensure default staff addon rate setting exists
        if (Schema::hasTable('system_settings')) {
            DB::table('system_settings')->updateOrInsert(
                ['key' => 'staff_price_per_day'],
                [
                    'value'      => '2.00',
                    'created_at' => now(),
                    'updated_at' => now(),
                ]
            );
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
    }
};
