<?php
declare(strict_types=1);
namespace App\Services;

use PDO;
use RuntimeException;
use ZipArchive;

/**
 * Recovery validation must target a SEPARATE EMPTY database and directory.
 * Never points at, empties, or overwrites the running application.
 */
final class BackupRecoveryVerifier
{
    public function __construct(private readonly SystemBackupManager $backups) {}

    public function restoreIntoEmptyTargets(string $backupId, PDO $target, string $emptyDirectory): array
    {
        $manifest = $this->backups->verify($backupId);
        $targetName = $target->query('SELECT DATABASE()')->fetchColumn();
        if (!is_string($targetName) || $targetName === '') {
            throw new RuntimeException('An explicit recovery database is required.');
        }
        if ($target->query('SHOW FULL TABLES')->fetchAll(PDO::FETCH_NUM) !== []) {
            throw new RuntimeException('Refusing to overwrite a nonempty database.');
        }
        if (!is_dir($emptyDirectory) || !is_writable($emptyDirectory) ||
            (scandir($emptyDirectory) ?: []) !== ['.', '..'] || is_link($emptyDirectory)) {
            throw new RuntimeException('Recovery requires an empty, writable directory.');
        }
        $root = realpath($emptyDirectory);
        $live = realpath(base_path());
        if (!$root || !$live || $root === $live || str_starts_with($root.'/', $live.'/')) {
            throw new RuntimeException('Refusing to restore into the live application.');
        }
        $zip = new ZipArchive();
        if ($zip->open($this->backups->backupDirectory().'/'.$backupId.'.zip', ZipArchive::RDONLY) !== true) {
            throw new RuntimeException('Backup ZIP unavailable.');
        }
        try {
            $stream = $zip->getStream('database.ndjson');
            if ($stream === false) throw new RuntimeException('Database archive missing.');
            $schemas = [];
            $counts = [];
            try {
                while (($line=fgets($stream)) !== false) {
                    if (strlen($line) > 20 * 1024 * 1024) throw new RuntimeException('Record too large.');
                    $item = json_decode($line, true, 32, JSON_THROW_ON_ERROR);
                    $table = (string)($item['table'] ?? '');
                    if (!preg_match('/^[A-Za-z0-9_]{1,64}$/D', $table) ||
                        !array_key_exists($table, $manifest['database_tables'])) {
                        throw new RuntimeException('Unknown backup table.');
                    }
                    if (($item['type']??'') === 'schema') {
                        $prefix = 'CREATE TABLE '.chr(96).$table.chr(96);
                        if (isset($schemas[$table]) ||
                            !str_starts_with(strtoupper((string)($item['ddl']??'')), strtoupper($prefix))) {
                            throw new RuntimeException('Invalid table schema.');
                        }
                        $schemas[$table]=(string)$item['ddl'];
                    } elseif (($item['type']??'') === 'row') {
                        $counts[$table]=($counts[$table]??0)+1;
                    } else {
                        throw new RuntimeException('Invalid record type.');
                    }
                }
            } finally { fclose($stream); }
            if (array_keys($manifest['database_tables']) !== array_keys($schemas)) {
                throw new RuntimeException('Backup database schema inventory mismatch.');
            }
            foreach ($manifest['database_tables'] as $table=>$expected) {
                if (($counts[$table]??0) !== $expected) throw new RuntimeException('Backup row counts invalid.');
            }
            $target->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $target->exec('SET FOREIGN_KEY_CHECKS=0');
            try {
                // DDL commits implicitly on MySQL. Errors leave only this empty recovery DB changed.
                foreach ($schemas as $ddl) $target->exec($ddl);
                $target->beginTransaction();
                try {
                    $stream = $zip->getStream('database.ndjson');
                    if ($stream === false) throw new RuntimeException('Database archive missing.');
                    try {
                        while (($line=fgets($stream)) !== false) {
                            $item = json_decode($line,true,32,JSON_THROW_ON_ERROR);
                            if (($item['type']??'') !== 'row') continue;
                            $table=(string)$item['table'];
                            $encoded=base64_decode((string)($item['data']??''),true);
                            if ($encoded === false) throw new RuntimeException('Invalid row encoding.');
                            $record=unserialize($encoded,['allowed_classes'=>false]);
                            if (!is_array($record) || $record===[] || count($record)>200) {
                                throw new RuntimeException('Invalid record data.');
                            }
                            foreach ($record as $column=>$value) {
                                if (!is_string($column) || !preg_match('/^[A-Za-z0-9_]{1,64}$/D',$column) ||
                                    (!is_scalar($value) && $value !== null)) {
                                    throw new RuntimeException('Unsafe recovered value.');
                                }
                            }
                            $columns=array_keys($record);
                            $quoted=array_map(static fn($s)=>chr(96).$s.chr(96),$columns);
                            $sql='INSERT INTO '.chr(96).$table.chr(96).' ('.implode(',',$quoted).
                                ') VALUES ('.implode(',',array_fill(0,count($record),'?')).')';
                            $target->prepare($sql)->execute(array_values($record));
                        }
                    } finally { fclose($stream); }
                    $target->commit();
                } catch (\Throwable $e) {
                    if ($target->inTransaction()) $target->rollBack();
                    throw $e;
                }
            } finally {
                $target->exec('SET FOREIGN_KEY_CHECKS=1');
            }
            foreach ($manifest['database_tables'] as $table=>$expected) {
                $count=(int)$target->query('SELECT COUNT(*) FROM '.chr(96).$table.chr(96))->fetchColumn();
                if ($count!==$expected) throw new RuntimeException('Restored row count mismatch.');
            }
            $files=0;
            foreach ($manifest['files'] as $item) {
                $relative=$item['path'];
                if (!is_string($relative) || str_starts_with($relative,'/') ||
                    str_contains($relative,chr(92)) ||
                    in_array('..',explode('/',$relative),true) ||
                    in_array('.',explode('/',$relative),true)) {
                    throw new RuntimeException('Unsafe file path in backup.');
                }
                $destination=$root.'/'.$relative;
                $parent=dirname($destination);
                if (!is_dir($parent) && !mkdir($parent,0700,true) && !is_dir($parent)) {
                    throw new RuntimeException('Cannot create recovery path.');
                }
                for ($p=$parent; strlen($p)>=strlen($root); $p=dirname($p)) {
                    if (is_link($p)) throw new RuntimeException('Recovery destination symlink.');
                    if ($p===$root) break;
                }
                if (file_exists($destination) || is_link($destination)) {
                    throw new RuntimeException('Refusing to overwrite recovered file.');
                }
                $data=$zip->getFromName('files/'.$relative);
                if (!is_string($data) || !hash_equals($item['sha256'],hash('sha256',$data))) {
                    throw new RuntimeException('Restored file checksum invalid.');
                }
                if (file_put_contents($destination,$data,LOCK_EX)!==strlen($data)) {
                    throw new RuntimeException('Recovery write failed.');
                }
                chmod($destination,$relative==='.env' ? 0600 : 0640);
                $files++;
            }
            return ['database'=>$targetName,'version'=>$manifest['version'],
                'tables'=>count($manifest['database_tables']),'rows'=>array_sum($manifest['database_tables']),
                'files'=>$files];
        } finally { $zip->close(); }
    }
}
