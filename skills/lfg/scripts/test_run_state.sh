#!/usr/bin/env bash
# Test battery for run_state.sh. Self-contained: runs in a mktemp -d sandbox,
# cleans up on exit, prints PASS/FAIL per case, exits non-zero if any case fails.
# Usage: test_run_state.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RS="$SCRIPT_DIR/run_state.sh"
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

fails=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; fails=$((fails + 1)); }

# assert_valid_json <name> <run_dir> — the atomicity smoke: state.json parses after every op
assert_valid_json() {
  if jq -e . "$2/state.json" > /dev/null 2>&1; then pass "$1"; else fail "$1"; fi
}

RUN="$SANDBOX/lfg-test"

# --- init creates valid JSON with phase=preflight ---
bash "$RS" init "$RUN"
assert_valid_json "init: state.json is valid JSON" "$RUN"
if [[ "$(jq -r .phase "$RUN/state.json")" == "preflight" ]]; then
  pass "init: phase=preflight"
else
  fail "init: phase=preflight"
fi

# --- set/get roundtrip for each allowed string key ---
declare -a KEYS=(phase pr_number base_ref head_ref consolidator run_token repo_root skill_dir)
declare -a VALS=(shipped 38 main lfg/harden consolidate-38 r2 /tmp/some-repo /tmp/skills/lfg)
for i in "${!KEYS[@]}"; do
  key="${KEYS[$i]}"; val="${VALS[$i]}"
  bash "$RS" set "$RUN" "$key" "$val"
  assert_valid_json "atomicity smoke: valid JSON after set $key" "$RUN"
  got="$(bash "$RS" get "$RUN" "$key")"
  if [[ "$got" == "$val" ]]; then
    pass "roundtrip: set/get $key"
  else
    fail "roundtrip: set/get $key (got '$got', want '$val')"
  fi
done

# --- roster round-trips as a JSON array ---
bash "$RS" set "$RUN" roster "rev-security-38, rev-tests-38,rev-docs-38"
assert_valid_json "atomicity smoke: valid JSON after set roster" "$RUN"
got="$(bash "$RS" get "$RUN" roster)"
want='["rev-security-38","rev-tests-38","rev-docs-38"]'
if [[ "$got" == "$want" ]]; then
  pass "roster: round-trips as a JSON array (whitespace trimmed)"
else
  fail "roster: round-trips as a JSON array (got '$got', want '$want')"
fi

# --- get with no key prints the whole JSON ---
if bash "$RS" get "$RUN" | jq -e '.phase and .roster' > /dev/null 2>&1; then
  pass "get: whole JSON without a key"
else
  fail "get: whole JSON without a key"
fi

# --- set rejects unknown key ---
if bash "$RS" set "$RUN" not_a_key oops > /dev/null 2>&1; then
  fail "set: rejects unknown key"
else
  pass "set: rejects unknown key"
fi

# --- set rejects unknown phase value ---
if bash "$RS" set "$RUN" phase not-a-phase > /dev/null 2>&1; then
  fail "set: rejects unknown phase value"
else
  pass "set: rejects unknown phase value"
fi

# --- get on missing file fails ---
if bash "$RS" get "$SANDBOX/no-such-run" > /dev/null 2>&1; then
  fail "get: missing state file exits non-zero"
else
  pass "get: missing state file exits non-zero"
fi

# --- get on missing key fails ---
FRESH="$SANDBOX/lfg-fresh"
bash "$RS" init "$FRESH"
if bash "$RS" get "$FRESH" pr_number > /dev/null 2>&1; then
  fail "get: missing key exits non-zero"
else
  pass "get: missing key exits non-zero"
fi

# --- init refuses to clobber an in-flight run (phase is 'shipped' from the roundtrip) ---
if bash "$RS" init "$RUN" > /dev/null 2>&1; then
  fail "init: refuses over an in-flight run"
else
  pass "init: refuses over an in-flight run"
fi
assert_valid_json "init refusal: state.json still valid JSON" "$RUN"
if [[ "$(bash "$RS" get "$RUN" phase)" == "shipped" && "$(bash "$RS" get "$RUN" pr_number)" == "38" ]]; then
  pass "init refusal: in-flight state left untouched"
else
  fail "init refusal: in-flight state left untouched"
fi

# --- init --force overrides the in-flight guard ---
bash "$RS" init "$RUN" --force
assert_valid_json "init --force: state.json still valid JSON" "$RUN"
if [[ "$(bash "$RS" get "$RUN" phase)" == "preflight" ]]; then
  pass "init --force: resets phase to preflight"
else
  fail "init --force: resets phase to preflight"
fi

# --- re-init over a terminal run resets to preflight (complete, then aborted) ---
bash "$RS" set "$RUN" phase complete
bash "$RS" init "$RUN"
assert_valid_json "re-init after complete: state.json still valid JSON" "$RUN"
if [[ "$(bash "$RS" get "$RUN" phase)" == "preflight" ]]; then
  pass "re-init after complete: resets phase to preflight"
else
  fail "re-init after complete: resets phase to preflight"
fi

bash "$RS" set "$RUN" phase aborted
assert_valid_json "atomicity smoke: valid JSON after set phase aborted" "$RUN"
bash "$RS" init "$RUN"
if [[ "$(bash "$RS" get "$RUN" phase)" == "preflight" ]]; then
  pass "re-init after aborted: resets phase to preflight"
else
  fail "re-init after aborted: resets phase to preflight"
fi

# --- no stray tmp files left behind ---
if compgen -G "$RUN/state.json.*" > /dev/null; then
  fail "atomicity: no leftover tmp files"
else
  pass "atomicity: no leftover tmp files"
fi

echo
if [[ "$fails" -eq 0 ]]; then
  echo "ALL PASS"
else
  echo "$fails FAILURE(S)"
  exit 1
fi
