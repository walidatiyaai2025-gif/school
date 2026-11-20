<?php
namespace App\Http\Controllers\Api;

use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Symfony\Component\HttpFoundation\StreamedResponse;

class OfficeConversionController extends Controller
{
    public function convert(Request $request): StreamedResponse
    {
        abort_unless(config('services.schoolpdf_office.enabled', false), 503, 'Office conversion unavailable');
        $validated = $request->validate([
            'document' => ['required', 'file', 'max:10240', 'mimes:doc,docx,xls,xlsx,ppt,pptx'],
        ]);
        $binary = config('services.schoolpdf_office.binary', '/usr/bin/libreoffice');
        abort_unless(is_file($binary) && is_executable($binary), 503, 'Converter unavailable');
        $directory = storage_path('app/private/office-conversion/'.bin2hex(random_bytes(16)));
        if (!mkdir($directory, 0700, true) && !is_dir($directory)) abort(503);
        try {
            $upload = $validated['document'];
            $extension = strtolower($upload->getClientOriginalExtension());
            $source = $directory.'/source.'.$extension;
            $upload->move($directory, basename($source));
            $profile = $directory.'/profile';
            mkdir($profile, 0700);
            $command = [
                $binary, '-env:UserInstallation=file://'.$profile,
                '--headless', '--nologo', '--nodefault', '--nolockcheck',
                '--convert-to', 'pdf', '--outdir', $directory, $source,
            ];
            $process = new \Symfony\Component\Process\Process($command);
            $process->setTimeout(45);
            $process->run();
            $output = $directory.'/source.pdf';
            abort_unless($process->isSuccessful() && is_file($output) && filesize($output) > 0, 422, 'Conversion failed');
            $bytes = file_get_contents($output);
            abort_unless($bytes !== false && strlen($bytes) <= 30 * 1024 * 1024, 422);
            return response()->streamDownload(static function () use ($bytes) {
                echo $bytes;
            }, 'converted.pdf', [
                'Content-Type' => 'application/pdf',
                'Cache-Control' => 'no-store, private',
                'X-Content-Type-Options' => 'nosniff',
            ]);
        } finally {
            $iterator = new \RecursiveIteratorIterator(
                new \RecursiveDirectoryIterator($directory, \FilesystemIterator::SKIP_DOTS),
                \RecursiveIteratorIterator::CHILD_FIRST
            );
            foreach ($iterator as $item) {
                if ($item->isLink() || $item->isFile()) unlink($item->getPathname());
                elseif ($item->isDir()) rmdir($item->getPathname());
            }
            rmdir($directory);
        }
    }
}
