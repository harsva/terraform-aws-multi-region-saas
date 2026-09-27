##############################################################################
# PROD — multi-region active/passive SaaS platform
#
# Primary region serves live traffic; secondary region is a warm standby.
# Route 53 failover routing flips traffic to secondary when the primary ALB
# health check fails.
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

# ---------------------------------------------------------------------------
# PRIMARY REGION
# ---------------------------------------------------------------------------
module "network_primary" {
  source    = "../../modules/network"
  providers = { aws = aws.primary }

  name                 = "${local.name}-primary"
  cidr_block           = var.primary_vpc_cidr
  azs                  = var.primary_azs
  public_subnet_cidrs  = var.primary_public_subnet_cidrs
  private_subnet_cidrs = var.primary_private_subnet_cidrs
  data_subnet_cidrs    = var.primary_data_subnet_cidrs
  single_nat_gateway   = false
  tags                 = local.common_tags
}

module "compute_primary" {
  source    = "../../modules/compute"
  providers = { aws = aws.primary }

  name               = "${local.name}-primary"
  vpc_id             = module.network_primary.vpc_id
  public_subnet_ids  = module.network_primary.public_subnet_ids
  private_subnet_ids = module.network_primary.private_subnet_ids
  instance_type      = var.instance_type
  min_size           = var.asg_min_size
  max_size           = var.asg_max_size
  desired_capacity   = var.asg_desired_capacity
  app_port           = var.app_port
  health_check_path  = var.health_check_path

  enable_deletion_protection = true
  tags                       = local.common_tags
}

module "database_primary" {
  source    = "../../modules/database"
  providers = { aws = aws.primary }

  name                  = "${local.name}-primary"
  vpc_id                = module.network_primary.vpc_id
  data_subnet_ids       = module.network_primary.data_subnet_ids
  app_security_group_id = module.compute_primary.app_security_group_id
  instance_class        = var.db_instance_class
  reader_count          = 1
  enable_rds_proxy      = true
  deletion_protection   = true
  tags                  = local.common_tags
}

module "cache_primary" {
  source    = "../../modules/cache"
  providers = { aws = aws.primary }

  name                  = "${local.name}-primary"
  vpc_id                = module.network_primary.vpc_id
  data_subnet_ids       = module.network_primary.data_subnet_ids
  app_security_group_id = module.compute_primary.app_security_group_id
  node_type             = var.cache_node_type
  num_cache_clusters    = 2
  tags                  = local.common_tags
}

# ---------------------------------------------------------------------------
# SECONDARY REGION (warm standby)
# ---------------------------------------------------------------------------
module "network_secondary" {
  source    = "../../modules/network"
  providers = { aws = aws.secondary }

  name                 = "${local.name}-secondary"
  cidr_block           = var.secondary_vpc_cidr
  azs                  = var.secondary_azs
  public_subnet_cidrs  = var.secondary_public_subnet_cidrs
  private_subnet_cidrs = var.secondary_private_subnet_cidrs
  data_subnet_cidrs    = var.secondary_data_subnet_cidrs
  single_nat_gateway   = false
  tags                 = local.common_tags
}

module "compute_secondary" {
  source    = "../../modules/compute"
  providers = { aws = aws.secondary }

  name               = "${local.name}-secondary"
  vpc_id             = module.network_secondary.vpc_id
  public_subnet_ids  = module.network_secondary.public_subnet_ids
  private_subnet_ids = module.network_secondary.private_subnet_ids
  instance_type      = var.instance_type
  min_size           = var.asg_min_size
  max_size           = var.asg_max_size
  desired_capacity   = var.asg_desired_capacity
  app_port           = var.app_port
  health_check_path  = var.health_check_path

  enable_deletion_protection = true
  tags                       = local.common_tags
}

module "cache_secondary" {
  source    = "../../modules/cache"
  providers = { aws = aws.secondary }

  name                  = "${local.name}-secondary"
  vpc_id                = module.network_secondary.vpc_id
  data_subnet_ids       = module.network_secondary.data_subnet_ids
  app_security_group_id = module.compute_secondary.app_security_group_id
  node_type             = var.cache_node_type
  num_cache_clusters    = 2
  tags                  = local.common_tags
}

# ---------------------------------------------------------------------------
# Route 53 failover (records live in the primary provider; global service)
# ---------------------------------------------------------------------------
module "dns_primary" {
  source    = "../../modules/dns"
  providers = { aws = aws.primary }
  count     = var.hosted_zone_id != "" ? 1 : 0

  name                  = local.name
  hosted_zone_id        = var.hosted_zone_id
  record_name           = var.app_fqdn
  region_role           = "PRIMARY"
  alb_dns_name          = module.compute_primary.alb_dns_name
  alb_zone_id           = module.compute_primary.alb_zone_id
  health_check_path     = var.health_check_path
  health_check_protocol = "HTTP"
  health_check_port     = 80
  tags                  = local.common_tags
}

module "dns_secondary" {
  source    = "../../modules/dns"
  providers = { aws = aws.primary }
  count     = var.hosted_zone_id != "" ? 1 : 0

  name                  = local.name
  hosted_zone_id        = var.hosted_zone_id
  record_name           = var.app_fqdn
  region_role           = "SECONDARY"
  alb_dns_name          = module.compute_secondary.alb_dns_name
  alb_zone_id           = module.compute_secondary.alb_zone_id
  health_check_path     = var.health_check_path
  health_check_protocol = "HTTP"
  health_check_port     = 80
  tags                  = local.common_tags
}
