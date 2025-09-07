#!/bin/bash

# Demo Script - Shows how the monitoring would work
# This demonstrates the actual commands and workflow

echo "🚀 Observability Platform Demo Script"
echo "======================================"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "1️⃣  Simulating High Error Rate Detection..."
echo "-------------------------------------------"
sleep 1

echo -e "${RED}⚠️  ALERT: High Error Rate Detected${NC}"
echo "   Service: payment-service"
echo "   Error Rate: 2.3% (threshold: 1%)"
echo "   Burn Rate: 14.4x (will exhaust budget in 2 days)"
echo ""

echo "2️⃣  Checking Error Budget Policy..."
echo "-------------------------------------------"
sleep 1

echo "   Current Error Budget: 45%"
echo -e "${YELLOW}   ⚠️  Policy: INCREASED RELIABILITY FOCUS${NC}"
echo "   - All deployments require extra testing"
echo "   - Post-deployment monitoring extended to 1 hour"
echo ""

echo "3️⃣  Running Diagnostic Commands..."
echo "-------------------------------------------"
sleep 1

echo "$ kubectl rollout history deployment/payment-service"
echo "deployment.apps/payment-service"
echo "REVISION  CHANGE-CAUSE"
echo "8         <none>"
echo -e "${RED}9         Deployed version 2.3.1 (15 minutes ago)${NC}"
echo ""

echo "$ kubectl logs -l app=payment-service --tail=5 | grep ERROR"
sleep 1
echo "2024-01-15T14:23:15.234Z ERROR NullPointerException at PaymentProcessor.java:156"
echo "2024-01-15T14:23:16.445Z ERROR Currency code is null"
echo "2024-01-15T14:23:17.667Z ERROR Failed to process payment: NPE"
echo ""

echo "4️⃣  Executing Recovery Procedure..."
echo "-------------------------------------------"
sleep 1

echo "$ kubectl rollout undo deployment/payment-service"
echo -e "${GREEN}✓ Rollback initiated${NC}"
echo "deployment.apps/payment-service rolled back"
echo ""

sleep 2

echo "5️⃣  Verifying Recovery..."
echo "-------------------------------------------"
echo "$ curl -s http://payment-service/health | jq .status"
echo -e "${GREEN}✓ \"healthy\"${NC}"
echo ""
echo "   Error Rate: 0.4% ✅"
echo "   Latency p95: 234ms ✅"
echo "   All systems operational"
echo ""

echo "6️⃣  MTTR Summary"
echo "-------------------------------------------"
echo "   Detection Time: 1 minute"
echo "   Investigation: 3 minutes"
echo "   Resolution: 2 minutes"
echo -e "${GREEN}   Total MTTR: 6 minutes${NC}"
echo ""

echo "✅ Demo Complete - Incident Resolved"