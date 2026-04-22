#!/usr/bin/env bash
# scripts/run-ralph.sh
#
# One-command Ralph Loop iteration launcher with automatic session capture
# and activity-log append. Also works with Caveman — Caveman runs inside the
# Claude Code session and does not change the capture mechanism.
#
# Usage:
#   ./scripts/run-ralph.sh [task-hint]
#
# Arguments:
#   task-hint   Optional. Used only in the log filename for later grep-ability
#               (e.g. "T-E01-06"). The actual task is picked by Ralph from
#               IMPLEMENTATION_PLAN.md, not from this hint.
#
# What this script does:
#   1. Captures the full TTY session to .ralph/logs/iter-TIMESTAMP-HINT.log
#   2. Launches Claude Code with --dangerously-skip-permissions
#   3. After the session ends, extracts a structured activity-log entry
#   4. Auto-routes the entry to docs/activity-logs/E-NN.txt based on the
#      task id in the EXIT_SIGNAL; falls back to cross-epic.txt if not
#      parseable
#   5. Leaves the raw log at .ralph/logs/ for later review or re-extraction

set -euo pipefail

# Always run from the repository root so relative paths work regardless of cwd
cd "$(dirname "$0")/.."

TASK_HINT="${1:-unknown}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
mkdir -p .ralph/logs
LOG=".ralph/logs/iter-${TIMESTAMP}-${TASK_HINT}.log"

# Sanity check: refuse to run if extractor is missing
if [[ ! -x scripts/ralph-log-to-activity.sh ]]; then
    echo "error: scripts/ralph-log-to-activity.sh not found or not executable" >&2
    echo "       expected to live in the repo — did you run this from outside the repo?" >&2
    exit 1
fi

# Sanity check: refuse to run if the `claude` CLI is missing
if ! command -v claude >/dev/null 2>&1; then
    echo "error: 'claude' command not found on PATH" >&2
    echo "       Claude Code CLI must be installed and on PATH before running Ralph" >&2
    exit 1
fi

echo "================================================================"
echo "  Ralph Loop iteration launcher"
echo "  Timestamp: ${TIMESTAMP}"
echo "  Log file:  ${LOG}"
echo "  Task hint: ${TASK_HINT}"
echo "================================================================"
echo ""
echo "At the Claude prompt, paste the standard trigger:"
echo ""
echo "  Follow the instructions in PROMPT.md exactly. PROMPT.md is in"
echo "  the repo root. Read it first, then execute it against the"
echo "  current state of IMPLEMENTATION_PLAN.md."
echo ""
echo "When Ralph prints EXIT_SIGNAL, press Ctrl+D to exit cleanly."
echo ""
read -r -p "Press Enter to launch... "

# Capture the full TTY session. `script -q` is quiet (no preamble/postamble).
# Using `bash -c` wrapper so that `exit 0` inside claude propagates back.
script -q -c "claude --dangerously-skip-permissions" "${LOG}"

echo ""
echo "================================================================"
echo "  Session ended. Extracting activity-log entry..."
echo "================================================================"

# Run the extractor
if ! ENTRY="$(./scripts/ralph-log-to-activity.sh "${LOG}" 2>&1)"; then
    echo "error: extractor failed. Raw log retained at ${LOG}" >&2
    echo "       Run the extractor manually to debug:" >&2
    echo "       ./scripts/ralph-log-to-activity.sh ${LOG}" >&2
    exit 1
fi

if [[ -z "${ENTRY}" ]]; then
    echo "warning: extractor produced no entry. Raw log retained at ${LOG}"
    exit 0
fi

# Determine target EPIC file from the TASK field in the extracted entry
# TASK: T-E01-06 -> E-01.txt
TASK_LINE="$(echo "${ENTRY}" | grep -E '^TASK: ' | head -1 || true)"
EPIC_NUM="$(echo "${TASK_LINE}" | grep -oE 'T-E[0-9]+' | head -1 | sed 's/T-E/E-/' || true)"

if [[ -n "${EPIC_NUM}" && -d docs/activity-logs ]]; then
    TARGET="docs/activity-logs/${EPIC_NUM}.txt"
    ROUTING="matched task id to EPIC ${EPIC_NUM}"
else
    TARGET="docs/activity-logs/cross-epic.txt"
    ROUTING="could not parse EPIC from task id; routing to cross-epic.txt"
fi

echo ""
echo "Routing: ${ROUTING}"
echo "Target:  ${TARGET}"
echo ""
echo "Preview of extracted entry:"
echo "----------------------------------------------------------------"
echo "${ENTRY}"
echo "----------------------------------------------------------------"
echo ""

read -r -p "Append to ${TARGET}? [Y/n] " CONFIRM
CONFIRM="${CONFIRM:-Y}"

if [[ "${CONFIRM}" =~ ^[Yy] ]]; then
    # Ensure the target file exists (with a leading newline if it already has content)
    if [[ -s "${TARGET}" ]]; then
        echo "" >> "${TARGET}"
    fi
    echo "${ENTRY}" >> "${TARGET}"
    echo ""
    echo "Entry appended to ${TARGET}"
    echo ""
    echo "Next steps:"
    echo "  1. Review:  tail -40 ${TARGET}"
    echo "  2. Edit:    \$EDITOR ${TARGET}  (to enrich narrative)"
    echo "  3. Commit:  git add ${TARGET} && git commit -m 'docs(activity-log): record ${TASK_HINT} session'"
else
    echo ""
    echo "Not appended. Raw log retained at ${LOG}"
    echo "To append manually later:"
    echo "  ./scripts/ralph-log-to-activity.sh ${LOG} >> ${TARGET}"
fi

echo ""
echo "Raw log retained at: ${LOG}"
