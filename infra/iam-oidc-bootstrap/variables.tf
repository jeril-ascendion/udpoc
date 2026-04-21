variable "github_org" {
  description = "GitHub org or user that owns the repository."
  type        = string
  default     = "jeril-ascendion"
}

variable "github_repo" {
  description = "GitHub repository name (without org)."
  type        = string
  default     = "udpoc"
}

variable "trusted_branch" {
  description = "Branch that is allowed to assume the role via OIDC."
  type        = string
  default     = "main"
}

variable "role_name" {
  description = "IAM role name assumed by GitHub Actions. Referenced by .github/workflows/deploy.yml as role-to-assume."
  type        = string
  default     = "github-oidc-deploy"
}

variable "state_bucket" {
  description = "S3 bucket holding Terraform state for all modules."
  type        = string
  default     = "udpoc-tfstate-cda8bf"
}

variable "lock_table" {
  description = "DynamoDB table used for Terraform state locking."
  type        = string
  default     = "udpoc-tflocks"
}
