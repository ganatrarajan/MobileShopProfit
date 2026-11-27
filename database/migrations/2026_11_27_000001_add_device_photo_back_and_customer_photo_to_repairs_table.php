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
        Schema::table('repairs', function (Blueprint $table) {
            if (!Schema::hasColumn('repairs', 'device_photo_back')) {
                $table->text('device_photo_back')->nullable()->after('device_photo');
            }
            if (!Schema::hasColumn('repairs', 'customer_photo')) {
                $table->text('customer_photo')->nullable()->after('device_photo_back');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('repairs', function (Blueprint $table) {
            if (Schema::hasColumn('repairs', 'customer_photo')) {
                $table->dropColumn('customer_photo');
            }
            if (Schema::hasColumn('repairs', 'device_photo_back')) {
                $table->dropColumn('device_photo_back');
            }
        });
    }
};
