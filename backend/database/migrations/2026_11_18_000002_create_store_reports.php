<?php
use Illuminate\Database\Migrations\Migration; use Illuminate\Database\Schema\Blueprint; use Illuminate\Support\Facades\Schema;
return new class extends Migration {
 public function up(): void {Schema::create('store_install_reports',function(Blueprint $t){$t->id();$t->date('report_date');$t->string('store',12);$t->char('country_code',2);$t->unsignedInteger('installs');$t->timestamps();$t->unique(['report_date','store','country_code']);});}
 public function down(): void {Schema::dropIfExists('store_install_reports');}
};
