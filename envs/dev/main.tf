##############################################################################
# DEV — single-region, cost-optimized composition.
# Single NAT gateway, smaller instances, RDS Proxy off, no deletion protection.
##############################################################################

locals {
  name = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "sre"
  }
}

module "network" {
  source = "../../modules/network"

  name                 = local.name
  cidr_block           = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  data_subnet_cidrs    = var.data_subnet_cidrs
  single_nat_gateway   = true # cost optimization for dev
  tags                 = local.common_tags
}

module "compute" {
  source = "../../modules/compute"

  name               = local.name
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  instance_type      = "t3.small"
  min_size           = 1
  max_size           = 3
  desired_capacity   = 1
  app_port           = var.app_port
  health_check_path  = var.health_check_path

  enable_deletion_protection = false
  tags                       = local.common_tags
}

module "database" {
  source = "../../modules/database"

  name                  = local.name
  vpc_id                = module.network.vpc_id
  data_subnet_ids       = module.network.data_subnet_ids
  app_security_group_id = module.compute.app_security_group_id
  instance_class        = "db.t4g.medium"
  reader_count          = 0 # single instance for dev
  enable_rds_proxy      = false
  deletion_protection   = false
  tags                  = local.common_tags
}

module "cache" {
  source = "../../modules/cache"

  name                  = local.name
  vpc_id                = module.network.vpc_id
  data_subnet_ids       = module.network.data_subnet_ids
  app_security_group_id = module.compute.app_security_group_id
  node_type             = "cache.t4g.micro"
  num_cache_clusters    = 1 # single node for dev
  tags                  = local.common_tags
}
