provider "aws" {
  region = "ap-southeast-1"
  default_tags {
    tags = {
      Project     = "udpoc"
      Environment = "shared"
      ManagedBy   = "terraform"
      Owner       = "ascendion"
      Module      = "iam-oidc-bootstrap"
    }
  }
}
