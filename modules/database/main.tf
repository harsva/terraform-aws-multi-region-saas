resource "random_password" "master" {
  length  = 24
  special = false
}

resource "aws_secretsmanager_secret" "db" {
  name       = "${var.name}-db-credentials"
  kms_key_id = var.kms_key_arn
  tags       = var.tags
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master.result
  })
}

# ---------------------------------------------------------------------------
# Networking for the DB tier
# ---------------------------------------------------------------------------
resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnets"
  subnet_ids = var.data_subnet_ids
  tags       = merge(var.tags, { Name = "${var.name}-db-subnets" })
}

resource "aws_security_group" "db" {
  name_prefix = "${var.name}-db-"
  description = "Aurora/RDS Proxy: ingress from app tier on 3306"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-db-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "MySQL from app tier"
  referenced_security_group_id = var.app_security_group_id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
}

# Allow the proxy (same SG) to reach the cluster.
resource "aws_vpc_security_group_ingress_rule" "db_self" {
  security_group_id            = aws_security_group.db.id
  description                  = "MySQL from proxy (self-referencing)"
  referenced_security_group_id = aws_security_group.db.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "db_all" {
  security_group_id = aws_security_group.db.id
  description       = "All egress"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ---------------------------------------------------------------------------
# Aurora MySQL cluster (Multi-AZ via multiple instances)
# ---------------------------------------------------------------------------
resource "aws_rds_cluster" "this" {
  cluster_identifier     = "${var.name}-aurora"
  engine                 = "aurora-mysql"
  engine_version         = var.engine_version
  database_name          = var.database_name
  master_username        = var.master_username
  master_password        = random_password.master.result
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]

  backup_retention_period      = var.backup_retention_days
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "sun:04:30-sun:05:30"

  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = !var.deletion_protection
  final_snapshot_identifier = var.deletion_protection ? "${var.name}-aurora-final" : null

  enabled_cloudwatch_logs_exports = ["audit", "error", "slowquery"]

  tags = merge(var.tags, { Name = "${var.name}-aurora" })

  lifecycle {
    ignore_changes = [master_password]
  }
}

# Writer + reader instances across AZs. Count = 1 writer + N readers.
resource "aws_rds_cluster_instance" "this" {
  count                = 1 + var.reader_count
  identifier           = "${var.name}-aurora-${count.index}"
  cluster_identifier   = aws_rds_cluster.this.id
  instance_class       = var.instance_class
  engine               = aws_rds_cluster.this.engine
  engine_version       = aws_rds_cluster.this.engine_version
  db_subnet_group_name = aws_db_subnet_group.this.name

  performance_insights_enabled = true
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds_monitoring.arn

  # Failover priority: instance 0 is preferred writer (tier 0).
  promotion_tier = count.index

  tags = merge(var.tags, { Name = "${var.name}-aurora-${count.index}" })
}

resource "aws_iam_role" "rds_monitoring" {
  name = "${var.name}-rds-enhanced-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ---------------------------------------------------------------------------
# RDS Proxy — graceful failover + connection pooling (prevents connection
# exhaustion during scaling/failover events).
# ---------------------------------------------------------------------------
resource "aws_iam_role" "proxy" {
  count = var.enable_rds_proxy ? 1 : 0
  name  = "${var.name}-rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "rds.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "proxy_secrets" {
  count = var.enable_rds_proxy ? 1 : 0
  name  = "${var.name}-rds-proxy-secrets"
  role  = aws_iam_role.proxy[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = aws_secretsmanager_secret.db.arn
      }, {
      Effect   = "Allow"
      Action   = ["kms:Decrypt"]
      Resource = "*"
      Condition = {
        StringEquals = { "kms:ViaService" = "secretsmanager.*.amazonaws.com" }
      }
    }]
  })
}

resource "aws_db_proxy" "this" {
  count                  = var.enable_rds_proxy ? 1 : 0
  name                   = "${var.name}-proxy"
  engine_family          = "MYSQL"
  role_arn               = aws_iam_role.proxy[0].arn
  vpc_subnet_ids         = var.data_subnet_ids
  vpc_security_group_ids = [aws_security_group.db.id]
  require_tls            = true
  idle_client_timeout    = 1800

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret.db.arn
  }

  tags = merge(var.tags, { Name = "${var.name}-proxy" })
}

resource "aws_db_proxy_default_target_group" "this" {
  count         = var.enable_rds_proxy ? 1 : 0
  db_proxy_name = aws_db_proxy.this[0].name

  connection_pool_config {
    max_connections_percent      = 90
    max_idle_connections_percent = 50
    connection_borrow_timeout    = 120
  }
}

resource "aws_db_proxy_target" "this" {
  count                 = var.enable_rds_proxy ? 1 : 0
  db_proxy_name         = aws_db_proxy.this[0].name
  target_group_name     = aws_db_proxy_default_target_group.this[0].name
  db_cluster_identifier = aws_rds_cluster.this.cluster_identifier
}
