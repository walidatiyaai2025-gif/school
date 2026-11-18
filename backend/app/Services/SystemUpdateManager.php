<?php
declare(strict_types=1);
namespace App\Services;

use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use RuntimeException;
use Throwable;
use ZipArchive;

/** Admin-initiated ZIP update, deliberately fail-closed at each irreversible boundary. */
final class SystemUpdateManager
{
    public function __construct(
        private readonly UpdatePackageVerifier $verifier,
        private readonly SystemBackupManager $backups,
    ) {}

    public function privateDirectory(): string
    {
        return storage_path('app/private/system-updates');
    }

    private function makeDirectory(): string
    {
        $dir = $this->privateDirectory();
        if (!is_dir($dir) && !mkdir($dir, 0700, true) && !is_dir($dir)) {
            throw new RuntimeException('Private update storage cannot be created.');
        }
        return $dir;
    }

    public function trustedKey(): ?string
    {
        return config('schoolpdf.update_public_key');
    }

    public function inspect(string $path): array
    {
        return $this->verifier->inspect($path, $this->backups->currentVersion(), $this->trustedKey());
    }

    public function stage(string $upload): array
    {
        $dir = $this->makeDirectory();
        $manifest = $this->inspect($upload);
        $id = bin2hex(random_bytes(20));
        $stored = $dir.'/stage-'.$id.'.zip';
        if (!copy($upload, $stored)) throw new RuntimeException('Unable to stage verified ZIP.');
        chmod($stored,0600);
        try {
            // Re-inspect after moving to private storage to exclude upload TOCTOU.
            $this->inspect($stored);
            return ['id'=>$id,'target_version'=>$manifest['target_version'],
                'release_notes'=>$manifest['release_notes']??'',
                'sha256'=>hash_file('sha256',$stored)];
        } catch (Throwable $e) {
            @unlink($stored);
            throw $e;
        }
    }

    public function install(string $id): array
    {
        if (!preg_match('/^[a-f0-9]{40}$/D',$id)) throw new RuntimeException('Invalid update token.');
        $dir = $this->makeDirectory();
        $lock = fopen($dir.'/operation.lock','c');
        if (!$lock || !flock($lock,LOCK_EX|LOCK_NB)) throw new RuntimeException('Another update or backup is active.');
        $archive = $dir.'/stage-'.$id.'.zip';
        $backup = null;
        $maintenance = false;
        $phase = 'VERIFY';
        $swapped = [];
        $migrationsStarted = false;
        try {
            // No stale server-side staged data is ever sufficient without re-verification.
            $manifest = $this->inspect($archive);
            if (!empty($manifest['requires_manual_deployment'])) {
                throw new RuntimeException('Update needs manual dependency deployment; ZIP update blocked.');
            }
            $zip = new ZipArchive();
            if ($zip->open($archive,ZipArchive::RDONLY) !== true) throw new RuntimeException('Cannot read staged update.');
            try {
                $this->status('BACKUP',$manifest['target_version']);
                $backup = $this->backups->create();
                $this->backups->verify($backup['id']);
                $phase='MAINTENANCE';
                if (Artisan::call('down',['--retry'=>120]) !== 0) {
                    throw new RuntimeException('Maintenance mode could not be enabled.');
                }
                $maintenance = true;
                $this->status('APPLY',$manifest['target_version']);
                $phase='APPLY';
                foreach ($manifest['files'] as $file) {
                    $relative = $file['path'];
                    $destination = base_path($relative);
                    $this->assertSafeDestination($destination);
                    $parent = dirname($destination);
                    if (!is_dir($parent) && !mkdir($parent,0755,true) && !is_dir($parent)) {
                        throw new RuntimeException('Cannot create update destination.');
                    }
                    $stream = $zip->getStream('payload/'.$relative);
                    if ($stream === false) throw new RuntimeException('Cannot extract signed file.');
                    $tmp = $destination.'.schoolpdf-'.bin2hex(random_bytes(8)).'.partial';
                    $output = fopen($tmp,'xb');
                    if (!$output) { fclose($stream); throw new RuntimeException('Cannot create temporary update file.'); }
                    try {
                        $copied = stream_copy_to_stream($stream,$output);
                        fflush($output);
                    } finally {
                        fclose($stream);
                        fclose($output);
                    }
                    if ($copied !== $file['bytes'] ||
                        !hash_equals($file['sha256'],hash_file('sha256',$tmp))) {
                        @unlink($tmp);
                        throw new RuntimeException('Update extracted file failed signature inventory check.');
                    }
                    chmod($tmp,0644);
                    $existed = is_file($destination);
                    if (!rename($tmp,$destination)) {
                        @unlink($tmp);
                        throw new RuntimeException('Cannot atomically replace update file.');
                    }
                    $swapped[$relative] = $existed;
                }

                $phase='MIGRATIONS';
                $migrationsStarted=true;
                $this->status('MIGRATIONS',$manifest['target_version']);
                if (Artisan::call('migrate',['--force'=>true]) !== 0) {
                    throw new RuntimeException('Migration failed; manual database recovery may be required.');
                }
                $phase='HEALTH';
                $this->status('HEALTH_CHECK',$manifest['target_version']);
                DB::select('SELECT 1');
                if (!is_file(base_path('vendor/autoload.php')) ||
                    !is_file(base_path('storage/app/private/install.lock'))) {
                    throw new RuntimeException('Post-upgrade application health check failed.');
                }
                Artisan::call('optimize:clear');
                $this->recordVersion($manifest['target_version'],$manifest['git_sha']);
                $this->status('FINISHED',$manifest['target_version']);
                Artisan::call('up');
                $maintenance = false;
                $this->history('success',$manifest,$backup['id']);
                @unlink($archive);
                return ['version'=>$manifest['target_version'],'backup'=>$backup['id']];
            } finally {
                $zip->close();
            }
        } catch (Throwable $error) {
            // A migration may commit DDL even when its command reports failure.
            // Never automatically revert schema/data once migrations have started.
            if ($migrationsStarted) {
                $this->status('RECOVERY_REQUIRED',null);
                $this->history('recovery_required',['target_version'=>'unknown'], $backup['id']??null);
            } else {
                if ($backup && $swapped !== []) {
                    try { $this->rollbackFiles($backup['id'],$swapped); }
                    catch (Throwable $restoreError) {
                        $this->status('RECOVERY_REQUIRED',null);
                        throw new RuntimeException('File recovery failed; maintenance retained.',0,$restoreError);
                    }
                }
                $this->status('FAILED_BEFORE_MIGRATIONS',null);
                if ($maintenance) Artisan::call('up');
                $maintenance=false;
            }
            throw new RuntimeException('Update stopped safely at phase '.$phase.'. '.($migrationsStarted
                ? 'Database may have changed: restore using verified backup and recovery plan.'
                : 'No database migrations were started.'),0,$error);
        } finally {
            // Maintenance is deliberately retained for a potentially partial DB migration.
            if ($lock) { flock($lock,LOCK_UN); fclose($lock); }
        }
    }

