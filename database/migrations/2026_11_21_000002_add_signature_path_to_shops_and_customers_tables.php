<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('shops') && !Schema::hasColumn('shops', 'signature_path')) {
            Schema::table('shops', function (Blueprint $table) {
                $table->string('signature_path')->nullable()->after('logo');
            });
        }

        if (Schema::hasTable('customers') && !Schema::hasColumn('customers', 'signature_path')) {
            Schema::table('customers', function (Blueprint $table) {
                $table->string('signature_path')->nullable()->after('notes');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('shops') && Schema::hasColumn('shops', 'signature_path')) {
            Schema::table('shops', function (Blueprint $table) {
                $table->dropColumn('signature_path');
            });
        }

        if (Schema::hasTable('customers') && Schema::hasColumn('customers', 'signature_path')) {
            Schema::table('customers', function (Blueprint $table) {
                $table->dropColumn('signature_path');
            });
        }
    }
};
