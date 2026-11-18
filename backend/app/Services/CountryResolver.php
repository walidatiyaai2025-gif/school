<?php
namespace App\Services;
use Illuminate\Http\Request;
/** Trust CF-IPCountry only if the direct TCP peer is a configured trusted proxy.
 * Client-supplied country parameters are always ignored. No IP is persisted. */
class CountryResolver {
 public function resolve(Request $request): ?string {
  $peer=$request->server('REMOTE_ADDR','');
  $ranges=config('schoolpdf.country_proxy_cidrs',[]);
  if (!collect($ranges)->contains(fn($cidr)=>self::inCidr((string)$peer,(string)$cidr))) return null;
  $value=strtoupper(trim((string)$request->header('CF-IPCountry','')));
  return preg_match('/^[A-Z]{2}$/',$value) && !in_array($value,['XX','T1','A1','A2','O1'],true)?$value:null;
 }
 public static function inCidr(string $ip,string $cidr): bool {
  $parts=explode('/',$cidr,2); if(count($parts)!==2)return false;
  $bin=@inet_pton($ip);$net=@inet_pton($parts[0]);if(!$bin||!$net||strlen($bin)!==strlen($net))return false;
  $bits=filter_var($parts[1],FILTER_VALIDATE_INT,['options'=>['min_range'=>0,'max_range'=>strlen($bin)*8]]);
  if($bits===false)return false;
  for($i=0;$i<strlen($bin);$i++){$mask=max(0,min(8,$bits-8*$i));if($mask===0)break;
   $byteMask=(0xFF << (8-$mask))&0xFF;
   if((ord($bin[$i])&$byteMask)!==(ord($net[$i])&$byteMask))return false;}
  return true;
 }
}
