<?php
namespace Tests\Feature;
use Tests\TestCase; use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;use App\Models\DeviceRegistration;
class DeviceApiTest extends TestCase {
 use RefreshDatabase;
 private function registration(string $id): array {
  return ['installation_id'=>$id,'platform'=>'android','app_version'=>'1.1.1','locale'=>'ar',
    'analytics_consent'=>true,'adult_confirmed'=>true,'notifications_enabled'=>false,'push_opt_in'=>false];
 }
 public function test_consent_is_required_and_country_cannot_be_forged(): void {
  $id=(string)Str::uuid();
  $this->postJson('/api/v1/device/register',array_merge($this->registration($id),['analytics_consent'=>false]))->assertStatus(422);
  $r=$this->postJson('/api/v1/device/register',array_merge($this->registration($id),['country_code'=>'KW']));
  $r->assertCreated()->assertJsonStructure(['installation_id','device_key']);
  $this->assertNull(DeviceRegistration::first()->country_code);
  $this->postJson('/api/v1/device/register',$this->registration($id))->assertStatus(409);
 }
 public function test_heartbeat_and_delete_require_device_secret(): void {
  $id=(string)Str::uuid();$r=$this->postJson('/api/v1/device/register',$this->registration($id))->json();
  $headers=['X-SchoolPDF-Install-ID'=>$id,'X-SchoolPDF-Device-Key'=>'a-stranger-with-invalid-key-012345678901234'];
  $this->withHeaders($headers)->postJson('/api/v1/device/heartbeat',[])->assertStatus(401);
  $headers['X-SchoolPDF-Device-Key']=$r['device_key'];
  $this->withHeaders($headers)->postJson('/api/v1/device/heartbeat',['app_version'=>'1.1.1'])->assertOk();
  $this->withHeaders($headers)->deleteJson('/api/v1/device')->assertOk();
  $this->assertDatabaseCount('device_registrations',0);
 }
 public function test_proxy_header_only_from_allowed_peer(): void {
  $resolver=new \App\Services\CountryResolver();
  $this->assertTrue($resolver::inCidr('127.0.0.1','127.0.0.0/8'));
  $this->assertFalse($resolver::inCidr('8.8.8.8','127.0.0.0/8'));
  $this->assertFalse($resolver::inCidr('not-ip','127.0.0.0/8'));
 }
}
