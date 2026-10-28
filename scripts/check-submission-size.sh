#!/usr/bin/env bash
# Zips PeekAhead.swiftpm the way it is submitted and fails if the archive is over the Swift Student Challenge limit.
# Usage: scripts/check-submission-size.sh [limit-in-MB]   (default 25)
set -euo pipefail

limit_mb="${1:-25}"
root="$(cd "$(dirname "$0")/.." && pwd)"
out_dir="$(mktemp -d)"
trap 'rm -rf "$out_dir"' EXIT

archive="$out_dir/PeekAhead.swiftpm.zip"
(
    cd "$root"
    zip -qr "$archive" PeekAhead.swiftpm -x '*.DS_Store' '*/xcuserdata/*' 'PeekAhead.swiftpm/.build/*'
)

bytes=$(wc -c <"$archive" | tr -d ' ')
limit_bytes=$((limit_mb * 1024 * 1024))
awk -v b="$bytes" -v l="$limit_mb" 'BEGIN { printf "PeekAhead.swiftpm.zip: %.1f MB (limit %d MB)\n", b / 1048576, l }'

if [ "$bytes" -gt "$limit_bytes" ]; then
    echo "error: the submission archive is over the limit" >&2
    exit 1
fi
