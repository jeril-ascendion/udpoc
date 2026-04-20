# AGENTS.md, conventions learned by agentic iterations

This file is appended to by Ralph Loop iterations. Each entry should be one or two lines documenting a non-obvious convention, gotcha, or pattern that future iterations should know. Keep entries short. Retire stale entries when they stop being relevant.

## Format

- [YYYY-MM-DD] [scope] convention or observation

## Current entries

- [2026-04-20] [plan] A task marked "in flight" in IMPLEMENTATION_PLAN.md may already be merged on main.
  Always cross-check `git log --oneline` for the task id before starting; if merged, close the plan entry with the commit SHA instead of redoing the work.
- [2026-04-20] [workspace] Workspace packages live at `apps/*` and `libs/@udpoc/*` (scoped prefix). pnpm-workspace.yaml globs must match this layout; do not flatten libs.
- [2026-04-20] [workspace] The 9 apps are `mobile, admin, eligibility, customer-data, document, liveness, workflow, notification, datahub-sync` (no `-service` suffix). E-11 Scheduler is not its own app: its daily-cron Lambda lives inside `apps/eligibility` per T-E04-06. `apps/mobile` holds a stub `package.json` alongside its Flutter sources so pnpm can orchestrate tooling uniformly.
