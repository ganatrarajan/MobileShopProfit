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
            $table->string('google_maps_url', 500)->nullable()->after('pincode');
            $table->decimal('latitude', 10, 7)->nullable()->after('google_maps_url');
            $table->decimal('longitude', 10, 7)->nullable()->after('latitude');
            $table->string('upi_id', 100)->nullable()->after('longitude');
            $table->string('tagline', 255)->nullable()->after('upi_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('shops', function (Blueprint $table) {
            $table->dropColumn(['google_maps_url', 'latitude', 'longitude', 'upi_id', 'tagline']);
        });
    }
};
