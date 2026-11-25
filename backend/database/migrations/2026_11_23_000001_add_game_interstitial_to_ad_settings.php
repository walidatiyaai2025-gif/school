<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::table('ad_settings', function (Blueprint $table) {
            $table->string('interstitial_unit_id')->nullable();
            $table->boolean('interstitial_enabled')->default(false);
        });
    }

    public function down(): void {
        Schema::table('ad_settings', function (Blueprint $table) {
            $table->dropColumn(['interstitial_unit_id', 'interstitial_enabled']);
        });
    }
};
