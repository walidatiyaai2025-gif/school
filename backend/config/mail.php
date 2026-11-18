<?php
return [
    'default' => env('MAIL_MAILER', 'log'),
    'mailers' => [
        'log' => ['transport' => 'log', 'channel' => env('MAIL_LOG_CHANNEL')],
        'smtp' => [
            'transport' => 'smtp', 'scheme' => env('MAIL_SCHEME'),
            'host' => env('MAIL_HOST', '127.0.0.1'), 'port' => (int)env('MAIL_PORT', 587),
            'username' => env('MAIL_USERNAME'), 'password' => env('MAIL_PASSWORD'),
            'timeout' => null, 'local_domain' => env('MAIL_EHLO_DOMAIN'),
        ],
    ],
    'from' => [
        'address' => env('MAIL_FROM_ADDRESS', 'no-reply@sclpdf.50sols.com'),
        'name' => env('MAIL_FROM_NAME', 'School PDF'),
    ],
];
