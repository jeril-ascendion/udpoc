# ADR-0008: Terraform state backend on S3 with DynamoDB locking

- **Status:** Accepted
- **Date:** 2026-04-20
- **Deciders:** Jeril John Panicker (Solutions Architect)
- **Related stories/tasks:** T-E01-01, T-E01-05.follow3
- **Related ADRs:** 0005, 0006

## Context and problem statement

Terraform requires a state backend to persist the mapping between declared resources and provisioned AWS entities. The backend must support concurrent access with locking so that a human operator and the CI deploy role cannot apply simultaneously, must be auditable, and must live in the same AWS account as the resources it tracks. State files may contain sensitive data (ARN references, policy documents, occasionally inline secrets that cannot be avoided), so encryption at rest is mandatory.

Terraform 1.10 has deprecated the `dynamodb_table` backend parameter in favour of `use_lockfile = true`, which uses S3 conditional writes for locking. The POC was bootstrapped (T-E01-01) with the older pattern and must plan migration.

## Decision drivers

- Native AWS backend (to avoid a third-party dependency like Terraform Cloud for a POC)
- Encryption at rest and versioning for state files
- Locking that works for both human operators and the CI deploy role (IAM-friendly)
- A clear migration path forward as Terraform evolves
- State-bucket name uniqueness (S3 bucket names are globally unique)

## Considered options

1. S3 state backend with DynamoDB table for locking (current state)
2. S3 state backend with `use_lockfile = true` (newer pattern, migration target)
3. Terraform Cloud as the state backend
4. HashiCorp Consul as the state backend
5. Local state files (no remote backend)

## Decision

Continue with the **S3 + DynamoDB** pattern for now (inherited from T-E01-01), with state bucket `udpoc-tfstate-cda8bf` (the suffix randomises the globally-unique bucket name) and lock table `udpoc-tflocks`, both in ap-southeast-1 with KMS encryption and bucket versioning enabled. Plan migration to `use_lockfile = true` across all modules as a scheduled chore (T-E01-05.follow3) — the migration retires the DynamoDB lock table and simplifies backend operations.

All modules share the single state bucket with distinct state keys: `<module-path>/terraform.tfstate`. The `github-oidc-deploy` IAM role used by CI has narrow read permissions on the state bucket and read/write permissions on the lock table, scoped to the exact resource ARNs.

## Consequences

### Positive

- State is durable (S3 versioning), encrypted (KMS), and auditable (CloudTrail records every state access).
- Lock table prevents concurrent apply races between human operators and CI.
- Narrow IAM permissions on the CI role keep blast radius small — the role can read state and acquire locks but cannot, by itself, modify unrelated resources.
- All POC-managed infrastructure has a single conceptual home (`udpoc-tfstate-cda8bf`).

### Negative

- Two resources to operate instead of one (bucket + lock table), until the lockfile migration.
- The DynamoDB table is an account-level resource that must not be accidentally deleted — protected by `lifecycle { prevent_destroy = true }`.
- State-file corruption recovery, while rare, requires manual S3 versioning restore plus lock-table cleanup.

### Neutral

- S3 bucket naming is globally unique — the `cda8bf` suffix on `udpoc-tfstate-cda8bf` was generated during T-E01-01 bootstrap and is committed into every module's backend config.
- The CI deploy role's permissions are narrow-start: initial permissions cover only state-bucket read and lock-table ops. Per-module permissions (e.g., `cognito-idp:*` for the Cognito module) are added when that module is first operated through the workflow.

## Alternatives considered

### Pure S3 with `use_lockfile = true` from day one

- **What it would have been:** skip the DynamoDB lock table, use S3 conditional writes for locking.
- **Why rejected at day one:** at the time of T-E01-01 bootstrap, the lockfile feature was too recent to be the default recommendation. **This is the planned migration target** — see T-E01-05.follow3.

### Terraform Cloud

- **What it would have been:** state hosted in Terraform Cloud (free tier), runs execution triggered via their pipeline.
- **Why rejected:** introduces a third-party service dependency for a POC whose success requires demonstrating that the entire stack can live inside AWS. Also introduces an external auth surface that is awkward to integrate with UD's SSO story.

### HashiCorp Consul backend

- **Why rejected:** requires operating a Consul cluster, which is massively disproportionate for POC needs.

### Local state files

- **Why rejected:** no team collaboration, no locking, no durability. Unacceptable even for POC work.

## Validation

Success indicator: concurrent `terraform plan` operations (one from CI, one from a human) do not race, do not corrupt state, and the second operation receives a clear lock-contention error. Migration success indicator: after T-E01-05.follow3 lands, `terraform init -migrate-state` on each module completes cleanly and subsequent applies work without the DynamoDB lock table. Failure indicator: state drift, lock-contention corruption, or inability to recover state from an accidental deletion.

## References

- `infra/bootstrap/` (state backend itself)
- `infra/iam-oidc-bootstrap/` (CI role permissions on state bucket and lock table)
- Terraform 1.10 changelog on `use_lockfile`
- AWS KMS documentation on bucket-default encryption
