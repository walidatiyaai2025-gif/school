<?php
declare(strict_types=1);
namespace App\Services;

use Illuminate\Support\Facades\DB;
use PDO;
use RecursiveDirectoryIterator;
use RecursiveIteratorIterator;
use RuntimeException;
use ZipArchive;

/** Creates integrity-checked, private backups before any update is allowed. */
final class SystemBackupManager
{
    public function backupDirectory(): string
    {
        return storage_path('app/private/system-updates/backups');
    }

    public function create(): array
    {
        $directory = $this->backupDirectory();
        if (!is_dir($directory) && !mkdir($directory, 0700, true) && !is_dir($directory)) {
            throw new RuntimeException('Cannot create private backup directory.');
        }
        $id = gmdate('Ymd-His').'-'.bin2hex(random_bytes(8));
        $temp = $directory.'/'.$id.'.zip.partial';
        $final = $directory.'/'.$id.'.zip';
        $sql = $directory.'/'.$id.'.database.ndjson.partial';
        $zip = new ZipArchive();
        if ($zip->open($temp, ZipArchive::CREATE|ZipArchive::EXCL) !== true) {
            throw new RuntimeException('Cannot create backup archive.');
        }
        $manifest = ['kind'=>'schoolpdf-backup','created_at'=>gmdate('c'),
            'version'=>$this->currentVersion(), 'files'=>[], 'database_tables'=>[]];
        $bytes = 0;
        try {
            $pdo = DB::connection()->getPdo();
            if ($pdo->getAttribute(PDO::ATTR_DRIVER_NAME) !== 'mysql') {
                throw new RuntimeException('Database backup requires MySQL/MariaDB.');
            }
            $handle = fopen($sql,'wb');
            if (!$handle) throw new RuntimeException('Cannot open database backup stream.');
            try {
                $tables = $pdo->query('SHOW FULL TABLES')->fetchAll(PDO::FETCH_NUM);
                foreach ($tables as $row) {
                    $table = (string)($row[0] ?? '');
                    $type = strtoupper((string)($row[1] ?? ''));
                    if ($type !== 'BASE TABLE') continue;
                    if (!preg_match('/^[A-Za-z0-9_]{1,64}$/D', $table)) {
                        throw new RuntimeException('Database contains an unsupported table name.');
                    }
                    $schema = $pdo->query('SHOW CREATE TABLE `'.$table.'`')->fetch(PDO::FETCH_NUM);
                    if (!$schema || !isset($schema[1])) throw new RuntimeException('Cannot export table schema.');
                    $this->writeLine($handle, ['type'=>'schema','table'=>$table,'ddl'=>$schema[1]]);
                    $cursor = $pdo->query('SELECT * FROM `'.$table.'`');
                    $count = 0;
                    while ($record = $cursor->fetch(PDO::FETCH_ASSOC)) {
                        $this->writeLine($handle, ['type'=>'row','table'=>$table,
                            'data'=>base64_encode(serialize($record))]);
                        $count++;
                        if (ftell($handle) > 1024*1024*1024) {
                            throw new RuntimeException('Database export exceeds 1 GiB safety limit.');
                        }
                    }
                    $manifest['database_tables'][$table] = $count;
                }
            } finally {
                fclose($handle);
            }
            $zip->addFile($sql, 'database.ndjson');
            $manifest['database_sha256'] = hash_file('sha256',$sql);

            $base = base_path();
            $iterator = new RecursiveIteratorIterator(
                new RecursiveDirectoryIterator($base, RecursiveDirectoryIterator::SKIP_DOTS)
            );
            foreach ($iterator as $file) {
                $full = $file->getPathname();
                $relative = str_replace('\\','/',substr($full,strlen($base)+1));
                $segments = explode('/',$relative);
                if (in_array('.git',$segments,true) || in_array('node_modules',$segments,true) ||
                    in_array('backups',$segments,true) && str_starts_with($relative,'storage/app/private/system-updates/') ||
                    str_starts_with($relative,'storage/logs/') ||
                    str_starts_with($relative,'storage/framework/cache/') ||
                    str_starts_with($relative,'storage/framework/views/') ||
                    str_starts_with($relative,'storage/framework/sessions/')) continue;
                if ($file->isLink()) throw new RuntimeException('Refusing symlink in backup: '.$relative);
                if (!$file->isFile()) continue;
                $size = $file->getSize();
                $bytes += $size;
                if ($bytes > 1024*1024*1024) throw new RuntimeException('Site backup exceeds 1 GiB limit.');
                $zip->addFile($full,'files/'.$relative);
                $manifest['files'][] = ['path'=>$relative,'bytes'=>$size,
                    'sha256'=>hash_file('sha256',$full)];
            }
            $zip->addFromString('BACKUP_MANIFEST.json',json_encode($manifest,JSON_THROW_ON_ERROR));
            if (!$zip->close()) throw new RuntimeException('Unable to finish backup ZIP.');
            $this->verifyAt($temp);
            if (!rename($temp,$final)) throw new RuntimeException('Unable to finalize backup.');
            chmod($final,0600);
            $sha = hash_file('sha256',$final);
            file_put_contents($final.'.sha256', $sha."\n",LOCK_EX);
            chmod($final.'.sha256',0600);
            return ['id'=>$id,'sha256'=>$sha,'bytes'=>filesize($final),'tables'=>count($manifest['database_tables'])];
        } catch (\Throwable $e) {
            $zip->close();
            @unlink($temp);
            throw $e;
        } finally {
            @unlink($sql);
        }
    }

