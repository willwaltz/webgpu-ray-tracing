#!/usr/bin/env bash
# Applies the patches to a Chromium source tree: Brave's (brave-browser's src, as Brave's sync
# leaves it). Brave's sync puts Chromium's files back as Brave patches them, which takes these
# changes out again: run this after each sync. It says so if they are in already.
#   scripts/apply.sh <path to src>
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
src=$(realpath "${1:?usage: scripts/apply.sh <path to the Chromium src directory>}")
dawn="$src/third_party/dawn"

if git -C "$dawn" apply -R --check "$root/patches/dawn.patch" 2>/dev/null; then
  echo "dawn.patch: already applied"
else
  git -C "$dawn" apply "$root/patches/dawn.patch"
  echo "dawn.patch: applied"
fi
if patch -p1 -R --dry-run -s -f -d "$src" <"$root/patches/chromium.patch" >/dev/null 2>&1; then
  echo "chromium.patch: already applied"
else
  patch -p1 -N --no-backup-if-mismatch -s -d "$src" <"$root/patches/chromium.patch"
  echo "chromium.patch: applied"
fi
