<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('used_mobiles', function (Blueprint $table) {
            if (!Schema::hasColumn('used_mobiles', 'amount_paid')) {
                $table->decimal('amount_paid', 12, 2)->default(0.00)->after('selling_price');
            }
            if (!Schema::hasColumn('used_mobiles', 'amount_due')) {
                $table->decimal('amount_due', 12, 2)->default(0.00)->after('amount_paid');
            }
            if (!Schema::hasColumn('used_mobiles', 'payment_status')) {
                $table->string('payment_status', 30)->default('paid')->after('amount_due');
            }
        });

        if (!Schema::hasTable('used_mobile_payments')) {
            Schema::create('used_mobile_payments', function (Blueprint $table) {
                $table->id();
                $table->foreignId('shop_id')->constrained('shops')->onDelete('cascade');
                $table->foreignId('used_mobile_id')->constrained('used_mobiles')->onDelete('cascade');
                $table->decimal('amount', 12, 2)->default(0.00);
                $table->string('payment_method', 50)->default('cash');
                $table->datetime('payment_date')->useCurrent();
                $table->text('notes')->nullable();
                $table->foreignId('created_by')->nullable()->constrained('users')->onDelete('set null');
                $table->timestamps();
                $table->softDeletes();

                $table->index(['shop_id', 'used_mobile_id']);
                $table->index('payment_date');
            });
        }

        // Backfill existing sold used mobiles so their amount_paid = selling_price, amount_due = 0, payment_status = 'paid'
        DB::statement("UPDATE used_mobiles SET amount_paid = COALESCE(selling_price, 0), amount_due = 0, payment_status = 'paid' WHERE status = 'sold' AND (amount_paid IS NULL OR amount_paid = 0)");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('used_mobile_payments');

        Schema::table('used_mobiles', function (Blueprint $table) {
            $columns = [];
            if (Schema::hasColumn('used_mobiles', 'payment_status')) {
                $columns[] = 'payment_status';
            }
            if (Schema::hasColumn('used_mobiles', 'amount_due')) {
                $columns[] = 'amount_due';
            }
            if (Schema::hasColumn('used_mobiles', 'amount_paid')) {
                $columns[] = 'amount_paid';
            }
            if (!empty($columns)) {
                $table->dropColumn($columns);
            }
        });
    }
};
