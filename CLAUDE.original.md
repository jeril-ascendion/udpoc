# CLAUDE.original.md — Repo instructions for Claude Code (human-readable source)

This is the source file. The caveman-compressed version (CLAUDE.md) is generated from this via claude /caveman:compress. Edit this file, not CLAUDE.md.

## What this repo is

UnionDigital Bank Customer Record Update (Re-KYC) Proof of Concept. pnpm + Nx monorepo with Flutter mobile app, Node.js/Fastify backend services, React admin screens, and Terraform infrastructure. See README.md for context.

## Non-negotiables

1. TDD always. No production code without a failing test first. Test names match D-01 section 13 acceptance criteria exactly (format: test_<Story>_<AC>_<slug>).
2. One task per branch. Branch name: feat/E-nn/T-Exx-nn-slug. Never push to main directly.
3. Conventional Commits. Scope equals task id. Example: feat(T-E04-02): BR-001 ID-expiry rule.
4. IDs are stable and cross-referenced. Story IDs, AC IDs, BR IDs, ADR IDs, Task IDs all come from their owning document (D-01, D-02, D-03). Never invent new IDs.

## Stack

- Runtime: Node 20.14.0, pnpm 9.12.0, Nx 19.8.14
- Backend: Fastify 4.28 + Zod 3.23 + TypeScript 5.5 + Drizzle + XState 5.18
- Mobile: Flutter 3.24.3, Dart 3.5.3, BLoC, go_router, dio
- Admin: React 18 + Vite + Tailwind + shadcn/ui
- Infra: Terraform (state in S3 udpoc-tfstate-cda8bf, lock udpoc-tflocks), ap-southeast-1
- Test: Vitest (backend), flutter_test (mobile), Playwright (admin), @xstate/test (state machines)
- Auth: AWS Cognito (two pools: customer + admin)
- Workflow: Appian Community Edition for maker-checker screens

## Conventions

- Colocated tests: foo.ts and foo.spec.ts in same directory.
- Integration tests: foo.int.spec.ts, run with DynamoDB Local + Localstack.
- Shared libs under libs/@udpoc/*; apps under apps/*.
- Every file change must go through a PR. Squash-merge only. Delete branch after merge.
- PR template at .github/pull_request_template.md.

## Source documents

- D-01 Functional Specifications (WHAT): docs/UD_CRU_POC_D01_Functional_Specs_v1.0.docx
- D-02 Technical Design (HOW): forthcoming
- D-03 Development Guide (BUILD): docs/UD_CRU_POC_D03_Development_Guide_v1.0.docx

## When in doubt

1. Read IMPLEMENTATION_PLAN.md to see the current task backlog.
2. Read AGENTS.md for patterns discovered by previous iterations.
3. If still unsure, prefer doing less over doing more. Stop and ask.
