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
        // 1. Add permissions JSON to users table
        if (!Schema::hasColumn('users', 'permissions')) {
            Schema::table('users', function (Blueprint $table) {
                $table->json('permissions')->nullable()->after('role');
            });
        }

        // 2. Add user_id to technicians table to link login account
        if (!Schema::hasColumn('technicians', 'user_id')) {
            Schema::table('technicians', function (Blueprint $table) {
                $table->foreignId('user_id')->nullable()->after('shop_id')->constrained('users')->onDelete('set null');
            });
        }

        // 3. Add max_staff_accounts to plans table
        if (!Schema::hasColumn('plans', 'max_staff_accounts')) {
            Schema::table('plans', function (Blueprint $table) {
                $table->unsignedInteger('max_staff_accounts')->default(1)->after('price');
            });

            // Set tier limits on existing plans
            DB::table('plans')->where('slug', 'monthly-plan-monthly')->update(['max_staff_accounts' => 1]);
            DB::table('plans')->where('slug', '3-month-plan-3-months')->update(['max_staff_accounts' => 2]);
            DB::table('plans')->where('slug', '6-months-package-6-months')->update(['max_staff_accounts' => 3]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasColumn('plans', 'max_staff_accounts')) {
            Schema::table('plans', function (Blueprint $table) {
                $table->dropColumn('max_staff_accounts');
            });
        }

        if (Schema::hasColumn('technicians', 'user_id')) {
            Schema::table('technicians', function (Blueprint $table) {
                $table->dropForeign(['user_id']);
                $table->dropColumn('user_id');
            });
        }

        if (Schema::hasColumn('users', 'permissions')) {
            Schema::table('users', function (Blueprint $table) {
                $table->dropColumn('permissions');
            });
        }
    }
};

