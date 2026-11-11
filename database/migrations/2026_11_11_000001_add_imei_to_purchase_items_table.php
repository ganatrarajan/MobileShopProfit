<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('purchase_items')) {
            Schema::table('purchase_items', function (Blueprint $table) {
                if (!Schema::hasColumn('purchase_items', 'imei1')) {
                    $table->string('imei1')->nullable()->after('quantity');
                }
                if (!Schema::hasColumn('purchase_items', 'imei2')) {
                    $table->string('imei2')->nullable()->after('imei1');
                }
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('purchase_items')) {
            Schema::table('purchase_items', function (Blueprint $table) {
                if (Schema::hasColumn('purchase_items', 'imei2')) {
                    $table->dropColumn('imei2');
                }
                if (Schema::hasColumn('purchase_items', 'imei1')) {
                    $table->dropColumn('imei1');
                }
            });
        }
    }
};

