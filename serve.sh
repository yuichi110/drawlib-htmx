#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

export UV_DEFAULT_INDEX="${UV_DEFAULT_INDEX:-https://pypi.org/simple}"

HAS_CHECK_FLAG=false
for arg in "$@"; do
    case "$arg" in
        --check|--no-skip-check)
            HAS_CHECK_FLAG=true
            ;;
    esac
done

if [ "$HAS_CHECK_FLAG" = true ]; then
    exec uvx --default-index "$UV_DEFAULT_INDEX" drawlib@0.3.9 serve docs/ "$@"
else
    exec uvx --default-index "$UV_DEFAULT_INDEX" drawlib@0.3.9 serve docs/ --skip-check "$@"
fi
