<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('inventory_items', function (Blueprint $table) {
            $table->integer('opening_stock')->default(0)->after('selling_price');
        });

        // Set opening_stock = current_stock for any existing records
        DB::statement('UPDATE inventory_items SET opening_stock = current_stock WHERE opening_stock = 0');
    }

    public function down(): void
    {
        Schema::table('inventory_items', function (Blueprint $table) {
            $table->dropColumn('opening_stock');
        });
    }
};