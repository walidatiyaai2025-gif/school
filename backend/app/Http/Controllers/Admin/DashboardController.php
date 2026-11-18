<?php
namespace App\Http\Controllers\Admin;
use App\Models\DeviceRegistration;use App\Models\PushCampaign;use Illuminate\Support\Facades\DB;
class DashboardController {
 public function index(){
  $total=DeviceRegistration::count();
  $active7=DeviceRegistration::where('last_seen_at','>=',now()->subDays(7))->count();
  $active30=DeviceRegistration::where('last_seen_at','>=',now()->subDays(30))->count();
  $pushReady=DeviceRegistration::where('push_opt_in',true)->where('notifications_enabled',true)->whereNotNull('fcm_token')->count();
  $countries=DeviceRegistration::selectRaw("COALESCE(country_code, '??') as code, COUNT(*) as count")
   ->groupBy('country_code')->orderByDesc('count')->limit(100)->get();
  $importedInstalls=DB::table('store_install_reports')->sum('installs');
  $campaigns=PushCampaign::latest()->limit(12)->get();
  return view('admin.dashboard',compact('total','active7','active30','pushReady','countries','campaigns','importedInstalls'));
 }
}
