project          = "saas-platform"
environment      = "prod"
primary_region   = "us-east-1"
secondary_region = "us-west-2"

instance_type        = "t3.medium"
asg_min_size         = 3
asg_max_size         = 12
asg_desired_capacity = 3

db_instance_class = "db.r6g.large"
cache_node_type   = "cache.r6g.large"

# Set these to enable Route 53 failover routing:
# hosted_zone_id = "Z0123456789ABCDEFGHIJ"
# app_fqdn       = "app.yourdomain.com"
