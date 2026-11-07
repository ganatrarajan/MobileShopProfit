<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('shops', function (Blueprint $table) {
            $table->unsignedInteger('custom_max_staff')->nullable()->default(null)->after('status');
            $table->date('custom_staff_valid_until')->nullable()->default(null)->after('custom_max_staff');
            $table->string('custom_staff_note', 255)->nullable()->default(null)->after('custom_staff_valid_until');
        });
    }

    public function down(): void
    {
        Schema::table('shops', function (Blueprint $table) {
            $table->dropColumn(['custom_max_staff', 'custom_staff_valid_until', 'custom_staff_note']);
        });
    }
};

