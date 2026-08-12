#!/usr/bin/env bash
# Symlinks bin/sbx and the bin/supabase shim into PREFIX (default ~/.local/bin).
# The shim must come BEFORE the real Supabase CLI in PATH to take effect.
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local/bin}"
REPO_DIR=$(cd "$(dirname "$0")" && pwd -P)

mkdir -p "$PREFIX"

for name in sbx supabase; do
  src="$REPO_DIR/bin/$name"
  dst="$PREFIX/$name"
  if [ -e "$dst" ] && [ "$(readlink "$dst" 2>/dev/null || true)" != "$src" ]; then
    printf 'install: refusing to overwrite %s (not an sbx symlink) — remove it yourself if that is intended\n' "$dst" >&2
    exit 1
  fi
  ln -sf "$src" "$dst"
  printf 'linked %s -> %s\n' "$dst" "$src"
done

# Sanity checks: a real CLI to delegate to, and PATH ordering.
real_found=""
OLD_IFS=$IFS; IFS=':'
for dir in $PATH; do
  if [ -n "$dir" ] && [ "$dir" != "$PREFIX" ] && [ -x "$dir/supabase" ]; then
    real_found="$dir/supabase"
    break
  fi
done
IFS=$OLD_IFS
if [ -z "$real_found" ]; then
  printf 'warning: no real Supabase CLI found in PATH — install it (brew install supabase/tap/supabase)\n' >&2
fi

first=$(command -v supabase || true)
if [ "$first" != "$PREFIX/supabase" ]; then
  printf 'warning: PATH resolves `supabase` to %s, not the sbx shim.\n' "${first:-<nothing>}" >&2
  printf '         Add this to your shell rc, before other PATH entries:\n' >&2
  printf '           export PATH="%s:$PATH"\n' "$PREFIX" >&2
fi

printf 'done. Try: sbx --help\n'
