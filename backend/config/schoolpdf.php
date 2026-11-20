<?php
return [
 'support_email'=>env('SCHOOLPDF_SUPPORT_EMAIL','info@50sols.com'),
 'base_url'=>env('SCHOOLPDF_BASE_URL','https://sclpdf.50sols.com'),
 'country_proxy_cidrs'=>array_filter(array_map('trim',explode(',',env('SCHOOLPDF_COUNTRY_PROXY_CIDRS','')))),
 'firebase_project'=>env('SCHOOLPDF_FIREBASE_PROJECT_ID',''),
 'service_account_file'=>env('SCHOOLPDF_GOOGLE_SERVICE_ACCOUNT_FILE',''),
 'ads_emergency_stop'=>(bool)env('SCHOOLPDF_ADS_EMERGENCY_STOP',false),
 // Compatibility with older .env files. Ad activation is now DB-policy
 // approved by Super Admin; these legacy flags are not activation switches.
 'allow_ads'=>(bool)env('SCHOOLPDF_ALLOW_ADS',false),
 'ads_policy_approved'=>(bool)env('SCHOOLPDF_ADS_POLICY_APPROVED',false),
 'update_public_key'=>env('SCHOOLPDF_ED25519_UPDATE_PUBLIC_KEY',''),
 ];
