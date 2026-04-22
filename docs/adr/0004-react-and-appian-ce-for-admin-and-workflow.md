# ADR-0004: React plus Appian Community Edition for admin and workflow

- **Status:** Accepted
- **Date:** 2026-04-20
- **Deciders:** Jeril John Panicker (Solutions Architect)
- **Related stories/tasks:** E-08, E-12, stories S-05/S-06/S-08/S-09/S-13/S-14
- **Related ADRs:** 0001, 0003

## Context and problem statement

The POC requires two distinct admin/workflow surfaces. First, a Maker-Checker workflow for bank operations staff to review, approve, or reject customer re-KYC submissions — this is a canonical BPM workflow with queues, claim semantics, cycle limits, and escalation. Second, an administrative portal for customer search, reconciliation reporting with PII masking and CSV export, and an operational dashboard — this is a conventional CRUD + reporting web application.

UnionDigital's production estate uses Appian as the enterprise BPM platform. Aligning the POC with that choice reduces the integration risk if the POC is promoted to production. Appian Community Edition (CE) is free for development and allows the workflow design to be exported as XML and committed to the repository.

## Decision drivers

- Alignment with UD's existing Appian footprint for production fit
- Separation of workflow semantics (Appian) from admin UI concerns (React)
- Ability to export Appian configurations as XML for source control
- Six-week POC timeline — must not build workflow primitives from scratch
- PII-masking requirements in reporting (S-13) that are easier in custom React than in Appian templates

## Considered options

1. React (Vite) for admin, Appian CE for workflow
2. Fully custom React for both admin and workflow (build queues, claim semantics, state machines ourselves)
3. AWS Step Functions for workflow + React for admin
4. Camunda (self-hosted) + React for admin
5. All-Appian (use Appian for both workflow and admin portal)

## Decision

Build the administrative portal (customer search, reconciliation, operational dashboard) as a React SPA using Vite, deployed to S3 and served via CloudFront. Build the Maker-Checker workflow (queues, claim, forward, approve, reject, escalate) in Appian Community Edition. The two communicate via the backend service API using a service-account JWT for Appian-to-API calls. Appian CE's application export is committed as XML to `apps/appian/` for source control.

## Consequences

### Positive

- Appian provides mature workflow primitives (queues, claim, SLA timers, escalation) that would take multiple weeks to build and harden in custom code.
- Production fit: UD's ops teams already operate Appian; the POC demo lives in their familiar tooling.
- The admin React SPA is independent of workflow and can be built/iterated fast.
- PII masking in the reconciliation report (S-13 AC02) is implemented in custom React where the masking logic is straightforward.

### Negative

- Two deploy pipelines and two UX paradigms to maintain and demo.
- Appian CE has licensing restrictions that preclude production use — the CE-to-licensed-tier transition is a post-POC concern but must be flagged.
- Appian expression language (SAIL) is a skill the team has but not in great depth; complex report logic in Appian is slower than in React.
- Integration between Appian and our backend API requires a service account and a static-lifetime JWT, which is a different auth pattern than the Cognito user-identity JWTs used elsewhere.

### Neutral

- Appian CE export/import is a manual step gated by T-E08-15; it cannot run inside Ralph Loop because the Appian environment is provisioned externally.
- Several E-08 tasks are marked `[blocked — Appian CE]` in the plan pending environment provisioning.

## Alternatives considered

### Fully custom React workflow

- **What it would have been:** build Maker-Checker queues, claim semantics, cycle counting, and escalation ourselves as React + backend code.
- **Why rejected:** reinvents a large and well-solved problem; would consume most of the POC timeline. Also loses production fit with UD's Appian estate.

### AWS Step Functions for workflow

- **What it would have been:** case state machine as a Step Functions state machine, Makers/Checkers acting via custom React screens that call `SendTaskSuccess` / `SendTaskFailure`.
- **Why rejected:** Step Functions is excellent for backend workflow but poor for human-in-the-loop workflows that need queues, claim, and cycle-limit logic. Building a queueing UI on top of SF tasks is effectively building Appian from primitives.

### Camunda (self-hosted)

- **What it would have been:** Camunda BPM as the workflow engine, React admin consuming Camunda's REST API.
- **Why rejected:** Camunda is a credible alternative in general but does not align with UD's existing Appian footprint. Introducing a second BPM stack purely for a POC is an anti-pattern.

### All-Appian

- **What it would have been:** Appian for both workflow and admin portal (customer search, reconciliation, dashboard).
- **Why rejected:** Appian's reporting and data-manipulation tooling is clumsy for the specific PII-masking and CSV-export requirements of S-13. Custom React gives us surgical control over mask behaviour and export formatting.

## Validation

Success indicator: a case submitted on mobile appears in the Appian Maker queue within 30 seconds (AC from S-09 AC01); a Maker can claim, review, forward to Checker, and the Checker can approve, triggering DataHub sync and notifications — all driven end-to-end through the Appian workflow. Failure indicator: Appian CE provisioning blocks the demo.

## References

- D-01 section 7 (workflow and state machine specification)
- D-03 section 8 (Appian application structure)
- Master Plan Section 8 (technology decisions)
