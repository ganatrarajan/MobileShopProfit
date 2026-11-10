<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (!Schema::hasTable('staff')) {
            Schema::create('staff', function (Blueprint $table) {
                $table->id();
                $table->foreignId('shop_id')->constrained('shops')->onDelete('cascade');
                $table->foreignId('user_id')->nullable()->constrained('users')->onDelete('set null');
                $table->string('name');
                $table->string('mobile', 20)->index();
                $table->string('email')->nullable();
                $table->string('designation', 100)->nullable();
                $table->decimal('salary', 10, 2)->nullable();
                $table->date('joining_date')->nullable();
                $table->text('address')->nullable();
                $table->text('notes')->nullable();
                $table->boolean('is_active')->default(true)->index();
                $table->timestamps();
                $table->softDeletes();
            });
        }

        // Deactivate bundled multi-staff base plans so only Solo Owner plans are available
        // Staff logins will now strictly use the per-day add-on (₹2 / day).
        if (Schema::hasTable('plans')) {
            DB::table('plans')
                ->where('max_staff_accounts', '>', 0)
                ->update([
                    'status'     => 'inactive',
                    'updated_at' => now(),
                ]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('staff');
    }
};

