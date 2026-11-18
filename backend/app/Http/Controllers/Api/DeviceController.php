<?php
namespace App\Http\Controllers\Api;
use App\Models\DeviceRegistration;use App\Services\CountryResolver;
use Illuminate\Http\Request;use Illuminate\Routing\Controller;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;
class DeviceController extends Controller {
 private function own(Request $request): DeviceRegistration {
  $id=(string)$request->header('X-SchoolPDF-Install-ID','');
  $secret=(string)$request->header('X-SchoolPDF-Device-Key','');
  abort_unless(Str::isUuid($id)&&strlen($secret)>=32,401,'Invalid device credentials');
  $device=DeviceRegistration::where('installation_id',$id)->first();
  abort_unless($device && hash_equals($device->token_hash,hash('sha256',$secret)),401,'Invalid device credentials');
  return $device;
 }
 public function register(Request $request,CountryResolver $country) {
  $data=$request->validate([
   'installation_id'=>'required|uuid','platform'=>'required|in:android,ios',
   'app_version'=>'required|string|max:32','locale'=>'nullable|string|max:12',
   'analytics_consent'=>'required|accepted',
   'adult_confirmed'=>'required|accepted',
   'notifications_enabled'=>'required|boolean','push_opt_in'=>'required|boolean',
   'fcm_token'=>'nullable|string|max:4096',
  ]);
  // This endpoint collects adult-opt-in analytics only. No child profile is sent or saved.
  if(DeviceRegistration::where('installation_id',$data['installation_id'])->exists())
    return response()->json(['message'=>'Already registered. Use the previous device key or reset registration.'],409);
  $secret=bin2hex(random_bytes(32));
  $device=DeviceRegistration::create([
   'installation_id'=>$data['installation_id'],'token_hash'=>hash('sha256',$secret),
   'platform'=>$data['platform'],'app_version'=>$data['app_version'],
   'country_code'=>$country->resolve($request),'locale'=>$data['locale']??'ar',
   'analytics_consent'=>true,
   'notifications_enabled'=>$data['notifications_enabled'],
   'push_opt_in'=>(bool)$data['push_opt_in'] && (bool)$data['notifications_enabled'],
   'fcm_token'=>(!empty($data['push_opt_in'])&&!empty($data['notifications_enabled']))?($data['fcm_token']??null):null,
   'last_seen_at'=>now(),
  ]);
  return response()->json(['installation_id'=>$device->installation_id,'device_key'=>$secret,'country_code'=>$device->country_code],201);
 }
 public function heartbeat(Request $request,CountryResolver $country) {
  $device=$this->own($request);
  $data=$request->validate([
   'app_version'=>'nullable|string|max:32','locale'=>'nullable|string|max:12',
   'notifications_enabled'=>'nullable|boolean','push_opt_in'=>'nullable|boolean',
   'fcm_token'=>'nullable|string|max:4096',
  ]);
  $device->fill(['last_seen_at'=>now()]);
  if(!$device->country_code)$device->country_code=$country->resolve($request);
  foreach(['app_version','locale','notifications_enabled','push_opt_in'] as $key)if(array_key_exists($key,$data))$device->{$key}=$data[$key];
  if(!$device->notifications_enabled || !$device->push_opt_in)$device->fcm_token=null;
  else if(array_key_exists('fcm_token',$data))$device->fcm_token=$data['fcm_token'];
  $device->save();
  return response()->json(['ok'=>true,'country_code'=>$device->country_code]);
 }
 public function delete(Request $request) {
  $device=$this->own($request);$device->delete();
  return response()->json(['deleted'=>true]);
 }
}
