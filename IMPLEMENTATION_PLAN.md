# IMPLEMENTATION_PLAN.md — Task backlog

Tasks are consumed by Ralph Loop one at a time. Topmost unblocked task is picked each iteration. Mark `[x]` when done; add sub-items as you discover them; mark `[blocked]` with a reason if external dependency prevents completion.

---

## E-01 Platform Foundations

- [x] T-E01-01 Bootstrap Terraform backend (S3 + DDB + KMS) — commit 98e28de
- [x] T-E01-01.5 Governance scaffolding — commit 35f1f64 (PR #1)
- [x] T-E01-02 pnpm workspace skeleton
- [x] T-E01-02.5 Workspace package directories (9 apps + 6 libs under libs/@udpoc/ with stub package.json per D-03 section 6.2); pnpm install must resolve all 15 packages
- [x] T-E01-03 ESLint + Prettier + Husky + commitlint
- [x] T-E01-04 CI PR workflow (lint/typecheck/test/coverage) — PR #18 (PR #17 was an accidental duplicate, same diff); CI verify job ran green on the PR itself
- [x] T-E01-05 CI deploy workflow + OIDC bootstrap — delivered via PR #22, then refactored (follow-on PR) to look up the shared OIDC provider as a `data` source instead of managing it (the provider is account-level, owned by another team in this production account; see AGENTS.md "AWS account blast-radius")
  - [x] T-E01-05.sub1 Terraform at infra/iam-oidc-bootstrap/ — IAM role `github-oidc-deploy` + narrow permissions policy + attachment. The GitHub OIDC provider is looked up via `data "aws_iam_openid_connect_provider"` (not managed). State key infra/iam-oidc-bootstrap/terraform.tfstate in existing udpoc-tfstate-cda8bf bucket. Permissions policy: s3:GetObject+ListBucket on udpoc-tfstate-cda8bf; dynamodb:GetItem+PutItem+DeleteItem on udpoc-tflocks. Role trust pinned to repo:jeril-ascendion/udpoc:ref:refs/heads/main, aud sts.amazonaws.com, max 1h session. Apply must be done manually once by a human.
  - [x] T-E01-05.sub2 .github/workflows/deploy.yml — workflow_dispatch with `module` + `action` inputs, id-token write permission, role-to-assume arn:aws:iam::852973339602:role/github-oidc-deploy, plan always, apply gated by input == "apply" and by `environment: deploy-prod`. Module input is a choice limited to infra/bootstrap and infra/iam-oidc-bootstrap (the directories that exist today).
  - [x] T-E01-05.follow1 Configure the `deploy-prod` GitHub Actions environment in repo settings with required reviewer(s) — DONE. Environment created, required reviewer set to jeril-ascendion, deployment branches limited to `main`, admin-bypass disabled.
  - [x] T-E01-05.follow2 After the first human-run `terraform apply` of infra/iam-oidc-bootstrap/, confirm the role ARN output matches the hardcoded value in deploy.yml (852973339602 / github-oidc-deploy) — DONE. Terraform apply created the role; `terraform output -raw deploy_role_arn` MD5-matches the ARN in deploy.yml (length 49, md5 cb3c1c664492f55a15a39f032bc64556).
  - [ ] T-E01-05.follow3 Migrate backend locking from deprecated `dynamodb_table` parameter to `use_lockfile = true` across all Terraform modules (infra/bootstrap, infra/iam-oidc-bootstrap, and any future modules). Tracking separately because it affects the existing merged T-E01-01 state.
  - [ ] T-E01-05.follow4 Deploy workflow smoke test produced an expected AccessDenied on kms:DescribeKey and s3:GetBucketPolicy when planning infra/bootstrap — the github-oidc-deploy role is scoped only to Terraform state read + lock table ops (per narrow-start design). Per-module permissions are added when each module is first operated through the workflow. No action needed now; tracked as a reminder.
- [ ] T-E01-06 Cognito user pools (customer + admin)
- [ ] T-E01-07 API Gateway custom domain api.udpoc.com
- [ ] T-E01-08 CloudFront for app.udpoc.com + demo.udpoc.com
- [ ] T-E01-09 Shared KMS keys (docs, state, logs)
- [ ] T-E01-10 EventBridge bus: udpoc-events
- [ ] T-E01-11 DynamoDB tables: cases, documents, audit
- [ ] T-E01-12 Observability baseline
- [ ] T-E01-13 Cost guardrails
- [ ] T-E01-14 Dev bootstrap script

## E-02 Mobile App Scaffold

- [ ] T-E02-01 Flutter project under apps/mobile
- [ ] T-E02-02 BLoC scaffolding + go_router routes
- [ ] T-E02-03 HTTP client (dio) with Cognito token interceptor
- [ ] T-E02-04 Theme + design tokens
- [ ] T-E02-05 Localisation scaffold (EN + FIL)
- [ ] T-E02-06 Certificate pinning (dev only)
- [ ] T-E02-07 Splash + login placeholder screens
- [ ] T-E02-08 Flutter integration-test harness

## E-03 Backend Services Scaffold

- [ ] T-E03-01 @udpoc/shared-types — Zod schemas
- [ ] T-E03-02 @udpoc/shared-auth — JWT + claim helpers
- [ ] T-E03-03 @udpoc/shared-aws — SDK wrappers
- [ ] T-E03-04 @udpoc/shared-observability — logger, tracer
- [ ] T-E03-05 @udpoc/shared-testing — factories + fixtures
- [ ] T-E03-06 @udpoc/state-machines — XState chart library
- [ ] T-E03-07 Fastify service template (canary service)
- [ ] T-E03-08 Lambda packaging (esbuild bundler)

## E-04 Eligibility Service (Story S-01)

- [ ] T-E04-01 Case domain types + Zod schema
- [ ] T-E04-02 BR-001 ID-expiry rule engine — AC: test_S01_AC01_id_expiry_within_30d_creates_case
- [ ] T-E04-03 BR-003 RiskFlagged event handler — AC: test_S01_AC02_medium_risk_flag_creates_case_within_60s
- [ ] T-E04-04 BR-005 de-dup within 90 days — AC: test_S01_AC03_manual_rekyc_deduped_within_90_days
- [ ] T-E04-05 BR-006 restricted-with-open-case — AC: test_S01_AC04_restricted_with_open_case_blocks_new_manual
- [ ] T-E04-06 Nightly scheduled Lambda (EventBridge cron)
- [ ] T-E04-07 CaseCreated event publisher
- [ ] T-E04-08 Integration test with DDB Local + Localstack

## E-05 Customer Data Service (Stories S-02, S-07)

- [ ] T-E05-01 Pre-fill endpoint GET /cases/:id/personal — AC: test_S02_AC01_personal_info_prefilled_from_datahub
- [ ] T-E05-02 Adult-only validation on write — AC: test_S02_AC02_dob_under_18_blocks_continue
- [ ] T-E05-03 Name character-set validation — AC: test_S02_AC03_name_accepts_philippine_char_set
- [ ] T-E05-04 Mobile number read-only — AC: test_S02_AC04_mobile_number_is_readonly_with_info
- [ ] T-E05-05 PSGC Philippine address validator — AC: test_S02_AC05_non_psgc_address_blocks_submit
- [ ] T-E05-06 Employment to Occupation filter API — AC: test_S07_AC01_employment_change_clears_occupation
- [ ] T-E05-07 Self-employed doc-required enforcement — AC: test_S07_AC02_self_employed_requires_business_doc
- [ ] T-E05-08 SoF derivation matrix (Appendix A.3)
- [ ] T-E05-09 PUT /cases/:id/personal — atomic write with audit

## E-06 Document Service (Story S-03)

- [ ] T-E06-01 Presign POST endpoint + 15-min expiry — AC: test_S03_AC01_presign_returns_15min_url_for_valid_pdf
- [ ] T-E06-02 Document count cap at 5 — AC: test_S03_AC02_presign_rejects_sixth_document_with_409
- [ ] T-E06-03 MIME whitelist enforcement — AC: test_S03_AC03_presign_rejects_unsupported_mime
- [ ] T-E06-04 Max file size enforcement (413) — AC: test_S03_AC04_presign_rejects_oversize
- [ ] T-E06-05 Scan-clean webhook transitions document — AC: test_S03_AC05_clean_scan_transitions_document_to_clean
- [ ] T-E06-06 Scan-infected quarantine + notify — AC: test_S03_AC06_infected_scan_quarantines_and_notifies
- [ ] T-E06-07 Idempotent confirm endpoint — AC: test_S03_AC07_confirm_is_idempotent_on_retry
- [ ] T-E06-08 Mobile resumable upload integration — AC: flutter_test_S03_AC08_upload_resumes_on_network_failure
- [ ] T-E06-09 Virus scan integration (ClamAV on Fargate)
- [ ] T-E06-10 S3 KMS encryption + lifecycle to quarantine bucket

## E-07 Liveness Service (Story S-04)

- [ ] T-E07-01 LivenessProvider port + mock adapter
- [ ] T-E07-02 Successful liveness advances case — AC: test_S04_AC01_successful_liveness_advances_to_review
- [ ] T-E07-03 Score-below-threshold marks failed — AC: test_S04_AC02_score_below_085_marks_failed
- [ ] T-E07-04 30-sec provider timeout counts as attempt — AC: test_S04_AC03_provider_timeout_counts_as_failed_attempt
- [ ] T-E07-05 Third-failure dual CTA in UI — AC: flutter_test_S04_AC04_third_failure_shows_dual_cta
- [ ] T-E07-06 60-minute cooldown — AC: flutter_test_S04_AC05_60min_cooldown_enforced
- [ ] T-E07-07 Webhook endpoint (signed) for provider callback
- [ ] T-E07-08 Onfido adapter (feature-flagged)
- [ ] T-E07-09 Ticket creation on max-attempt exhaustion (S-08) — AC: test_S08_AC01_ticket_links_case_and_failure_reasons

## E-08 Workflow + Appian (Stories S-05, S-06, S-08, S-09)

- [ ] T-E08-01 Case state chart (XState) with model tests
- [ ] T-E08-02 POST /cases/:id/submit transitions Draft to Submitted
- [ ] T-E08-03 Maker claim endpoint — AC: test_S09_AC02_claim_is_exclusive_to_first_maker
- [ ] T-E08-04 Maker forward transitions Submitted to Pending — AC: test_S09_AC03_maker_forward_transitions_to_pending
- [ ] T-E08-05 Maker-Checker separation — AC: test_S09_AC04_maker_cannot_also_be_checker
- [ ] T-E08-06 Checker approval triggers DataHub sync + notifications — AC: test_S09_AC05_checker_approve_syncs_datahub_and_notifies
- [ ] T-E08-07 Checker rejection flags documents — AC: test_S09_AC06_reject_with_reason_flags_documents
- [ ] T-E08-08 Cycle limit + auto-escalation at 4th cycle — AC: test_S09_AC07_fourth_cycle_auto_escalates_to_manager
- [ ] T-E08-09 Case visible in Maker queue within 30s — AC: test_S09_AC01_submitted_case_visible_in_maker_queue_30s
- [ ] T-E08-10 Appian UDCRU application skeleton [blocked — Appian CE provisioning]
- [ ] T-E08-11 Maker Queue report (S-A-01) [blocked — Appian CE]
- [ ] T-E08-12 Maker Review interface (S-A-02) [blocked — Appian CE]
- [ ] T-E08-13 Checker Queue + Review (S-A-03, S-A-04) [blocked — Appian CE]
- [ ] T-E08-14 Service account + JWT for Appian to API
- [ ] T-E08-15 Export Appian app to XML and commit [blocked — Appian CE]
- [ ] T-E08-16 Restricted modal UI (S-M-08) — AC: flutter_test_S05_AC01_restricted_modal_is_persistent
- [ ] T-E08-17 Feature lock on Restricted — AC: flutter_test_S05_AC02_restricted_blocks_transactional_features
- [ ] T-E08-18 Restricted cleared on Approval — AC: test_S05_AC03_approved_case_restores_regular_status
- [ ] T-E08-19 Dormant modal UI (S-M-10) — AC: flutter_test_S06_AC01_dormant_modal_shows_reactivate_only
- [ ] T-E08-20 Charging-Dormant shows both CTAs — AC: flutter_test_S06_AC02_charging_dormant_shows_both_ctas

## E-09 Notification Service (Story S-12)

- [ ] T-E09-01 Template registry — T-01 to T-71
- [ ] T-E09-02 Channel dispatchers: SES, SNS-SMS, FCM
- [ ] T-E09-03 Approved three-channel fan-out — AC: test_S12_AC01_approved_fanout_to_sms_email_push
- [ ] T-E09-04 Throttle / dedup — AC: test_S12_AC02_throttle_suppresses_duplicate_within_1h
- [ ] T-E09-05 Retry with exponential backoff
- [ ] T-E09-06 Delivery-log emission to audit

## E-10 DataHub Sync (Story S-10)

- [ ] T-E10-01 DataHub mock service
- [ ] T-E10-02 CaseApproved consumer to DataHub PUT — AC: test_S10_AC01_approved_event_propagates_to_datahub_within_60s
- [ ] T-E10-03 Idempotent writes — AC: test_S10_AC02_idempotent_event_consumption
- [ ] T-E10-04 Poison-message DLQ — AC: test_S10_AC03_poison_message_after_5_retries_goes_to_dlq
- [ ] T-E10-05 Alert on DLQ non-empty

## E-11 Scheduler (Story S-11)

- [ ] T-E11-01 Scheduler Lambda — daily cron 02:00 Manila — AC: test_S11_AC01_due_customer_picked_by_daily_run
- [ ] T-E11-02 Batch of 500 per SQS send — AC: test_S11_AC02_batch_size_limits_respected
- [ ] T-E11-03 Load-test harness (locust) for 10k customers

## E-12 Admin React Screens (Stories S-13, S-14)

- [ ] T-E12-01 Vite app scaffold + Cognito Hosted UI login
- [ ] T-E12-02 Customer search (S-A-05)
- [ ] T-E12-03 Reconciliation report list view — AC: test_S13_AC01_report_shows_field_level_changes_masked
- [ ] T-E12-04 Reconciliation CSV export with PII masking — AC: test_S13_AC02_csv_export_masks_pii_without_reason_code
- [ ] T-E12-05 Operational dashboard (S-A-07)
- [ ] T-E12-06 Health endpoint in every service — AC: test_S14_AC01_health_endpoint_returns_200_with_contract
- [ ] T-E12-07 Deep-health endpoint — AC: test_S14_AC02_deep_health_reports_db_failure_as_503

## Cross-EPIC integration

- [ ] T-X-01 End-to-end J-1 happy path (synthetic customer)
- [ ] T-X-02 End-to-end J-4 Restricted path
- [ ] T-X-03 Demo data seed script
- [ ] T-X-04 Demo reset script
- [ ] T-X-05 UD compliance review walkthrough script
