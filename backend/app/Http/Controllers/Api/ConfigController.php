<?php
namespace App\Http\Controllers\Api;

use App\Models\AdApproval;
use App\Models\AdSetting;

class ConfigController {
    public function __invoke() {
        // Only approved/active AdMob banners. Server emergency stop overrides
        // all dashboard settings. Before migration or on DB failure, fail OFF.
        $enabled=AdApproval::isApproved()
            && !config('schoolpdf.ads_emergency_stop');
        $providers=$enabled
            ? AdSetting::where('provider','admob')->where('enabled',true)
                ->whereIn('platform',['android','ios'])
                ->get(['provider','platform','banner_unit_id'])
            : [];
        return response()->json([
            'app'=>'School PDF','version'=>'1.1.4',
            'privacy_url'=>'https://sclpdf.50sols.com/privacy',
            'support_url'=>'https://sclpdf.50sols.com/support',
            'ads'=>[
                'enabled'=>$enabled && count($providers)>0,
                'families_safe'=>true,
                'max_content_rating'=>'G',
                'third_party_mediation'=>false,
                'providers'=>$providers,
            ],
        ])->header('Cache-Control','private, no-store');
    }
}
