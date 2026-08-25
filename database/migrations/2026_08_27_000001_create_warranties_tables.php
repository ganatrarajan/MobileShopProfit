<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('warranties', function (Blueprint $table) {
            $table->id();
            $table->foreignId('shop_id')->constrained('shops')->onDelete('cascade');
            $table->foreignId('customer_id')->constrained('customers')->onDelete('cascade');
            $table->foreignId('device_id')->constrained('devices')->onDelete('cascade');
            $table->foreignId('sale_id')->nullable()->constrained('sales')->onDelete('set null');
            $table->foreignId('repair_id')->nullable()->constrained('repairs')->onDelete('set null');
            
            $table->string('warranty_number')->index(); // e.g. WAR-000001
            $table->string('warranty_type')->default('sale'); // sale, repair
            $table->date('warranty_start_date');
            $table->date('warranty_end_date');
            $table->integer('duration_days')->default(30);
            
            $table->text('warranty_terms')->nullable();
            $table->string('status')->default('active'); // active, expiring_soon, expired, voided
            $table->text('notes')->nullable();
            
            $table->foreignId('created_by')->nullable()->constrained('users')->onDelete('set null');
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['shop_id', 'warranty_number']);
        });

        Schema::create('warranty_claims', function (Blueprint $table) {
            $table->id();
            $table->foreignId('shop_id')->constrained('shops')->onDelete('cascade');
            $table->foreignId('warranty_id')->constrained('warranties')->onDelete('cascade');
            $table->foreignId('customer_id')->constrained('customers')->onDelete('cascade');
            $table->foreignId('device_id')->constrained('devices')->onDelete('cascade');
            
            $table->string('claim_number')->index(); // e.g. CLM-000001
            $table->date('claim_date');
            $table->text('complaint');
            $table->string('claim_status')->default('open');
            // open, checking, approved, rejected, repairing, resolved, closed
            
            $table->text('resolution')->nullable();
            $table->text('notes')->nullable();
            $table->dateTime('resolved_at')->nullable();
            
            $table->foreignId('created_by')->nullable()->constrained('users')->onDelete('set null');
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['shop_id', 'claim_number']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('warranty_claims');
        Schema::dropIfExists('warranties');
    }
};