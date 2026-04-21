output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "deploy_role_arn" {
  description = "ARN of the IAM role assumed by the deploy workflow. Hardcode this into .github/workflows/deploy.yml."
  value       = aws_iam_role.deploy.arn
}

output "deploy_role_name" {
  description = "Name of the IAM role assumed by the deploy workflow."
  value       = aws_iam_role.deploy.name
}
