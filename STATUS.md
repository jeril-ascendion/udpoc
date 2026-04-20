# POC Status

Last updated: 2026-04-20

## Overall

- Phase: Foundations (E-01)
- Critical path: Platform foundations -> Backend scaffold -> Eligibility service -> Mobile scaffold
- Target demo: TBD (6 weeks from Master Plan sign-off, per Q-07)

## EPIC status

| EPIC | Name | Status | Notes |
|------|------|--------|-------|
| E-01 | Platform Foundations | In progress | T-E01-01 done; T-E01-01.5 in flight; rest pending |
| E-02 | Mobile App Scaffold | Not started | Blocked on T-E01-06 |
| E-03 | Backend Services Scaffold | Not started | Blocked on T-E01-09/10/11 |
| E-04 | Eligibility Service | Not started | Depends on E-03 |
| E-05 | Customer Data Service | Not started | Depends on E-03, E-04 |
| E-06 | Document Service | Not started | Depends on E-03 |
| E-07 | Liveness Service | Not started | Depends on E-03 |
| E-08 | Workflow + Appian | Not started | Depends on E-03 and Appian CE provisioning |
| E-09 | Notification Service | Not started | Depends on E-03, T-E01-10 |
| E-10 | DataHub Sync | Not started | Depends on E-08 |
| E-11 | Scheduler | Not started | Depends on E-04 |
| E-12 | Admin React Screens | Not started | Depends on T-E01-08 |

## Open blockers

None.

## Open decisions

- OQ-02 (D-01): Onfido sandbox or mock-only for liveness, pending credentials
- Other OQ-01 through OQ-08 from D-01 section 18.1, UD engagement needed

## Recent milestones

- 2026-04-20: T-E01-01 complete, Terraform backend deployed to AWS 852973339602 / ap-southeast-1
- 2026-04-20: Master Plan sign-off (Section 8 decisions closed)
- 2026-04-20: D-01 Functional Specifications v1.0 delivered
- 2026-04-20: D-03 Development Guide v1.0 delivered
