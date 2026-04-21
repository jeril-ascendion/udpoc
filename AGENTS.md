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

## AWS account blast-radius

The POC runs in AWS account 852973339602, which is a shared production
account running other Ascendion workloads and other teams' resources.
Four rules follow from this:

1. **Naming**: every POC resource must be namespaced with `udpoc-` in its
   primary identifier, so it is trivially distinguishable from other
   teams' resources by name alone.
2. **No management of shared infrastructure**: never create Terraform
   `resource` blocks for account-level resources that pre-exist or may
   be shared — IAM OIDC identity providers, Route 53 public hosted
   zones, ACM certificates for wildcard domains, IAM SAML providers,
   service-linked roles. Use `data` sources to reference them instead.
   Before proposing a create, run an `aws <service> list-<resource>s`
   call to check if it already exists.
3. **Environment approval is load-bearing**: the `deploy-prod` GitHub
   Actions environment gate on `terraform apply` is not ceremonial.
   Every apply must be reviewed by a human before it runs. Do not
   remove the gate or auto-approve it, even for "obviously safe"
   changes.
4. **Stateful resource protection**: DynamoDB tables, S3 buckets, and
   KMS keys must have `lifecycle { prevent_destroy = true }` during POC
   lifetime. Remove only when deprovisioning the POC.

This rule was discovered the hard way in T-E01-05 when Ralph's initial
bootstrap module would have modified the existing shared OIDC provider's
thumbprint list and tags. The module was refactored to use a data source
(T-E01-05-refactor) before any shared resource was touched.

## Display masking in Claude Code sessions

The Claude.ai web and mobile chat interfaces automatically redact 12-digit
strings and ARN patterns in both directions — content sent TO Claude and
content rendered FROM Claude. Effects observed:

- A 12-digit AWS account number pasted in a prompt may reach `claude -p`
  as `[REDACTED_PHILIPPINES_BANK_ACCOUNT_NUMBER_N]` and be written
  literally into files. Happened once in T-E01-05-refactor on main.tf.
- ARNs returned by shell commands display as `[REDACTED_AWS_ARN_N]` in
  terminal echo but are not actually altered in shell variables or files.
- `grep "arn:aws:iam::"` cannot verify ARN contents; the display will
  show the result with the ARN masked.

Defensive patterns:

- **For edits**: never embed literal account numbers or ARNs in prompts
  sent via `claude -p`. Use shell-variable expansion from the live
  environment: `ACCT=$(aws sts get-caller-identity --query Account
  --output text)` then reference `${ACCT}` in shell commands (sed,
  printf). Python scripts using `f-strings` against environment
  variables also work.
- **For verification**: after any file edit involving an account-scoped
  identifier, confirm with `grep -c "REDACTED"` (expect 0) and an MD5
  or character-by-character print of the target line. Visual inspection
  of a diff through the chat interface is NOT sufficient.
- **For pastes**: when showing Claude the contents of a file, prefer
  using Python's `hashlib.md5` hexdigest or a `wc -c` byte count as
  corroborating evidence alongside any visual paste.

## Pre-apply resource-existence check (for Ralph)

Before any Terraform `apply` that creates account-scoped resources
(IAM OIDC providers, Route53 zones, ACM certs, IAM SAML providers),
run the corresponding `aws <service> list-<resources>` command first.
If the resource already exists, refactor the Terraform to look it up
as a data source instead of creating it. Never run `terraform apply`
to create a resource that already exists in the account — the apply
will fail with `EntityAlreadyExists` at best, and at worst will
clobber a shared resource if the create succeeds.
