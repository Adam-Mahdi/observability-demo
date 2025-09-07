#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}💥 SIMULATING PAYMENT SERVICE OUTAGE${NC}"
echo "===================================="
echo ""
echo "Current status: All systems operational ✅"
echo ""
read -p "Press Enter to simulate service failure..."

# Kill the service
docker stop demo-payment-service 2>/dev/null

echo -e "${RED}⚠️  SERVICE DOWN!${NC}"
echo "Payment service is not responding"
echo ""

# Send failure metrics
echo -e "${YELLOW}Sending error metrics to Datadog...${NC}"
for i in {1..20}; do
  echo "payment.transaction.count:1|c|#status:error,service:payment,env:demo" | nc -u -w0 127.0.0.1 8125
  echo "payment.service.health:0|g|#service:payment,env:demo" | nc -u -w0 127.0.0.1 8125
done

echo ""
echo -e "${RED}Check your Datadog monitors - they should be alerting!${NC}"
echo ""
read -p "Press Enter to recover the service..."

# Restart service
docker start demo-payment-service 2>/dev/null || docker run -d --name demo-payment-service -p 8080:80 nginx:alpine

echo -e "${GREEN}✅ SERVICE RECOVERED${NC}"
echo ""

# Send recovery metrics
for i in {1..10}; do
  echo "payment.transaction.count:1|c|#status:success,service:payment,env:demo" | nc -u -w0 127.0.0.1 8125
  echo "payment.service.health:1|g|#service:payment,env:demo" | nc -u -w0 127.0.0.1 8125
done

echo -e "${GREEN}Recovery complete! Service is healthy.${NC}"
echo ""
echo "Key metrics:"
echo "- Time to detect: <1 minute (automated)"
echo "- Time to recover: <2 minutes"
echo "- Customer impact: ~40 failed transactions"
echo ""
echo "This demonstrates real incident response capability!"