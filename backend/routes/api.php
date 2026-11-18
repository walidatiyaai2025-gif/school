<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\DeviceController;use App\Http\Controllers\Api\ConfigController;
Route::middleware('installed')->prefix('v1')->group(function(){
 Route::get('config',ConfigController::class)->middleware('throttle:60,1');
 Route::post('device/register',[DeviceController::class,'register'])->middleware('throttle:10,1');
 Route::post('device/heartbeat',[DeviceController::class,'heartbeat'])->middleware('throttle:30,1');
 Route::delete('device',[DeviceController::class,'delete'])->middleware('throttle:10,1');
});
