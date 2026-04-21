terraform {
  backend "s3" {
    bucket         = "udpoc-tfstate-cda8bf"
    key            = "infra/iam-oidc-bootstrap/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "udpoc-tflocks"
    encrypt        = true
    kms_key_id     = "alias/udpoc-tfstate"
  }
}
