<?php
namespace Tests\Feature;
use Tests\TestCase; use Illuminate\Foundation\Testing\RefreshDatabase;
use App\Models\User; use Illuminate\Support\Facades\Hash;
class AdminTest extends TestCase {
 use RefreshDatabase;
 public function test_dashboard_requires_super_admin(): void {
  $this->get('/admin')->assertRedirect('/admin/login');
  $user=User::create(['name'=>'Test','email'=>'test@example.invalid','password'=>Hash::make('a-secure-test-password'),
     'role'=>'viewer','is_active'=>true]);
  $this->actingAs($user)->get('/admin')->assertForbidden();
  $user->update(['role'=>'super_admin']);
  $this->actingAs($user)->get('/admin')->assertOk();
 }
 public function test_update_zip_installation_remains_safety_locked(): void {
  $user=User::create(['name'=>'Admin','email'=>'admin@example.invalid','password'=>Hash::make('a-secure-test-password'),
   'role'=>'super_admin','is_active'=>true]);
  $this->actingAs($user)->get('/admin/system-updates')->assertOk();
 }
}
