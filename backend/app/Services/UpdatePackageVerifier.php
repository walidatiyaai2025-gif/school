<?php
declare(strict_types=1);
namespace App\Services;

use RuntimeException;
use ZipArchive;

/** Fail-closed, detached Ed25519 ZIP validation for admin-delivered updates. */
final class UpdatePackageVerifier
{
    private const MAX_FILES = 60000;
    private const MAX_EXPANDED = 350000000;
    private const ALLOWED_ROOTS = ['app','bootstrap','config','database','public','resources','routes','vendor'];
    private const ALLOWED_FILES = ['artisan','composer.json','composer.lock'];

    public function inspect(string $archive, string $current, ?string $publicKey): array
    {
        $decoded = base64_decode((string)$publicKey, true);
        if (!extension_loaded('sodium') || $decoded === false ||
            strlen($decoded) !== SODIUM_CRYPTO_SIGN_PUBLICKEYBYTES) {
            throw new RuntimeException('The trusted Ed25519 public key is not configured.');
        }
        if (!is_file($archive) || !is_readable($archive)) {
            throw new RuntimeException('Update package not available.');
        }
        $zip = new ZipArchive();
        if ($zip->open($archive, ZipArchive::RDONLY) !== true) {
            throw new RuntimeException('Cannot open update ZIP.');
        }
        try {
            if ($zip->numFiles < 3 || $zip->numFiles > self::MAX_FILES) {
                throw new RuntimeException('Invalid update archive file count.');
            }
            $seen = [];
            $expanded = 0;
            $payload = [];
            for ($i=0; $i<$zip->numFiles; $i++) {
                $entry = $zip->statIndex($i);
                $name = $entry['name'];
                if (!is_string($name) || $name === '' ||
                    str_contains($name, '\\') || str_starts_with($name, '/') ||
                    preg_match('/^[A-Za-z]:/', $name) ||
                    preg_match('/[[:cntrl:]]/', $name) ||
                    str_contains($name, '//') || str_ends_with($name, '/')) {
                    throw new RuntimeException('Unsafe archive entry.');
                }
                $parts = explode('/', $name);
                if (in_array('.', $parts, true) || in_array('..', $parts, true)) {
                    throw new RuntimeException('Path traversal in ZIP.');
                }
                $folded = strtolower($name);
                if (isset($seen[$folded])) {
                    throw new RuntimeException('Duplicate ZIP entry.');
                }
                $seen[$folded] = true;
                $mode = ((int)($entry['external_attributes'] ?? 0) >> 16) & 0170000;
                if ($mode === 0120000 || ($mode !== 0 && $mode !== 0100000)) {
                    throw new RuntimeException('Symlinks and special ZIP entries are prohibited.');
                }
                $expanded += (int)$entry['size'];
                if ($expanded > self::MAX_EXPANDED) {
                    throw new RuntimeException('ZIP expands beyond safe limit.');
                }
                if (str_starts_with($name, 'payload/')) {
                    $relative = substr($name, 8);
                    $segments = explode('/', $relative);
                    if ($relative === '' || str_starts_with($relative, '.') ||
                        in_array('.env', $segments, true) ||
                        in_array('.git', $segments, true) ||
                        in_array('storage', $segments, true) ||
                        in_array('setup-access.key', $segments, true) ||
                        in_array('install.lock', $segments, true) ||
                        (count($segments) === 1 && !in_array($relative, self::ALLOWED_FILES, true)) ||
                        (count($segments) > 1 && !in_array($segments[0], self::ALLOWED_ROOTS, true))) {
                        throw new RuntimeException('Update payload contains a protected path.');
                    }
                    $payload[$relative] = ['zip_path'=>$name,'bytes'=>(int)$entry['size']];
                } elseif (!in_array($name, ['manifest.json','signature.ed25519'], true)) {
                    throw new RuntimeException('Unexpected file outside update payload.');
                }
            }
            $raw = $zip->getFromName('manifest.json');
            $signatureText = $zip->getFromName('signature.ed25519');
            if (!is_string($raw) || strlen($raw) > 1048576 ||
                !is_string($signatureText) || strlen($signatureText) > 100) {
                throw new RuntimeException('Missing or oversized signed manifest.');
            }
            $signature = base64_decode(trim($signatureText), true);
            if (!is_string($signature) || strlen($signature) !== SODIUM_CRYPTO_SIGN_BYTES ||
                !sodium_crypto_sign_verify_detached($signature, $raw, $decoded)) {
                throw new RuntimeException('Update signature verification failed.');
            }
            $manifest = json_decode($raw, true, 64, JSON_THROW_ON_ERROR);
            if (!is_array($manifest) ||
                ($manifest['kind'] ?? '') !== 'schoolpdf-update' ||
                ($manifest['project'] ?? '') !== 'School PDF' ||
                !preg_match('/^\d+\.\d+\.\d+$/D', (string)($manifest['target_version'] ?? '')) ||
                !preg_match('/^\d+\.\d+\.\d+$/D', (string)($manifest['minimum_supported_version'] ?? '')) ||
                !preg_match('/^[a-f0-9]{40}$/D', (string)($manifest['git_sha'] ?? ''))) {
                throw new RuntimeException('Invalid signed manifest.');
            }
            $target = $manifest['target_version'];
            if (version_compare($target, $current, '<=') ||
                version_compare($current, $manifest['minimum_supported_version'], '<')) {
                throw new RuntimeException('Update version is older or incompatible.');
            }
            if (!is_array($manifest['supported_base_versions'] ?? null) ||
                !in_array($current, $manifest['supported_base_versions'], true)) {
                throw new RuntimeException('This installed release is not an approved upgrade source.');
            }
            if (version_compare(PHP_VERSION, (string)($manifest['min_php'] ?? '99.0'), '<')) {
                throw new RuntimeException('PHP version is incompatible with this update.');
            }
            if (!is_array($manifest['files'] ?? null) ||
                count($manifest['files']) !== count($payload)) {
                throw new RuntimeException('Signed payload inventory does not match ZIP.');
            }
            foreach ($manifest['files'] as $item) {
                if (!is_array($item) || !is_string($item['path'] ?? null) ||
                    !isset($payload[$item['path']]) ||
                    !preg_match('/^[a-f0-9]{64}$/D', (string)($item['sha256'] ?? '')) ||
                    ($item['bytes'] ?? null) !== $payload[$item['path']]['bytes']) {
                    throw new RuntimeException('Invalid signed payload entry.');
                }
                $name = $item['path'];
                $stream = $zip->getStream($payload[$name]['zip_path']);
                if ($stream === false) throw new RuntimeException('Cannot read ZIP entry.');
                $ctx = hash_init('sha256');
                hash_update_stream($ctx, $stream);
                fclose($stream);
                if (!hash_equals($item['sha256'], hash_final($ctx))) {
                    throw new RuntimeException('File digest does not match signed manifest.');
                }
                unset($payload[$name]);
            }
            if ($payload !== []) throw new RuntimeException('Unlisted ZIP files.');
            return $manifest;
        } finally {
            $zip->close();
        }
    }
}
