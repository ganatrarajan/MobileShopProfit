<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn("users", "last_app_opened_at")) {
            Schema::table("users", function (Blueprint $table) {
                $table->timestamp("last_app_opened_at")->nullable();
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn("users", "last_app_opened_at")) {
            Schema::table("users", function (Blueprint $table) {
                $table->dropColumn("last_app_opened_at");
            });
        }
    }
};
