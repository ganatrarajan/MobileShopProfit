<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('repairs', function (Blueprint $table) {
            $table->index(['shop_id', 'repair_status']);
            $table->index(['shop_id', 'created_at']);
        });

        Schema::table('warranties', function (Blueprint $table) {
            $table->index(['shop_id', 'status', 'warranty_end_date']);
        });

        Schema::table('expenses', function (Blueprint $table) {
            $table->index(['shop_id', 'expense_date']);
        });
    }

    public function down(): void
    {
        Schema::table('repairs', function (Blueprint $table) {
            $table->dropIndex(['shop_id', 'repair_status']);
            $table->dropIndex(['shop_id', 'created_at']);
        });

        Schema::table('warranties', function (Blueprint $table) {
            $table->dropIndex(['shop_id', 'status', 'warranty_end_date']);
        });

        Schema::table('expenses', function (Blueprint $table) {
            $table->dropIndex(['shop_id', 'expense_date']);
        });
    }
};