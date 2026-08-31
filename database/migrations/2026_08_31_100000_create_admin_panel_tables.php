<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. SaaS Plans Table
        Schema::create('plans', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('slug')->unique();
            $table->decimal('price', 10, 2)->default(0.00);
            $table->string('billing_period')->default('monthly'); // monthly, annual
            $table->string('status')->default('active');         // active, inactive
            $table->timestamps();
        });

        // Seed default plans
        DB::table('plans')->insert([
            [
                'name'           => 'Monthly Plan',
                'slug'           => 'monthly',
                'price'          => 200.00,
                'billing_period' => 'monthly',
                'status'         => 'active',
                'created_at'     => now(),
                'updated_at'     => now(),
            ],
            [
                'name'           => 'Annual Plan',
                'slug'           => 'annual',
                'price'          => 2000.00,
                'billing_period' => 'annual',
                'status'         => 'active',
                'created_at'     => now(),
                'updated_at'     => now(),
            ],
        ]);

        // 2. Subscriptions Table
        Schema::create('subscriptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('shop_id')->constrained('shops')->cascadeOnDelete();
            $table->foreignId('plan_id')->nullable()->constrained('plans')->nullOnDelete();
            $table->string('status')->default('trial'); // trial, active, expired, cancelled
            $table->timestamp('start_date')->nullable();
            $table->timestamp('expiry_date')->nullable();
            $table->string('payment_status')->default('free'); // free, paid, pending
            $table->timestamps();
        });

        // 3. Support Requests Table
        Schema::create('support_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('shop_id')->nullable()->constrained('shops')->nullOnDelete();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('type')->default('contact'); // contact, problem, feedback
            $table->string('subject')->nullable();
            $table->text('message');
            $table->integer('rating')->nullable();
            $table->json('metadata')->nullable();
            $table->string('status')->default('open'); // open, in_progress, resolved
            $table->timestamps();
        });

        // 4. Admin Audit Logs Table
        Schema::create('admin_audit_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('admin_id')->constrained('users')->cascadeOnDelete();
            $table->string('action');
            $table->string('target_type')->nullable();
            $table->unsignedBigInteger('target_id')->nullable();
            $table->text('details')->nullable();
            $table->string('ip_address')->nullable();
            $table->timestamps();
        });

        // 5. Seed default Super Admin User
        $existingAdmin = DB::table('users')->where('email', 'admin@mobileprofits.com')->first();
        if (! $existingAdmin) {
            DB::table('users')->insert([
                'name'       => 'Platform Super Admin',
                'email'      => 'admin@mobileprofits.com',
                'mobile'     => '9999999999',
                'phone'      => '9999999999',
                'role'       => 'super_admin',
                'password'   => Hash::make('password123'),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('admin_audit_logs');
        Schema::dropIfExists('support_requests');
        Schema::dropIfExists('subscriptions');
        Schema::dropIfExists('plans');
    }
};
