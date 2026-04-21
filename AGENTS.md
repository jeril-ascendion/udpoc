# AGENTS.md, conventions learned by agentic iterations

This file is appended to by Ralph Loop iterations. Each entry should be one or two lines documenting a non-obvious convention, gotcha, or pattern that future iterations should know. Keep entries short. Retire stale entries when they stop being relevant.

## Format

- [YYYY-MM-DD] [scope] convention or observation

## Current entries

- [2026-04-20] [plan] A task marked "in flight" in IMPLEMENTATION_PLAN.md may already be merged on main.
  Always cross-check `git log --oneline` for the task id before starting; if merged, close the plan entry with the commit SHA instead of redoing the work.
- [2026-04-20] [workspace] Workspace packages live at `apps/*` and `libs/@udpoc/*` (scoped prefix). pnpm-workspace.yaml globs must match this layout; do not flatten libs.
- [2026-04-20] [scaffolding] Scaffolding tasks must be verified with `pnpm ls --recursive` (not just `pnpm install`): exit-zero on an empty workspace is insufficient. Confirm every canonical package in docs/canonical-package-names.md appears in the listing.
- [2026-04-20] [prettier] `*.md` is in `.prettierignore` on purpose: Prettier re-parses underscores as emphasis and mangles identifiers like `EXIT_SIGNAL` in prose. Do not remove — format markdown by hand.
- [2026-04-20] [ci] Always `pnpm install --frozen-lockfile` in CI and when reproducing locally: a plain `pnpm install` will silently upgrade pinned deps (observed ESLint drift 8.57.1 → 9.39.4) and break lint.
- [2026-04-20] [git-push] Pushing anything under `.github/workflows/` requires the git credential/OAuth App to carry the `workflow` scope; a plain `repo` scope is refused with "refusing to allow an OAuth App to create or update workflow". Fix once per machine with `gh auth refresh -h github.com -s workflow`.
- [2026-04-21] [terraform] For offline scaffolding verification (no AWS creds), use `terraform init -backend=false` — plain `terraform init` tries to contact the S3 backend and hangs/fails. `terraform validate` still runs with `-backend=false`.
