#!/usr/bin/env bash
# Promote a fresh conversion (src.staging) to the live src/ tree.
# Run after tools/convert.sh. Kept separate so an accidental re-convert only
# rewrites src.staging, never your live src/ (git is the final safety net).
#
#   ./tools/convert.sh && ./tools/promote.sh
set -euo pipefail
cd "$(dirname "$0")/.."
[ -d src.staging ] || { echo "no src.staging — run tools/convert.sh first"; exit 1; }
rm -rf src
cp -r src.staging src
rm -rf src.staging
echo "promoted src.staging -> src ($(find src -name '*.hx' | wc -l | tr -d ' ') .hx files)"
