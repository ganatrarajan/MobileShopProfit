<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('warranty_claims') && !Schema::hasColumn('warranty_claims', 'deleted_at')) {
            Schema::table('warranty_claims', function (Blueprint $table) {
                $table->softDeletes();
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('warranty_claims') && Schema::hasColumn('warranty_claims', 'deleted_at')) {
            Schema::table('warranty_claims', function (Blueprint $table) {
                $table->dropSoftDeletes();
            });
        }
    }
};
