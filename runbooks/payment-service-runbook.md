# 💳 Payment Service Runbook

## Service Overview

The Payment Service handles all payment processing for our e-commerce platform, integrating with Stripe, PayPal, and internal wallet systems.

### Architecture
```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│ API Gateway │────▶│Payment Service│────▶│Payment Providers│
└─────────────┘     └──────────────┘     └─────────────────┘
                            │
                    ┌───────▼────────┐
                    │  PostgreSQL    │
                    │  Payment DB    │
                    └────────────────┘
```

### Key Metrics
- **SLO**: 99.9% availability (43.2 min downtime/month allowed)
- **Latency Target**: p95 < 500ms
- **Error Budget**: 0.1% (currently 0.05% consumed this month)

### Dependencies
- PostgreSQL (payment-db.rds.amazonaws.com)
- Redis Cache (payment-cache.redis.amazonaws.com)
- Stripe API
- PayPal API
- Order Service
- Notification Service

## 🚨 Common Issues and Resolutions

### Issue 1: High Error Rate (>1%)

**Symptoms:**
- Alert: "High Error Rate - Payment Service"
- Customer reports of failed payments
- Error rate spike in Datadog dashboard

**Investigation:**
```bash
# Check recent deployments
kubectl rollout history deployment/payment-service -n production

# Check current pod status
kubectl get pods -l app=payment-service -n production

# View recent logs
kubectl logs -l app=payment-service -n production --tail=100 | grep ERROR

# Check database connections
kubectl exec -it $(kubectl get pod -l app=payment-service -n production -o jsonpath="{.items[0].metadata.name}") -n production -- psql -h payment-db.rds.amazonaws.com -U payment_user -c "SELECT state, count(*) FROM pg_stat_activity GROUP BY state;"
```

**Resolution Steps:**
1. **If recent deployment (<1 hour):**
   ```bash
   # Rollback to previous version
   kubectl rollout undo deployment/payment-service -n production
   
   # Verify rollback
   kubectl rollout status deployment/payment-service -n production
   ```

2. **If payment provider issue:**
   ```bash
   # Check Stripe status
   curl -s https://status.stripe.com/api/v2/status.json | jq .status.indicator
   
   # Enable circuit breaker
   kubectl set env deployment/payment-service CIRCUIT_BREAKER_ENABLED=true -n production
   ```

3. **If database issue:**
   ```bash
   # Check connection pool
   kubectl exec -it $(kubectl get pod -l app=payment-service -n production -o jsonpath="{.items[0].metadata.name}") -n production -- env | grep DB_POOL
   
   # Increase pool size temporarily
   kubectl set env deployment/payment-service DB_POOL_SIZE=50 -n production
   ```

### Issue 2: High Latency (p95 > 500ms)

**Symptoms:**
- Alert: "High Latency - Payment Service"
- Slow checkout experience
- Queue buildup

**Investigation:**
```bash
# Check CPU and memory usage
kubectl top pods -l app=payment-service -n production

# Check slow queries
kubectl exec -it payment-db-client -n production -- psql -h payment-db.rds.amazonaws.com -U payment_user -c "SELECT query, mean_time, calls FROM pg_stat_statements WHERE mean_time > 100 ORDER BY mean_time DESC LIMIT 10;"

# Check cache hit rate
kubectl exec -it $(kubectl get pod -l app=payment-service -n production -o jsonpath="{.items[0].metadata.name}") -n production -- redis-cli -h payment-cache.redis.amazonaws.com INFO stats | grep hit
```

**Resolution Steps:**
1. **Scale horizontally:**
   ```bash
   kubectl scale deployment/payment-service --replicas=10 -n production
   ```

2. **Clear cache if stale:**
   ```bash
   kubectl exec -it $(kubectl get pod -l app=payment-service -n production -o jsonpath="{.items[0].metadata.name}") -n production -- redis-cli -h payment-cache.redis.amazonaws.com FLUSHDB
   ```

