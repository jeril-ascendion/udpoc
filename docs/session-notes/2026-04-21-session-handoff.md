# UD CRU POC — Session Handoff

**Prepared:** 2026-04-21
**Next session prerequisite:** read this file first, then follow the orientation commands at the bottom.

## 1. Executive state

You are building the UnionDigital Bank Customer Record Update (Re-KYC) Proof-of-Concept as Solutions Architect for Ascendion Digital Services Philippines. The POC is a pnpm and Nx monorepo delivering Flutter mobile + Node.js/Fastify backend + React admin + Appian workflow + Terraform infrastructure.

Current EPIC: E-01 Platform Foundations. Five of fourteen E-01 tasks complete (T-E01-01 through T-E01-05). T-E01-06 is next.

Repo: https://github.com/jeril-ascendion/udpoc at commit b04bf39 on main. 24 PRs merged.

AWS account: 852973339602. IMPORTANT: this is a shared production account running other Ascendion workloads. See "AWS account blast-radius" in AGENTS.md. All POC resources must be namespaced with udpoc-, no management of shared infrastructure, environment approval on deploys is load-bearing.

Region: ap-southeast-1 (Singapore).

SSO profile: PowerUserAccess-852973339602. Always specify --profile explicitly on AWS CLI, never rely on default.

## 2. The T-E01-05 story (most important context)

T-E01-05 "CI deploy workflow + OIDC bootstrap" was the work of this session. It went through four iterations and three PRs before landing cleanly. The story matters because it produced the production-account discipline that governs everything going forward.

### 2.1 Attempts

Attempt 1 (pre-session): Ralph delivered only the workflow YAML, not the OIDC bootstrap. Plan entry was ambiguous. Branch deleted, plan rewritten in PR #20 with explicit MUST-deliver-both sub-bullets.

Attempt 2: Ralph launched from a stale chore/ branch that predated PR #20, read the old plan, delivered only the workflow again. Branch deleted. Led to PROMPT.md rule 1 in PR #21: Ralph must verify `git rev-parse --abbrev-ref HEAD == main` before starting, else exit TASK_BLOCKED_start_not_on_main.

Attempt 3: With rule 1 in place, Ralph delivered both sub-tasks cleanly. Merged as PR #22. Commit 82c81cc. The Terraform module managed the GitHub Actions OIDC provider as a resource; workflow pinned role ARN for account 852973339602 role github-oidc-deploy; apply gated via deploy-prod GitHub Actions environment.

Attempt 4 - the refactor (during this session): Manual terraform apply revealed that the OIDC provider at token.actions.githubusercontent.com ALREADY EXISTED in the account (CreateDate 2026-03-13, owned by another team). A role GitHubActionsDeployRole already trusted it. Ralph's resource block would have modified the provider's thumbprint list and added 5 project tags to a resource we do not own. Refactored to use data "aws_iam_openid_connect_provider" instead. Merged as PR #23. Commit 56bd3a1.

### 2.2 Manual steps completed after PR #23 merged

1. terraform state rm aws_iam_openid_connect_provider.github to drop the imported-then-refactored resource from state without destroying it in AWS
2. terraform init -upgrade regenerated .terraform.lock.hcl without hashicorp/tls
3. terraform apply of infra/iam-oidc-bootstrap/ created 3 resources (role github-oidc-deploy, policy github-oidc-deploy-terraform-state, attachment). Zero changes to the OIDC provider.
4. Verified terraform output -raw deploy_role_arn md5-matches the ARN hardcoded in .github/workflows/deploy.yml (md5 cb3c1c664492f55a15a39f032bc64556)
5. Configured deploy-prod GitHub Actions environment: required reviewer jeril-ascendion, deployment branches restricted to main only, "Allow administrators to bypass" unchecked
6. Smoke-tested the deploy workflow: OIDC auth succeeded, terraform plan on infra/bootstrap got expected AccessDenied on kms:DescribeKey and s3:GetBucketPolicy because the role has narrow-start permissions (state-bucket read + lock ops only). This is by design; per-module permissions get added when each module joins the workflow.

### 2.3 T-E01-05 final status — all sub-items resolved

- sub1 Terraform module: DONE via PR #22 + PR #23 refactor
- sub2 Deploy workflow: DONE, verified end-to-end via smoke test
- follow1 deploy-prod environment: DONE, configured
- follow2 ARN verification: DONE, md5 match confirmed
- follow3 dynamodb_table deprecated parameter migration: still OPEN, affects all modules, separate scope
- follow4 per-module permissions philosophy note: reminder, no action

## 3. PRs merged this session

