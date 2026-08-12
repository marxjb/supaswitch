#!/usr/bin/env bash
# Convenience wrapper for the git-clone install path; the linking logic itself
# lives in `sbx install` so npm installs use the same code.
set -euo pipefail
exec "$(cd "$(dirname "$0")" && pwd -P)/bin/sbx" install "${PREFIX:-$HOME/.local/bin}"
