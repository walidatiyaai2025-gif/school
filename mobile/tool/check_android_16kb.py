#!/usr/bin/env python3
"""Reject Android APK native shared objects with ELF PT_LOAD alignment below 16 KB.

Uses only stdlib, so this can run on CI and Windows. Checks all packaged ABIs,
never infers 16 KB compliance merely from a successful Gradle build.
"""
import argparse
import struct
import sys
import zipfile
from pathlib import Path

PAGE = 0x4000


def load_alignments(raw: bytes) -> list[int]:
    if len(raw) < 64 or raw[:4] != b'\x7fELF' or raw[5] != 1:
        raise ValueError('invalid or unsupported ELF header')
    if raw[4] == 2:
        phoff = struct.unpack_from('<Q', raw, 32)[0]
        entry_size = struct.unpack_from('<H', raw, 54)[0]
        count = struct.unpack_from('<H', raw, 56)[0]
        fmt = '<IIQQQQQQ'
    elif raw[4] == 1:
        phoff = struct.unpack_from('<I', raw, 28)[0]
        entry_size = struct.unpack_from('<H', raw, 42)[0]
        count = struct.unpack_from('<H', raw, 44)[0]
        fmt = '<IIIIIIII'
    else:
        raise ValueError('unsupported ELF class')
    if entry_size < struct.calcsize(fmt) or count == 0 or phoff + count * entry_size > len(raw):
        raise ValueError('malformed ELF program headers')
    aligns = []
    for i in range(count):
        offset = phoff + i * entry_size
        if struct.unpack_from('<I', raw, offset)[0] == 1:
            aligns.append(struct.unpack_from(fmt, raw, offset)[-1])
    if not aligns:
        raise ValueError('no PT_LOAD segments')
    return aligns


def verify(apk: Path) -> bool:
    ok, found = True, 0
    with zipfile.ZipFile(apk) as archive:
        if archive.testzip() is not None:
            raise ValueError('APK ZIP integrity failure')
        for entry in archive.infolist():
            # APKs use lib/<abi>; Android App Bundles use base/lib/<abi>.
            relative = entry.filename.removeprefix('base/')
            if not relative.startswith('lib/') or not relative.endswith('.so'):
                continue
            found += 1
            try:
                aligns = load_alignments(archive.read(entry))
                aligned = all(a >= PAGE for a in aligns)
            except ValueError as exc:
                print(f'FAIL {entry.filename}: {exc}')
                aligned = False
                aligns = []
            print(f'{"PASS" if aligned else "FAIL"} {entry.filename}: LOAD alignments {", ".join(hex(a) for a in aligns)}')
            ok = ok and aligned
    if found == 0:
        print('FAIL: APK lacks native libraries')
        ok = False
    print(f'16KB ELF PT_LOAD alignment: {"PASS" if ok else "FAIL"} ({found} shared libraries checked)')
    return ok


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('apk', type=Path)
    args = parser.parse_args()
    if not args.apk.is_file():
        print(f'APK missing: {args.apk}', file=sys.stderr)
        return 2
    try:
        return 0 if verify(args.apk) else 1
    except (ValueError, zipfile.BadZipFile, OSError) as exc:
        print(f'16KB alignment verification error: {exc}', file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())
