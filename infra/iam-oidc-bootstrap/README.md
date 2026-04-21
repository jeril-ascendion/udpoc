# iam-oidc-bootstrap

Chicken-and-egg module: creates the GitHub Actions OIDC provider and the IAM
role (`github-oidc-deploy`) assumed by `.github/workflows/deploy.yml`. The
deploy workflow cannot apply this module because the workflow needs the role
to exist first — so apply this module **once, manually**, with a human's AWS
credentials.

## Trust

- Repo: `jeril-ascendion/udpoc`
- Branch: `main` only (via the `sub` claim `repo:<org>/<repo>:ref:refs/heads/main`)
- Audience: `sts.amazonaws.com`

## Permissions

Starts narrow — enough to read Terraform state and acquire/release the lock:

- `s3:GetObject`, `s3:ListBucket` on `udpoc-tfstate-cda8bf`
- `dynamodb:GetItem`, `dynamodb:PutItem`, `dynamodb:DeleteItem` on `udpoc-tflocks`

Additional permissions required to apply specific modules (e.g. Cognito, API
Gateway) must be added as separate, scoped IAM policies in follow-up tasks.

## One-time apply (human)

```sh
cd infra/iam-oidc-bootstrap
terraform init
terraform plan
terraform apply
```

State lands in `s3://udpoc-tfstate-cda8bf/infra/iam-oidc-bootstrap/terraform.tfstate`.

After apply, copy the `deploy_role_arn` output and confirm it matches the ARN
hardcoded in `.github/workflows/deploy.yml`
(`arn:aws:iam::852973339602:role/github-oidc-deploy`).
