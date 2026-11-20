<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Add login timestamps to users table
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'last_mobile_login_at')) {
                $table->timestamp('last_mobile_login_at')->nullable()->after('last_app_opened_at');
            }
            if (!Schema::hasColumn('users', 'last_web_login_at')) {
                $table->timestamp('last_web_login_at')->nullable()->after('last_mobile_login_at');
            }
        });

        // 2. Add login timestamps to shops table
        Schema::table('shops', function (Blueprint $table) {
            if (!Schema::hasColumn('shops', 'last_mobile_login_at')) {
                $table->timestamp('last_mobile_login_at')->nullable()->after('web_access_note');
            }
            if (!Schema::hasColumn('shops', 'last_web_login_at')) {
                $table->timestamp('last_web_login_at')->nullable()->after('last_mobile_login_at');
            }
        });

        // 3. Backfill initial data from existing last_app_opened_at
        try {
            DB::statement("UPDATE users SET last_mobile_login_at = last_app_opened_at WHERE last_app_opened_at IS NOT NULL");
            
            DB::statement("
                UPDATE shops s
                JOIN users u ON u.shop_id = s.id AND u.role = 'owner'
                SET s.last_mobile_login_at = u.last_app_opened_at
                WHERE u.last_app_opened_at IS NOT NULL AND s.last_mobile_login_at IS NULL
            ");
        } catch (\Throwable $e) {
            // Non-critical data migration
        }
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'last_mobile_login_at')) {
                $table->dropColumn('last_mobile_login_at');
            }
            if (Schema::hasColumn('users', 'last_web_login_at')) {
                $table->dropColumn('last_web_login_at');
            }
        });

        Schema::table('shops', function (Blueprint $table) {
            if (Schema::hasColumn('shops', 'last_mobile_login_at')) {
                $table->dropColumn('last_mobile_login_at');
            }
            if (Schema::hasColumn('shops', 'last_web_login_at')) {
                $table->dropColumn('last_web_login_at');
            }
        });
    }
};
