<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class AdSetting extends Model {
 protected $fillable=['provider','platform','app_id','banner_unit_id','interstitial_unit_id','interstitial_enabled','enabled','notes'];
 protected function casts(): array {return ['enabled'=>'boolean','interstitial_enabled'=>'boolean'];}
}
