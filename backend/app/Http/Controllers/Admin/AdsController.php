<?php
namespace App\Http\Controllers\Admin;
use App\Models\AdSetting;use Illuminate\Http\Request;
class AdsController {
 public function index(){ $rows=AdSetting::orderBy('provider')->get(); $txt=is_file(public_path('app-ads.txt'))?file_get_contents(public_path('app-ads.txt')):'';return view('admin.ads',['rows'=>$rows,'txt'=>$txt]); }
 public function save(Request $request) {
  $d=$request->validate(['provider'=>'required|in:admob,applovin,unity_levelplay,mintegral,meta',
   'platform'=>'required|in:android,ios','enable'=>'nullable|boolean','app_id'=>'nullable|string|max:255',
   'banner_unit_id'=>'nullable|string|max:255','notes'=>'nullable|string|max:2000']);
  $row=AdSetting::updateOrCreate(['provider'=>$d['provider'],'platform'=>$d['platform']],[
   'app_id'=>$d['app_id']??null,'banner_unit_id'=>$d['banner_unit_id']??null,'notes'=>$d['notes']??null,
   'enabled'=>(bool)($request->boolean('enable') && config('schoolpdf.allow_ads') && config('schoolpdf.ads_policy_approved'))]);
  return back()->with('ok','Saved. Enable is effective only if both server safety flags and mobile consent checks are configured.');
 }
 public function sellers(Request $request) {
  $d=$request->validate(['sellers'=>'required|string|max:20000']);
  $lines=preg_split('/\r?\n/',trim($d['sellers']));
  foreach($lines as $line) {
   if(trim($line)===''||str_starts_with(trim($line),'#'))continue;
   if(!preg_match('/^[a-zA-Z0-9.-]+,\s*[a-zA-Z0-9_-]+,\s*(DIRECT|RESELLER)(,\s*[a-zA-Z0-9_-]+)?$/',$line))
     return back()->withErrors(['sellers'=>'Invalid seller record. Paste the exact network authorization line.']);
  }
  file_put_contents(public_path('app-ads.txt'),implode("\n",$lines)."\n",LOCK_EX);
  return back()->with('ok','app-ads.txt saved. Verify it at the public URL.');
 }
}
