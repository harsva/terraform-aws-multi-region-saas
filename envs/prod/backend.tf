# Remote state: S3 backend with DynamoDB state locking.
# Bucket/table are bootstrapped once — see docs/REMOTE_STATE.md.
# Values are provided via `terraform init -backend-config=...` or a backend.hcl file
# to keep environment-specific values out of version control.
terraform {
  backend "s3" {
    key          = "multi-region-saas/prod/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
    # bucket, region, dynamodb_table supplied at init time via -backend-config
  }
}
