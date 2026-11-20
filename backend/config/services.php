<?php
return [
    'schoolpdf_office' => [
        'enabled' => env('SCHOOLPDF_OFFICE_CONVERSION_ENABLED', false),
        'binary' => env('SCHOOLPDF_OFFICE_BINARY', '/usr/bin/libreoffice'),
    ],
];
