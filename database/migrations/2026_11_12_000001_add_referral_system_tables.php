<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('shops', function (Blueprint $table) {
            if (!Schema::hasColumn('shops', 'referral_code')) {
                $table->string('referral_code', 24)->unique()->nullable()->after('status');
            }
            if (!Schema::hasColumn('shops', 'referred_by_shop_id')) {
                $table->unsignedBigInteger('referred_by_shop_id')->nullable()->index()->after('referral_code');
            }
            if (!Schema::hasColumn('shops', 'referral_points_balance')) {
                $table->decimal('referral_points_balance', 12, 2)->default(0)->after('referred_by_shop_id');
            }
            if (!Schema::hasColumn('shops', 'referral_enabled_override')) {
                $table->boolean('referral_enabled_override')->nullable()->after('referral_points_balance');
            }
            if (!Schema::hasColumn('shops', 'referral_reward_mode_override')) {
                $table->string('referral_reward_mode_override', 32)->nullable()->after('referral_enabled_override');
            }
            if (!Schema::hasColumn('shops', 'custom_referral_signup_points')) {
                $table->decimal('custom_referral_signup_points', 10, 2)->nullable()->after('referral_reward_mode_override');
            }
            if (!Schema::hasColumn('shops', 'custom_referral_recharge_percent')) {
                $table->decimal('custom_referral_recharge_percent', 5, 2)->nullable()->after('custom_referral_signup_points');
            }
            if (!Schema::hasColumn('shops', 'custom_referral_max_redeem_percent')) {
                $table->decimal('custom_referral_max_redeem_percent', 5, 2)->nullable()->after('custom_referral_recharge_percent');
            }
        });

        if (!Schema::hasTable('referral_point_transactions')) {
            Schema::create('referral_point_transactions', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('shop_id')->index();
                $table->unsignedBigInteger('related_shop_id')->nullable()->index();
                $table->unsignedBigInteger('subscription_id')->nullable();
                $table->unsignedBigInteger('payment_transaction_id')->nullable();
                $table->string('type', 16); // credit, debit
                $table->string('source', 40); // signup_bonus, welcome_bonus, recharge_commission, plan_redeem, admin_adjustment
                $table->decimal('points', 12, 2);
                $table->decimal('balance_after', 12, 2);
                $table->string('description', 255);
                $table->json('meta')->nullable();
                $table->timestamps();
            });
        }

        // Backfill referral codes for existing shops
        $shops = DB::table('shops')->whereNull('referral_code')->get(['id', 'name']);
        foreach ($shops as $shop) {
            $prefix = strtoupper(preg_replace('/[^A-Za-z0-9]/', '', (string) $shop->name));
            $prefix = substr($prefix, 0, 4) ?: 'SHOP';
            do {
                $code = $prefix . strtoupper(Str::random(4));
            } while (DB::table('shops')->where('referral_code', $code)->exists());

            DB::table('shops')->where('id', $shop->id)->update(['referral_code' => $code]);
        }

        // Seed default global referral settings if not already present
        $defaults = [
            'referral_enabled'            => '1',
            'referral_reward_mode'        => 'signup_and_recharge',
            'referral_signup_points'      => '50',
            'referral_welcome_points'     => '0',
            'referral_recharge_percent'   => '10',
            'referral_max_redeem_percent' => '50',
            'referral_app_link'           => '',
        ];

        $now = now();
        foreach ($defaults as $key => $val) {
            $exists = DB::table('system_settings')->where('key', $key)->exists();
            if (!$exists) {
                DB::table('system_settings')->insert([
                    'key'        => $key,
                    'value'      => $val,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);
            }
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('referral_point_transactions');

        Schema::table('shops', function (Blueprint $table) {
            $cols = [
                'referral_code',
                'referred_by_shop_id',
                'referral_points_balance',
                'referral_enabled_override',
                'referral_reward_mode_override',
                'custom_referral_signup_points',
                'custom_referral_recharge_percent',
                'custom_referral_max_redeem_percent',
            ];
            foreach ($cols as $col) {
                if (Schema::hasColumn('shops', $col)) {
                    $table->dropColumn($col);
                }
            }
        });
    }
};

