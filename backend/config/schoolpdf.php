<?php
return [
 'base_url'=>env('SCHOOLPDF_BASE_URL','https://sclpdf.50sols.com'),
 'country_proxy_cidrs'=>array_filter(array_map('trim',explode(',',env('SCHOOLPDF_COUNTRY_PROXY_CIDRS','')))),
 'firebase_project'=>env('SCHOOLPDF_FIREBASE_PROJECT_ID',''),
 'service_account_file'=>env('SCHOOLPDF_GOOGLE_SERVICE_ACCOUNT_FILE',''),
 'allow_ads'=>(bool)env('SCHOOLPDF_ALLOW_ADS',false),
 'ads_policy_approved'=>(bool)env('SCHOOLPDF_ADS_POLICY_APPROVED',false),
 'update_public_key'=>env('SCHOOLPDF_ED25519_UPDATE_PUBLIC_KEY',''),
 ];
