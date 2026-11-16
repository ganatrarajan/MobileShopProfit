<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('used_mobiles', function (Blueprint $table) {
            // Purchase / Buy GST fields
            if (!Schema::hasColumn('used_mobiles', 'purchase_tax_rate')) {
                $table->decimal('purchase_tax_rate', 5, 2)->default(0)->after('purchase_price');
            }
            if (!Schema::hasColumn('used_mobiles', 'purchase_tax_type')) {
                $table->string('purchase_tax_type', 20)->default('exclusive')->after('purchase_tax_rate');
            }
            if (!Schema::hasColumn('used_mobiles', 'purchase_tax_amount')) {
                $table->decimal('purchase_tax_amount', 12, 2)->default(0)->after('purchase_tax_type');
            }
            if (!Schema::hasColumn('used_mobiles', 'purchase_cgst_amount')) {
                $table->decimal('purchase_cgst_amount', 12, 2)->default(0)->after('purchase_tax_amount');
            }
            if (!Schema::hasColumn('used_mobiles', 'purchase_sgst_amount')) {
                $table->decimal('purchase_sgst_amount', 12, 2)->default(0)->after('purchase_cgst_amount');
            }
            if (!Schema::hasColumn('used_mobiles', 'purchase_igst_amount')) {
                $table->decimal('purchase_igst_amount', 12, 2)->default(0)->after('purchase_sgst_amount');
            }
            if (!Schema::hasColumn('used_mobiles', 'purchase_is_inter_state')) {
                $table->boolean('purchase_is_inter_state')->default(false)->after('purchase_igst_amount');
            }

            // Sale GST fields
            if (!Schema::hasColumn('used_mobiles', 'tax_rate')) {
                $table->decimal('tax_rate', 5, 2)->default(0)->after('selling_price');
            }
            if (!Schema::hasColumn('used_mobiles', 'tax_type')) {
                $table->string('tax_type', 20)->default('exclusive')->after('tax_rate');
            }
            if (!Schema::hasColumn('used_mobiles', 'tax_amount')) {
                $table->decimal('tax_amount', 12, 2)->default(0)->after('tax_type');
            }
            if (!Schema::hasColumn('used_mobiles', 'cgst_amount')) {
                $table->decimal('cgst_amount', 12, 2)->default(0)->after('tax_amount');
            }
            if (!Schema::hasColumn('used_mobiles', 'sgst_amount')) {
                $table->decimal('sgst_amount', 12, 2)->default(0)->after('cgst_amount');
            }
            if (!Schema::hasColumn('used_mobiles', 'igst_amount')) {
                $table->decimal('igst_amount', 12, 2)->default(0)->after('sgst_amount');
            }
            if (!Schema::hasColumn('used_mobiles', 'is_inter_state')) {
                $table->boolean('is_inter_state')->default(false)->after('igst_amount');
            }
        });
    }

    public function down(): void
    {
        Schema::table('used_mobiles', function (Blueprint $table) {
            $table->dropColumn([
                'purchase_tax_rate',
                'purchase_tax_type',
                'purchase_tax_amount',
                'purchase_cgst_amount',
                'purchase_sgst_amount',
                'purchase_igst_amount',
                'purchase_is_inter_state',
                'tax_rate',
                'tax_type',
                'tax_amount',
                'cgst_amount',
                'sgst_amount',
                'igst_amount',
                'is_inter_state',
            ]);
        });
    }
};
