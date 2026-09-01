<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('system_settings')) {
            Schema::create('system_settings', function (Blueprint $table) {
                $table->id();
                $table->string('key')->unique();
                $table->text('value')->nullable();
                $table->timestamps();
            });

            DB::table('system_settings')->insert([
                ['key' => 'support_email', 'value' => 'support@mobileprofits.com', 'created_at' => now(), 'updated_at' => now()],
                ['key' => 'support_phone', 'value' => '+91 98765 43210', 'created_at' => now(), 'updated_at' => now()],
                ['key' => 'support_hours', 'value' => 'Mon - Sat: 9:00 AM - 8:00 PM IST', 'created_at' => now(), 'updated_at' => now()],
            ]);
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('system_settings');
    }
};