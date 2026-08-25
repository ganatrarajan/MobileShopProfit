<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('sale_items', 'inventory_item_id')) {
            Schema::table('sale_items', function (Blueprint $table) {
                $table->foreignId('inventory_item_id')->nullable()->after('sale_id')->constrained('inventory_items')->onDelete('set null');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('sale_items', 'inventory_item_id')) {
            Schema::table('sale_items', function (Blueprint $table) {
                $table->dropForeign(['inventory_item_id']);
                $table->dropColumn('inventory_item_id');
            });
        }
    }
};