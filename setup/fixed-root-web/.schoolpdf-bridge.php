<?php
/**
 * Fixed Document Root bridge for sclpdf.50sols.com on shared cPanel.
 *
 * Keep the Laravel application at $HOME/sclpdf, entirely outside public_html.
 * This file is deployed ONLY in $HOME/public_html/sclpdf.50sols.com.
 * Never accept an application path or filename from a request parameter.
 */
declare(strict_types=1);

function schoolpdfPrivateRoot(): string
{
    $home = realpath(dirname(__DIR__, 2));
    $web = realpath(__DIR__);
    if ($home === false || $web === false ||
        basename(__DIR__) !== 'sclpdf.50sols.com' ||
        basename(dirname(__DIR__)) !== 'public_html') {
        http_response_code(503);
        exit('School PDF: fixed document root layout does not match this package.');
    }

    $expected = $home . DIRECTORY_SEPARATOR . 'sclpdf';
    $private = realpath($expected);
    if ($private === false || $private !== $expected ||
        str_starts_with($private . DIRECTORY_SEPARATOR, $web . DIRECTORY_SEPARATOR) ||
        str_starts_with($web . DIRECTORY_SEPARATOR, $private . DIRECTORY_SEPARATOR) ||
        !is_file($private . '/SETUP_MANIFEST.json') ||
        !is_file($private . '/vendor/autoload.php') ||
        !is_file($private . '/bootstrap/app.php') ||
        !is_file($private . '/public/index.php') ||
        !is_file($private . '/public/install.php')) {
        http_response_code(503);
        exit('School PDF: private Laravel package missing or unsafe. Check File Manager.');
    }

    $manifest = json_decode((string)file_get_contents($private . '/SETUP_MANIFEST.json'), true);
    if (!is_array($manifest) || ($manifest['project'] ?? null) !== 'School PDF' ||
        ($manifest['kind'] ?? null) !== 'fresh-install' ||
        ($manifest['signed_updates'] ?? null) !== true) {
        http_response_code(503);
        exit('School PDF: the private installation package is not verified.');
    }
    return $private;
}

/**
 * Stream only explicitly approved public assets from the PRIVATE app.
 * This allows admin changes to app-ads.txt and later signed asset updates to
 * appear immediately without symlinks, shell commands or a second web deploy.
 */
function schoolpdfServePublicAsset(string $private): bool
{
    $path = parse_url((string)($_SERVER['REQUEST_URI'] ?? '/'), PHP_URL_PATH);
    if (!is_string($path)) {
        return false;
    }

    $named = [
        '/app-ads.txt' => 'text/plain; charset=utf-8',
        '/ads.txt' => 'text/plain; charset=utf-8',
        '/robots.txt' => 'text/plain; charset=utf-8',
        '/brand-icon.png' => 'image/png',
        '/favicon.ico' => 'image/x-icon',
    ];
    $assets = preg_match(
        '~^/(?:build|assets)/[A-Za-z0-9_./-]+\.(?:css|js|png|jpg|jpeg|gif|webp|svg|ico|woff|woff2|ttf)$~D',
        $path
    ) === 1;

    if (!isset($named[$path]) && !$assets) {
        // Never let encoded/path-traversal variants reach a private asset.
        if (str_contains($path, '%') || str_contains($path, '\\') ||
            str_contains($path, "\0") || str_contains($path, '/../') ||
            str_ends_with($path, '/..')) {
            http_response_code(400);
            exit('Invalid request path.');
        }
        return false;
    }

    $segments = explode('/', ltrim($path, '/'));
    foreach ($segments as $segment) {
        if ($segment === '' || $segment === '.' || $segment === '..' ||
            str_starts_with($segment, '.') || str_contains($segment, '\\')) {
            http_response_code(403);
            exit('Invalid public asset path.');
        }
    }

    $public = realpath($private . '/public');
    $asset = realpath($private . '/public/' . ltrim($path, '/'));
    if ($public === false || $asset === false ||
        !str_starts_with($asset, $public . DIRECTORY_SEPARATOR) ||
        !is_file($asset) || !is_readable($asset)) {
        http_response_code(404);
        exit('Public asset not found.');
    }

    $types = [
        'css' => 'text/css; charset=utf-8', 'js' => 'text/javascript; charset=utf-8',
        'png' => 'image/png', 'jpg' => 'image/jpeg', 'jpeg' => 'image/jpeg',
        'gif' => 'image/gif', 'webp' => 'image/webp', 'svg' => 'image/svg+xml',
        'ico' => 'image/x-icon', 'woff' => 'font/woff', 'woff2' => 'font/woff2',
        'ttf' => 'font/ttf',
    ];
    $extension = strtolower(pathinfo($asset, PATHINFO_EXTENSION));
    $contentType = $named[$path] ?? ($types[$extension] ?? 'application/octet-stream');
    header('Content-Type: ' . $contentType);
    header('X-Content-Type-Options: nosniff');
    header('Cache-Control: ' . ($path === '/app-ads.txt' ? 'no-cache' : 'public, max-age=300'));
    header('Content-Length: ' . (string)filesize($asset));
    if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'HEAD') {
        readfile($asset);
    }
    return true;
}
