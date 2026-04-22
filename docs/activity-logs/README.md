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

### Recommended: from a Ralph session via the wrapper (automatic)

The `scripts/run-ralph.sh` wrapper launches Claude Code under session capture, runs the extractor on the captured log when the session ends, auto-routes the entry to the correct EPIC file based on the task id in EXIT_SIGNAL, and prompts before appending.

```bash
./scripts/run-ralph.sh T-E01-06
```

The argument is only used in the log filename for later grep-ability. The actual task Ralph picks up comes from IMPLEMENTATION_PLAN.md, not from this hint. After the session ends, the script:

1. Extracts a structured entry from the raw log
2. Parses the task id from EXIT_SIGNAL to determine the target EPIC file
3. Previews the entry, asks for confirmation, appends on approval
4. Retains the raw log at `.ralph/logs/iter-TIMESTAMP-HINT.log` regardless

Caveman-enabled sessions work identically — Caveman runs inside Claude Code and does not change the capture mechanism. The extractor picks up the `[CAVEMAN:FULL]` / `[CAVEMAN:ULTRA]` statusline badges and records the active mode in the `CAVEMAN:` field.

### Manual: from a raw log file (when the wrapper is not appropriate)

If a session was captured outside the wrapper, or an existing raw log needs to be retroactively extracted:

```bash
./scripts/ralph-log-to-activity.sh .ralph/logs/iter-20260422-143000-T-E01-06.log >> docs/activity-logs/E-01.txt
```

The extractor always writes to stdout; the user is responsible for the correct redirect target.

### From a Claude chat session (claude.ai)

No automatic capture exists for the web chat interface. At the end of any substantive session, the assistant emits a candidate entry in the format above; the user copies the block and appends it to the correct file:

```bash
cat >> docs/activity-logs/cross-epic.txt <<'BLOCK'
<paste the block>
BLOCK
```

### From manual work (human at the terminal)

When you run commands outside Claude — for example, `terraform apply` from the local shell — write the entry by hand. The `manual` source value flags it as operator action rather than agent action.

## What to include, what to omit

Include: branch created, task attempted, commits produced, key decisions, unexpected discoveries, external factors (vendor issues, CI flakiness, corporate IT), links to ADRs opened or changed.

Omit: verbatim stack traces, long log dumps, secrets of any kind, personal commentary.

If a session produces an ADR, the entry body should name the ADR file. If a session reveals a need for a future ADR, note that too.

## Retention

Logs (entries) are committed to the repository. They are part of the deliverable and should survive any local cleanup.

Raw session captures under `.ralph/logs/` are NOT committed (see `.gitignore`); they are per-developer and may contain transient context that should not live in the shared repository.

File size rotation: if an EPIC log exceeds ~5 MB, rename to `E-01.part1.txt` and start `E-01.part2.txt`. No EPIC is expected to approach this limit (roughly 30-50 entries total per EPIC).

## Related tooling

- `scripts/run-ralph.sh` — the wrapper described above
- `scripts/ralph-log-to-activity.sh` — the extractor (used standalone or by the wrapper)
- `scripts/test-extractor.sh` — reproducible sanity test for the extractor; run after any change to extractor logic
