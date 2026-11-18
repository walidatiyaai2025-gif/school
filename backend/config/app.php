<?php
return [
 'name'=>env('APP_NAME','School PDF'), 'env'=>env('APP_ENV','production'), 'debug'=>(bool)env('APP_DEBUG',false),
 'url'=>env('APP_URL','https://sclpdf.50sols.com'), 'timezone'=>'UTC', 'locale'=>env('APP_LOCALE','ar'),
 'fallback_locale'=>env('APP_FALLBACK_LOCALE','en'), 'faker_locale'=>'en_US',
 'key'=>env('APP_KEY'), 'cipher'=>'AES-256-CBC', 'previous_keys'=>array_filter(explode(',',env('APP_PREVIOUS_KEYS',''))),
 'maintenance'=>['driver'=>'file','store'=>'database'],
];
