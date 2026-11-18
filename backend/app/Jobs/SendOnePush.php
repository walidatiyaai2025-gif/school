<?php
namespace App\Jobs;
use App\Models\PushDelivery;use App\Services\FcmSender;
use Illuminate\Contracts\Queue\ShouldQueue;use Illuminate\Foundation\Queue\Queueable;
class SendOnePush implements ShouldQueue {
 use Queueable;
 public $timeout=60;public $tries=2;
 public function __construct(public int $deliveryId) {}
 public function handle(FcmSender $fcm): void {
  $delivery=PushDelivery::with(['campaign','device'])->find($this->deliveryId);
  if(!$delivery||$delivery->status!=='queued')return;
  $campaign=$delivery->campaign;$device=$delivery->device;
  try {
   if(!$device||!$device->analytics_consent||!$device->push_opt_in||!$device->notifications_enabled||!$device->fcm_token)
     throw new \RuntimeException('Token withdrawn or missing');
   $message=$fcm->send($device->fcm_token,$campaign->title,$campaign->body);
   $delivery->update(['status'=>'sent','provider_message_id'=>$message]);
   $campaign->increment('sent_count');
  } catch(\Throwable $e) {
   $delivery->update(['status'=>'failed','error_message'=>mb_substr($e->getMessage(),0,250)]);
   $campaign->increment('failed_count');
  }
  $campaign->refresh();
  if(($campaign->sent_count+$campaign->failed_count)>=$campaign->total_targets && $campaign->status==='sending')
   $campaign->update(['status'=>'finished','sent_at'=>now()]);
 }
}
