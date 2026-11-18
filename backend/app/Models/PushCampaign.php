<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class PushCampaign extends Model {
 protected $fillable=['title','body','country_code','status','created_by','total_targets','sent_count','failed_count','sent_at'];
 protected function casts(): array {return ['sent_at'=>'datetime'];}
}
