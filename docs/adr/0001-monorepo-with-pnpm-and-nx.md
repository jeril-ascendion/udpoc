# ADR-0001: Monorepo with pnpm and Nx

- **Status:** Accepted
- **Date:** 2026-04-20
- **Deciders:** Jeril John Panicker (Solutions Architect)
- **Related stories/tasks:** T-E01-02, T-E01-02.5, Master Plan Section 8
- **Related ADRs:** none

## Context and problem statement

The POC spans four deployable artefacts — a Flutter mobile app, Node.js/Fastify backend services, a React admin portal, and Appian workflow definitions — plus Terraform infrastructure and a handful of shared TypeScript libraries (schemas, auth helpers, AWS SDK wrappers, observability, testing fixtures, state machines). These artefacts share domain types (case, document, customer record, event payloads) that must not drift between the mobile client and the services that serve it.

We must choose a source-control topology that (a) prevents schema drift, (b) enables atomic cross-cutting pull requests, (c) matches the way a five-week POC is actually staffed (a small team of generalists, not independent feature teams), and (d) keeps CI fast enough that the TDD-via-Ralph-Loop cadence stays productive.

## Decision drivers

- Schema contract sharing between Flutter mobile and Node backend without a duplicated source of truth
- Single-PR atomicity for changes that touch more than one service (e.g., a case-state-machine change that affects backend, mobile, and Appian adapter)
- Matching team shape — one SA plus a small implementation group, not independently staffed service teams
- CI feedback time inside the Ralph Loop TDD cadence
- Developer onboarding friction for an 8-12 week POC

## Considered options

1. Monorepo with pnpm workspaces and Nx task orchestration
2. Multi-repo (one per deployable) with a shared types package published to a private registry
3. Monorepo with npm/yarn workspaces and Turbo
4. Monorepo with Bazel
5. Monorepo with Lerna

## Decision

Adopt a single pnpm workspace at the repository root, with Nx as the task runner and dependency graph. Applications live under `apps/` and shared libraries under `libs/@udpoc/` with the `@udpoc` scope prefix. Exact directory names come from `docs/canonical-package-names.md`; Ralph must not invent names.

## Consequences

### Positive

- One `pnpm install` provisions every app and library; contributors need only Node, pnpm, and the language-specific SDKs for the apps they touch.
- Nx's affected-graph means CI only re-runs tests for packages downstream of changed files, keeping PR verification fast.
- Shared types between mobile (via code generation from `@udpoc/shared-types` Zod schemas) and backend removes a whole class of serialisation bugs.
- Atomic PRs for cross-cutting changes — a state-machine change can land in backend, mobile, and tests in a single squash merge.

### Negative

- Nx configuration is a learning surface for anyone new to the codebase; `nx.json` and per-project `project.json` files must stay consistent.
- Flutter lives in the monorepo but is not an Nx project per se; its build lifecycle is orchestrated outside Nx via standard Flutter tooling, which is a seam.
- pnpm's strict module resolution occasionally surfaces dependency errors that a flatter node_modules would mask.

### Neutral

- `pnpm install --frozen-lockfile` is required in CI and when reproducing issues locally; a plain `pnpm install` will silently upgrade pinned deps (observed ESLint drift 8.57.1 → 9.39.4).
- Workspace package directories must be verified with `pnpm ls --recursive` after scaffolding; exit-zero on an empty workspace is insufficient evidence of correctness.

## Alternatives considered

### Multi-repo with published shared types

- **What it would have been:** one repository per deployable, shared types published as `@udpoc/shared-types` to a private npm registry.
- **Why rejected:** introduces a versioning cliff between the types package and the services that consume it, and requires CI to handle a publish-then-consume release dance. For a POC with one shared team, the coordination cost exceeds the benefit. Atomic cross-service PRs become impossible.

### pnpm workspaces with Turbo instead of Nx

- **What it would have been:** same workspace layout, Turbo (turborepo.com) as the task runner.
- **Why rejected:** Turbo is lighter-weight but does not offer Nx's affected-graph with the same fidelity or its generator ecosystem. For a POC that will be extended (post-POC roadmap includes additional services), Nx's project-graph investment pays back as the repo grows.

### Bazel monorepo

- **What it would have been:** Bazel build rules across TypeScript, Dart, and Terraform.
- **Why rejected:** over-engineered for a 14-story POC. Bazel's setup cost is justified in repos of 100+ developers, not in a small team POC. The team skill concentration is on Node and pnpm, not on Bazel.

### Lerna monorepo

- **Why rejected:** Lerna has been in maintenance mode since 2022. Its responsibilities are now split between npm workspaces (for dependency management) and Nx (for task orchestration); using both together is the modern path.

## Validation

Success indicator: the repository can be cloned, `pnpm install` run, and any single package's tests executed in under five minutes on a developer laptop with no prior setup. Failure indicator: schema drift between mobile and backend (detected via type errors in an integration test).

## References

- D-03 Development Guide section 6 (workspace layout)
- `docs/canonical-package-names.md` (authoritative name list)
- `pnpm-workspace.yaml`, `nx.json`, `tsconfig.base.json`
