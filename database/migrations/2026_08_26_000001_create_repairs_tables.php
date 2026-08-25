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
        Schema::create('repairs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('shop_id')->constrained('shops')->onDelete('cascade');
            $table->foreignId('customer_id')->constrained('customers')->onDelete('cascade');
            $table->foreignId('device_id')->constrained('devices')->onDelete('cascade');
            
            $table->string('job_number')->index(); // e.g. JOB-000001
            $table->date('date_received');
            $table->date('expected_delivery_date')->nullable();
            $table->dateTime('delivered_date')->nullable();
            
            $table->text('problem_description');
            $table->json('device_condition')->nullable(); // ['Screen damaged', 'Body scratched']
            $table->text('condition_notes')->nullable();
            $table->json('accessories_received')->nullable(); // ['Charger', 'Cable']
            $table->text('accessories_notes')->nullable();
            
            $table->string('pin_passcode')->nullable();
            
            $table->decimal('estimated_cost', 10, 2)->default(0.00);
            $table->decimal('final_cost', 10, 2)->default(0.00);
            $table->decimal('labour_cost', 10, 2)->default(0.00);
            $table->decimal('amount_paid', 10, 2)->default(0.00);
            $table->decimal('amount_due', 10, 2)->default(0.00);
            
            $table->string('repair_status')->default('received')->index();
            // received, diagnosing, waiting_customer, waiting_parts, repairing, ready, delivered, cancelled
            
            $table->text('customer_notes')->nullable();
            $table->text('internal_notes')->nullable();
            
            $table->foreignId('created_by')->nullable()->constrained('users')->onDelete('set null');
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['shop_id', 'job_number']);
        });

        Schema::create('repair_parts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('repair_id')->constrained('repairs')->onDelete('cascade');
            $table->string('part_name');
            $table->integer('quantity')->default(1);
            $table->decimal('cost_price', 10, 2)->nullable();
            $table->decimal('selling_price', 10, 2)->default(0.00);
            $table->text('notes')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('repair_payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('shop_id')->constrained('shops')->onDelete('cascade');
            $table->foreignId('repair_id')->constrained('repairs')->onDelete('cascade');
            $table->decimal('amount', 10, 2);
            $table->string('payment_method')->default('cash'); // cash, upi, card, bank_transfer, other
            $table->dateTime('payment_date');
            $table->text('notes')->nullable();
            $table->foreignId('created_by')->nullable()->constrained('users')->onDelete('set null');
            $table->timestamps();
            $table->softDeletes();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('repair_payments');
        Schema::dropIfExists('repair_parts');
        Schema::dropIfExists('repairs');
    }
};