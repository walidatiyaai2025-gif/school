<?php
namespace App\Http\Controllers\Admin;

use App\Models\AdApproval;
use App\Models\AdSetting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdsController {
    public function index() {
        $rows=AdSetting::orderBy('provider')->get();
        $txt=is_file(public_path('app-ads.txt'))?file_get_contents(public_path('app-ads.txt')):'';
        return view('admin.ads',[
            'rows'=>$rows,
            'txt'=>$txt,
            'approval'=>AdApproval::isApproved(),
            'emergencyStop'=>(bool)config('schoolpdf.ads_emergency_stop'),
        ]);
    }

    public function policy(Request $request) {
        $data=$request->validate([
            'enable'=>'required|boolean',
            'certified_admob'=>'required_if:enable,1|accepted_if:enable,1',
            'child_treatment'=>'required_if:enable,1|accepted_if:enable,1',
            'ump_configured'=>'required_if:enable,1|accepted_if:enable,1',
            'play_declarations'=>'required_if:enable,1|accepted_if:enable,1',
            'mediation_review'=>'required_if:enable,1|accepted_if:enable,1',
        ]);
        $enabled=$request->boolean('enable');
        if($enabled && config('schoolpdf.ads_emergency_stop')) {
            return back()->withErrors(['enable'=>'Ads emergency stop is set on this host.']);
        }
        DB::transaction(function() use($enabled) {
            AdApproval::updateOrCreate(['id'=>1],[
                'approved'=>$enabled,
                'approved_at'=>$enabled?now():null,
                'approved_by'=>$enabled?auth()->id():null,
            ]);
            if(!$enabled) AdSetting::where('enabled',true)->update(['enabled'=>false,'interstitial_enabled'=>false]);
        });
        return back()->with('ok',$enabled
            ?'Families advertising approval saved. Enable the AdMob banner below to serve ads.'
            :'All ad providers disabled immediately. No mobile rebuild needed to turn them off.');
    }

    public function save(Request $request) {
        $data=$request->validate([
            'provider'=>'required|in:admob,applovin,unity_levelplay,mintegral,meta',
            'platform'=>'required|in:android,ios',
            'enable'=>'nullable|boolean',
            'app_id'=>'nullable|string|max:255',
            'banner_unit_id'=>'nullable|string|max:255',
            'interstitial_unit_id'=>'nullable|string|max:255',
            'enable_interstitial'=>'nullable|boolean',
            'interstitial_families_confirmed'=>'required_if:enable_interstitial,1|accepted_if:enable_interstitial,1',
            'notes'=>'nullable|string|max:2000',
        ]);
        $want=$request->boolean('enable');
        $wantInterstitial=$request->boolean('enable_interstitial');
        $allowed=$data['provider']==='admob' && AdApproval::isApproved()
            && !config('schoolpdf.ads_emergency_stop');
        if($want && !$allowed) {
            return back()->withErrors(['enable'=>'Families approval required. Only verified AdMob is allowed.']);
        }
        if($wantInterstitial && (!$want || !$allowed)) {
            return back()->withErrors(['enable_interstitial'=>'Interstitial ads require an enabled, Families-approved AdMob provider.']);
        }
        $appId=trim($data['app_id']??'');
        $bannerId=trim($data['banner_unit_id']??'');
        $interstitialId=trim($data['interstitial_unit_id']??'');
        if($want && (!preg_match('/^ca-app-pub-(\d+)~\d+$/',$appId,$app)
                || !preg_match('/^ca-app-pub-(\d+)\/\d+$/',$bannerId,$unit)
                || $app[1]!==$unit[1])) {
            return back()->withErrors(['banner_unit_id'=>'App ID and Banner Unit must be valid AdMob IDs from the same publisher.']);
        }
        if ($wantInterstitial && (!preg_match('/^ca-app-pub-(\d+)\/\d+$/',$interstitialId,$interstitial)
            || $interstitial[1]!==$app[1] || $interstitialId===$bannerId)) {
            return back()->withErrors(['interstitial_unit_id'=>'Use a dedicated AdMob Interstitial Unit ID from the same publisher, different from the Banner Unit.']);
        }
        AdSetting::updateOrCreate(
            ['provider'=>$data['provider'],'platform'=>$data['platform']],
            ['app_id'=>$appId?:null,'banner_unit_id'=>$bannerId?:null,
             'interstitial_unit_id'=>$interstitialId?:null,
             'interstitial_enabled'=>$wantInterstitial && $want && $allowed,
             'notes'=>$data['notes']??null,'enabled'=>$want && $allowed]
        );
        return back()->with('ok',$want
            ?'AdMob enabled for the selected platform. Game interstitials are independently gated; child-safe treatment is mandatory.'
            :'Settings saved. This provider is disabled.');
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
