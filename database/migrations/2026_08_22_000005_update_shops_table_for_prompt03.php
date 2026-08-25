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
            if (! Schema::hasColumn('shops', 'user_id')) {
                $table->foreignId('user_id')->nullable()->after('id')->constrained('users')->cascadeOnDelete();
            }
            if (! Schema::hasColumn('shops', 'state')) {
                $table->string('state')->nullable()->after('city');
            }
            if (! Schema::hasColumn('shops', 'pincode')) {
                $table->string('pincode')->nullable()->after('state');
            }
            if (! Schema::hasColumn('shops', 'gst_number')) {
                $table->string('gst_number')->nullable()->after('pincode');
            }
            if (! Schema::hasColumn('shops', 'logo')) {
                $table->string('logo')->nullable()->after('gst_number');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('shops', function (Blueprint $table) {
            $table->dropForeign(['user_id']);
            $table->dropColumn(['user_id', 'state', 'pincode', 'gst_number', 'logo']);
        });
    }
};
