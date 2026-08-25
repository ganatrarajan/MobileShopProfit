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
        Schema::create('devices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('shop_id')->constrained('shops')->cascadeOnDelete();
            $table->foreignId('customer_id')->constrained('customers')->cascadeOnDelete();
            $table->string('device_type')->default('Mobile'); // Mobile, Tablet, Laptop, Other
            $table->string('brand');
            $table->string('model');
            $table->string('variant')->nullable();
            $table->string('color')->nullable();
            $table->string('imei_1', 20)->nullable()->index();
            $table->string('imei_2', 20)->nullable()->index();
            $table->string('serial_number')->nullable()->index();
            $table->date('purchase_date')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('devices');
    }
};
