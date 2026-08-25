<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('expense_categories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('shop_id')->nullable()->constrained('shops')->onDelete('cascade');
            $table->string('name');
            $table->string('slug');
            $table->boolean('is_system_default')->default(false);
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['shop_id', 'slug']);
        });

        // Seed default system categories
        $defaultCategories = [
            'Rent',
            'Salary',
            'Electricity',
            'Internet / Phone',
            'Maintenance',
            'Transport',
            'Marketing',
            'Software / Subscription',
            'Bank / Payment Charges',
            'Other',
        ];

        $now = now();
        foreach ($defaultCategories as $catName) {
            DB::table('expense_categories')->insert([
                'shop_id' => null,
                'name' => $catName,
                'slug' => Str::slug($catName),
                'is_system_default' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('expense_categories');
    }
};