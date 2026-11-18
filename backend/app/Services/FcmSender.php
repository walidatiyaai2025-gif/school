<?php
namespace App\Services;
use Illuminate\Support\Facades\Http;
use RuntimeException;
class FcmSender {
 private function b64(string $s): string {return rtrim(strtr(base64_encode($s),'+/','-_'),'=');}
 public function send(string $token,string $title,string $body): string {
  $file=config('schoolpdf.service_account_file');$project=config('schoolpdf.firebase_project');
  if(!$file || !$project || !is_file($file))throw new RuntimeException('Firebase service account is not configured');
  $account=json_decode((string)file_get_contents($file),true,512,JSON_THROW_ON_ERROR);
  if(empty($account['client_email'])||empty($account['private_key']))throw new RuntimeException('Invalid service account');
  $now=time();$claim=['iss'=>$account['client_email'],'scope'=>'https://www.googleapis.com/auth/firebase.messaging',
    'aud'=>'https://oauth2.googleapis.com/token','iat'=>$now,'exp'=>$now+3000];
  $unsigned=$this->b64(json_encode(['alg'=>'RS256','typ'=>'JWT'],JSON_THROW_ON_ERROR)).'.'.$this->b64(json_encode($claim,JSON_THROW_ON_ERROR));
  if(!openssl_sign($unsigned,$signature,$account['private_key'],OPENSSL_ALGO_SHA256))throw new RuntimeException('OAuth signing failed');
  $resp=Http::asForm()->timeout(20)->post('https://oauth2.googleapis.com/token',[
   'grant_type'=>'urn:ietf:params:oauth:grant-type:jwt-bearer','assertion'=>$unsigned.'.'.$this->b64($signature)]);
  if(!$resp->successful())throw new RuntimeException('FCM OAuth failed '.$resp->status());
  $access=$resp->json('access_token');
  if(!is_string($access)||!$access)throw new RuntimeException('FCM OAuth token missing');
  $result=Http::withToken($access)->timeout(20)->post('https://fcm.googleapis.com/v1/projects/'.rawurlencode($project).'/messages:send',[
   'message'=>['token'=>$token,'notification'=>['title'=>$title,'body'=>$body],
    'android'=>['notification'=>['channel_id'=>'schoolpdf_updates']],'apns'=>['payload'=>['aps'=>['sound'=>'default']]]],
  ]);
  if(!$result->successful())throw new RuntimeException('FCM send HTTP '.$result->status().': '.substr((string)$result->json('error.status'),0,100));
  return (string)$result->json('name','');
 }
}
