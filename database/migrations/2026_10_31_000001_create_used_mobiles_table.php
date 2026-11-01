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
        Schema::create('used_mobiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('shop_id')->constrained('shops')->onDelete('cascade');

            // Reference Numbers
            $table->string('purchase_ref_number')->index(); // e.g. UMB-00001
            $table->string('sale_invoice_number')->nullable()->index(); // e.g. UMS-00001

            // Seller Details (Verification & Police safety)
            $table->string('seller_name');
            $table->string('seller_phone');
            $table->text('seller_address')->nullable();
            $table->string('id_proof_type')->nullable(); // Aadhaar Card, Driving License, Voter ID, Passport, PAN Card
            $table->string('id_proof_number')->nullable();
            $table->string('id_proof_photo')->nullable();
            $table->string('seller_photo')->nullable();

            // Device Specifications
            $table->string('brand'); // Apple, Samsung, Vivo, etc.
            $table->string('model'); // iPhone 12, Galaxy S21
            $table->string('imei1')->index(); // 15 digits IMEI
            $table->string('imei2')->nullable();
            $table->string('serial_number')->nullable();
            $table->string('color')->nullable();
            $table->string('ram')->nullable(); // 6 GB, 8 GB
            $table->string('storage')->nullable(); // 128 GB, 256 GB
            $table->string('battery_health')->nullable(); // 85%, Good, etc.

            // Physical Condition & Checklist
            $table->string('device_condition')->default('good'); // mint, good, fair, damaged
            $table->text('condition_notes')->nullable();
            $table->json('accessories_included')->nullable(); // ['Original Box', 'Charger', 'Original Bill']

            // Purchase Financials
            $table->date('purchase_date');
            $table->decimal('purchase_price', 12, 2)->default(0.00);
            $table->string('payment_mode')->default('cash'); // cash, upi, bank_transfer
            $table->text('purchase_notes')->nullable();

            // Refurbishment / Repair Cost Tracking (For accurate profit)
            $table->decimal('repair_cost', 12, 2)->default(0.00);
            $table->text('repair_details')->nullable();
            $table->decimal('total_cost', 12, 2)->default(0.00); // purchase_price + repair_cost

            // Sale Information (When sold to customer)
            $table->date('sale_date')->nullable();
            $table->string('buyer_name')->nullable();
            $table->string('buyer_phone')->nullable();
            $table->text('buyer_address')->nullable();
            $table->decimal('selling_price', 12, 2)->nullable();
            $table->string('sale_payment_mode')->nullable(); // cash, upi, card
            $table->integer('warranty_days')->default(0); // 7, 15, 30 days testing warranty
            $table->date('warranty_expiry_date')->nullable();
            $table->text('warranty_terms')->nullable();
            $table->text('sale_notes')->nullable();
            $table->decimal('profit', 12, 2)->nullable(); // selling_price - total_cost

            // Status Lifecycle
            $table->string('status')->default('in_stock')->index(); // in_stock, sold, returned, scrapped

            // User tracking
            $table->foreignId('created_by')->nullable()->constrained('users')->onDelete('set null');
            $table->foreignId('sold_by')->nullable()->constrained('users')->onDelete('set null');

            $table->timestamps();
            $table->softDeletes();

            $table->index(['shop_id', 'status']);
            $table->index(['shop_id', 'purchase_date']);
            $table->index(['shop_id', 'sale_date']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('used_mobiles');
    }
};

