# Activity logs

Per-EPIC chronological record of what happened during POC delivery. Developers joining the project, or returning to it after time away, should be able to grep these files and reconstruct the cadence, decisions, and surprises of the work.

## Files

- `E-01.txt` — Platform Foundations
- `E-02.txt` — Mobile App Scaffold
- `E-03.txt` — Backend Services Scaffold
- ...one per EPIC E-01 through E-12
- `cross-epic.txt` — work that spans EPICs or is meta (governance, tooling, planning sessions)

Create a file when the first entry for that EPIC is written. Do not pre-create empty files.

## Entry format

Every entry is a fixed-width block delimited by `=` lines. Fields are greppable (colon-separated, at start of line). The body below the `-` separator is free-form prose.

```
================================================================================
ENTRY: 2026-04-22T14:30:00+08:00
SOURCE: claude-chat | ralph | caveman | manual
TASK: T-E01-06 | governance | discussion
ACTOR: jeril | claude-opus-4.7 | claude-code-ralph
BRANCH: feat/E-01/T-E01-06-cognito-pools | main | n/a
COMMITS: abc1234, def5678 | none
FILES TOUCHED: infra/cognito/main.tf, IMPLEMENTATION_PLAN.md | none
CAVEMAN: none | [CAVEMAN:FULL] | [CAVEMAN:ULTRA]
EXIT: TASK_DONE_T-E01-06 | TASK_BLOCKED_<reason> | session-end
LOG_FILE: .ralph/logs/iter-20260422-143000-T-E01-06.log | n/a
--------------------------------------------------------------------------------
Free-form prose. What was attempted, what happened, what was decided, what
surprised us, what future work was discovered. Link to ADRs created or updated
by reference to their file path. Keep to one or two paragraphs.
================================================================================
```

## How entries are produced

### From a Claude chat session (claude.ai)

At the end of any substantive session, Claude emits a candidate entry in the format above. The user copies the block and appends it to the correct file:

```bash
# Append to the correct EPIC file
cat >> docs/activity-logs/E-01.txt <<'BLOCK'
<paste the block>
BLOCK
```

### From a Ralph Loop session

Ralph captures its own session via `script`, producing a raw log at `.ralph/logs/iter-TIMESTAMP-TASK.log`. After the session ends:

```bash
./scripts/ralph-log-to-activity.sh .ralph/logs/iter-20260422-143000-T-E01-06.log >> docs/activity-logs/E-01.txt
```

The script strips ANSI codes, extracts metadata (branch, commits, EXIT_SIGNAL, Caveman mode if detected), and emits a well-formed entry. The narrative body will be terse; edit the file afterward to add context if the log alone is not self-explanatory.

### From a Caveman-enabled Ralph session

Same capture mechanism — the output of `script` includes Caveman's terse responses and the statusline badge. The extractor detects `[CAVEMAN:*]` tokens in the log and records the active mode in the `CAVEMAN:` field. No separate tooling required.

### From manual work (human at the terminal)

When you run commands outside Claude — for example, `terraform apply` from the local shell — write the entry by hand. The `manual` source value flags it as operator action rather than agent action.

## What to include, what to omit

Include: branch created, task attempted, commits produced, key decisions, unexpected discoveries, external factors (vendor issues, CI flakiness, corporate IT), links to ADRs opened or changed.

Omit: verbatim stack traces, long log dumps, secrets of any kind, personal commentary.

If a session produces an ADR, the entry body should name the ADR file. If a session reveals a need for a future ADR, note that too.

## Retention

Logs are committed to the repository. They are part of the deliverable and should survive any local cleanup.

File size rotation: if an EPIC log exceeds ~5 MB, rename to `E-01.part1.txt` and start `E-01.part2.txt`. E-01 is not expected to approach this limit (roughly 30-50 entries total).
