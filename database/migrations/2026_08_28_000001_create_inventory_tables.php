<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inventory_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('shop_id')->constrained('shops')->onDelete('cascade');
            $table->string('name');
            $table->string('category')->default('General');
            $table->string('brand')->nullable();
            $table->string('model')->nullable();
            $table->string('sku')->nullable();
            $table->string('item_type')->default('spare_part'); // mobile, spare_part, accessory, other
            $table->decimal('purchase_price', 10, 2)->default(0.00);
            $table->decimal('selling_price', 10, 2)->default(0.00);
            $table->integer('current_stock')->default(0);
            $table->integer('minimum_stock')->default(2);
            $table->string('unit')->default('pcs');
            $table->text('description')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();

            $table->index(['shop_id', 'item_type']);
            $table->index(['shop_id', 'category']);
            $table->index(['shop_id', 'is_active']);
        });

        Schema::create('inventory_serials', function (Blueprint $table) {
            $table->id();
            $table->foreignId('shop_id')->constrained('shops')->onDelete('cascade');
            $table->foreignId('inventory_item_id')->constrained('inventory_items')->onDelete('cascade');
            $table->string('imei1')->nullable();
            $table->string('imei2')->nullable();
            $table->string('serial_number')->nullable();
            $table->string('status')->default('available'); // available, sold, used_in_repair, damaged, returned
            $table->timestamps();
            $table->softDeletes();

            $table->index(['shop_id', 'imei1']);
            $table->index(['shop_id', 'imei2']);
            $table->index(['shop_id', 'serial_number']);
        });

        Schema::create('stock_movements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('shop_id')->constrained('shops')->onDelete('cascade');
            $table->foreignId('inventory_item_id')->constrained('inventory_items')->onDelete('cascade');
            $table->string('movement_type'); // opening_stock, purchase, sale, repair_usage, adjustment, return, damaged
            $table->integer('quantity'); // positive for additions, negative for deductions
            $table->decimal('unit_cost', 10, 2)->nullable();
            $table->string('reference_type')->nullable(); // sale, repair, manual
            $table->unsignedBigInteger('reference_id')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['shop_id', 'inventory_item_id']);
            $table->index(['shop_id', 'movement_type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('stock_movements');
        Schema::dropIfExists('inventory_serials');
        Schema::dropIfExists('inventory_items');
    }
};