    private function writeLine($file, array $value): void
    {
        $text = json_encode($value,JSON_THROW_ON_ERROR)."\n";
        if (fwrite($file,$text) !== strlen($text)) throw new RuntimeException('Database export write failed.');
    }

    public function currentVersion(): string
    {
        $lock = storage_path('app/private/install.lock');
        if (!is_file($lock)) throw new RuntimeException('School PDF is not installed.');
        $data = json_decode((string)file_get_contents($lock),true,32,JSON_THROW_ON_ERROR);
        $version = (string)($data['version'] ?? '');
        if (!preg_match('/^\d+\.\d+\.\d+$/D',$version)) {
            throw new RuntimeException('Installed version record invalid.');
        }
        return $version;
    }

    public function availableBackups(): array
    {
        $directory = $this->backupDirectory();
        if (!is_dir($directory)) return [];
        $archives = glob($directory.'/*.zip') ?: [];
        rsort($archives);
        return array_slice(array_map(static fn($path) => [
            'id'=>basename($path,'.zip'),
            'created_at'=>gmdate('Y-m-d H:i:s',filemtime($path)),
            'size_bytes'=>filesize($path),
        ],$archives),0,20);
    }

    public function verify(string $id): array
    {
        if (!preg_match('/^\d{8}-\d{6}-[a-f0-9]{16}$/D',$id)) {
            throw new RuntimeException('Invalid backup reference.');
        }
        $path=$this->backupDirectory().'/'.$id.'.zip';
        $checksum = $path.'.sha256';
        if (!is_file($path) || !is_file($checksum) ||
            !hash_equals(trim(file_get_contents($checksum)),hash_file('sha256',$path))) {
            throw new RuntimeException('Backup checksum missing or incorrect.');
        }
        return $this->verifyAt($path);
    }

    private function verifyAt(string $path): array
    {
        $zip = new ZipArchive();
        if ($zip->open($path,ZipArchive::RDONLY) !== true) throw new RuntimeException('Unreadable backup ZIP.');
        try {
            $raw=$zip->getFromName('BACKUP_MANIFEST.json');
            if (!is_string($raw)) throw new RuntimeException('Backup manifest missing.');
            $manifest=json_decode($raw,true,32,JSON_THROW_ON_ERROR);
            if (($manifest['kind']??null)!=='schoolpdf-backup') throw new RuntimeException('Invalid backup manifest.');
            $db=$zip->getFromName('database.ndjson');
            if (!is_string($db) || hash('sha256',$db)!==($manifest['database_sha256']??'')) {
                throw new RuntimeException('Database backup corrupted.');
            }
            foreach (($manifest['files']??[]) as $item) {
                $name=$item['path']??'';
                if (!is_string($name) || str_starts_with($name,'/') ||
                    str_contains($name,'..') || str_contains($name,'\\')) {
                    throw new RuntimeException('Invalid path in backup manifest.');
                }
                $bytes=$zip->getFromName('files/'.$name);
                if (!is_string($bytes) || strlen($bytes)!==$item['bytes'] ||
                    !hash_equals($item['sha256'],hash('sha256',$bytes))) {
                    throw new RuntimeException('Backup file corrupted.');
                }
            }
            return $manifest;
        } finally {
            $zip->close();
        }
    }
}
