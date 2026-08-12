#!/usr/bin/env bash
# sbx test suite — offline and deterministic. Uses a fake `supabase` binary
# (no network, no real tokens) and throwaway keychain entries namespaced by
# PID, removed on exit. Run: tests/run-tests.sh
set -u

ROOT=$(cd "$(dirname "$0")/.." && pwd -P)
TMP=$(mktemp -d)
P_A="sbx-test-$$-a"
P_B="sbx-test-$$-b"
PASS=0
FAIL=0

cleanup() {
  security delete-generic-password -s sbx -a "$P_A" >/dev/null 2>&1 || true
  security delete-generic-password -s sbx -a "$P_B" >/dev/null 2>&1 || true
  rm -rf "$TMP"
}
trap cleanup EXIT

ok()   { PASS=$((PASS + 1)); printf 'ok   %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$1"; }

assert_eq() {  # desc want got
  if [ "$2" = "$3" ]; then ok "$1"; else fail "$1 — want [$2], got [$3]"; fi
}

assert_status() {  # desc want-status got-status
  if [ "$2" = "$3" ]; then ok "$1"; else fail "$1 — want exit $2, got $3"; fi
}

# Fake "real" CLI: reports argv, cwd, and the token it received.
mkdir -p "$TMP/fakebin"
cat > "$TMP/fakebin/supabase" <<'EOF'
#!/usr/bin/env bash
echo "argv=[$*] cwd=$PWD token=${SUPABASE_ACCESS_TOKEN:-unset}"
EOF
chmod +x "$TMP/fakebin/supabase"
export PATH="$ROOT/bin:$TMP/fakebin:$PATH"

mkdir -p "$TMP/repoA/nested/deep" "$TMP/repoB" "$TMP/plain"
echo "$P_A" > "$TMP/repoA/.supabase-account"
printf '# client account\n\n%s\n' "$P_B" > "$TMP/repoB/.supabase-account"

# --- profile store -----------------------------------------------------------

out=$(echo "sbp_token_AAA" | sbx add "$P_A")
assert_eq "add reports a new profile" "stored new profile '$P_A'" "$out"
echo "sbp_token_BBB" | sbx add "$P_B" >/dev/null
assert_eq "token roundtrip"      "sbp_token_AAA" "$(sbx token "$P_A")"
assert_eq "list contains both"   "2"             "$(sbx list | grep -c "^sbx-test-$$-")"

# Rotating a token: re-adding replaces in place and says so, rather than
# silently overwriting a working credential on a mistyped profile name.
out=$(echo "sbp_token_ROTATED" | sbx add "$P_A")
assert_eq "re-add reports a replacement" "replaced the token for existing profile '$P_A'" "$out"
assert_eq "re-add replaces the token"    "sbp_token_ROTATED" "$(sbx token "$P_A")"
assert_eq "re-add leaves no duplicate"   "1" "$(sbx list | grep -c "^$P_A$")"
echo "sbp_token_AAA" | sbx add "$P_A" >/dev/null  # restore for later assertions

echo "not-a-token" | sbx add "$P_A" >/dev/null 2>&1
assert_status "add rejects non-sbp token" 1 $?
assert_eq "rejected add left token intact" "sbp_token_AAA" "$(sbx token "$P_A")"

echo "sbp_x" | sbx add "bad name" >/dev/null 2>&1
assert_status "add rejects invalid profile name" 1 $?

sbx token "sbx-test-$$-nope" >/dev/null 2>&1
assert_status "token for unknown profile fails" 1 $?

# --- shim resolution rules ---------------------------------------------------

assert_eq "repo file selects token" \
  "argv=[projects list] cwd=$TMP/repoA token=sbp_token_AAA" \
  "$(cd "$TMP/repoA" && supabase projects list)"

assert_eq "walk-up from nested dir, cwd preserved" \
  "argv=[db push] cwd=$TMP/repoA/nested/deep token=sbp_token_AAA" \
  "$(cd "$TMP/repoA/nested/deep" && supabase db push)"

assert_eq "comments/blanks in account file ignored" \
  "argv=[status] cwd=$TMP/repoB token=sbp_token_BBB" \
  "$(cd "$TMP/repoB" && supabase status)"

(cd "$TMP/repoA" && supabase a) > "$TMP/out.parallel-a" &
(cd "$TMP/repoB" && supabase b) > "$TMP/out.parallel-b" &
wait
assert_eq "parallel: repoA kept its account" \
  "argv=[a] cwd=$TMP/repoA token=sbp_token_AAA" "$(cat "$TMP/out.parallel-a")"
assert_eq "parallel: repoB kept its account" \
  "argv=[b] cwd=$TMP/repoB token=sbp_token_BBB" "$(cat "$TMP/out.parallel-b")"

assert_eq "no account file passes through untouched" \
  "argv=[--version] cwd=$TMP/plain token=unset" \
  "$(cd "$TMP/plain" && supabase --version)"

assert_eq "explicit env var beats account file" \
  "argv=[whoami] cwd=$TMP/repoA token=sbp_explicit" \
  "$(cd "$TMP/repoA" && SUPABASE_ACCESS_TOKEN=sbp_explicit supabase whoami)"

echo "sbx-test-$$-nope" > "$TMP/plain/.supabase-account"
out=$(cd "$TMP/plain" && supabase projects list 2>&1)
assert_status "unknown profile is a hard error" 1 $?
case "$out" in
  *argv=* ) fail "unknown profile must not reach the real CLI" ;;
  * ) ok "unknown profile does not reach the real CLI" ;;
