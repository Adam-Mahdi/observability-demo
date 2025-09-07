#!/bin/bash

# Simulate a Real Incident for Demo
# This shows the observability platform detecting and helping resolve issues

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${BLUE}🎬 LIVE INCIDENT SIMULATION${NC}"
echo "================================"
echo ""

echo "Current state: All systems operational ✅"
echo "Error rate: 0.4%"
echo "P95 Latency: 234ms"
echo "Error budget remaining: 72%"
echo ""

read -p "Press Enter to simulate a deployment bug..."
echo ""

echo -e "${YELLOW}📦 Deploying payment-service v2.3.1...${NC}"
sleep 2

# Inject errors by modifying the service
echo -e "${RED}⚠️  ALERT: High Error Rate Detected!${NC}"
echo "Time: $(date '+%H:%M:%S')"
echo "Service: payment-service"
echo "Error Rate: 15.3% (threshold: 1%)"
echo "Burn Rate: 14.4x"
echo ""

echo -e "${RED}🔥 Error Budget Policy: ACTIVE${NC}"
echo "Budget Remaining: 68% → 45% (rapidly decreasing)"
echo "Policy: Feature freeze recommended"
echo ""

echo "📱 Paging on-call engineer..."
sleep 2
echo -e "${GREEN}✓ Adam acknowledged (response time: 45 seconds)${NC}"
echo ""

echo -e "${BLUE}🔍 Running diagnostics...${NC}"
echo "$ curl http://localhost:8081/api/payment"
curl -s http://localhost:8081/api/payment | jq '.' 2>/dev/null || echo '{"error": "Payment processing failed"}'
echo ""

echo "$ docker logs payment-service --tail 5"
echo "2024-01-15T14:23:15.234Z ERROR NullPointerException at PaymentProcessor.java:156"
echo "2024-01-15T14:23:16.445Z ERROR Currency validation failed: null"
echo "2024-01-15T14:23:17.667Z ERROR Payment rejected: invalid currency"
echo ""

echo -e "${BLUE}📊 Checking Grafana dashboard...${NC}"
echo "→ Error spike started 3 minutes ago"
echo "→ Correlates with deployment of v2.3.1"
echo "→ Affecting 15% of payment requests"
echo ""

read -p "Press Enter to execute rollback..."
echo ""

echo -e "${GREEN}🔄 Rolling back to v2.3.0...${NC}"
docker restart payment-service 2>/dev/null
sleep 3

echo "✓ Rollback completed"
echo ""

echo -e "${GREEN}📈 Monitoring recovery...${NC}"
for i in {1..5}; do
    error_rate=$((15 - i * 3))
    if [ $error_rate -lt 1 ]; then
        error_rate="0.4"
    fi
    echo "  Error rate: ${error_rate}%"
    sleep 1
done

echo ""
echo -e "${GREEN}✅ INCIDENT RESOLVED${NC}"
echo "Duration: 6 minutes"
echo "Customer impact: ~2,300 failed payments"
echo "Error budget consumed: 0.23%"
echo ""

echo "📋 Post-Incident Actions:"
echo "  ✓ Rollback successful"
echo "  ✓ Error rate back to normal (0.4%)"
echo "  ✓ Creating incident ticket"
echo "  ✓ Scheduling post-mortem"
echo ""

echo -e "${BLUE}📊 MTTR Breakdown:${NC}"
echo "  Detection: 1 minute (automated)"
echo "  Response: 1 minute"
echo "  Investigation: 2 minutes"
echo "  Resolution: 2 minutes"
echo "  Total: 6 minutes"
echo ""

echo -e "${GREEN}Key Success Factors:${NC}"
echo "  • Multi-window burn rate prevented false positive"
echo "  • Error budget policy guided response"
echo "  • Runbook provided exact commands"
echo "  • Grafana dashboard showed correlation"
echo "  • Quick rollback capability"