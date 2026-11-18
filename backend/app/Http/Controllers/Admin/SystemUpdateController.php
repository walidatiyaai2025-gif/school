<?php
declare(strict_types=1);
namespace App\Http\Controllers\Admin;

use App\Services\SystemBackupManager;
use App\Services\SystemUpdateManager;
use Illuminate\Http\Request;
use RuntimeException;
use Throwable;

final class SystemUpdateController
{
    public function index(Request $request, SystemUpdateManager $updates, SystemBackupManager $backups)
    {
        return view('admin.updates', [
            'version'=>$backups->currentVersion(),
            'keyConfigured'=>is_string($updates->trustedKey()) &&
                strlen((string)$updates->trustedKey()) >= 40,
            'progress'=>$updates->progress(),
            'history'=>$updates->historyEntries(),
            'staged'=>$request->session()->get('schoolpdf_staged_update'),
            'verifiedBackup'=>$request->session()->get('schoolpdf_verified_backup'),
            'backups'=>$backups->availableBackups(),
        ]);
    }

    public function verify(Request $request, SystemUpdateManager $updates)
    {
        $request->validate(['package'=>'required|file|max:102400|mimes:zip']);
        try {
            $staged = $updates->stage($request->file('package')->getRealPath());
            $request->session()->put('schoolpdf_staged_update', $staged);
            return back()->with('status','Update signature, compatibility and all payload hashes verified.');
        } catch (Throwable $e) {
            return back()->withErrors(['package'=>'Update rejected: '.$e->getMessage()]);
        }
    }

    public function backup(SystemUpdateManager $updates)
    {
        try {
            $backup = $updates->backupNow();
            return back()->with('status','A complete backup was created and verified.');
        } catch (Throwable $e) {
            return back()->withErrors(['backup'=>'Backup failed: '.$e->getMessage()]);
        }
    }

    public function install(Request $request, SystemUpdateManager $updates)
    {
        $request->validate(['confirm'=>'required|in:INSTALL']);
        $staged = $request->session()->get('schoolpdf_staged_update');
        if (!is_array($staged) || !preg_match('/^[a-f0-9]{40}$/D',(string)($staged['id']??''))) {
            return back()->withErrors(['package'=>'Verify a signed update ZIP before installation.']);
        }
        try {
            $result = $updates->install($staged['id']);
            $request->session()->forget('schoolpdf_staged_update');
            return back()->with('status','Update installed: '.$result['version'].'. Backup: '.$result['backup']);
        } catch (Throwable $e) {
            return back()->withErrors(['package'=>$e->getMessage()]);
        }
    }

    public function verifyBackup(Request $request, SystemBackupManager $backups)
    {
        $request->validate(['backup_id'=>'required|string|max:48']);
        try {
            $manifest = $backups->verify($request->input('backup_id'));
            $request->session()->put('schoolpdf_verified_backup',[
                'id'=>$request->input('backup_id'),
                'version'=>$manifest['version'],'created_at'=>$manifest['created_at']
            ]);
            return back()->with('status','Backup integrity verified; download for documented recovery.');
        } catch (Throwable $e) {
            return back()->withErrors(['backup'=>'Backup verification failed: '.$e->getMessage()]);
        }
    }

    public function downloadBackup(Request $request, SystemBackupManager $backups)
    {
        $id = $request->route('id');
        $backups->verify($id);
        return response()->download($backups->backupDirectory().'/'.$id.'.zip','SchoolPDF-Backup-'.$id.'.zip',[
            'Cache-Control'=>'no-store, private',
            'X-Content-Type-Options'=>'nosniff',
        ]);
    }
}
