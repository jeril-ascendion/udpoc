# iam-oidc-bootstrap

Creates the IAM role (`github-oidc-deploy`) assumed by
`.github/workflows/deploy.yml` via GitHub Actions OIDC, plus its scoped
permissions policy and role-policy attachment.

**This module does NOT manage the GitHub OIDC provider.** The provider
at `token.actions.githubusercontent.com` is account-level, shared
infrastructure owned by another team in this AWS account (it predates
the POC; CreateDate 2026-03-13). The module looks it up as a data
source and references its ARN. See `AGENTS.md` entry "AWS account
blast-radius" for the policy that drove this decision.

Chicken-and-egg: the deploy workflow cannot apply this module because
the workflow needs the role to exist first — so apply this module
**once, manually**, with a human's AWS credentials.

## Trust

- Repo: `jeril-ascendion/udpoc`
- Branch: `main` only (via the `sub` claim `repo:<org>/<repo>:ref:refs/heads/main`)
- Audience: `sts.amazonaws.com`
- Max session duration: 1 hour

## Permissions

Starts narrow — enough to read Terraform state and acquire/release the lock:

- `s3:GetObject`, `s3:ListBucket` on `udpoc-tfstate-cda8bf`
- `dynamodb:GetItem`, `dynamodb:PutItem`, `dynamodb:DeleteItem` on `udpoc-tflocks`

Additional permissions required to apply specific modules (e.g. Cognito, API
Gateway) must be added as separate, scoped IAM policies in follow-up tasks.

## One-time apply (human)

```sh
cd infra/iam-oidc-bootstrap
aws sso login --profile PowerUserAccess-852973339602
export AWS_PROFILE=PowerUserAccess-852973339602
terraform init
terraform plan
# Expect: 3 to add (role, policy, attachment). NO changes to the OIDC provider.
# If plan shows changes to aws_iam_openid_connect_provider, STOP and review.
terraform apply
```

State lands in `s3://udpoc-tfstate-cda8bf/infra/iam-oidc-bootstrap/terraform.tfstate`.

After apply, copy the `deploy_role_arn` output and confirm it matches the ARN
hardcoded in `.github/workflows/deploy.yml`.

## What happened here (for history)

The module originally managed the OIDC provider itself via
`resource "aws_iam_openid_connect_provider"` and a `data "tls_certificate"`
lookup for dynamic thumbprints. That design would have modified a provider
shared with another team in this production account. The module was
refactored under T-E01-05-refactor to look up the provider as a data
source, never touching it.
