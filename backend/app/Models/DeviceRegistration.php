<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Prunable;
class DeviceRegistration extends Model {
 use Prunable;
 public function prunable(){return static::where('last_seen_at','<',now()->subDays(90));}
 protected $fillable=['installation_id','token_hash','platform','app_version','country_code','locale','notifications_enabled','push_opt_in','analytics_consent','fcm_token','last_seen_at'];
 protected $hidden=['token_hash','fcm_token'];
 protected function casts(): array {return ['notifications_enabled'=>'boolean','push_opt_in'=>'boolean','analytics_consent'=>'boolean','fcm_token'=>'encrypted','last_seen_at'=>'datetime'];}
}
