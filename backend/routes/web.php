<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\AuthController;use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\CampaignController;use App\Http\Controllers\Admin\AdsController;
use App\Http\Controllers\Admin\SystemUpdateController;
use App\Http\Controllers\Admin\StoreReportController;
Route::get('/',fn()=>view('legal.home'));
Route::view('/privacy','legal.privacy')->name('privacy');
Route::view('/terms','legal.terms');
Route::view('/support','legal.support');
Route::middleware('installed')->prefix('admin')->name('admin.')->group(function(){
 Route::get('login',[AuthController::class,'loginPage'])->name('login');
 Route::post('login',[AuthController::class,'login'])->middleware('throttle:5,1')->name('login.submit');
 Route::middleware('admin')->group(function(){
  Route::get('/',[DashboardController::class,'index'])->name('dashboard');
  Route::post('campaigns',[CampaignController::class,'create'])->name('campaign.create');
  Route::post('campaigns/{campaign}/send',[CampaignController::class,'send'])->name('campaign.send');
  Route::post('queue/process',[CampaignController::class,'process'])->name('queue.process');
  Route::post('store-report/import',[StoreReportController::class,'import'])->name('store.import');
  Route::get('ads',[AdsController::class,'index'])->name('ads');
  Route::post('ads',[AdsController::class,'save'])->name('ads.save');
  Route::post('ads/sellers',[AdsController::class,'sellers'])->name('ads.sellers');
  Route::get('system-updates',[SystemUpdateController::class,'index'])->name('updates');
  Route::post('system-updates/verify',[SystemUpdateController::class,'verify'])->name('updates.verify');
  Route::post('logout',[AuthController::class,'logout'])->name('logout');
 });
});
