<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Purchases table
        Schema::table('purchases', function (Blueprint $table) {
            if (!Schema::hasColumn('purchases', 'tax_amount')) {
                $table->decimal('tax_amount', 12, 2)->default(0)->after('discount');
            }
            if (!Schema::hasColumn('purchases', 'tax_rate')) {
                $table->decimal('tax_rate', 5, 2)->default(0)->after('tax_amount');
            }
            if (!Schema::hasColumn('purchases', 'tax_type')) {
                $table->string('tax_type', 20)->default('exclusive')->after('tax_rate'); // 'exclusive' or 'inclusive'
            }
            if (!Schema::hasColumn('purchases', 'is_inter_state')) {
                $table->boolean('is_inter_state')->default(false)->after('tax_type');
            }
            if (!Schema::hasColumn('purchases', 'cgst_amount')) {
                $table->decimal('cgst_amount', 12, 2)->default(0)->after('is_inter_state');
            }
            if (!Schema::hasColumn('purchases', 'sgst_amount')) {
                $table->decimal('sgst_amount', 12, 2)->default(0)->after('cgst_amount');
            }
            if (!Schema::hasColumn('purchases', 'igst_amount')) {
                $table->decimal('igst_amount', 12, 2)->default(0)->after('sgst_amount');
            }
        });

        // 2. Purchase items table
        Schema::table('purchase_items', function (Blueprint $table) {
            if (!Schema::hasColumn('purchase_items', 'tax_amount')) {
                $table->decimal('tax_amount', 12, 2)->default(0)->after('purchase_rate');
            }
            if (!Schema::hasColumn('purchase_items', 'tax_rate')) {
                $table->decimal('tax_rate', 5, 2)->default(0)->after('tax_amount');
            }
            if (!Schema::hasColumn('purchase_items', 'tax_type')) {
                $table->string('tax_type', 20)->default('exclusive')->after('tax_rate');
            }
        });

        // 3. Sales table
        Schema::table('sales', function (Blueprint $table) {
            if (!Schema::hasColumn('sales', 'tax_rate')) {
                $table->decimal('tax_rate', 5, 2)->default(0)->after('tax_amount');
            }
            if (!Schema::hasColumn('sales', 'tax_type')) {
                $table->string('tax_type', 20)->default('exclusive')->after('tax_rate');
            }
            if (!Schema::hasColumn('sales', 'is_inter_state')) {
                $table->boolean('is_inter_state')->default(false)->after('tax_type');
            }
            if (!Schema::hasColumn('sales', 'cgst_amount')) {
                $table->decimal('cgst_amount', 12, 2)->default(0)->after('is_inter_state');
            }
            if (!Schema::hasColumn('sales', 'sgst_amount')) {
                $table->decimal('sgst_amount', 12, 2)->default(0)->after('cgst_amount');
            }
            if (!Schema::hasColumn('sales', 'igst_amount')) {
                $table->decimal('igst_amount', 12, 2)->default(0)->after('sgst_amount');
            }
        });

        // 4. Sale items table
        Schema::table('sale_items', function (Blueprint $table) {
            if (!Schema::hasColumn('sale_items', 'tax_rate')) {
                $table->decimal('tax_rate', 5, 2)->default(0)->after('tax_amount');
            }
            if (!Schema::hasColumn('sale_items', 'tax_type')) {
                $table->string('tax_type', 20)->default('exclusive')->after('tax_rate');
            }
            if (!Schema::hasColumn('sale_items', 'cgst_amount')) {
                $table->decimal('cgst_amount', 12, 2)->default(0)->after('tax_type');
            }
            if (!Schema::hasColumn('sale_items', 'sgst_amount')) {
                $table->decimal('sgst_amount', 12, 2)->default(0)->after('cgst_amount');
            }
            if (!Schema::hasColumn('sale_items', 'igst_amount')) {
                $table->decimal('igst_amount', 12, 2)->default(0)->after('sgst_amount');
            }
        });

        // 5. Inventory items table
        Schema::table('inventory_items', function (Blueprint $table) {
            if (!Schema::hasColumn('inventory_items', 'tax_rate')) {
                $table->decimal('tax_rate', 5, 2)->default(0)->after('selling_price');
            }
            if (!Schema::hasColumn('inventory_items', 'tax_type')) {
                $table->string('tax_type', 20)->default('exclusive')->after('tax_rate');
            }
        });
    }

    public function down(): void
    {
        Schema::table('purchases', function (Blueprint $table) {
            $table->dropColumn(['tax_amount', 'tax_rate', 'tax_type', 'is_inter_state', 'cgst_amount', 'sgst_amount', 'igst_amount']);
        });

        Schema::table('purchase_items', function (Blueprint $table) {
            $table->dropColumn(['tax_amount', 'tax_rate', 'tax_type']);
        });

        Schema::table('sales', function (Blueprint $table) {
            $table->dropColumn(['tax_rate', 'tax_type', 'is_inter_state', 'cgst_amount', 'sgst_amount', 'igst_amount']);
        });

        Schema::table('sale_items', function (Blueprint $table) {
            $table->dropColumn(['tax_rate', 'tax_type', 'cgst_amount', 'sgst_amount', 'igst_amount']);
        });

        Schema::table('inventory_items', function (Blueprint $table) {
            $table->dropColumn(['tax_rate', 'tax_type']);
        });
    }
};

