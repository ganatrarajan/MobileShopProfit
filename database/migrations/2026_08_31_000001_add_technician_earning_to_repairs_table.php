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
            $table->decimal('technician_earning', 10, 2)->default(0.00)->after('technician_id');
            $table->decimal('technician_paid_amount', 10, 2)->default(0.00)->after('technician_earning');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('repairs', function (Blueprint $table) {
            $table->dropColumn(['technician_earning', 'technician_paid_amount']);
        });
    }
};