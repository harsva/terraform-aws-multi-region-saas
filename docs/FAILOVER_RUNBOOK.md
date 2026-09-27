# Failover Runbook

Operational runbook for the multi-region active/passive topology. Written from an
SRE / incident-response perspective.

## Normal state

- **Primary (us-east-1)** serves all live traffic via Route 53 failover routing.
- **Secondary (us-west-2)** is a warm standby: full compute + cache provisioned,
  receiving no traffic while the primary is healthy.
- Route 53 health checks probe the primary ALB every 30s (3 failures = unhealthy).

## Automatic regional failover

1. Primary ALB health check fails 3 consecutive times.
2. Route 53 marks the PRIMARY record unhealthy and resolves the app FQDN to the
   SECONDARY ALB.
3. Clients reconnect to the secondary region (DNS TTL governs propagation).

**SRE action items during a regional failover:**
- Confirm the secondary ASG has scaled to handle full production load.
- Verify data replication/restore strategy for Aurora (this repo provisions
  independent regional clusters; cross-region replication is a documented extension).
- Open an incident, capture timeline, begin RCA.

## Database failover (within a region)

- Aurora runs a writer + reader across AZs. On writer failure, Aurora promotes a
  reader (promotion_tier ordering).
- **RDS Proxy** holds the application-facing endpoint. During failover it preserves
  the connection pool, so the app does **not** experience a connection-exhaustion
  storm — it briefly pauses in-flight queries and resumes against the new writer.
- App connection string points at the **proxy endpoint**, never the cluster endpoint.

## Redis / distributed locks

- ElastiCache replication group runs Multi-AZ with automatic failover.
- Application distributed locks (e.g. Redlock-style) must use short TTLs and
  fencing tokens so a failover does not leave a stale lock held.

## Deployment / rollback

- The ASG uses a **rolling instance refresh** (min 90% healthy). A bad deploy is
  rolled back by reverting the launch template version and triggering a new refresh.
- ALB target group uses `slow_start` so fresh instances warm up before taking full load.
