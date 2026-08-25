<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('sales', function (Blueprint $table) {
            $table->string('sale_type')->default('regular')->after('shop_id');
            $table->string('customer_name')->nullable()->after('customer_id');
            $table->string('customer_mobile')->nullable()->after('customer_name');
        });
    }

    public function down(): void
    {
        Schema::table('sales', function (Blueprint $table) {
            $table->dropColumn(['sale_type', 'customer_name', 'customer_mobile']);
        });
    }
};