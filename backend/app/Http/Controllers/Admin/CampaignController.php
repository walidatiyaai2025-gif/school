<?php
namespace App\Http\Controllers\Admin;
use App\Jobs\SendCampaign;use App\Models\PushCampaign;
use Illuminate\Http\Request;use Illuminate\Support\Facades\DB;
class CampaignController {
 public function create(Request $request) {
  $d=$request->validate(['title'=>'required|string|max:140','body'=>'required|string|max:1000',
   'country_code'=>['nullable','regex:/^[A-Z]{2}$/']]);
  $c=PushCampaign::create(['title'=>$d['title'],'body'=>$d['body'],
   'country_code'=>$d['country_code']??null,'created_by'=>auth()->id(),'status'=>'draft']);
  return redirect()->route('admin.dashboard')->with('ok','Draft #'.$c->id.' created; review before sending.');
 }
 public function send(PushCampaign $campaign) {
  // Defensive state transition; repeated POSTs cannot queue twice.
  $changed=PushCampaign::whereKey($campaign->id)->where('status','draft')->update(['status'=>'queued']);
  if(!$changed)return back()->withErrors(['campaign'=>'Campaign already queued or sent']);
  SendCampaign::dispatch($campaign->id);
  return back()->with('ok','Campaign queued. A configured queue worker or manual processor is required.');
 }
 public function process() {
  // Bounded manual queue processing for hosting without background workers.
  try {\Illuminate\Support\Facades\Artisan::call('queue:work',['--stop-when-empty'=>true,'--max-jobs'=>20,'--max-time'=>15,'--tries'=>2]);}
  catch(\Throwable $e){return back()->withErrors(['queue'=>'Queue could not be processed; check hosting permissions.']);}
  return back()->with('ok','Processed up to 20 queued jobs.');
 }
}