3. **Enable read replicas:**
   ```bash
   kubectl set env deployment/payment-service READ_REPLICA_ENABLED=true -n production
   ```

### Issue 3: Payment Provider Integration Failure

**Symptoms:**
- Specific payment method failing
- Webhook errors
- Timeout errors

**Investigation:**
```bash
# Check provider-specific errors
kubectl logs -l app=payment-service -n production --tail=500 | grep -E "(stripe|paypal|wallet)"

# Test provider connectivity
kubectl exec -it $(kubectl get pod -l app=payment-service -n production -o jsonpath="{.items[0].metadata.name}") -n production -- curl -I https://api.stripe.com/v1/charges

# Check webhook logs
kubectl logs -l app=payment-webhook-processor -n production --tail=100
```

**Resolution Steps:**
1. **Rotate API keys if authentication errors:**
   ```bash
   # Update secret
   kubectl create secret generic payment-provider-keys \
     --from-literal=stripe_key=$NEW_STRIPE_KEY \
     --from-literal=paypal_key=$NEW_PAYPAL_KEY \
     --dry-run=client -o yaml | kubectl apply -f - -n production
   
   # Restart pods to pick up new keys
   kubectl rollout restart deployment/payment-service -n production
   ```

2. **Enable fallback provider:**
   ```bash
   kubectl set env deployment/payment-service FALLBACK_PROVIDER_ENABLED=true -n production
   ```

### Issue 4: Database Connection Pool Exhaustion

**Symptoms:**
- "connection pool exhausted" errors
- Timeouts on database operations
- Cascading failures

**Quick Fix:**
```bash
# Kill idle connections
kubectl exec -it payment-db-client -n production -- psql -h payment-db.rds.amazonaws.com -U payment_user -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'idle' AND state_change < now() - interval '10 minutes';"

# Increase pool size
kubectl set env deployment/payment-service DB_POOL_SIZE=100 DB_POOL_TIMEOUT=30 -n production

# Scale service to distribute load
kubectl scale deployment/payment-service --replicas=15 -n production
```

## 🔧 Maintenance Procedures

### Rolling Deployment
```bash
# Set image
kubectl set image deployment/payment-service payment-service=payment-service:v2.0.0 -n production

# Watch rollout
kubectl rollout status deployment/payment-service -n production -w

# Verify health
curl -s https://api.company.com/health/payment | jq .
```

### Database Maintenance
```bash
# Create backup before maintenance
kubectl exec -it payment-db-client -n production -- pg_dump -h payment-db.rds.amazonaws.com -U payment_user payment_db > backup-$(date +%Y%m%d-%H%M%S).sql

# Run VACUUM and ANALYZE
kubectl exec -it payment-db-client -n production -- psql -h payment-db.rds.amazonaws.com -U payment_user -c "VACUUM ANALYZE;"
```

## 📞 Escalation Matrix

| Severity | Condition | Primary Contact | Backup Contact | Response Time |
|----------|-----------|-----------------|----------------|---------------|
| P1 | Service Down | On-call Engineer | Platform Lead | 5 minutes |
| P1 | Data Loss Risk | Platform Lead | CTO | Immediate |
| P2 | Degraded Performance | On-call Engineer | Senior SRE | 15 minutes |
| P3 | Single Provider Issue | On-call Engineer | None | 30 minutes |
| P4 | Minor Issues | Ticket | None | Next business day |

### Contacts
- **On-call**: Check PagerDuty or `@oncall` in Slack
- **Platform Lead**: John Smith (+1-555-0100)
- **Database Team**: `#database-team` in Slack
- **Security Team**: security@company.com
- **Payment Provider Support**:
  - Stripe: dashboard.stripe.com/support
  - PayPal: paypal.com/merchantsupport

## 🔍 Debugging Commands

