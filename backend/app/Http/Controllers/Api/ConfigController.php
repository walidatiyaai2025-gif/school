<?php
namespace App\Http\Controllers\Api;
use App\Models\AdSetting;
class ConfigController {
 public function __invoke() {
  // IDs are public configuration, but remote config alone must never bypass mobile age/CMP checks.
  $enabled=config('schoolpdf.allow_ads') && config('schoolpdf.ads_policy_approved');
  return response()->json([
   'app'=>'School PDF','version'=>'1.1.3','privacy_url'=>'https://sclpdf.50sols.com/privacy',
   'support_url'=>'https://sclpdf.50sols.com/support',
   'ads'=>['enabled'=>$enabled,'providers'=>$enabled?AdSetting::where('enabled',true)->get(['provider','platform','banner_unit_id']):[]],
  ])->header('Cache-Control','public, max-age=300');
 }
}
