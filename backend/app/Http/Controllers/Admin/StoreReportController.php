<?php
namespace App\Http\Controllers\Admin;
use Illuminate\Http\Request;use Illuminate\Support\Facades\DB;
class StoreReportController {
 public function import(Request $request){
  $request->validate(['csv'=>'required|file|max:2048|mimes:csv,txt']);
  $handle=fopen($request->file('csv')->getRealPath(),'r');
  if(!$handle)return back()->withErrors(['csv'=>'Unreadable CSV']);
  try {
   $header=fgetcsv($handle); if($header!==['report_date','store','country_code','installs'])
     return back()->withErrors(['csv'=>'Expected CSV header: report_date,store,country_code,installs']);
   $items=[];$count=0;
   while(($row=fgetcsv($handle))!==false){
    if(++$count>5000||count($row)!==4)return back()->withErrors(['csv'=>'Bad row or too many rows']);
    [$date,$store,$country,$installs]=$row;
    if(!preg_match('/^20\d{2}-\d{2}-\d{2}$/',$date)||
      !in_array($store,['google_play','app_store'],true)||!preg_match('/^[A-Z]{2}$/',$country)||
      !preg_match('/^\d{1,9}$/',$installs)||!checkdate((int)substr($date,5,2),(int)substr($date,8,2),(int)substr($date,0,4)))
      return back()->withErrors(['csv'=>'Invalid CSV row format']);
    $items[]=['report_date'=>$date,'store'=>$store,'country_code'=>$country,'installs'=>(int)$installs];
   }
   DB::transaction(function()use($items){foreach($items as $row){DB::table('store_install_reports')->updateOrInsert(
     ['report_date'=>$row['report_date'],'store'=>$row['store'],'country_code'=>$row['country_code']],
     ['installs'=>$row['installs'],'updated_at'=>now(),'created_at'=>now()]);}});
   return back()->with('ok',"Imported $count normalized CSV rows. Source authenticity is not verified automatically.");
  } finally {fclose($handle);}
 }
}
