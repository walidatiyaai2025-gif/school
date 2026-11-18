<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class PushDelivery extends Model {
 protected $fillable=['push_campaign_id','device_registration_id','status','provider_message_id','error_message'];
 public function campaign(){return $this->belongsTo(PushCampaign::class,'push_campaign_id');}
 public function device(){return $this->belongsTo(DeviceRegistration::class,'device_registration_id');}
}
