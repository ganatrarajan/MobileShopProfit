<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('payment_gateway_configs')) {
            Schema::create('payment_gateway_configs', function (Blueprint $table) {
                $table->id();
                $table->string('gateway_name')->default('Razorpay');
                $table->string('key_id')->nullable();
                $table->text('key_secret')->nullable();
                $table->text('webhook_secret')->nullable();
                $table->string('mode')->default('test'); // test, live
                $table->string('currency')->default('INR');
                $table->boolean('active')->default(true);
                $table->integer('trial_months')->default(3);
                $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
                $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
                $table->timestamps();
            });
        }

        if (!Schema::hasTable('payment_transactions')) {
            Schema::create('payment_transactions', function (Blueprint $table) {
                $table->id();
                $table->foreignId('shop_id')->constrained('shops')->cascadeOnDelete();
                $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
                $table->foreignId('plan_id')->nullable()->constrained('plans')->nullOnDelete();
                $table->string('order_id')->unique();
                $table->string('payment_id')->nullable()->index();
                $table->text('signature')->nullable();
                $table->decimal('amount', 10, 2)->default(0.00);
                $table->string('currency', 10)->default('INR');
                $table->string('status')->default('pending'); // pending, successful, failed
                $table->string('payment_method')->default('Online');
                $table->string('gateway_name')->default('Razorpay');
                $table->json('gateway_response')->nullable();
                $table->text('failure_reason')->nullable();
                $table->timestamps();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('payment_transactions');
        Schema::dropIfExists('payment_gateway_configs');
    }
};
