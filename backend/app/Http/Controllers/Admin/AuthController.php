<?php
namespace App\Http\Controllers\Admin;
use Illuminate\Http\Request;use Illuminate\Support\Facades\Auth;
class AuthController {
 public function loginPage() {return view('admin.login');}
 public function login(Request $request) {
  $data=$request->validate(['email'=>'required|email','password'=>'required|string']);
  if(Auth::attempt(['email'=>$data['email'],'password'=>$data['password'],'is_active'=>true])){
   if(Auth::user()->role!=='super_admin'){Auth::logout();return back()->withErrors(['email'=>'Not authorized']);}
   $request->session()->regenerate();return redirect()->route('admin.dashboard');
  }
  return back()->withErrors(['email'=>'Invalid credentials']);
 }
 public function logout(Request $request){Auth::logout();$request->session()->invalidate();$request->session()->regenerateToken();return redirect()->route('admin.login');}
}
