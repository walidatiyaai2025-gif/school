<?php
/** Public-only entrypoint. Laravel and Composer stay outside public_html. */
declare(strict_types=1);
require __DIR__ . '/.schoolpdf-bridge.php';
$schoolpdfPrivate = schoolpdfPrivateRoot();
if (schoolpdfServePublicAsset($schoolpdfPrivate)) {
    exit;
}
require $schoolpdfPrivate . '/public/index.php';
