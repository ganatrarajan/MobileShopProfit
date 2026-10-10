<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create("push_notifications", function (Blueprint $table) {
            $table->id();
            $table->string("title");
            $table->text("description");
            $table->string("image_url")->nullable();
            $table->string("target_type")->default("all");
            $table->json("target_user_ids")->nullable();
            $table->integer("recipients_count")->default(0);
            $table->foreignId("created_by")->nullable()->constrained("users")->onDelete("set null");
            $table->timestamp("sent_at")->useCurrent();
            $table->timestamps();
        });

        Schema::create("user_notifications", function (Blueprint $table) {
            $table->id();
            $table->foreignId("user_id")->constrained()->onDelete("cascade");
            $table->foreignId("push_notification_id")->nullable()->constrained("push_notifications")->onDelete("cascade");
            $table->string("title");
            $table->text("description");
            $table->string("image_url")->nullable();
            $table->boolean("is_read")->default(false);
            $table->timestamp("read_at")->nullable();
            $table->timestamps();
        });

        if (!Schema::hasColumn("users", "fcm_token")) {
            Schema::table("users", function (Blueprint $table) {
                $table->string("fcm_token")->nullable()->after("remember_token");
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists("user_notifications");
        Schema::dropIfExists("push_notifications");

        if (Schema::hasColumn("users", "fcm_token")) {
            Schema::table("users", function (Blueprint $table) {
                $table->dropColumn("fcm_token");
            });
        }
    }
};
