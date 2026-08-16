#!/usr/bin/env bash
set -euo pipefail
VERSION="$(tr -d '[:space:]' < .xcodegen-version)"
PREFIX="${RUNNER_TEMP:-/tmp}/xcodegen-${VERSION}"
mkdir -p "$PREFIX"
ARCHIVE="$PREFIX/xcodegen.zip"
curl -fsSL "https://github.com/yonaskolb/XcodeGen/releases/download/${VERSION}/xcodegen.zip" -o "$ARCHIVE"
rm -rf "$PREFIX/extracted"
mkdir -p "$PREFIX/extracted"
unzip -q "$ARCHIVE" -d "$PREFIX/extracted"
BIN="$(find "$PREFIX/extracted" -type f -name xcodegen | head -n 1)"
if [[ -z "$BIN" ]]; then
  echo "XcodeGen binary not found in release archive" >&2
  exit 1
fi
install -m 755 "$BIN" /usr/local/bin/xcodegen
xcodegen --version
