# ADR-0007: ap-southeast-1 as the primary AWS region

- **Status:** Accepted
- **Date:** 2026-04-20
- **Deciders:** Jeril John Panicker (Solutions Architect)
- **Related stories/tasks:** T-E01-01, all E-01 tasks with regional AWS resources
- **Related ADRs:** 0005, 0006

## Context and problem statement

The POC serves UnionDigital Bank, a Philippine digital bank, whose customer base is concentrated in the Philippines. All compute, storage, and messaging resources for the POC must be deployed to a specific AWS region. The choice affects round-trip latency from customer devices, AWS service availability (not every service exists in every region at feature parity), data residency considerations relevant to BSP (Bangko Sentral ng Pilipinas) regulatory expectations for banking data, and the ability to integrate with adjacent UD infrastructure if the POC is promoted to production.

AWS does not currently operate a region inside the Philippines. The closest regions are ap-southeast-1 (Singapore), ap-east-1 (Hong Kong), ap-northeast-1 (Tokyo), and ap-southeast-2 (Sydney).

## Decision drivers

- Round-trip latency from Philippine customer devices to the region
- AWS service availability and feature parity in the region
- BSP data-residency guidance (data processing should be in a jurisdiction with an appropriate legal framework)
- Alignment with UD's existing AWS estate (if promoted, cross-region architecture is costly)
- Availability of all POC-required services: Cognito, API Gateway, CloudFront, EventBridge, DynamoDB, KMS, Lambda, SES, SNS, SQS

## Considered options

1. ap-southeast-1 (Singapore)
2. ap-east-1 (Hong Kong)
3. ap-northeast-1 (Tokyo)
4. ap-southeast-2 (Sydney)
5. Multi-region (primary + DR)

## Decision

Use **ap-southeast-1 (Singapore)** as the single primary region for all POC infrastructure. CloudFront, ACM certificates attached to CloudFront distributions, and IAM OIDC providers live in `us-east-1` by AWS requirement (these are global or must be us-east-1); all other resources live in ap-southeast-1. A DR region is not in scope for the POC.

## Consequences

### Positive

- Round-trip latency from Manila to ap-southeast-1 is roughly 30-40 ms — the best of the available Asia-Pacific regions for Philippine customers.
- ap-southeast-1 is a mature region with full AWS service parity for every service the POC uses.
- Singapore is a defensible data-processing jurisdiction under BSP expectations (has a data protection framework, has a Singapore–Philippines mutual recognition context for financial regulation).
- Alignment with UD's production estate — UD runs workloads in ap-southeast-1 today.

### Negative

- A single-region deployment has no regional DR story; the POC's availability is bounded by Singapore's regional availability. Acceptable for a demo; would need revisiting for production.
- ACM certificates for CloudFront must be provisioned in us-east-1, creating a dual-region Terraform pattern for the CloudFront module specifically.
- CloudFront's edge latency to Manila is better than origin latency but is itself served from edge locations not in ap-southeast-1, which introduces nuance for cache-miss behaviour.

### Neutral

- The Terraform provider block must explicitly specify `region = "ap-southeast-1"` for the default provider and `region = "us-east-1"` for the CloudFront/ACM alias provider — the workflow hardcodes both.
- Costs in ap-southeast-1 are roughly 10-15% higher than us-east-1 for equivalent resources; this is expected and acceptable for POC spend.

## Alternatives considered

### ap-east-1 (Hong Kong)

- **What it would have been:** primary region in Hong Kong, closer than Singapore by a small margin.
- **Why rejected:** ap-east-1 has meaningfully less AWS service coverage than ap-southeast-1 (for example, some Cognito features lag). Hong Kong's data-residency framework has different BSP optics than Singapore's. Latency advantage is marginal (roughly 5 ms).

### ap-northeast-1 (Tokyo)

- **What it would have been:** primary region in Tokyo.
- **Why rejected:** latency from Manila to Tokyo is ~60-70 ms, double Singapore's. Full service parity but no other advantage.

### ap-southeast-2 (Sydney)

- **What it would have been:** primary region in Sydney.
- **Why rejected:** latency is ~90-100 ms — worst of the viable options for Philippine customers.

### Multi-region (primary + DR)

- **What it would have been:** ap-southeast-1 as primary with ap-northeast-1 or ap-east-1 as DR, cross-region replication on stateful stores.
- **Why rejected:** materially increases POC complexity and cost for a benefit (regional DR) that is not part of the POC's success criteria. Revisit for production.

## Validation

Success indicator: round-trip latency from a Manila test device to the API Gateway custom domain stays under 100 ms P95. Failure indicator: region unavailability or a specific AWS service missing a feature the POC requires.

## References

- AWS region service availability matrix
- BSP Circular 808 (Guidelines on Cloud Computing) — data-residency framing
- Master Plan Section 8
