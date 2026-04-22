#!/usr/bin/env bash
# scripts/ralph-log-to-activity.sh
#
# Extract a structured activity-log entry from a raw Ralph Loop session log.
# The raw log is produced by the Ralph launch pattern:
#   script -q -c "claude --dangerously-skip-permissions" .ralph/logs/iter-TIMESTAMP-TASK.log
#
# Usage:
#   ./scripts/ralph-log-to-activity.sh <logfile> [>> docs/activity-logs/E-NN.txt]
#
# The script emits a single well-formed entry block on stdout. The narrative
# body is deliberately minimal — edit the destination file after appending if
# more context is warranted.

set -euo pipefail

LOG="${1:-}"
if [[ -z "$LOG" ]]; then
    echo "Usage: $0 <ralph-log-file>" >&2
    echo "Example: $0 .ralph/logs/iter-20260422-143000-T-E01-06.log" >&2
    exit 1
fi

if [[ ! -f "$LOG" ]]; then
    echo "Error: log file not found: $LOG" >&2
    exit 1
fi

# Strip ANSI escape codes and carriage-return artifacts from the raw log
CLEAN=$(mktemp)
trap 'rm -f "$CLEAN"' EXIT
# Remove ANSI CSI sequences; remove bare CRs that `script` emits for terminal redraws
sed -E $'s/\x1B\\[[0-9;?]*[a-zA-Z]//g; s/\x1B\\][^\x07]*\x07//g; s/\r//g' "$LOG" > "$CLEAN"

# File modification time — portable between GNU coreutils (Linux) and BSD (macOS)
if stat -c %y "$LOG" >/dev/null 2>&1; then
    MTIME=$(stat -c %y "$LOG" | cut -d'.' -f1 | tr ' ' 'T')
else
    MTIME=$(stat -f %Sm -t "%Y-%m-%dT%H:%M:%S" "$LOG" 2>/dev/null || echo "unknown")
fi

# Task id — prefer the one embedded in the filename if it follows our convention
FILENAME_TASK=$(basename "$LOG" | grep -oE 'T-E[0-9]+-[0-9]+(\.[0-9]+)?' | head -1 || true)
EXIT_TASK=$(grep -oE 'EXIT_SIGNAL: TASK_(DONE|BLOCKED)_[A-Za-z0-9_.-]+' "$CLEAN" | tail -1 | sed -E 's/.*TASK_(DONE|BLOCKED)_//' || true)
TASK="${FILENAME_TASK:-${EXIT_TASK:-unknown}}"

# Branch — look for the branch Ralph created
BRANCH=$(grep -oE 'feat/E-[0-9]+/T-E[0-9]+-[0-9]+[a-z0-9.-]*' "$CLEAN" | head -1 || echo "unknown")

# Commits — git commit output emits lines like "[branch-name abc1234]"
COMMITS=$(grep -oE '\[[a-zA-Z0-9/_.-]+ [a-f0-9]{7,}\]' "$CLEAN" \
    | grep -oE '[a-f0-9]{7,}' | sort -u | tr '\n' ',' | sed 's/,$//' || true)
COMMITS="${COMMITS:-none}"

# Files touched — look for lines that look like git status/diff output
# Best-effort; narrative edit can fill in gaps
FILES=$(grep -oE '(modified|new file|deleted):[[:space:]]+[a-zA-Z0-9/_.-]+' "$CLEAN" \
    | awk '{print $NF}' | sort -u | tr '\n' ',' | sed 's/,$//' || true)
FILES="${FILES:-see commit diff}"

# Caveman mode — detect the statusline badge Caveman renders
CAVEMAN=$(grep -oE '\[CAVEMAN(:[A-Z]+)?\]' "$CLEAN" | sort -u | tr '\n' ',' | sed 's/,$//' || true)
CAVEMAN="${CAVEMAN:-none}"

# Final exit signal — Ralph prints this as the last line
EXIT_SIG=$(grep -oE 'EXIT_SIGNAL: [A-Z_][A-Za-z0-9_.-]*' "$CLEAN" | tail -1 || echo "EXIT_SIGNAL: unknown")

# Duration hint — line count of the clean log
LINES=$(wc -l < "$CLEAN")

cat <<ENTRY
================================================================================
ENTRY: ${MTIME}+08:00
SOURCE: ralph
TASK: ${TASK}
ACTOR: claude-code-ralph
BRANCH: ${BRANCH}
COMMITS: ${COMMITS}
FILES TOUCHED: ${FILES}
CAVEMAN: ${CAVEMAN}
EXIT: ${EXIT_SIG}
LOG_FILE: ${LOG}
LOG_LINES: ${LINES}
--------------------------------------------------------------------------------
Ralph attempted ${TASK}. See raw log at ${LOG} for full transcript.
Commits produced on branch ${BRANCH}: ${COMMITS}.
Final signal: ${EXIT_SIG}.
(Edit this body to add narrative context before the next entry is appended.)
================================================================================
ENTRY
