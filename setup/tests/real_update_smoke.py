#!/usr/bin/env python3
"""Test the EXACT signed update ZIP against the extracted prior verified Setup ZIP.

Runs only on disposable CI MariaDB databases; never contacts production.
"""
from __future__ import annotations
import base64
import hashlib
import json
import os
from pathlib import Path
import subprocess
import zipfile


def run_real_update_smoke(app: Path, env: dict, php: str) -> None:
    archive = Path(os.environ["SCHOOLPDF_REAL_UPDATE_ARCHIVE"]).resolve()
    target = os.environ["SCHOOLPDF_REAL_UPDATE_TARGET_VERSION"]
    assert archive.is_file(), "exact Update ZIP missing"
    current = json.loads((app / "storage/app/private/install.lock").read_text())["version"]
    assert current in ("1.1.2", "1.1.3"), f"unsupported CI starting version: {current}"
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        manifest_raw = z.read("manifest.json")
        manifest = json.loads(manifest_raw)
        assert manifest["kind"] == "schoolpdf-update"
        assert manifest["target_version"] == target
        assert manifest["supported_base_versions"] == ["1.1.3"]
        assert manifest["git_sha"] == os.environ["GITHUB_SHA"]
        assert "public/app-ads.txt" not in [f["path"] for f in manifest["files"]]
        assert not any("storage/" in f["path"] or f["path"] == ".env" for f in manifest["files"])
        assert "resources/views/legal/data-deletion.blade.php" in [f["path"] for f in manifest["files"]]
        assert "vendor/autoload.php" in [f["path"] for f in manifest["files"]]
        detached = base64.b64decode(z.read("signature.ed25519"), validate=True)
        assert len(detached) == 64
    expected_public = Path(os.environ["SCHOOLPDF_UPDATE_PUBLIC_FILE"]).read_text().strip()
    e = env.copy()
    e.pop("SCHOOLPDF_FORM", None)
    e["SCHOOLPDF_SMOKE_TARGET_VERSION"] = target
    e["SCHOOLPDF_SMOKE_EXPECTED_PUBLIC"] = expected_public
    installed_env = (app / ".env").read_bytes()
    if os.environ.get("SCHOOLPDF_REQUIRE_KEY_MATCH") == "1":
        assert ('SCHOOLPDF_ED25519_UPDATE_PUBLIC_KEY="' + expected_public + '"').encode() in installed_env, (
            "previous verified Setup has a different trusted release signer")
    public_validation = subprocess.run(
        [php, "-r",
         '$p=base64_decode(getenv("SCHOOLPDF_SMOKE_EXPECTED_PUBLIC"),true);'
         '$s=base64_decode(getenv("SCHOOLPDF_SMOKE_SIGNATURE"),true);'
         'exit(is_string($p)&&is_string($s)&&sodium_crypto_sign_verify_detached($s,'
         'stream_get_contents(STDIN),$p)?0:4);'],
        input=manifest_raw, env={**e, "SCHOOLPDF_SMOKE_SIGNATURE":base64.b64encode(detached).decode()},
        capture_output=True, timeout=15)
    assert public_validation.returncode == 0, "actual update signature invalid"

    # These are test records in an isolated disposable database only.
    files = app / "storage/app/private"
    files.mkdir(parents=True, exist_ok=True)
    upload = files / "schoolpdf-ci-user-upload.bin"
    upload.write_bytes(b"keep original file bytes across release upgrade\n")
    original_ads = b"google.com, pub-ci-live-edited, DIRECT, ci-fixture\n"
    ads_file = app / "public/app-ads.txt"
    ads_file.write_bytes(original_ads)

    def run_php(source: str, package: Path) -> subprocess.CompletedProcess:
        base = (
            'require $argv[1]."/vendor/autoload.php";'
            '$app=require $argv[1]."/bootstrap/app.php";'
            r'$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();'
            # CI PR runs use a disposable signer; a main release must match the
            # public key installed from the original production Setup archive.
            '$k=getenv("SCHOOLPDF_SMOKE_EXPECTED_PUBLIC");'
            '$app["config"]->set("schoolpdf.update_public_key",$k);'
        )
        return subprocess.run([php, "-r", base + source, str(app), str(package)],
                              env=e, capture_output=True, text=True, timeout=220)

    # Real production lineage: verified Setup 1.1.2 was upgraded with the
    # actual signed 1.1.3 Update. Reconstruct the chain rather than editing
    # an installer lock or faking the migration baseline.
    if current == "1.1.2":
        prior = Path(os.environ["SCHOOLPDF_PRIOR_UPDATE_ARCHIVE"]).resolve()
        assert prior.is_file(), "actual prior v1.1.3 signed Update ZIP missing"
        prior_run = subprocess.run([php, "-r", r'''
require $argv[1]."/vendor/autoload.php";
$app=require $argv[1]."/bootstrap/app.php";
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
$m=$app->make(App\Services\SystemUpdateManager::class);
$s=$m->stage($argv[2]); $r=$m->install($s["id"]);
if (($r["version"]??"")!=="1.1.3") exit(11);
echo "ACTUAL_PRIOR_UPGRADE_OK";''', str(app), str(prior)],
            env=e, capture_output=True, text=True, timeout=220)
        assert prior_run.returncode == 0 and "ACTUAL_PRIOR_UPGRADE_OK" in prior_run.stdout, (
            "actual prior signed v1.1.3 update failed: " + prior_run.stderr[-1000:])
    assert json.loads((app / "storage/app/private/install.lock").read_text())["version"] == "1.1.3"

    before = run_php(r'''
use Illuminate\Support\Facades\DB;
DB::table("device_registrations")->insert([
  "installation_id"=>"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
  "token_hash"=>str_repeat("a",64),"platform"=>"android",
  "app_version"=>"1.1.3","locale"=>"en",
  "notifications_enabled"=>0,"push_opt_in"=>0,"analytics_consent"=>1,
  "last_seen_at"=>now(),"created_at"=>now(),"updated_at"=>now()
]);
if (DB::table("users")->where("email","ci-preview@example.invalid")->count()!==1) exit(2);
echo "DISPOSABLE_BASE_READY";''', archive)
    assert before.returncode == 0 and "DISPOSABLE_BASE_READY" in before.stdout, (
        "CI base data fixture failed: " + before.stderr[-600:])

    # A checksum-tampered package with the original valid signature must fail.
    corrupted = app.parent / "tampered-update.zip"
    with zipfile.ZipFile(archive) as original, zipfile.ZipFile(corrupted,"w",zipfile.ZIP_DEFLATED) as bad:
        corrupted_one = False
        for entry in original.infolist():
            value = original.read(entry.filename)
            if entry.filename.startswith("payload/") and not corrupted_one:
                value += b"\nTAMPERED\n"
                corrupted_one = True
            bad.writestr(entry.filename, value)
    bad_result = run_php(r'''
$m=$app->make(App\Services\SystemUpdateManager::class);
try {$m->inspect($argv[2]);exit(5);}
catch (RuntimeException $e) {echo "TAMPER_BLOCKED";}''', corrupted)
    assert bad_result.returncode == 0 and "TAMPER_BLOCKED" in bad_result.stdout, (
        "tampered update accepted " + bad_result.stderr[-450:])
    assert (app / "storage/app/private/install.lock").is_file()

    upgraded = run_php(r'''
$m=$app->make(App\Services\SystemUpdateManager::class);
$s=$m->stage($argv[2]);
$r=$m->install($s["id"]);
if (($r["version"]??"")!==getenv("SCHOOLPDF_SMOKE_TARGET_VERSION")) exit(6);
$b=$app->make(App\Services\SystemBackupManager::class);
$b->verify($r["backup"]);
echo "REAL_ZIP_UPGRADE_OK";''', archive)
    assert upgraded.returncode == 0 and "REAL_ZIP_UPGRADE_OK" in upgraded.stdout, (
        "actual signed release upgrade failed: " + upgraded.stderr[-1100:] +
        " stdout: " + upgraded.stdout[-700:])
    assert (app / ".env").read_bytes() == installed_env, ".env changed"
    assert upload.read_bytes() == b"keep original file bytes across release upgrade\n", "upload changed"
    assert ads_file.read_bytes() == original_ads, "live app-ads.txt overwritten"
    assert json.loads((app / "storage/app/private/install.lock").read_text())["version"] == target
    assert (app / "resources/views/legal/data-deletion.blade.php").is_file()
    assert (app / "app/Models/AdApproval.php").is_file(), "new ad policy model missing"
    assert not (app / "storage/framework/down").exists()

    post = run_php(r'''
use Illuminate\Support\Facades\DB;
if (DB::table("users")->where("email","ci-preview@example.invalid")->count()!==1) exit(7);
if (DB::table("device_registrations")->where("installation_id","aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")->count()!==1) exit(8);
if (DB::table("migrations")->count()<1) exit(9);
echo "LIVE_DB_ROWS_PRESERVED";''', archive)
    assert post.returncode == 0 and "LIVE_DB_ROWS_PRESERVED" in post.stdout, (
        "DB records not preserved " + post.stderr[-600:])

    replay = run_php(r'''
$m=$app->make(App\Services\SystemUpdateManager::class);
try {$m->inspect($argv[2]);exit(10);}
catch (RuntimeException $e) {echo "REPLAY_BLOCKED";}''',archive)
    assert replay.returncode == 0 and "REPLAY_BLOCKED" in replay.stdout
    print(f"PASS: exact signed ZIP upgraded actual verified base Setup 1.1.3→{target}.")
    print("PASS: manifest signature, tamper/replay rejection, backup verified,")
    print("admin/device database records, .env, uploads, live app-ads.txt preserved.")
