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
        Schema::table('shops', function (Blueprint $table) {
            $table->boolean('is_web_enabled')->default(false)->after('custom_discount_is_one_time');
            $table->date('web_valid_until')->nullable()->after('is_web_enabled');
            $table->string('web_access_note')->nullable()->after('web_valid_until');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('shops', function (Blueprint $table) {
            $table->dropColumn(['is_web_enabled', 'web_valid_until', 'web_access_note']);
        });
    }
};
