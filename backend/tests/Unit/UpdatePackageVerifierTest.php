<?php
declare(strict_types=1);
namespace Tests\Unit;

use App\Services\UpdatePackageVerifier;
use PHPUnit\Framework\TestCase;
use RuntimeException;
use ZipArchive;

final class UpdatePackageVerifierTest extends TestCase
{
    private array $temporary = [];

    protected function tearDown(): void
    {
        foreach ($this->temporary as $path) @unlink($path);
        parent::tearDown();
    }

    private function package(array $payload = ['payload/app/test.php' => '<?php echo 1;'],
                             array $overrides = [], bool $validSignature = true): array
    {
        $keypair = sodium_crypto_sign_keypair();
        $public = base64_encode(sodium_crypto_sign_publickey($keypair));
        $secret = sodium_crypto_sign_secretkey($keypair);
        $manifest = array_replace([
            'project' => 'School PDF',
            'kind' => 'schoolpdf-update',
            'target_version' => '1.1.3',
            'minimum_supported_version' => '1.1.2',
            'supported_base_versions' => ['1.1.2'],
            'git_sha' => str_repeat('a', 40),
            'min_php' => '8.2',
            'files' => array_map(static fn($name,$bytes)=>[
                'path'=>substr($name,8), 'bytes'=>strlen($bytes),
                'sha256'=>hash('sha256',$bytes)], array_keys($payload),array_values($payload))
        ], $overrides);
        $raw = json_encode($manifest, JSON_THROW_ON_ERROR);
        $signed = sodium_crypto_sign_detached($raw, $secret);
        if (!$validSignature) $signed[0] = chr(ord($signed[0]) ^ 1);
        $file = tempnam(sys_get_temp_dir(), 'schoolpdf-update-');
        $this->temporary[] = $file;
        $zip = new ZipArchive();
        self::assertTrue($zip->open($file, ZipArchive::OVERWRITE) === true);
        $zip->addFromString('manifest.json', $raw);
        $zip->addFromString('signature.ed25519', base64_encode($signed));
        foreach ($payload as $name => $bytes) $zip->addFromString($name, $bytes);
        self::assertTrue($zip->close());
        return [$file, $public];
    }

    public function test_accepts_complete_signed_update_only(): void
    {
        [$file,$key] = $this->package();
        $manifest = (new UpdatePackageVerifier())->inspect($file, '1.1.2', $key);
        self::assertSame('1.1.3', $manifest['target_version']);
    }

    public function test_rejects_signature_tampering(): void
    {
        [$file,$key] = $this->package(validSignature:false);
        $this->expectException(RuntimeException::class);
        (new UpdatePackageVerifier())->inspect($file, '1.1.2', $key);
    }

    public function test_rejects_untrusted_signer(): void
    {
        [$file] = $this->package();
        $otherKey = base64_encode(sodium_crypto_sign_publickey(sodium_crypto_sign_keypair()));
        $this->expectException(RuntimeException::class);
        (new UpdatePackageVerifier())->inspect($file, '1.1.2', $otherKey);
    }

    public function test_rejects_missing_signing_configuration(): void
    {
        [$file] = $this->package();
        $this->expectException(RuntimeException::class);
        (new UpdatePackageVerifier())->inspect($file, '1.1.2', null);
    }

    public function test_rejects_path_traversal(): void
    {
        [$file,$key] = $this->package(['payload/app/../.env'=>'password']);
        $this->expectException(RuntimeException::class);
        (new UpdatePackageVerifier())->inspect($file, '1.1.2', $key);
    }

    public function test_rejects_runtime_environment_file(): void
    {
        [$file,$key] = $this->package(['payload/.env'=>'APP_KEY=secret']);
        $this->expectException(RuntimeException::class);
        (new UpdatePackageVerifier())->inspect($file, '1.1.2', $key);
    }

    public function test_rejects_older_or_unsupported_release(): void
    {
        [$file,$key] = $this->package();
        $this->expectException(RuntimeException::class);
        (new UpdatePackageVerifier())->inspect($file, '1.1.3', $key);
    }

    public function test_rejects_unsigned_content_change(): void
    {
        [$file,$key] = $this->package(
            ['payload/app/test.php'=>'changed'],
            ['files'=>[['path'=>'app/test.php','bytes'=>7,'sha256'=>str_repeat('0',64)]]]
        );
        $this->expectException(RuntimeException::class);
        (new UpdatePackageVerifier())->inspect($file, '1.1.2', $key);
    }

    public function test_rejects_symlink_entry(): void
    {
        [$file,$key] = $this->package();
        $zip = new ZipArchive();
        self::assertTrue($zip->open($file) === true);
        self::assertTrue($zip->setExternalAttributesName(
            'payload/app/test.php', ZipArchive::OPSYS_UNIX, 0120777 << 16));
        $zip->close();
        $this->expectException(RuntimeException::class);
        (new UpdatePackageVerifier())->inspect($file, '1.1.2', $key);
    }
}
