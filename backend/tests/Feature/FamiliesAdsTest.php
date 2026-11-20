<?php
namespace Tests\Feature;

use App\Models\AdSetting;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FamiliesAdsTest extends TestCase {
    use RefreshDatabase;

    private function superAdmin(): User {
        return User::create([
            'name'=>'Families QA','email'=>'families@example.invalid',
            'password'=>'example-strong-hashed-password',
            'role'=>'super_admin','is_active'=>true,
        ]);
    }
    private function admobData(bool $enabled=true): array {
        return [
            'provider'=>'admob','platform'=>'android',
            'app_id'=>'ca-app-pub-3218037275900725~8048418854',
            'banner_unit_id'=>'ca-app-pub-3218037275900725/8379591348',
            'enable'=>$enabled?'1':'0',
        ];
    }
    private function approvalData(): array {
        return [
            'enable'=>'1','certified_admob'=>'1','child_treatment'=>'1',
            'ump_configured'=>'1','play_declarations'=>'1',
            'mediation_review'=>'1',
        ];
    }
    public function test_ads_are_disabled_before_explicit_superadmin_policy_review(): void {
        $this->getJson('/api/v1/config')->assertOk()->assertJsonPath('ads.enabled',false);
        $this->post('/admin/ads/policy',$this->approvalData())->assertRedirect('/admin/login');
        $this->actingAs($this->superAdmin())->post('/admin/ads',$this->admobData())->assertSessionHasErrors('enable');
        $this->assertDatabaseCount('ad_settings',0);
        $this->getJson('/api/v1/config')->assertJsonPath('ads.enabled',false);
    }
    public function test_partial_review_cannot_activate_ads(): void {
        $this->actingAs($this->superAdmin());
        $this->post('/admin/ads/policy',['enable'=>'1','certified_admob'=>'1'])
            ->assertSessionHasErrors(['child_treatment','ump_configured','play_declarations','mediation_review']);
        $this->getJson('/api/v1/config')->assertJsonPath('ads.enabled',false);
    }
    public function test_approved_google_admob_can_serve_but_no_other_networks(): void {
        $this->actingAs($this->superAdmin());
        $this->post('/admin/ads/policy',$this->approvalData())->assertSessionHasNoErrors();
        $this->post('/admin/ads',$this->admobData())->assertSessionHasNoErrors();
        $this->getJson('/api/v1/config')->assertOk()->assertJsonPath('ads.enabled',true)
            ->assertJsonPath('ads.max_content_rating','G')
            ->assertJsonPath('ads.third_party_mediation',false)
            ->assertJsonCount(1,'ads.providers')
            ->assertJsonPath('ads.providers.0.provider','admob');
        $other=$this->admobData();
        $other['provider']='meta';
        $this->post('/admin/ads',$other)->assertSessionHasErrors('enable');
        $this->assertDatabaseCount('ad_settings',1);
    }
    public function test_invalid_or_cross_publisher_ids_are_blocked(): void {
        $this->actingAs($this->superAdmin())
            ->post('/admin/ads/policy',$this->approvalData());
        $bad=$this->admobData();
        $bad['banner_unit_id']='ca-app-pub-9999999999999999/8379591348';
        $this->post('/admin/ads',$bad)->assertSessionHasErrors('banner_unit_id');
        $this->getJson('/api/v1/config')->assertJsonPath('ads.enabled',false);
    }
    public function test_revoke_and_emergency_stop_block_ads_immediately(): void {
        $this->actingAs($this->superAdmin())
            ->post('/admin/ads/policy',$this->approvalData());
        $this->post('/admin/ads',$this->admobData());
        config()->set('schoolpdf.ads_emergency_stop',true);
        $this->getJson('/api/v1/config')->assertJsonPath('ads.enabled',false);
        config()->set('schoolpdf.ads_emergency_stop',false);
        $this->post('/admin/ads/policy',['enable'=>'0'])->assertSessionHasNoErrors();
        $this->getJson('/api/v1/config')->assertJsonPath('ads.enabled',false);
        $this->assertFalse((bool)AdSetting::first()->enabled);
    }
    public function test_non_superadmin_cannot_approve_or_enable_ads(): void {
        $viewer=User::create([
            'name'=>'Viewer','email'=>'viewer@example.invalid',
            'password'=>'example-strong-hashed-password','role'=>'viewer','is_active'=>true,
        ]);
        $this->actingAs($viewer)->post('/admin/ads/policy',$this->approvalData())->assertForbidden();
        $this->actingAs($viewer)->post('/admin/ads',$this->admobData())->assertForbidden();
        $this->getJson('/api/v1/config')->assertJsonPath('ads.enabled',false);
    }
}
