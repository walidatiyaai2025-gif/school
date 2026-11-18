<?php
namespace Tests;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Illuminate\Contracts\Console\Kernel;
abstract class TestCase extends BaseTestCase {
 public function createApplication() {
  $app=require __DIR__.'/../bootstrap/app.php';
  $app->make(Kernel::class)->bootstrap();
  return $app;
 }
 protected function setUp(): void {
  parent::setUp();
  if(!is_dir(storage_path('app/private')))mkdir(storage_path('app/private'),0750,true);
  file_put_contents(storage_path('app/private/install.lock'),'testing');
 }
 protected function tearDown(): void {
  @unlink(storage_path('app/private/install.lock'));
  parent::tearDown();
 }
}
