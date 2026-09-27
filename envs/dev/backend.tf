terraform {
  backend "s3" {
    key          = "multi-region-saas/dev/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
    # bucket, region supplied at init time via -backend-config
  }
}
