# ADR-0003: Node.js and Fastify for backend services

- **Status:** Accepted
- **Date:** 2026-04-20
- **Deciders:** Jeril John Panicker (Solutions Architect)
- **Related stories/tasks:** E-03, E-04, E-05, E-06, E-07, E-09, E-10, E-11
- **Related ADRs:** 0001

## Context and problem statement

The POC backend comprises several small services — Eligibility, Customer Data, Document, Liveness, Notification, DataHub Sync, Scheduler — each of which follows the same shape: event-driven, short-running, integrated with DynamoDB for persistence, SQS/EventBridge for messaging, and Cognito for authentication. These services must deploy as AWS Lambda functions (per Master Plan decision) with a consistent service template, share schema definitions with the Flutter mobile app, and be testable against DynamoDB Local and LocalStack for CI.

The team has deep TypeScript/Node experience from prior UD and FSI engagements. The existing Ascendion patterns for similar banking POCs use Fastify as the HTTP layer.

## Decision drivers

- Native fit with the monorepo and shared-types strategy (ADR-0001) — both mobile and backend consume `@udpoc/shared-types`
- AWS Lambda as the compute target, with cold-start envelope that constrains runtime choices
- Team skill concentration in TypeScript
- Need for strict schema validation at the service boundary (Zod) to catch contract drift
- Reuse of Ascendion internal patterns that shorten time-to-first-service

## Considered options

1. Node.js 20 + Fastify + TypeScript
2. Node.js 20 + Express + TypeScript
3. Go + standard library or chi
4. Python + FastAPI
5. Java 21 + Spring Boot (native image via GraalVM)

## Decision

Build backend services in Node.js 20 with Fastify as the HTTP framework, TypeScript as the implementation language, and Zod for runtime schema validation at every service boundary. Package services for Lambda via esbuild bundling. A single canary service template (T-E03-07) establishes the pattern and every subsequent service is cut from that template.

## Consequences

### Positive

- Shared-types story: Zod schemas defined once in `@udpoc/shared-types` are validated at HTTP boundaries in backend and surfaced as Dart types in mobile via codegen.
- Fastify's schema-first design makes request/response validation declarative and fast — the JSON Schema validator is compiled, not interpreted per request.
- Lambda cold starts are acceptable for the POC traffic profile (interactive user flows, not high-fanout).
- Service template amortises observability, auth, and error-handling concerns across every service.

### Negative

- Cold-start latency on infrequently-invoked Lambdas (Scheduler, DataHub Sync) may exceed 1s on initial call; mitigation is provisioned concurrency, which costs money even when idle.
- Node.js and Lambda's execution model does not fit long-running workflows — those live in Appian (ADR-0004) or Step Functions.
- TypeScript build complexity (esbuild config, tsconfig project references) is a long tail that must be managed.

### Neutral

- Every service exposes a standard `GET /health` (shallow) and `GET /health/deep` (with dependency checks) — contract enforced in T-E12-06 and T-E12-07.
- Service-to-service communication is via EventBridge events, not direct HTTP calls, with one exception: the BFF endpoints the mobile app hits synchronously.

## Alternatives considered

### Express

- **What it would have been:** the same structure with Express replacing Fastify.
- **Why rejected:** Express has no first-class schema validation, weaker TypeScript story, and is roughly 2-3x slower on JSON-heavy workloads. Fastify has been the default for new Node HTTP services for several years.

### Go

- **What it would have been:** Go services, likely using chi or Echo, deployed as Lambda functions via the Go Lambda runtime.
- **Why rejected:** excellent cold-start and runtime performance, but the team does not have Go skill concentration, and the shared-schema story with the TypeScript mobile contract is more friction than benefit. The backend is not the bottleneck for a POC of this shape.

### Python + FastAPI

- **What it would have been:** FastAPI services with Pydantic models.
- **Why rejected:** Pydantic is a peer of Zod but does not interoperate with the TypeScript/Dart ecosystem for the shared-types strategy. Python on Lambda also has heavier cold-start than Node for equivalent code.

### Java + Spring Boot (with GraalVM native image)

- **What it would have been:** Spring Boot services with native-image compilation to keep Lambda cold starts tolerable.
- **Why rejected:** GraalVM native-image tooling is mature but adds build complexity that is excessive for a POC. Team skill on Java exists but is concentrated on traditional JVM Spring, not native image. Startup time would be worse than Node even after optimisation.

## Validation

Success indicator: the canary service (T-E03-07) demonstrates a full request path — Cognito-authenticated POST, Zod-validated request body, DynamoDB write, EventBridge event emission — under 200 ms P99 warm and under 1.5 s cold, with 100% test coverage of the happy path. Failure indicator: average cold-start exceeds 2 s on any service.

## References

- D-03 section 7 (backend service template)
- D-01 section 11 (API surface)
- Fastify documentation on Lambda deployment
