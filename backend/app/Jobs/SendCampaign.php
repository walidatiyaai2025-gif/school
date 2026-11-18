<?php
namespace App\Jobs;
use App\Models\DeviceRegistration;use App\Models\PushCampaign;
use App\Models\PushDelivery;use Illuminate\Contracts\Queue\ShouldQueue;use Illuminate\Foundation\Queue\Queueable;
class SendCampaign implements ShouldQueue {
 use Queueable;
 public $timeout=120;
 public function __construct(public int $campaignId) {}
 public function handle(): void {
  $campaign=PushCampaign::findOrFail($this->campaignId);
  if($campaign->status!=='queued')return;
  $query=DeviceRegistration::query()->where('analytics_consent',true)->where('notifications_enabled',true)
   ->where('push_opt_in',true)->whereNotNull('fcm_token');
  if($campaign->country_code)$query->where('country_code',$campaign->country_code);
  $count=(clone $query)->count();
  $campaign->update(['status'=>'sending','total_targets'=>$count]);
  $query->orderBy('id')->chunkById(100,function($devices)use($campaign){
   foreach($devices as $device){
    $delivery=PushDelivery::firstOrCreate(['push_campaign_id'=>$campaign->id,'device_registration_id'=>$device->id],['status'=>'queued']);
    if($delivery->wasRecentlyCreated) SendOnePush::dispatch($delivery->id);
   }
  });
  if($count===0)$campaign->update(['status'=>'finished','sent_at'=>now()]);
 }
}
