# D-01 v1.1 Functional Specifications (Revised) — Work in Progress

**Status:** ~15% drafted as of 2026-04-21. Not yet a deliverable document.

## What's in this folder

- `diagrams/*.mmd` — six Mermaid source files for planned figures in the final DOCX
- `README.md` (this file) — structural plan for the completed document

## What's still needed

This work was started mid-session and paused so that session context could be preserved. Completing D-01 v1.1 requires a dedicated session (estimated 60–90 minutes).

When picking this up in a new session:

1. Ask the user to re-upload `Product Reference Form (PRF) - Customer Record Update Latest 2026.pdf` (v5.0 March 2026). This PRF is the source truth for FR-001 through FR-032+, the 7 use cases, risk segmentation, and the Philippine regulatory references.
2. Read all 6 `.mmd` files in `diagrams/`.
3. Read the structural plan in section "Planned D-01 v1.1 structure" below.
4. Draft the remaining ~14 diagrams (listed below).
5. Render all diagrams to PNG via `mmdc` (see rendering instructions below).
6. Build the DOCX via `docx-js` following the professional engineering standard (Arial default, US Letter, 1-inch margins, numbered sections, rendered diagrams embedded).
7. Pack, validate, deliver.

## Planned D-01 v1.1 structure (24 sections)

1. Document Control
2. Executive Summary
3. Scope and Objectives
4. Business Context + Philippine regulatory (BSP M-2020-003 §4209S, Data Privacy Act, BSP Circular 1083, Circular 706, AMLA, PDIC)
5. Stakeholders and RACI
6. Glossary and Abbreviations
7. User Personas
8. Business Rules Catalog (BR-001 through BR-012)
9. Functional Requirements Catalog (FR-001 through FR-032+, from the PRF)
10. User Stories with Acceptance Criteria (S-01 through S-14)
11. User Journeys (J-1 through J-6) with Mermaid flowcharts
12. Mobile Modal States (S-M-01 through S-M-12)
13. Admin Portal Screens (S-A-01 through S-A-07)
14. Data Model (logical)
15. State Machines (Case, Account Status, Document) — Mermaid stateDiagram-v2
16. Integration Points and Sequence Diagrams
17. Validation Rules and Field Specifications
18. Notification Catalog (T-01 through T-71)
19. Risk Segmentation (High/Normal/Low → 1y/2y/3y refresh window per PRF FR-005)
20. Non-Functional Requirements
21. Constraints, Risks, Dependencies
22. Open Questions (PRF's 18, with recommended resolutions)
23. Traceability Matrix (FR → BR → Story → AC → Test name)
24. Appendices (SoF derivation matrix, Employment → Occupation matrix, PSGC address schema, complete FR-to-AC trace)

## Diagrams drafted (6 of ~20)

| File | Purpose | Section |
|------|---------|---------|
| `d01-01-system-context.mmd` | Top-level system context showing mobile app, backend, Appian, DataHub, Thought Machine, external vendors (Onfido, AML, PSGC), and BSP regulatory authorities | §3 Scope |
| `d01-02-journey-j1-id-expiring.mmd` | Happy-path customer journey for expired/expiring ID triggering re-KYC | §11 J-1 |
| `d01-03-journey-j2-dormant.mmd` | Customer journey for Restricted / Dormant / Dormant-Charging account reactivation via re-KYC | §11 J-2 |
| `d01-04-journey-j3-kyc-expiring.mmd` | Risk-based KYC refresh cycle (High/Normal/Low → 1y/2y/3y windows) | §11 J-3 |
| `d01-05-journey-j4-dedup.mmd` | Handling existing open cases (BR-006 deduplication behaviour) | §11 J-4 |
| `d01-06-case-state-machine.mmd` | Case lifecycle state machine: Draft → InProgress → Submitted → UnderMakerReview → PendingChecker → Approved/Rejected with cycle-cap escalation | §15 |

## Diagrams still needed

- J-5 admin-initiated manual re-KYC journey
- J-6 transaction-inactivity 365-days journey
- Account-status state machine (Regular / Restricted / Dormant / Dormant-Charging transitions)
- Document lifecycle state machine (Uploaded → UnderReview → Approved/Rejected)
- Mobile modal state flow overview (all 12 modal states and their triggers)
- Admin portal navigation structure
- Sequence diagram: pre-fill from DataHub on journey start
- Sequence diagram: document presign + upload (S3 pre-signed URLs)
- Sequence diagram: liveness webhook (Onfido callback)
- Sequence diagram: maker-checker approval (Appian workflow state transitions)
- Sequence diagram: CaseApproved event fan-out (DataHub sync, status flip, notifications)
- Risk segmentation decision tree (inputs → risk profile score)
- Logical component diagram (backend services, their data stores, their external integrations)
- Employment status → occupation dropdown → Source of Funds data flow

## Rendering instructions

The environment this was drafted in had `@mermaid-js/mermaid-cli` v11.12.0 and Chrome at `/home/claude/.cache/puppeteer/chrome/linux-131.0.6778.204/chrome-linux64/chrome`. A `puppeteer-config.json` was used to point mmdc at Chrome with `--no-sandbox`, `--disable-setuid-sandbox`, `--disable-dev-shm-usage`.

Example render command:

    mmdc -i diagrams/d01-01-system-context.mmd \
         -o diagrams/d01-01-system-context.png \
         -p puppeteer-config.json \
         -b white \
         -w 1400 \
         --scale 2

All 20 rendered PNGs should live alongside their .mmd sources.

## Output format

Primary deliverable: `docs/UD_CRU_POC_D01_Functional_Specs_v1.1.docx` (replaces v1.0). Generated via `docx-js` with:

- Arial default font
- US Letter page size (12240 × 15840 DXA)
- 1-inch margins (1440 DXA)
- Numbered Heading 1 / 2 / 3 via overridden built-in styles
- Tables with explicit columnWidths (DXA), not percentages
- Diagrams embedded as PNG images with alt text
- Table of Contents at the start
- Page numbers in footer

Target length: 80–120 pages. No hard upper limit per user directive.

## Audience

Joint audience: UD business/compliance stakeholders + Ascendion engineering team. Plain language for the business side, precise IDs and ACs for engineering. Compliance officers need to be able to read every BR without mentally translating.
