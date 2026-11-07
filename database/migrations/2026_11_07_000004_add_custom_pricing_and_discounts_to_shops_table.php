<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('shops', function (Blueprint $table) {
            $table->decimal('custom_discount_percent', 5, 2)->nullable()->default(null)->after('custom_staff_note');
            $table->json('custom_plan_prices')->nullable()->default(null)->after('custom_discount_percent');
            $table->decimal('custom_staff_price_per_day', 8, 2)->nullable()->default(null)->after('custom_plan_prices');
            $table->date('custom_discount_valid_until')->nullable()->default(null)->after('custom_staff_price_per_day');
            $table->string('custom_discount_note', 255)->nullable()->default(null)->after('custom_discount_valid_until');
        });
    }

    public function down(): void
    {
        Schema::table('shops', function (Blueprint $table) {
            $table->dropColumn([
                'custom_discount_percent',
                'custom_plan_prices',
                'custom_staff_price_per_day',
                'custom_discount_valid_until',
                'custom_discount_note',
            ]);
        });
    }
};

