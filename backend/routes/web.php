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
Route::view('/data-deletion','legal.data-deletion')->name('data-deletion');
Route::view('/delete-account','legal.data-deletion'); // No consumer accounts: explain local and device-data deletion.
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
  Route::post('ads/policy',[AdsController::class,'policy'])->middleware('throttle:5,1')->name('ads.policy');
  Route::post('ads/sellers',[AdsController::class,'sellers'])->name('ads.sellers');
  Route::get('system-updates',[SystemUpdateController::class,'index'])->name('updates');
  Route::post('system-updates/verify',[SystemUpdateController::class,'verify'])->middleware('throttle:5,1')->name('updates.verify');
  Route::post('system-updates/backup',[SystemUpdateController::class,'backup'])->middleware('throttle:2,1')->name('updates.backup');
  Route::post('system-updates/install',[SystemUpdateController::class,'install'])->middleware('throttle:2,1')->name('updates.install');
  Route::post('system-updates/backup/verify',[SystemUpdateController::class,'verifyBackup'])->middleware('throttle:5,1')->name('updates.backup.verify');
  Route::get('system-updates/backup/{id}/download',[SystemUpdateController::class,'downloadBackup'])->middleware('throttle:5,1')->name('updates.backup.download');
  Route::post('logout',[AuthController::class,'logout'])->name('logout');
 });
});
