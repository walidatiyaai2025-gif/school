<?php
namespace App\Http\Controllers\Admin;
use Illuminate\Http\Request;
class SystemUpdateController {
 public function index(){return view('admin.updates',['version'=>'1.1.2']);}
 public function verify(Request $request) {
  $request->validate(['package'=>'required|file|max:102400|mimes:zip']);
  // Never apply a ZIP based only on a SHA-256; signing, backup, compatible migrations,
  // atomic file swap and disaster recovery must be proven before enabling in production.
  return back()->withErrors(['package'=>'Update installation is safety-locked until signed ZIP verification, recovery and exact-release CI are completed. No files changed.']);
 }
}
