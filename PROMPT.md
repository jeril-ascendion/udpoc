# PROMPT.md, Ralph Loop entry prompt

You are working on the UnionDigital Customer Record Update (Re-KYC) POC.
Context is fresh. Begin by reading these files, in this order:
  1. CLAUDE.md or CLAUDE.original.md (repo conventions, stack, non-negotiables)
  2. IMPLEMENTATION_PLAN.md (your task backlog)
  3. AGENTS.md (conventions learned by previous iterations)

Pick ONE unchecked and unblocked task from IMPLEMENTATION_PLAN.md, preferring the topmost task. The chosen task has an id like T-Exx-nn.

For that task:
  1. Before any other action, run git status. If you are on main, create and switch to a branch named feat/E-nn/T-Exx-nn-short-slug where nn matches the task id. If you are already on a feature branch from a previous partial attempt at the same task, continue on it. Never work directly on main.
  2. Write the failing test(s) named exactly as specified in the task Acceptance Criteria. Run them. They must fail for the right reason (not a syntax error or missing import).
  3. Write the minimum production code that makes the tests pass. Run them. They must pass.
  4. Refactor if needed. Tests must stay green at every step.
  5. Update IMPLEMENTATION_PLAN.md to mark the task done. If you discovered new sub-tasks, add them as unchecked items under the same EPIC.
  6. If you discovered a convention worth teaching future iterations, append a single two-line entry to AGENTS.md with date, scope, and the convention. Do not prune old entries.
  7. Stage and commit with a Conventional Commit message scoped to the task id. Example: feat(T-E04-02): BR-001 ID-expiry rule.
  8. Push the branch to origin. Do not merge, do not open a PR, do not touch main.
  9. Print EXIT_SIGNAL: TASK_DONE_<task-id> as the last line of your output.

Hard constraints:
  - No production code without a failing test first. Ever.
  - Never edit more than one task worth of files.
  - Never commit failing tests.
  - Never push to main directly. Always use feat/E-nn/T-Exx-nn-slug branches.
  - If the task is blocked by external dependency you cannot resolve, mark it blocked in IMPLEMENTATION_PLAN.md with the reason, commit the plan change on the current branch (creating one if necessary), push, and exit with EXIT_SIGNAL: TASK_BLOCKED_<task-id>.
  - If the task is scaffolding with no ACs (for example T-E01-xx tasks per D-03 section 10.1), the TDD step is replaced by a verification step. The verification must (a) run the tool expected to exercise the scaffolding (for example pnpm install, terraform validate, nx graph, tsc --noEmit), (b) confirm exit code zero, AND (c) confirm that the expected artefacts actually exist and have nontrivial content. For pnpm workspace scaffolding, "nontrivial" means pnpm-lock.yaml exists AND every workspace package declared in pnpm-workspace.yaml is resolvable (pnpm ls --recursive lists them). Exit-zero on an empty workspace is NOT sufficient.
  - Canonical identifiers come from these sources, in order of precedence: (1) docs/canonical-package-names.md for workspace directory and package names, (2) D-03 (docs/UD_CRU_POC_D03_Development_Guide_v1.0.docx) for all other identifiers, (3) D-01 or D-02 where D-03 explicitly delegates. Do not invent names. If D-03 lists 9 apps and 6 libs with specific names, create them with those exact names, no renaming, no substitutions, no omissions, no additions. If the canonical source is silent on a name you need, stop and mark the task blocked rather than guessing.
  - Version-pin decisions must be explicit. When a task introduces or updates a tool, library, or config generator, the commit message body must list each chosen version and a one-line rationale. Example: "ESLint 9.11 (flat config, required for Node 20+), Prettier 3.3 (stable), Husky 9.1 (simplified hook syntax), commitlint 19 with @commitlint/config-conventional". Do not bury version choices in lockfiles alone; the commit message is the audit trail.
