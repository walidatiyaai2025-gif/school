#!/usr/bin/env python3
"""Derive a fail-closed fixed-cPanel-DocumentRoot deployment from EXACT tested Setup ZIP.

Two safe artifacts:
 - SchoolPDF-WebBridge-vX.Y.Z.zip: web-only bridge for an existing private $HOME/sclpdf
 - SchoolPDF-FixedRoot-Setup-vX.Y.Z.zip: clean-install one-ZIP extracted at $HOME

No shell, symlinks, Laravel root, credentials or Composer commands in public_html.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import stat
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
WEB_SOURCE = ROOT / "setup/fixed-root-web"
BRIDGE_FILES = (".htaccess", ".schoolpdf-bridge.php", "index.php", "install.php")
EXTRA_SETUP = {"SETUP_MANIFEST.json", "BUILD_INFO.json", "START_HERE.txt"}
PRIVATE_PREFIX = "sclpdf/"
PUBLIC_PREFIX = "public_html/sclpdf.50sols.com/"
SUPPORTED_EXTENSION = (".zip",)


def digest(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def safe_zip_name(name: str) -> bool:
    if not name or name.startswith("/") or "\\" in name or "\0" in name:
        return False
    parts = PurePosixPath(name).parts
    return all(p not in ("", ".", "..") for p in parts) and "//" not in name


def zip_write(z: zipfile.ZipFile, path: str, payload: bytes) -> None:
    if not safe_zip_name(path):
        raise ValueError("Unsafe output ZIP path")
    entry = zipfile.ZipInfo(path, date_time=(2026, 1, 1, 0, 0, 0))
    entry.compress_type = zipfile.ZIP_DEFLATED
    entry.external_attr = ((stat.S_IFREG | 0o644) << 16)
    z.writestr(entry, payload)


def verified_source(archive: Path, checksum: Path, acceptance: Path) -> tuple[dict, dict[str, bytes]]:
    if not archive.is_file() or not checksum.is_file() or not acceptance.is_file():
        raise ValueError("BLOCKED: exact verified Setup ZIP, SHA256 and acceptance evidence required")
    expected = checksum.read_text(encoding="utf-8").split()
    if len(expected) != 2 or expected[1] != archive.name or digest(archive.read_bytes()) != expected[0]:
        raise ValueError("BLOCKED: original Setup ZIP checksum mismatch")
    evidence = json.loads(acceptance.read_text(encoding="utf-8"))
    if evidence.get("archive_sha256") != expected[0] or evidence.get("exact_setup_zip_fresh_install") != "PASS" or evidence.get("migration_failure_isolated_recovery") != "PASS":
        raise ValueError("BLOCKED: missing independent exact-package acceptance")
    payload = {}
    with zipfile.ZipFile(archive) as src:
        if src.testzip() is not None:
            raise ValueError("BLOCKED: corrupt input archive")
        for info in src.infolist():
            if info.is_dir() or not safe_zip_name(info.filename) or info.filename in payload:
                raise ValueError("BLOCKED: unsafe, duplicate or directory source ZIP entry")
            mode = stat.S_IFMT(info.external_attr >> 16)
            if mode not in (0, stat.S_IFREG):
                raise ValueError("BLOCKED: symlink or non-file in input ZIP")
            payload[info.filename] = src.read(info)
    manifest = json.loads(payload["SETUP_MANIFEST.json"].decode("utf-8"))
    if manifest.get("project") != "School PDF" or manifest.get("kind") != "fresh-install" or manifest.get("signed_updates") is not True:
        raise ValueError("BLOCKED: not a trusted School PDF Setup package")
    if manifest.get("git_sha") != evidence.get("source_git_sha") or not re.fullmatch(r"[0-9a-f]{40}", manifest["git_sha"]):
        raise ValueError("BLOCKED: acceptance source commit mismatch")
    version = manifest.get("version", "")
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        raise ValueError("BLOCKED: invalid version")
    declared = {}
    for file in manifest.get("files", []):
        name = file["path"]
        if not safe_zip_name(name) or name in declared or name not in payload:
            raise ValueError("BLOCKED: invalid setup manifest path")
        if len(payload[name]) != file["bytes"] or digest(payload[name]) != file["sha256"]:
            raise ValueError("BLOCKED: Setup payload does not match file manifest")
        declared[name] = True
    if set(payload) != set(declared) | EXTRA_SETUP:
        raise ValueError("BLOCKED: unlisted files in Setup archive")
    if not {"public/index.php", "public/install.php", "public/.htaccess", "vendor/autoload.php", "composer.lock"}.issubset(payload):
        raise ValueError("BLOCKED: incomplete Laravel files")
    for secret in (".env", "setup-access.key", "storage/app/private/install.lock", "PREVIEW-NOT-FOR-PRODUCTION.txt"):
        if secret in payload:
            raise ValueError("BLOCKED: live credentials or preview marker found")
    return manifest, payload


def build(root: Path, archive: Path, checksum: Path, acceptance: Path, output: Path) -> tuple[Path, Path]:
    manifest, private_payload = verified_source(archive, checksum, acceptance)
    version = manifest["version"]
    web_payload = {}
    for filename in BRIDGE_FILES:
        file = root / "setup/fixed-root-web" / filename
        if not file.is_file() or not file.stat().st_size or file.is_symlink():
            raise ValueError("BLOCKED: missing or unsafe public bridge source")
        web_payload[filename] = file.read_bytes()
    if "require $schoolpdfPrivate . '/public/index.php';" not in web_payload["index.php"].decode("utf-8"):
        raise ValueError("BLOCKED: bridge index does not invoke PRIVATE Laravel")
    if "require $schoolpdfPrivate . '/public/install.php';" not in web_payload["install.php"].decode("utf-8"):
        raise ValueError("BLOCKED: bridge does not invoke PRIVATE installer")
    if "School PDF" not in web_payload[".schoolpdf-bridge.php"].decode("utf-8"):
        raise ValueError("BLOCKED: missing project-specific private root check")
    if any(b in name for name in web_payload for b in ("/", "\\")):
        raise ValueError("BLOCKED: invalid bridge web file")
    output.mkdir(parents=True, exist_ok=True)
    web_name = f"SchoolPDF-WebBridge-v{version}.zip"
    full_name = f"SchoolPDF-FixedRoot-Setup-v{version}.zip"
    web_zip, full_zip = output / web_name, output / full_name
    instructions = (
        "SCHOOL PDF — FIXED DOCUMENT ROOT — cPanel only\n"
        "Domain: sclpdf.50sols.com\n"
        "Extract this ONE ZIP at your cPanel HOME folder (not public_html).\n"
        "It creates: $HOME/sclpdf/ (private Laravel) and\n"
        "$HOME/public_html/sclpdf.50sols.com/ (public entrypoints ONLY).\n"
        "DO NOT extract onto an existing installed $HOME/sclpdf; use the\n"
        "SchoolPDF-WebBridge ZIP instead to preserve live settings/data.\n"
        "PHP >=8.2; extensions: pdo_mysql, mbstring, openssl, zip, sodium, fileinfo.\n"
        "Prepare HTTPS + MySQL via cPanel; visit https://sclpdf.50sols.com/install.\n"
        "Read the one-time setup-access.key from the PRIVATE $HOME/sclpdf folder.\n"
        "The installer removes that token and locks itself after successful setup.\n"
        "No production server Composer, npm, SSH or terminal commands are needed.\n"
    ).encode("utf-8")

    with zipfile.ZipFile(web_zip, "w") as z:
        for name, data in sorted(web_payload.items()):
            zip_write(z, name, data)
    with zipfile.ZipFile(full_zip, "w") as z:
        for name, data in sorted(private_payload.items()):
            zip_write(z, PRIVATE_PREFIX + name, data)
        for name, data in sorted(web_payload.items()):
            zip_write(z, PUBLIC_PREFIX + name, data)
        zip_write(z, "SchoolPDF-FixedRoot-START_HERE.txt", instructions)

    for file in (web_zip, full_zip):
        with zipfile.ZipFile(file) as z:
            if z.testzip() is not None:
                raise ValueError("BLOCKED: output ZIP integrity failure")
            names = z.namelist()
            if len(set(names)) != len(names) or any(not safe_zip_name(n) for n in names):
                raise ValueError("BLOCKED: output ZIP entry safety failure")
            if file == web_zip and (set(names) != set(BRIDGE_FILES) or any("/" in n for n in names)):
                raise ValueError("BLOCKED: web-only ZIP contains non-public files")
            if file == full_zip and (not any(n.startswith(PRIVATE_PREFIX + "vendor/") for n in names) or
                                     any(n.startswith("public_html/") and not n.startswith(PUBLIC_PREFIX) for n in names)):
                raise ValueError("BLOCKED: fixed-root ZIP directory isolation failure")
        (output / (file.name + ".sha256")).write_text(
            digest(file.read_bytes()) + "  " + file.name + "\n", encoding="utf-8"
        )
    print("VERIFIED SOURCE", manifest["git_sha"])
    print("FIXED ROOT WEB BRIDGE", web_zip)
    print("FIXED ROOT ONE-ZIP CLEAN INSTALL", full_zip)
    return web_zip, full_zip


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--root", type=Path, default=ROOT)
    p.add_argument("--archive", type=Path, required=True)
    p.add_argument("--checksum", type=Path, required=True)
    p.add_argument("--acceptance", type=Path, required=True)
    p.add_argument("--output", type=Path, required=True)
    args = p.parse_args()
    try:
        build(args.root, args.archive, args.checksum, args.acceptance, args.output)
    except (OSError, ValueError, KeyError, zipfile.BadZipFile) as exc:
        print("FIXED ROOT RELEASE BLOCKED:", exc, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
