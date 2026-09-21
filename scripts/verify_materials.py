#!/usr/bin/env python3
"""Verify a downloaded materials snapshot without the private source workspace."""
import hashlib
import json
from pathlib import Path
import sys


def verify(root: Path) -> int:
    if root.is_symlink():
        raise ValueError("Package directory must not be a symlink")
    root = root.resolve(strict=True)
    paths = list(root.rglob("*"))
    if any(p.is_symlink() for p in paths):
        raise ValueError("Package contains a symlink")
    manifest = json.loads((root / "manifest.json").read_text(encoding="utf-8"))
    entries = manifest["files"]
    actual = {p.relative_to(root).as_posix() for p in paths if p.is_file()}
    if actual != set(entries) | {"manifest.json"}:
        raise ValueError("Package file list differs from manifest")
    for name, entry in entries.items():
        relative = Path(name)
        if relative.is_absolute() or ".." in relative.parts:
            raise ValueError("Invalid manifest path")
        content = (root / relative).read_bytes()
        if hashlib.sha256(content).hexdigest() != entry["sha256"]:
            raise ValueError(f"SHA-256 mismatch: {name}")
        if len(content) != entry["size_bytes"]:
            raise ValueError(f"Size mismatch: {name}")
    return len(entries)


if __name__ == "__main__":
    package = Path(__file__).resolve().parents[1] / "materials" / "20260921"
    if len(sys.argv) > 1:
        package = Path(sys.argv[1])
    try:
        count = verify(package)
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        raise SystemExit(1)
    print(f"PASS: {count} material files match manifest (integrity only).")
