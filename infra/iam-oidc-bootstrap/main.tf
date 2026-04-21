data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

# The GitHub Actions OIDC provider is account-level, shared infrastructure.
# In this POC account (852973339602) it is owned by another team (it
# predates this POC; CreateDate 2026-03-13). This module does NOT manage
# the provider; it looks it up as a data source and only manages the role,
# policy, and attachment that are specific to udpoc.
#
# See AGENTS.md "AWS account blast-radius" for the policy that drove this
# decision.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Restrict to workflows running on the trusted branch of the owning repo only.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.trusted_branch}"]
    }
  }
}

resource "aws_iam_role" "deploy" {
  name                 = var.role_name
  description          = "Assumed by GitHub Actions deploy workflow via OIDC. Trusts ${var.github_org}/${var.github_repo} on branch ${var.trusted_branch}."
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  max_session_duration = 3600
}

data "aws_iam_policy_document" "terraform_state" {
  statement {
    sid    = "ReadState"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.state_bucket}",
      "arn:${data.aws_partition.current.partition}:s3:::${var.state_bucket}/*",
    ]
  }

  statement {
    sid    = "LockState"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.lock_table}",
    ]
  }
}

resource "aws_iam_policy" "terraform_state" {
  name        = "${var.role_name}-terraform-state"
  description = "Narrow start: read-only access to Terraform state and lock for ${var.role_name}. Broaden as the deploy workflow grows."
  policy      = data.aws_iam_policy_document.terraform_state.json
}

resource "aws_iam_role_policy_attachment" "terraform_state" {
  role       = aws_iam_role.deploy.name
  policy_arn = aws_iam_policy.terraform_state.arn
}
