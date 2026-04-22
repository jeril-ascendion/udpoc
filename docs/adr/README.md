# Architectural Decision Records

This directory contains the Architectural Decision Records (ADRs) for the UnionDigital CRU Re-KYC POC. Each ADR documents a single architecturally significant decision, the context in which it was made, the alternatives considered, and the consequences that follow.

## Format

We use the [MADR](https://adr.github.io/madr/) (Markdown Architectural Decision Records) format. Each record includes:

- **Status**: `Proposed` | `Accepted` | `Deprecated` | `Superseded by ADR-XXXX`
- **Context**: the forces at play — technical, organisational, regulatory
- **Decision**: what we chose
- **Consequences**: positive, negative, and neutral downstream effects
- **Alternatives considered**: the options we evaluated and why we did not pick them

The blank template is in [`template.md`](./template.md). Copy it to `NNNN-short-slug.md` where `NNNN` is the next unused four-digit sequence number.

## When to write an ADR

An ADR is warranted when a decision meets **all** of the following:

1. It has a material architectural consequence — it shapes how the system is built, deployed, or operated.
2. It has real alternatives — a choice between plausible options, not a forced move.
3. Reversing it would be costly — in engineering effort, vendor lock-in, or retraining.

Conventions and gotchas that do not meet this bar (for example, "Prettier is disabled on `*.md` because it mangles underscores in identifiers") belong in [`AGENTS.md`](../../AGENTS.md), not here. Process rules for Ralph Loop belong in [`PROMPT.md`](../../PROMPT.md).

## Lifecycle

- A new ADR starts as `Proposed` when opened in a pull request.
- It becomes `Accepted` when the PR is merged.
- If a later decision replaces it, the newer ADR marks it `Superseded by ADR-XXXX`, and the older ADR's status line is updated in the same PR.
- ADRs are not deleted. Superseded ADRs remain as historical record.

## Relationship to other documents

| Document | Contains |
|----------|----------|
| D-01 Functional Specs | what the system must do (requirements) |
| D-02 Technical Design | how the system is built (the design itself) |
| D-03 Development Guide | conventions and tooling for building it |
| **ADRs (this directory)** | **why specific design choices were made, and what was rejected** |
| AGENTS.md | conventions and gotchas discovered in practice |
| PROMPT.md | rules that govern Ralph Loop agent behaviour |
| STATUS.md | current state of delivery |
| IMPLEMENTATION_PLAN.md | task backlog |

## Current ADRs

### Tier 1 — Foundational (Accepted)

| ID | Title | Date |
|----|-------|------|
| [0001](./0001-monorepo-with-pnpm-and-nx.md) | Monorepo with pnpm and Nx | 2026-04-20 |
| [0002](./0002-flutter-for-mobile.md) | Flutter for the mobile application | 2026-04-20 |
| [0003](./0003-nodejs-fastify-for-backend.md) | Node.js and Fastify for backend services | 2026-04-20 |
| [0004](./0004-react-and-appian-ce-for-admin-and-workflow.md) | React plus Appian Community Edition for admin and workflow | 2026-04-20 |
| [0005](./0005-terraform-for-iac.md) | Terraform for infrastructure as code | 2026-04-20 |
| [0006](./0006-shared-production-aws-account-posture.md) | Operating posture for the shared production AWS account | 2026-04-21 |
| [0007](./0007-region-ap-southeast-1.md) | ap-southeast-1 as the primary AWS region | 2026-04-20 |
| [0008](./0008-terraform-state-backend.md) | Terraform state backend on S3 with DynamoDB locking | 2026-04-20 |

### Tier 2 — Governance and delivery process (planned)

To be added: Ralph Loop TDD discipline, canonical-package-names as source of truth, deploy-prod manual approval gate, OIDC provider as data source, narrow-start IAM permissions, squash-merge with branch protection.

### Tier 3 — Domain and architecture (planned)

To be added: POC scope of 14 of 35 stories, XState case state machine, EventBridge for event-driven composition, Cognito pool topology, Liveness provider port pattern, Maker-Checker with Appian.

## Index maintenance

When adding an ADR, update the table above. When superseding an ADR, update the status in the superseded file and in the table entry.
