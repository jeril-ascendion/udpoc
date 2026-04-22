# ADR-0002: Flutter for the mobile application

- **Status:** Accepted
- **Date:** 2026-04-20
- **Deciders:** Jeril John Panicker (Solutions Architect)
- **Related stories/tasks:** E-02, all S-0* user stories with a mobile surface
- **Related ADRs:** 0001

## Context and problem statement

The CRU Re-KYC flow is fundamentally a mobile experience: existing UnionDigital customers receive a trigger notification, open the app, authenticate, confirm identity via liveness, and re-submit documents. Fourteen of fourteen in-scope user stories include a mobile UI touchpoint. The mobile application must deliver a native-feeling experience on both iOS and Android, support on-device camera integration for document capture and liveness, support certificate pinning for API traffic, and be demoable on commodity test devices within the POC timeline.

The team has skill concentration in Dart/Flutter from prior engagements and no significant Swift/Kotlin depth. The POC has a 6-week demo target from Master Plan sign-off, which constrains the realistic scope of native-per-platform work.

## Decision drivers

- Single codebase covering iOS and Android, given team skill shape
- Native access to camera, biometrics, and secure storage (for liveness and document flows)
- Ability to ship a demo-quality build within six weeks
- Longer-term extensibility post-POC (UD may take the app forward if the POC is approved)
- Performance and UX parity with the existing UnionDigital customer-facing app

## Considered options

1. Flutter (Dart)
2. React Native
3. Native per platform (Swift/SwiftUI for iOS, Kotlin/Jetpack Compose for Android)
4. Kotlin Multiplatform Mobile (KMM) with native UI

## Decision

Build the mobile application in Flutter 3.24.3 with Dart 3.5.3. Use BLoC for state management and `go_router` for navigation. Certificate pinning is configured in the HTTP client (`dio`) and is enabled in dev and prod builds; disabled only via a debug-only override gate.

## Consequences

### Positive

- One codebase covers both platforms; the small POC team can cover both with the same skillset.
- Flutter's widget system gives pixel-level control over UI, which matters for the document-capture and liveness screens where native widgets vary meaningfully between platforms.
- Strong ecosystem for the specific integrations we need: camera, biometrics, secure storage, locale handling (EN + FIL).
- Hot-reload shortens the feedback loop during UI iteration.

### Negative

- Accessibility parity with native requires explicit attention; default Flutter widgets are not automatically accessible to the same standard as UIKit/Jetpack.
- Native module integration (for any iOS or Android-specific SDK the liveness vendor ships) requires platform-channel code in Swift and Kotlin, which the team has limited experience with. Mitigation: use vendors that ship Flutter plugins directly.
- App size is larger than a comparable native app (~40 MB baseline vs ~10-15 MB native).

### Neutral

- The mobile app is a separate build pipeline from the Node.js apps — Flutter lives in the monorepo under `apps/mobile/` but is not orchestrated by Nx; its CI is a separate GitHub Actions workflow.
- Code generation from `@udpoc/shared-types` Zod schemas to Dart models is needed so the contract between mobile and backend is enforced at compile time on both sides.

## Alternatives considered

### React Native

- **What it would have been:** TypeScript + React Native with Expo or bare workflow, reusing skills from the admin portal's React codebase.
- **Why rejected:** the team's mobile skill concentration is in Flutter, and the POC timeline does not permit re-tooling. React Native's native-module story for camera and liveness is more fragile than Flutter's, and custom UI work tends to hit platform-divergence cliffs sooner.

### Native per platform

- **What it would have been:** parallel Swift/SwiftUI and Kotlin/Compose apps.
- **Why rejected:** doubles the mobile surface area in a POC that has six weeks to demo. Team does not have staffing to cover both natively.

### Kotlin Multiplatform Mobile

- **What it would have been:** shared business logic in Kotlin, native UI per platform.
- **Why rejected:** KMM is production-ready but still requires parallel UI work. The UI-heavy nature of CRU (liveness, document capture, form validation) means the UI is most of the work; sharing only business logic gives a small fraction of the benefit that Flutter gives.

## Validation

Success indicator: the mobile app builds for both platforms from a single `apps/mobile` directory, passes the planned integration-test harness (T-E02-08), and runs demo flows on a mid-range Android device and a current iPhone. Failure indicator: platform-specific divergence requiring per-platform code paths in more than 20% of screens.

## References

- D-01 section 5 (user journeys, all mobile-originated)
- D-03 section 4 (mobile toolchain), section 6.2 (package names)
- Flutter 3.24 release notes
