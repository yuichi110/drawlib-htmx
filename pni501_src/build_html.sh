#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PARENT_DIR"

export UV_DEFAULT_INDEX="${UV_DEFAULT_INDEX:-https://pypi.org/simple}"
DRAWLIB_CMD="${DRAWLIB_CMD:-uvx drawlib@0.3.9}"

BACKUP_DIR="$SCRIPT_DIR/.pni501_backup"
rm -rf "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

for f in pni501.pdf pni501_score.json; do
    if [ -f "docs/pni501/$f" ]; then
        cp -p "docs/pni501/$f" "$BACKUP_DIR/$f"
    fi
done

restore_artifacts() {
    mkdir -p "docs/pni501"
    for f in pni501.pdf pni501_score.json; do
        if [ -f "$BACKUP_DIR/$f" ] && [ ! -f "docs/pni501/$f" ]; then
            cp -p "$BACKUP_DIR/$f" "docs/pni501/$f"
        fi
    done
    rm -rf "$BACKUP_DIR"
}
trap restore_artifacts EXIT

echo "Building PNI501 Diagnostic Report HTML -> docs/pni501/..."
$DRAWLIB_CMD build html pni501_src/ -o docs/pni501/
echo "HTML build complete: docs/pni501/"
