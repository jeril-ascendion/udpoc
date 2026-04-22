# UnionDigital CRU Re-KYC POC

Proof-of-Concept implementation of the Customer Record Update (Re-KYC) module for UnionDigital Bank, delivered by Ascendion Digital Services Philippines.

## What this repo contains

Mobile (Flutter), backend services (Node.js/Fastify), admin portal (React + Appian Community Edition), and infrastructure (Terraform) — all as a single pnpm + Nx monorepo. Fourteen user stories from D-01 are in scope; the rest of the 35-story backlog is deferred per the Master Plan.

## Documents

- **Master Plan** — `docs/UD_CRU_POC_Master_Plan_v0.1.docx`
- **D-01 Functional Specifications** — `docs/UD_CRU_POC_D01_Functional_Specs_v1.0.docx`
- **D-02 Technical Design** — forthcoming
- **D-03 Development Guide** — `docs/UD_CRU_POC_D03_Development_Guide_v1.0.docx`

## Quick start

1. Read D-03 sections 2-5 to set up your machine.
2. Read CLAUDE.original.md for repo conventions.
3. Pick a task from IMPLEMENTATION_PLAN.md.
4. Branch: feat/E-nn/T-Exx-nn-slug.
5. TDD. Green tests. PR. Squash-merge.

## Infrastructure

- AWS Account 852973339602 (shared production account; see AGENTS.md "AWS account blast-radius" and ADR-0006)
- Region ap-southeast-1 (Singapore)
- Terraform state bucket: udpoc-tfstate-cda8bf
- Terraform lock table: udpoc-tflocks
- Domain: udpoc.com

## Status

See STATUS.md.

## Contact

Jeril John Panicker, Solutions Architect, Ascendion Digital Services Philippines.
