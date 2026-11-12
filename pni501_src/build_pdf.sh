#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PARENT_DIR"

export UV_DEFAULT_INDEX="${UV_DEFAULT_INDEX:-https://pypi.org/simple}"
DRAWLIB_CMD="${DRAWLIB_CMD:-uvx drawlib@0.3.9}"

mkdir -p docs/pni501
echo "Building PNI501 Diagnostic Report PDF -> docs/pni501/pni501.pdf..."
$DRAWLIB_CMD build pdf pni501_src/ -o docs/pni501/pni501.pdf --generate-index
if [ -f "docs/pni501/pni501_en.pdf" ]; then
    mv -f "docs/pni501/pni501_en.pdf" "docs/pni501/pni501.pdf"
fi
echo "PDF build complete: docs/pni501/pni501.pdf"
