# terraform-aws-multi-region-saas

Production-grade, multi-region AWS infrastructure for a mission-critical SaaS platform,
built with Terraform. Models an active/passive multi-region topology with automated
database failover, elastic compute, distributed caching, and DNS health-check failover.

This mirrors the kind of platform operated in a 24/7 Cloud Operations / SRE context:
multi-AZ EC2 Auto Scaling fleets, Aurora MySQL with RDS Proxy for graceful failover,
ElastiCache Redis for distributed locking, an Application Load Balancer, and Route 53
failover routing — sustaining high availability across regions.

## Architecture

```
                         Route 53 (failover routing + health checks)
                                     |
                 ┌───────────────────┴───────────────────┐
                 │ PRIMARY (us-east-1)                    │ SECONDARY (us-west-2)
                 │                                        │
          ┌──────▼──────┐                          ┌──────▼──────┐
          │     ALB     │                          │     ALB     │
          └──────┬──────┘                          └──────┬──────┘
        ┌────────┴────────┐                      ┌────────┴────────┐
   ┌────▼────┐       ┌────▼────┐            ┌────▼────┐       ┌────▼────┐
   │ EC2 ASG │  ...  │ EC2 ASG │            │ EC2 ASG │  ...  │ EC2 ASG │   (multi-AZ)
   └────┬────┘       └────┬────┘            └─────────┘       └─────────┘
        │                 │
   ┌────▼─────────────────▼────┐
   │  RDS Proxy → Aurora MySQL │  (writer + reader, Multi-AZ)
   └───────────────────────────┘
   ┌───────────────────────────┐
   │  ElastiCache Redis (repl)  │  (distributed locks / session/cache)
   └───────────────────────────┘
```

## Design principles

- **Multi-AZ by default** — every stateful and stateless tier spans at least two Availability Zones.
- **Graceful DB failover** — RDS Proxy sits in front of Aurora MySQL so application connections
  survive failovers without connection-exhaustion storms (a real production failure mode).
- **Distributed coordination** — ElastiCache Redis (replication group, Multi-AZ, automatic failover)
  for distributed locks and shared state.
- **DNS failover** — Route 53 health checks flip traffic to the secondary region if the primary ALB
  becomes unhealthy.
- **Reusable modules** — `network`, `compute`, `database`, `cache`, `dns` are composed per environment.
- **Remote state** — S3 backend with DynamoDB state locking (see `backend.tf` and `docs/REMOTE_STATE.md`).

## Repository layout

```
modules/
  network/     VPC, subnets (public/private/data), NAT, route tables, flow logs
  compute/     Launch template, Auto Scaling Group, ALB, target group, security groups
  database/    Aurora MySQL cluster (Multi-AZ) + RDS Proxy
  cache/        ElastiCache Redis replication group (Multi-AZ, auto-failover)
  dns/          Route 53 records + health checks for regional failover
envs/
  dev/          Single-region, cost-optimized composition
  prod/         Multi-region active/passive composition
```

## Usage

```bash
cd envs/prod
terraform init
terraform plan  -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```

> Requires Terraform >= 1.5 and AWS provider >= 5.0. Configure the S3 backend before `init`
> (see `docs/REMOTE_STATE.md`).

## Validation

This repo is validated in CI with `terraform fmt -check`, `terraform validate`, and `tflint`.
See `.github/workflows/terraform.yml`.
