<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class AdSetting extends Model {
 protected $fillable=['provider','platform','app_id','banner_unit_id','enabled','notes'];
 protected function casts(): array {return ['enabled'=>'boolean'];}
}