    public function backupNow(): array
    {
        $dir=$this->makeDirectory();
        $lock=fopen($dir.'/operation.lock','c');
        if (!$lock || !flock($lock,LOCK_EX|LOCK_NB)) throw new RuntimeException('Another operation is active.');
        try {
            $backup=$this->backups->create();
            $this->backups->verify($backup['id']);
            return $backup;
        } finally {
            flock($lock,LOCK_UN); fclose($lock);
        }
    }

    private function assertSafeDestination(string $destination): void
    {
        $base=realpath(base_path());
        if (!$base || !str_starts_with($destination,$base.'/')) {
            throw new RuntimeException('Update destination outside application root.');
        }
        $rel=substr($destination,strlen($base)+1);
        $parent=$base;
        foreach (explode('/',$rel) as $part) {
            if ($part === '' || $part === '.' || $part === '..') throw new RuntimeException('Invalid path.');
            $parent.='/'.$part;
            if (is_link($parent)) throw new RuntimeException('Symlink in destination path.');
        }
    }

    private function rollbackFiles(string $backupId,array $swapped): void
    {
        $this->backups->verify($backupId);
        $path=$this->backups->backupDirectory().'/'.$backupId.'.zip';
        $zip = new ZipArchive();
        if ($zip->open($path,ZipArchive::RDONLY) !== true) throw new RuntimeException('Backup ZIP not readable.');
        try {
            foreach (array_reverse($swapped,true) as $relative=>$existed) {
                $destination=base_path($relative);
                $this->assertSafeDestination($destination);
                if (!$existed) {
                    if (is_file($destination) && !unlink($destination)) {
                        throw new RuntimeException('Cannot remove added file during recovery.');
                    }
                    continue;
                }
                $source=$zip->getStream('files/'.$relative);
                if ($source===false) throw new RuntimeException('Backup missing overwritten file.');
                $temp=$destination.'.rollback-'.bin2hex(random_bytes(6));
                $out=fopen($temp,'xb');
                if (!$out) { fclose($source); throw new RuntimeException('Cannot write restored file.'); }
                stream_copy_to_stream($source,$out);
                fclose($source); fclose($out);
                if (!rename($temp,$destination)) throw new RuntimeException('Cannot restore original file.');
            }
        } finally { $zip->close(); }
    }

    private function recordVersion(string $version,string $sha): void
    {
        $path=storage_path('app/private/install.lock');
        $current=json_decode((string)file_get_contents($path),true,32,JSON_THROW_ON_ERROR);
        $current['version']=$version;
        $current['git_sha']=$sha;
        $current['updated_at']=gmdate('c');
        $temp=$path.'.next';
        if (file_put_contents($temp,json_encode($current,JSON_THROW_ON_ERROR)."\n",LOCK_EX) === false ||
            !rename($temp,$path)) throw new RuntimeException('Cannot write installed version.');
        chmod($path,0640);
    }

    private function status(string $phase,?string $version): void
    {
        $data=['phase'=>$phase,'target_version'=>$version,'updated_at'=>gmdate('c')];
        file_put_contents($this->makeDirectory().'/progress.json',
            json_encode($data,JSON_THROW_ON_ERROR),LOCK_EX);
    }

    private function history(string $state,array $manifest,?string $backupId): void
    {
        file_put_contents($this->makeDirectory().'/history.jsonl',
            json_encode(['state'=>$state,'target_version'=>$manifest['target_version']??null,
                'backup'=>$backupId,'at'=>gmdate('c')],JSON_THROW_ON_ERROR)."\n",
            FILE_APPEND|LOCK_EX);
    }

    public function progress(): array
    {
        $path=$this->privateDirectory().'/progress.json';
        return is_file($path)?(json_decode((string)file_get_contents($path),true)??[]):[];
    }

    public function historyEntries(): array
    {
        $path=$this->privateDirectory().'/history.jsonl';
        if (!is_file($path)) return [];
        return array_slice(array_reverse(array_values(array_filter(array_map(
            static fn($line)=>json_decode($line,true),file($path,FILE_IGNORE_NEW_LINES)
        )))),0,20);
    }
}