esac
rm "$TMP/plain/.supabase-account"

# The shim must never touch the CLI's repo-local link state (supabase/.temp).
mkdir -p "$TMP/repoA/supabase/.temp"
echo "refref" > "$TMP/repoA/supabase/.temp/project-ref"
(cd "$TMP/repoA" && supabase secrets list >/dev/null)
assert_eq "link state untouched by shim" "refref" "$(cat "$TMP/repoA/supabase/.temp/project-ref")"

# --- installer ---------------------------------------------------------------

PREFIX="$TMP/prefix" "$ROOT/install.sh" >/dev/null 2>&1
assert_eq "installer links shim" "$ROOT/bin/supabase" "$(readlink "$TMP/prefix/supabase")"
assert_eq "installer links sbx"  "$ROOT/bin/sbx"      "$(readlink "$TMP/prefix/sbx")"

assert_eq "shim works via installed symlinks" \
  "argv=[x] cwd=$TMP/repoA token=sbp_token_AAA" \
  "$(cd "$TMP/repoA" && PATH="$TMP/prefix:$TMP/fakebin:/usr/bin:/bin" "$TMP/prefix/supabase" x)"

mkdir -p "$TMP/prefix2" && echo foreign > "$TMP/prefix2/supabase"
PREFIX="$TMP/prefix2" "$ROOT/install.sh" >/dev/null 2>&1
assert_status "installer refuses to clobber foreign file" 1 $?
assert_eq "foreign file left intact" "foreign" "$(cat "$TMP/prefix2/supabase")"

PREFIX="$TMP/prefix" "$ROOT/install.sh" >/dev/null 2>&1
assert_status "re-install is idempotent" 0 $?

# man(1) searches a bin dir's sibling share/man, so the page must land there.
page="$TMP/share/man/man1/sbx.1"
if [ -r "$page" ] && head -1 "$page" | grep -q '^\.TH SBX 1'; then
  ok "installer puts the man page where man(1) looks"
else
  fail "expected a readable man page at <prefix>/../share/man/man1/sbx.1"
fi
if command -v mandoc >/dev/null 2>&1; then
  lint=$(mandoc -T lint "$ROOT/man/sbx.1" 2>&1)
  assert_eq "man page is free of roff warnings" "" "$lint"
fi

# --- summary -----------------------------------------------------------------

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
