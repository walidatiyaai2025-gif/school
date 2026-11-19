<?php
/** Use the ORIGINAL installer in the private Laravel root. */
declare(strict_types=1);
require __DIR__ . '/.schoolpdf-bridge.php';
$schoolpdfPrivate = schoolpdfPrivateRoot();
require $schoolpdfPrivate . '/public/install.php';