### Service Health Check
```bash
# Comprehensive health check
kubectl exec -it $(kubectl get pod -l app=payment-service -n production -o jsonpath="{.items[0].metadata.name}") -n production -- curl -s localhost:8080/health/detailed | jq .
```

### View Distributed Traces
```bash
# Get trace for failed payment
echo "Check Datadog APM: https://app.datadoghq.com/apm/traces?query=service:payment-service status:error"
```

### Database Diagnostics
```bash
# Active queries
kubectl exec -it payment-db-client -n production -- psql -h payment-db.rds.amazonaws.com -U payment_user -c "SELECT pid, now() - query_start as duration, state, query FROM pg_stat_activity WHERE state != 'idle' ORDER BY duration DESC;"

# Table locks
kubectl exec -it payment-db-client -n production -- psql -h payment-db.rds.amazonaws.com -U payment_user -c "SELECT * FROM pg_locks WHERE NOT granted;"

# Index usage
kubectl exec -it payment-db-client -n production -- psql -h payment-db.rds.amazonaws.com -U payment_user -c "SELECT schemaname, tablename, indexname, idx_scan FROM pg_stat_user_indexes ORDER BY idx_scan;"
```

### Cache Diagnostics
```bash
# Redis memory usage
kubectl exec -it $(kubectl get pod -l app=payment-service -n production -o jsonpath="{.items[0].metadata.name}") -n production -- redis-cli -h payment-cache.redis.amazonaws.com INFO memory

# Cache key patterns
kubectl exec -it $(kubectl get pod -l app=payment-service -n production -o jsonpath="{.items[0].metadata.name}") -n production -- redis-cli -h payment-cache.redis.amazonaws.com --scan --pattern "payment:*" | head -20
```

## 📊 Dashboards & Monitoring

- [Payment Service Main Dashboard](https://app.datadoghq.com/dashboard/payment-service-main)
- [Payment Provider Status](https://app.datadoghq.com/dashboard/payment-providers)
- [Database Performance](https://app.datadoghq.com/dashboard/payment-db-performance)
- [Error Analysis](https://app.datadoghq.com/dashboard/payment-errors)
- [SLO Dashboard](https://app.datadoghq.com/slo/payment-service-availability)

## 🔄 Recovery Procedures

### Complete Service Recovery
```bash
#!/bin/bash
# Full recovery script

# 1. Check and fix database
kubectl exec -it payment-db-client -n production -- psql -h payment-db.rds.amazonaws.com -U payment_user -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'idle';"

# 2. Clear cache
kubectl exec -it $(kubectl get pod -l app=payment-service -n production -o jsonpath="{.items[0].metadata.name}") -n production -- redis-cli -h payment-cache.redis.amazonaws.com FLUSHDB

# 3. Restart service with increased resources
kubectl set resources deployment/payment-service -n production --limits=cpu=2000m,memory=4Gi --requests=cpu=1000m,memory=2Gi
kubectl rollout restart deployment/payment-service -n production

# 4. Scale up
kubectl scale deployment/payment-service --replicas=20 -n production

# 5. Verify recovery
sleep 60
kubectl get pods -l app=payment-service -n production
curl -s https://api.company.com/health/payment | jq .

# 6. Enable monitoring
kubectl set env deployment/payment-service ENHANCED_MONITORING=true -n production
```

## 📝 Post-Incident Actions

1. Create incident ticket in Jira
2. Update status page
3. Schedule post-mortem (within 48 hours)
4. Update this runbook with findings
5. Share learnings in #platform-team channel

## 🔗 Related Documentation

- [Payment Service Architecture](https://docs.company.com/payment-service/architecture)
- [Database Schema](https://docs.company.com/payment-service/database)
- [API Documentation](https://api.company.com/docs/payment)
- [Security Considerations](https://docs.company.com/payment-service/security)
- [Disaster Recovery Plan](https://docs.company.com/payment-service/dr)

---

**Last Updated**: 2024-01-15
**Version**: 2.1.0
**Maintained By**: Platform Team