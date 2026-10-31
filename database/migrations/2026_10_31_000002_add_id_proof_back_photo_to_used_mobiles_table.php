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
        Schema::table('used_mobiles', function (Blueprint $table) {
            $table->string('id_proof_back_photo')->nullable()->after('id_proof_photo');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('used_mobiles', function (Blueprint $table) {
            $table->dropColumn('id_proof_back_photo');
        });
    }
};

