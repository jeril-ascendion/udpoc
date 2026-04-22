# ADR-0006: Operating posture for the shared production AWS account

- **Status:** Accepted
- **Date:** 2026-04-21
- **Deciders:** Jeril John Panicker (Solutions Architect)
- **Related stories/tasks:** T-E01-05 (discovery), all subsequent E-01 tasks
- **Related ADRs:** 0005

## Context and problem statement

The POC was originally understood to run in an Ascendion sandbox AWS account. During T-E01-05 (CI deploy workflow and OIDC bootstrap), manual Terraform apply revealed that the AWS account — while allocated to Ascendion — is in fact a **shared production account running other teams' workloads**. An IAM OIDC identity provider at `token.actions.githubusercontent.com` already existed (created 2026-03-13 by another team). Ralph's initial module would have managed that provider as a Terraform `resource` and modified its thumbprint list and tags, which could have affected unrelated workloads.

This discovery came after the module had been planned. The module was refactored to use a `data` source for the OIDC provider rather than a `resource` block, and the broader operating posture was rewritten around the principle that the account is shared and must be treated as production by the POC team.

The README.md at the time of writing still describes the account as "Ascendion sandbox, confirmed for POC use" — this is inconsistent with reality and is corrected in the same PR that introduces this ADR.

## Decision drivers

- Preventing damage to other teams' workloads is a non-negotiable hard constraint
- The POC cannot cause any identifiable disruption to unrelated production systems in the same account
- Ralph Loop, operating without deep environmental awareness, must be constrained by mechanical rules rather than by judgement
- The CI apply gate is the last line of defence and must remain non-ceremonial

## Considered options

1. Operate under a four-rule blast-radius discipline with namespaced resources, data-sourced shared resources, mandatory approval gates, and protected stateful resources
2. Negotiate a dedicated AWS account for the POC
3. Use LocalStack exclusively for all POC work
4. Use a personal AWS account for POC infrastructure, migrate later

## Decision

Operate under four explicit blast-radius rules, codified in AGENTS.md and enforced in PROMPT.md as a hard constraint on Ralph:

1. **Namespacing.** Every POC resource must carry `udpoc-` in its primary identifier, making ownership trivial to distinguish from other teams' resources by name alone.
2. **No management of shared infrastructure.** Never create Terraform `resource` blocks for account-level resources that may pre-exist or be shared — IAM OIDC identity providers, Route 53 public hosted zones, ACM certificates for wildcard domains, IAM SAML providers, service-linked roles. Use `data` sources to reference them. Before proposing a `resource`, run an `aws <service> list-<resource>s` call to verify non-existence.
3. **Environment approval is load-bearing.** The `deploy-prod` GitHub Actions environment gate on `terraform apply` is not ceremonial. Every apply is reviewed by a human (jeril-ascendion is the required reviewer) before it runs.
4. **Stateful resource protection.** DynamoDB tables, S3 buckets, and KMS keys carry `lifecycle { prevent_destroy = true }` during POC lifetime. This is removed only when deprovisioning the POC.

## Consequences

### Positive

- Mechanical discipline replaces environmental judgement — Ralph cannot inadvertently touch another team's resource because it is constrained by rules that apply before apply.
- Audit trail: every apply is linked to a human approval and a GitHub run.
- If a mistake is made, the `prevent_destroy` lifecycle rule blocks the worst class of accident (inadvertent table or bucket deletion).
- The `data`-source-over-`resource` pattern makes the POC's Terraform inherently safer in any account with pre-existing shared resources.

### Negative

- Deploys are slower because every apply requires manual approval, even for changes that feel obviously safe.
- The per-module IAM permissions model is narrow-start — when each module is first operated through the workflow, permissions must be added explicitly, which is friction.
- The pre-apply `aws list-*` reconnaissance step adds a few minutes to each infrastructure task.

### Neutral

- This posture is appropriate regardless of the account's classification; if the POC later moves to a dedicated sandbox, the same rules cost nothing and remain useful.
- Display masking in the Claude.ai web interface (12-digit numbers and ARN patterns are redacted) creates verification friction when the account ID or role ARN is the subject of the work. Defensive patterns are documented in AGENTS.md.

## Alternatives considered

### Dedicated AWS account for the POC

- **What it would have been:** spin up a new AWS account under Ascendion's organisation for this POC alone.
- **Why rejected:** organisational process to provision a new account exceeds the POC timeline. Revisit if the POC is promoted.

### LocalStack exclusively

- **What it would have been:** run all AWS services locally via LocalStack, demoing against the mock.
- **Why rejected:** LocalStack does not faithfully emulate Cognito, EventBridge inter-service behaviour, or IAM policy evaluation. The demo must run against real AWS to be credible to UD. LocalStack remains useful for developer-loop testing (T-E03-08 onward) but is not the POC's deployment target.

### Personal AWS account

- **What it would have been:** a developer's personal AWS account hosts the POC until production.
- **Why rejected:** violates data-handling policy for synthetic customer data that resembles real PII patterns, and creates a billing/ownership problem at handover.

## Validation

Success indicator: POC delivery completes with zero incidents affecting other teams' workloads in the account. No inadvertent `resource`-vs-`data` errors ship past Ralph's pre-apply check. Every `terraform apply` in the main deploy workflow is tied to a named human approval. Failure indicator: any of the above violated.

## References

- AGENTS.md section "AWS account blast-radius"
- PROMPT.md hard constraint on pre-apply resource-existence check
- `docs/session-notes/2026-04-21-session-handoff.md` section 2 (the T-E01-05 story that produced this posture)
