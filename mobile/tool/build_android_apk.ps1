# Windows PowerShell. Requires Flutter, Android SDK, Java and Python on PATH.
$ErrorActionPreference = 'Stop'
Set-Location (Resolve-Path (Join-Path $PSScriptRoot '..'))
function Run-Checked([string]$Command, [string[]]$Arguments) {
  & $Command @Arguments
  if ($LASTEXITCODE -ne 0) { throw "$Command failed with exit code $LASTEXITCODE" }
}
Run-Checked flutter @('create','--project-name','school_pdf','--platforms','android','--org','com.fiftysols','.')
Run-Checked python @('tool/patch_platforms.py')
Run-Checked flutter @('pub','get')
Run-Checked dart @('run','flutter_launcher_icons')
Run-Checked flutter @('analyze','--no-fatal-infos')
Run-Checked flutter @('test')
Run-Checked flutter @('build','apk','--debug','--no-pub')
$source='build/app/outputs/flutter-apk/app-debug.apk'
if (!(Test-Path $source) -or (Get-Item $source).Length -lt 100000) { throw "APK missing/empty at $source" }
New-Item -ItemType Directory -Force -Path 'dist' | Out-Null
$target='dist/SchoolPDF-v1.1.1-debug.apk'
Copy-Item $source $target -Force
$hash=(Get-FileHash $target -Algorithm SHA256).Hash.ToLower()
"$hash  SchoolPDF-v1.1.1-debug.apk" | Set-Content 'dist/SHA256SUMS.txt'
Write-Host "APK: $((Resolve-Path $target).Path)"