- PR #20 (eaf39f8) chore(plan): rewrite T-E01-05 with explicit sub-tasks
- PR #21 (7a9bc57) chore(prompt): require Ralph to start from clean main
- PR #22 (82c81cc) feat(T-E01-05): CI deploy workflow + OIDC bootstrap
- PR #23 (56bd3a1) feat(T-E01-05-refactor): use OIDC provider as data source, not managed resource
- PR #24 (b04bf39) chore(T-E01-05): close follow1 and follow2, add follow4 reminder

PR #25 (incoming) is this session handoff + D-01 partial work.

## 4. Governance rules locked in

### 4.1 Repository protection

- Branch protection on main: required status check "verify (lint + typecheck + test)" (classic rule)
- Settings: squash-merge only (merge commits disabled, rebase disabled), auto-delete head branches ON
- Pre-commit hook runs pnpm exec lint-staged (eslint + prettier on staged files only)
- Commit-msg hook runs commitlint (conventional commits, header up to 100 chars)
- *.md in .prettierignore on purpose (Prettier mangles underscores in identifiers)

### 4.2 deploy-prod GitHub Actions environment

- Required reviewer: jeril-ascendion
- Deployment branches: main only
- Admin bypass: disabled
- Gates the apply job in .github/workflows/deploy.yml. Manual approval required for every apply.

### 4.3 PROMPT.md Ralph rules — now 10 hard constraints and 9 workflow steps

Workflow steps: (1) start-from-main check + pull + branch; (2) failing test; (3) minimum code to pass; (4) refactor; (5) update plan; (6) append AGENTS.md; (7) conventional commit; (8) push branch (no PR); (9) print EXIT_SIGNAL.

Hard constraints (9 total) include: TDD discipline, scope isolation, canonical identifiers from docs/canonical-package-names.md or D-03 never invented, version-pin decisions in commit body, scaffolding-verification artefact checks, and the newest addition: resource-existence check before any Terraform resource block for account-scoped resources (IAM OIDC providers, Route53 zones, ACM certs, IAM SAML providers, service-linked roles). If the resource exists, use a data source.

### 4.4 AGENTS.md — 11 conventions learned

Notable additions from this session:

- AWS account blast-radius (4 rules): namespace with udpoc-, never manage shared infra (use data sources), environment approval is load-bearing, prevent_destroy = true on stateful resources
- Display masking in Claude Code sessions: the Claude web interface redacts 12-digit strings and ARN patterns bidirectionally; defensive patterns involve shell-variable expansion from live environment, regex-on-disk rather than literal string matching, grep -c for count-based verification, md5sum for content identity
- Pre-apply resource-existence check (for Ralph): operational companion to the PROMPT.md hard constraint

## 5. Ralph calibration

Seven tasks completed, current track record:

- T-E01-01: manual Terraform, no Ralph
- T-E01-01.5: 1 clean, plan-maintenance, ideal Ralph task
- T-E01-02: 1 clean, root scaffolding
- T-E01-02.5: 2 iterations, first iteration invented names; fixed via canonical-package-names.md
- T-E01-03: 1 with force-push rework, ESLint 9 flat + lint-staged 15 via explicit targeted prompt
- T-E01-04: 2, correctly marked BLOCKED first time on OAuth scope error
- T-E01-05: 3 attempts + 1 refactor, final delivery clean after PROMPT rule 1 fix

Calibration verdict: Ralph is reliable for IAM/Terraform tasks when (a) launched from clean main, (b) given explicit MUST language in plan entries, (c) the task stays within one module boundary. Ralph is NOT reliable for tasks that require knowledge of the surrounding environment (e.g., "this resource might already exist in the account"). The resource-existence PROMPT.md constraint now catches that class of error.

Batch readiness: T-E01-06 Cognito is a good next solo Ralph run. If clean, T-E01-07 + T-E01-08 (networking/domains) can be tried as a 2-iteration batch.

## 6. Operational knowledge for the next session

### 6.1 Environment

- Dev machine: ASCGPHLAP2536 (Windows 11 corporate laptop) running WSL2 Ubuntu 24.04
- Repo path: ~/projects/udpoc (inside WSL)
- Toolchain: Node 20.14.0 (via nvm), pnpm 9.12.0 (via corepack), Nx 19.8.14, Terraform 1.9.x (workflow pins 1.9.8), AWS CLI v2.34.6 with SSO, Flutter 3.24.3 + Dart 3.5.3, Claude Code 2.1.116

### 6.2 Running Ralph

Shell commands:

    cd ~/projects/udpoc
    git checkout main && git pull
    git status
    mkdir -p .ralph/logs
    LOG=".ralph/logs/iter-$(date +%Y%m%d-%H%M%S)-T-E01-NN.log"
    script -q -c "claude --dangerously-skip-permissions" "$LOG"

