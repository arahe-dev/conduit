#!/usr/bin/env bash
set -euo pipefail
APP_PATH="$1"
OUT_DIR="$2"
mkdir -p "$OUT_DIR/Payload"
rm -rf "$OUT_DIR/Payload/"*
cp -R "$APP_PATH" "$OUT_DIR/Payload/ProductivityTracker.app"
(
  cd "$OUT_DIR"
  rm -f ProductivityTracker-unsigned.ipa
  zip -qry ProductivityTracker-unsigned.ipa Payload
)
python3 - <<'PY' "$OUT_DIR/ProductivityTracker-unsigned.ipa" "$OUT_DIR/SHA256SUMS.txt"
import hashlib, sys
from pathlib import Path
ipa = Path(sys.argv[1])
digest = hashlib.sha256(ipa.read_bytes()).hexdigest()
Path(sys.argv[2]).write_text(f"{digest}  {ipa.name}\n")
print(digest)
PY
python3 - <<'PY' "$OUT_DIR/ProductivityTracker-unsigned.ipa"
import sys, zipfile
from pathlib import Path
ipa = Path(sys.argv[1])
with zipfile.ZipFile(ipa) as zf:
    names = zf.namelist()
print("IPA entries:")
for name in names:
    print(name)
assert any(name == "Payload/ProductivityTracker.app/" or name.startswith("Payload/ProductivityTracker.app/") for name in names), "Missing app payload"
assert any("ProductivityTracker.app/Info.plist" in name for name in names), "Missing Info.plist"
appex = [name for name in names if name.endswith(".appex/") or ".appex/" in name]
print("appex entries:", appex)
PY
