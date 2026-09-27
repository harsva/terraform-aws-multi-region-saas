# Remote State — S3 backend with DynamoDB locking

Terraform state is stored remotely in S3 with locking to prevent concurrent
applies from corrupting state. This is bootstrapped once per account.

## 1. Bootstrap the backend (one-time)

Create an encrypted, versioned S3 bucket and a DynamoDB lock table:

```bash
AWS_REGION=us-east-1
STATE_BUCKET=saas-platform-tfstate-$(aws sts get-caller-identity --query Account --output text)
LOCK_TABLE=saas-platform-tf-locks

# S3 bucket
aws s3api create-bucket --bucket "$STATE_BUCKET" --region "$AWS_REGION"
aws s3api put-bucket-versioning --bucket "$STATE_BUCKET" \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket "$STATE_BUCKET" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms"}}]}'
aws s3api put-public-access-block --bucket "$STATE_BUCKET" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# DynamoDB lock table (used with S3 native locking as a secondary guard)
aws dynamodb create-table --table-name "$LOCK_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST --region "$AWS_REGION"
```

> This project uses `use_lockfile = true` (S3-native state locking, Terraform >= 1.10).
> The DynamoDB table above is optional but recommended if you also run older
> Terraform versions; add `dynamodb_table = "$LOCK_TABLE"` to the init config.

## 2. Initialize an environment

Create a `backend.hcl` (do not commit environment-specific values):

```hcl
bucket = "saas-platform-tfstate-<account-id>"
region = "us-east-1"
```

Then:

```bash
cd envs/prod
terraform init -backend-config=../../backend.hcl
```

## 3. Why this matters (SRE perspective)

- **Locking** prevents two engineers (or a human + CI) from applying at once,
  which is a classic cause of corrupted state and partial infra changes.
- **Versioning** lets you recover a previous state if an apply goes wrong.
- **Encryption** protects sensitive values (endpoints, ARNs) that land in state.