At the interactive prompt:

    Follow the instructions in PROMPT.md exactly. PROMPT.md is in the repo root. Read it first, then execute it against the current state of IMPLEMENTATION_PLAN.md.

After EXIT_SIGNAL: press Ctrl+D to cleanly exit. Closing the terminal without exit leaves a zombie Claude process.

### 6.3 Known traps (encountered this session)

1. Stale branch launches - fixed by PROMPT rule 1
2. Duplicate PRs from clicking both "Compare and pull request" banner and "New pull request" button (PRs 17 and 18 from earlier T-E01-04 work)
3. Shared OIDC provider with existing role, fixed by resource-existence check PROMPT constraint + AGENTS blast-radius rules
4. Display masking in Claude web interface, documented in AGENTS.md; use shell-variable expansion for AWS identifiers, never embed literals in claude -p prompts
5. Terraform CLI caches providers stale, rm -rf .terraform .terraform.lock.hcl and re-init with -upgrade when removing provider requirements
6. terraform output -raw omits trailing newline, do not use plain diff to compare outputs; use shell string equality or md5 of stripped content
7. dynamodb_table backend parameter deprecated, captured as T-E01-05.follow3, not yet migrated

## 7. Unfinished deliverables — documents

### 7.1 D-01 v1.1 Functional Specifications (Revised)

Status: about 15% drafted.

- 6 of ~20 planned Mermaid diagrams completed as .mmd source files in docs/deliverables-work-in-progress/d01/diagrams/
- No DOCX built
- Structural plan captured in docs/deliverables-work-in-progress/d01/README.md

Source document required: Product Reference Form (PRF) - Customer Record Update Latest 2026.pdf (v3.0 dated 2025-08-06, updated to v5.0 2026-03-06). Not in repo. Next session must ask user to re-upload.

Planned structure: 24 sections, 80-120 pages DOCX, professional engineering global standard. See docs/deliverables-work-in-progress/d01/README.md for the full section list.

Realistic time estimate: 60-90 minutes, consuming most of a session's context. Should be its own session.

### 7.2 D-02 v1.0 Technical Solution Design

Status: 0%, planned but not started.

Planned structure: reference architecture, component inventory, per-service design, data model (physical), event schemas, state machines in XState, API contracts (OpenAPI + Zod), IaC module tree, security and compliance, observability, testing strategy, deployment topology, ADRs.

Prerequisites: D-01 v1.1 finished + the PRF + D-03 Development Guide (in repo).

Realistic time estimate: 60-100 minutes. Separate session from D-01.

## 8. Priming the next Claude session

When you open the next chat, paste the priming message that lives in docs/session-notes/2026-04-21-priming-message.txt (also part of this PR). It instructs the new Claude to read this handoff and five other files in order before taking any action.

## 9. What is next after T-E01-05

### 9.1 Priority 1: T-E01-06 Cognito user pools

Good Ralph candidate. Homogeneous with T-E01-05's IAM work. Single Terraform module. Should fit one Ralph iteration.

If clean, try T-E01-07 + T-E01-08 (API Gateway custom domain + CloudFront) as a 2-iteration batch.

### 9.2 Priority 2: T-E01-05.follow3 dynamodb_table backend migration

Short chore: change both Terraform backend configs (infra/bootstrap/backend.tf and infra/iam-oidc-bootstrap/backend.tf) from dynamodb_table = "udpoc-tflocks" to use_lockfile = true. Then re-run terraform init -migrate-state on both modules. Can be batched with another task.

### 9.3 Priority 3: D-01 v1.1 functional specifications

When user brings the PRF to a new session. Own the session.

### 9.4 Priority 4: D-02 v1.0 technical design

After D-01 is done. Own its own session.

### 9.5 Remaining E-01 tasks (after T-E01-06)

T-E01-07 API Gateway custom domain, T-E01-08 CloudFront, T-E01-09 Shared KMS, T-E01-10 EventBridge, T-E01-11 DynamoDB tables, T-E01-12 Observability baseline, T-E01-13 Cost guardrails, T-E01-14 Dev bootstrap script.

E-02 Mobile App Scaffold blocked on T-E01-06.
E-03 Backend Services Scaffold blocked on T-E01-09/10/11.

## 10. One last thing

This session's single biggest lesson: the POC runs in a shared production account, not a sandbox. Every subsequent task treats that as a hard constraint. When Ralph writes Terraform, when you manually apply anything, when you merge a PR, all of it operates under the blast-radius rules. The deploy-prod manual approval gate is the last line of defense. Do not make it ceremonial.

End of handoff.
