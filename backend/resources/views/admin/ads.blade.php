<x-shell title="School PDF — Families Ads Settings">
<div class="row" style="justify-content:space-between">
  <h1>💰 AdMob — إعلانات آمنة لجميع الأعمار</h1>
  <a href="{{ route('admin.dashboard') }}">العودة للوحة</a>
</div>
<p>Official domain <code>sclpdf.50sols.com</code> · <a href="{{ url('/app-ads.txt') }}">app-ads.txt</a> · <a href="{{ url('/privacy') }}">Privacy</a></p>
@if(session('ok'))<div class="ok">{{ session('ok') }}</div>@endif
@if($errors->any())<div class="error">{{ $errors->first() }}</div>@endif
<div class="card">
  <h2>Families Advertising Readiness / مراجعة سياسة إعلانات الأطفال</h2>
  <p>الحالة الحالية: <strong>{{ $emergencyStop ? 'EMERGENCY STOP' : ($approval ? 'Approved by Super Admin' : 'Disabled — awaiting approval') }}</strong></p>
  <p class="muted">Only Google AdMob self-certified SDK. For child/teen/unknown: CHILD treatment, no personalized ads, G-rated inventory, no other mediation networks. Game interstitials require a separate, approved, age-safe unit and a dismissible creative. Confirm real Google Play / AdMob controls before enabling. This admin approval is NOT proof of Play certification.</p>
  <form action="{{ route('admin.ads.policy') }}" method="post">@csrf
    <label><input type="radio" name="enable" value="0" checked style="width:auto"> Disable all ads immediately / إيقاف كل الإعلانات</label>
    <label><input type="radio" name="enable" value="1" style="width:auto"> Enable after review / تفعيل بعد المراجعة</label>
    <label><input type="checkbox" name="certified_admob" value="1" style="width:auto"> Verified the installed Google AdMob Android SDK version is Families Self-Certified.</label>
    <label><input type="checkbox" name="child_treatment" value="1" style="width:auto"> Tested child, teen, adult, unknown: age screen, CHILD treatment, G rating and non-personalized ads.</label>
    <label><input type="checkbox" name="ump_configured" value="1" style="width:auto"> Configured Google AdMob Privacy &amp; messaging (UMP) for applicable adult audiences.</label>
    <label><input type="checkbox" name="play_declarations" value="1" style="width:auto"> Reviewed Google Play Families, Ads, Advertising ID, Data Safety and updated public privacy policy.</label>
    <label><input type="checkbox" name="mediation_review" value="1" style="width:auto"> Confirmed no unapproved third-party mediation/custom events can serve ads to children.</label>
    <p><button type="submit">Save reviewed policy / حفظ مراجعة الأمان</button></p>
  </form>
  <p class="muted">Emergency stop: <code>SCHOOLPDF_ADS_EMERGENCY_STOP=true</code> on host; this always forces ads off. All enable actions are protected by Super Admin auth and CSRF.</p>
</div>
<div class="grid" style="grid-template-columns:1fr 1fr">
<div class="card"><h2>Google AdMob Banner / بانر</h2>
<form method="post" action="{{ route('admin.ads.save') }}">@csrf
<label>الشبكة / Provider</label>
<select name="provider"><option value="admob">Google AdMob (Families certified)</option>
<option value="applovin">AppLovin (storage only — never enabled)</option>
<option value="unity_levelplay">Unity (storage only — never enabled)</option>
<option value="mintegral">Mintegral (storage only — never enabled)</option>
<option value="meta">Meta (storage only — never enabled)</option></select>
<label>المنصة / Platform</label><select name="platform"><option value="android">Android</option><option value="ios">iOS</option></select>
<label>AdMob App ID</label><input name="app_id" autocomplete="off" placeholder="ca-app-pub-...~...">
<label>Banner Unit ID</label><input name="banner_unit_id" autocomplete="off" placeholder="ca-app-pub-.../...">
<label>Game Interstitial Ad Unit ID (different from Banner)</label>
<input name="interstitial_unit_id" autocomplete="off" placeholder="ca-app-pub-.../...">
<label><input type="checkbox" name="enable_interstitial" value="1" style="width:auto">
Enable XO full-screen interstitial after six completed games, at the replay transition</label>
<label><input type="checkbox" name="interstitial_families_confirmed" value="1" style="width:auto">
I reviewed the Interstitial creative/close UX for children (clear dismissal within 5 seconds), Google Play Families compliance, G-rated non-personalized inventory, and AdMob app readiness.</label>
<p class="muted">Banner and Interstitial use separate Google AdMob units. Games remain free if no fill/consent/network. In debug, use Google's test Interstitial ID; do not click real ads during testing. New backend migration is required before enabling this format.</p>
<label>Notes</label><textarea name="notes"></textarea>
<label><input type="checkbox" name="enable" value="1" style="width:auto"> Enable this AdMob banner only after the Families checklist is approved</label>
<p><button>Save AdMob settings</button></p>
</form></div>
<div class="card"><h2>app-ads.txt — Authorized sellers</h2>
<form method="post" action="{{ route('admin.ads.sellers') }}">@csrf
<textarea rows="12" name="sellers" dir="ltr" spellcheck="false">{{ old('sellers',$txt) }}</textarea>
<p><button>Save app-ads.txt</button></p></form>
<p>Google UMP forms and ad mediation sources are configured separately in AdMob Console.</p>
</div></div>
<div class="card"><h2>Configured Providers / الشبكات المحفوظة</h2>
<table><tr><th>Provider</th><th>Platform</th><th>App ID</th><th>Banner</th><th>Interstitial</th><th>Status</th></tr>
@forelse($rows as $r)
<tr><td>{{ $r->provider }}</td><td>{{ $r->platform }}</td>
<td>{{ $r->app_id }}</td><td>{{ $r->banner_unit_id }}</td>
<td>{{ $r->interstitial_unit_id ?: '—' }} · {{ $r->interstitial_enabled && $r->enabled && $approval && !$emergencyStop ? 'Enabled' : 'OFF' }}</td>
<td>{{ $r->enabled ? ($approval && !$emergencyStop ? 'Active' : 'Safety OFF') : 'Disabled' }}</td></tr>
@empty<tr><td colspan="6">No configured providers yet.</td></tr>@endforelse</table>
</div>
</x-shell>
