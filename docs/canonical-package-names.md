# Canonical package names — per D-03 section 6.2

These are the exact names Ralph and all engineers must use. No renaming, no abbreviating, no omitting, no adding.

## apps/

1. apps/mobile                     — Flutter mobile app (D-03 §10.2)
2. apps/admin-react                — React admin screens S-A-05/06/07 (§10.12)
3. apps/case-service               — Case + workflow Node service (§10.3, canary in T-E03-07)
4. apps/document-service           — Presign + scan + retrieval (§10.6)
5. apps/liveness-service           — Provider-abstracted liveness (§10.7)
6. apps/eligibility-service        — Nightly eligibility + risk-flag handler (§10.4)
7. apps/notification-service       — SMS/email/push fan-out (§10.9)
8. apps/datahub-sync               — CaseApproved to DataHub publisher (§10.10)
9. apps/scheduler                  — Periodic review scheduler (§10.11)

(apps/keepalive-appian is deferred until E-08 actually needs Appian.)

## libs/@udpoc/

1. libs/@udpoc/shared-types            — Zod schemas + TS types
2. libs/@udpoc/shared-auth             — JWT + Cognito helpers
3. libs/@udpoc/shared-aws              — SDK wrappers
4. libs/@udpoc/shared-observability    — Logger, tracer, metrics
5. libs/@udpoc/shared-testing          — Test factories + fixtures
6. libs/@udpoc/state-machines          — XState charts (case, account, document)

## Package naming convention

- Root: @udpoc/root (private workspace root, not publishable)
- Apps: @udpoc/<app-dir-name> (e.g. @udpoc/case-service, @udpoc/admin-react)
- Libs: @udpoc/<lib-dir-name> (e.g. @udpoc/shared-types)
