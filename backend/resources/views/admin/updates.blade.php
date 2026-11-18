<x-shell title="School PDF — System Updates">
<h1>⚙️ Settings → System → System Updates</h1>
@if(session('status'))<div class="card" role="status">{{ session('status') }}</div>@endif
@if($errors->any())<div class="card error" role="alert">{{ $errors->first() }}</div>@endif

<div class="card">
    <h2>Version &amp; Release Notes — الإصدار الحالي</h2>
    <p>Current Version: <strong>{{ $version }}</strong></p>
    <p>Latest Available Version: <strong>{{ $staged['target_version'] ?? 'No verified upload yet' }}</strong></p>
    @if($staged)<p>Release Notes: {{ $staged['release_notes'] ?: 'Not supplied by signer' }}</p>@endif
    <p>Signed Update Verification: <strong>{{ $keyConfigured ? 'Configured' : 'Not configured — updates blocked' }}</strong></p>
    <p>تأكد من أن مفتاح التحقق العام تم تثبيته بواسطة جهة النشر الموثوقة. لا تقبل أي ZIP دون توقيع أصلي.</p>
</div>

<div class="card">
    <h2>1. Upload Update ZIP → Verify Package</h2>
    <form method="post" enctype="multipart/form-data" action="{{ route('admin.updates.verify') }}">
        @csrf
        <label for="package">Signed update archive (.zip)</label>
        <input id="package" type="file" name="package" accept=".zip" required>
        <button type="submit" @disabled(!$keyConfigured)>Verify Package</button>
    </form>
</div>

<div class="card">
    <h2>2. Backup Now → 3. Install Update</h2>
    <form method="post" action="{{ route('admin.updates.backup') }}">
        @csrf
        <p>Creates a private, integrity-checked files + MySQL/MariaDB backup. No uploaded documents or live settings are removed.</p>
        <button type="submit">Backup Now</button>
    </form>
    @if($staged && $keyConfigured)
    <form method="post" action="{{ route('admin.updates.install') }}">
        @csrf
        <p><strong>Verified target:</strong> {{ $staged['target_version'] }}. A fresh verified backup is required automatically before modification.</p>
        <label for="confirm-update">Type INSTALL to confirm</label>
        <input id="confirm-update" name="confirm" required autocomplete="off" pattern="INSTALL" maxlength="7">
        <button type="submit">Install Verified Update</button>
    </form>
    @else
        <p>Install Update is unavailable until a verified, compatible signed ZIP is uploaded.</p>
    @endif
</div>

<div class="card">
    <h2>Update Progress</h2>
    <p>State: <strong>{{ $progress['phase'] ?? 'IDLE' }}</strong></p>
    <p>Last change: {{ $progress['updated_at'] ?? '—' }}</p>
    @if(($progress['phase'] ?? '') === 'RECOVERY_REQUIRED')
        <p class="error">Recovery required: database migrations may have changed data. Do not repeat the update or reset the database. Verify and download the backup below, then follow the documented recovery plan.</p>
    @endif
</div>

<div class="card">
    <h2>Backup &amp; Recovery</h2>
    <p>Backup archives remain outside the public web directory. A backup must pass SHA-256 and manifest inspection before download or use.</p>
    @forelse($backups as $backup)
        <div class="row">
            <span>Backup: {{ $backup['created_at'] }} UTC ({{ number_format($backup['size_bytes']/1048576,2) }} MB)</span>
            <form method="post" action="{{ route('admin.updates.backup.verify') }}">
                @csrf<input type="hidden" name="backup_id" value="{{ $backup['id'] }}">
                <button type="submit">Verify Backup</button>
            </form>
            <a href="{{ route('admin.updates.backup.download',['id'=>$backup['id']]) }}">Download Backup</a>
        </div>
    @empty
        <p>No backups exist yet.</p>
    @endforelse
    @if($verifiedBackup)<p>Verified backup: {{ $verifiedBackup['created_at'] }} | Original version: {{ $verifiedBackup['version'] }}</p>@endif
    <p><strong>Recovery safety:</strong> If a migration was attempted, automatic database rollback is deliberately disabled. Preserve the current site and use a separately validated restore plan. Backups should be tested on a disposable database before live recovery.</p>
</div>

<div class="card">
    <h2>Update History</h2>
    @forelse($history as $entry)
        <p>{{ $entry['at'] ?? '—' }} — {{ $entry['state'] ?? 'unknown' }} — {{ $entry['target_version'] ?? '—' }}</p>
    @empty
        <p>No completed update attempts.</p>
    @endforelse
    <a href="{{ route('admin.dashboard') }}">العودة إلى لوحة الإدارة</a>
</div>
</x-shell>
