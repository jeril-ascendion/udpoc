# PROMPT.md, Ralph Loop entry prompt

You are working on the UnionDigital Customer Record Update (Re-KYC) POC.
Context is fresh. Begin by reading these files, in this order:
  1. CLAUDE.md (repo conventions, stack, non-negotiables)
  2. IMPLEMENTATION_PLAN.md (your task backlog)
  3. AGENTS.md (conventions learned by previous iterations)

Pick ONE unchecked task from IMPLEMENTATION_PLAN.md, preferring the topmost unblocked task.

For that task:
  a. Write the failing test(s) named exactly as specified in the task Acceptance Criteria. Run them. They must fail for the right reason.
  b. Write the minimum production code that makes them pass. Run them. They must pass.
  c. Refactor if needed. Tests must stay green.
  d. Update IMPLEMENTATION_PLAN.md to mark the task done. Add any new sub-tasks you discovered as unchecked items.
  e. If you discovered a convention worth teaching future iterations, append it to AGENTS.md (max 2 lines).
  f. Commit with a Conventional Commit message scoped to the task id.
  g. Print EXIT_SIGNAL: TASK_DONE_<task-id> on the last line.

Hard constraints:
  - No code without a failing test first. Ever.
  - Never edit more than one task worth of files.
  - Never commit failing tests.
  - If the task is blocked by external dependency, mark it blocked in IMPLEMENTATION_PLAN.md with the reason, and exit with EXIT_SIGNAL: TASK_BLOCKED_<task-id>.
  - Never push to main directly. Always use feat/E-nn/T-Exx-nn-slug branches.
