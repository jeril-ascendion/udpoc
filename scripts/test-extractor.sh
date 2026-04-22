#!/usr/bin/env bash
# scripts/test-extractor.sh
#
# Reproducible sanity test for scripts/ralph-log-to-activity.sh.
# Fabricates a minimal fake Ralph session log, runs the extractor, and
# asserts that each critical field is populated correctly.
#
# Run this after any change to the extractor. A clean pass means the
# extractor handles the baseline case correctly; it does not prove
# correctness on edge cases (Caveman mode, blocked tasks, multi-commit
# iterations), which should be added as the extractor evolves.

set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -x scripts/ralph-log-to-activity.sh ]]; then
    echo "error: scripts/ralph-log-to-activity.sh not found or not executable" >&2
    exit 1
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "${TMPDIR}"' EXIT

FAKE_LOG="${TMPDIR}/iter-20260101-000000-T-E99-01.log"

cat > "${FAKE_LOG}" <<'FAKE'
$ git checkout -b feat/E-99/T-E99-01-baseline
Switched to a new branch 'feat/E-99/T-E99-01-baseline'
$ echo "make a change"
modified: path/to/file.ts
new file: path/to/another.ts
$ git commit -m "feat(T-E99-01): baseline"
[feat/E-99/T-E99-01-baseline abc1234] feat(T-E99-01): baseline
[CAVEMAN:FULL]
EXIT_SIGNAL: TASK_DONE_T-E99-01
FAKE

OUTPUT="$(./scripts/ralph-log-to-activity.sh "${FAKE_LOG}")"

PASS=0
FAIL=0

check() {
    local label="$1"
    local pattern="$2"
    if echo "${OUTPUT}" | grep -qE "${pattern}"; then
        echo "  PASS  ${label}"
        PASS=$((PASS + 1))
    else
        echo "  FAIL  ${label}"
        echo "        pattern: ${pattern}"
        FAIL=$((FAIL + 1))
    fi
}

echo "Extractor output:"
echo "----------------------------------------------------------------"
echo "${OUTPUT}"
echo "----------------------------------------------------------------"
echo ""
echo "Assertions:"

check "TASK field contains T-E99-01"         '^TASK: T-E99-01'
check "SOURCE is ralph"                      '^SOURCE: ralph'
check "BRANCH parsed correctly"              '^BRANCH: feat/E-99/T-E99-01-baseline'
check "COMMITS contains abc1234"             '^COMMITS:.*abc1234'
check "FILES TOUCHED is not a literal 'see'" '^FILES TOUCHED: (path/to/file\.ts|path/to/another\.ts)'
check "CAVEMAN mode detected"                '^CAVEMAN: \[CAVEMAN:FULL\]'
check "EXIT contains TASK_DONE_T-E99-01"     '^EXIT: EXIT_SIGNAL: TASK_DONE_T-E99-01'
check "Opening delimiter present"            '^={80}$'
check "Closing delimiter present"            '(^|\n)={80}$'

echo ""
echo "Result: ${PASS} passed, ${FAIL} failed"

if [[ ${FAIL} -gt 0 ]]; then
    exit 1
fi

exit 0
