# ADR-0005: Terraform for infrastructure as code

- **Status:** Accepted
- **Date:** 2026-04-20
- **Deciders:** Jeril John Panicker (Solutions Architect)
- **Related stories/tasks:** T-E01-01, T-E01-05, all E-01 platform tasks
- **Related ADRs:** 0006, 0008

## Context and problem statement

Every piece of AWS infrastructure for the POC — Cognito user pools, API Gateway, CloudFront, KMS keys, EventBridge buses, DynamoDB tables, IAM roles, CloudWatch dashboards — must be provisioned as code. Manual console provisioning is not acceptable even for a POC because (a) the AWS account is a shared production account with other teams' workloads (see ADR-0006), (b) the POC may be promoted, in which case the infrastructure definitions are the production-deployment artefact, and (c) the Ralph Loop TDD agent cadence requires reproducible, scriptable infrastructure changes.

The team has deep Terraform experience across prior FSI engagements. UD's production estate is also largely Terraform-managed.

## Decision drivers

- Team skill concentration in Terraform with HCL
- Alignment with UD's existing IaC tooling for post-POC continuity
- Ability to plan-before-apply with human approval in the CI pipeline
- Module reusability across bootstrap, service, and shared-resource concerns
- State backend that supports concurrent access and locking from both human operators and the CI deploy role

## Considered options

1. Terraform 1.9.x with HashiCorp-maintained AWS provider
2. AWS CDK (TypeScript)
3. Pulumi (TypeScript)
4. AWS CloudFormation with SAM for serverless resources
5. Terragrunt over Terraform

## Decision

Use Terraform 1.9.x (workflow-pinned to 1.9.8) with the HashiCorp AWS provider. Organise infrastructure into a per-concern module tree under `infra/` — `bootstrap` for state backend, `iam-oidc-bootstrap` for the CI deploy role, `cognito`, `api-gateway`, `cloudfront`, `kms-keys`, `event-bus`, `dynamodb`, and so on. Each module has its own state file keyed under the shared state bucket. Terraform is never applied automatically — every apply goes through the GitHub Actions `deploy-prod` environment which requires manual human approval (ADR pending in Tier 2).

## Consequences

### Positive

- One language, one state mechanism across all AWS resources.
- Terraform Registry provides mature modules for patterns we do not want to hand-write (VPCs, KMS aliasing).
- `terraform plan` produces a human-readable, reviewable artefact before any change is applied — critical in a shared production account (ADR-0006).
- Ralph Loop can produce Terraform changes and push branches; humans approve the apply gate.

### Negative

- HCL is not a general-purpose language; complex logic (especially dynamic module composition) is awkward.
- State management is a standing operational concern — state lock contention, state drift from manual console changes, state-file corruption in rare cases.
- Provider version management is its own discipline; the `.terraform.lock.hcl` file must be committed and reviewed like any other source artefact.

### Neutral

- The `dynamodb_table` backend parameter is deprecated in Terraform 1.10+. We use it today (inherited from T-E01-01) and will migrate to `use_lockfile = true` in a scheduled chore (T-E01-05.follow3).
- Offline scaffolding verification requires `terraform init -backend=false`; a plain `init` tries to reach the S3 backend and fails without credentials.

## Alternatives considered

### AWS CDK (TypeScript)

- **What it would have been:** infrastructure as TypeScript, using CDK constructs, synthesising to CloudFormation templates.
- **Why rejected:** CDK is excellent for teams whose primary language is TypeScript and who accept CloudFormation as the deploy substrate. However, CloudFormation error messages and stack rollback semantics are markedly worse than Terraform's plan-apply cycle in a shared production account where we must be confident about exactly what will change. UD's existing IaC is Terraform, so CDK introduces a second IaC paradigm to the estate.

### Pulumi

- **What it would have been:** infrastructure as TypeScript or Python with Pulumi's own state backend or S3 backend.
- **Why rejected:** strong tool, but the team skill concentration is in Terraform, and Pulumi does not align with UD's production IaC choice. Team training cost outweighs benefit for a POC.

### CloudFormation with SAM

- **What it would have been:** CloudFormation templates for all resources, SAM for Lambda packaging.
- **Why rejected:** CloudFormation's user experience for the plan/review/apply cycle is notably worse than Terraform's. Stack rollback behaviour is a risk in shared account operations.

### Terragrunt over Terraform

- **What it would have been:** Terragrunt as an orchestration layer above Terraform to manage per-environment configuration and DRY module composition.
- **Why rejected:** Terragrunt shines in multi-environment, multi-account setups (dev/stage/prod across accounts). The POC runs in a single account, one environment, so the abstraction cost of Terragrunt is not yet justified. Revisit if the POC is promoted and multi-account becomes real.

## Validation

Success indicator: every piece of AWS infrastructure required by the POC can be reproduced in a clean account by running the workflow modules in dependency order, with human approval at each apply. Failure indicator: drift between deployed state and repository state caused by manual console changes.

## References

- `infra/bootstrap/`, `infra/iam-oidc-bootstrap/`
- `.github/workflows/deploy.yml`
- AGENTS.md "AWS account blast-radius"
- HashiCorp Terraform 1.9 changelog
