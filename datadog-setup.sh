#!/bin/bash

# Datadog Quick Setup Script
# Sets up real monitoring in your Datadog trial account

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🐕 Datadog Setup Guide${NC}"
echo "======================="
echo ""

echo -e "${YELLOW}Step 1: Install Datadog Agent${NC}"
echo "After creating your account, get your API key from:"
echo "https://app.datadoghq.com/organization-settings/api-keys"
echo ""

read -p "Enter your Datadog API key: " DD_API_KEY
export DD_API_KEY=$DD_API_KEY

echo ""
echo -e "${BLUE}Installing Datadog Agent in Docker...${NC}"

# Add Datadog agent to our docker-compose
cat >> docker-compose.override.yml << EOF
version: '3.8'

services:
  datadog-agent:
    image: gcr.io/datadoghq/agent:7
    container_name: datadog-agent
    environment:
      - DD_API_KEY=${DD_API_KEY}
      - DD_SITE=datadoghq.com
      - DD_APM_ENABLED=true
      - DD_LOGS_ENABLED=true
      - DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL=true
      - DD_CONTAINER_EXCLUDE="image:gcr.io/datadoghq/agent*"
      - DD_PROCESS_AGENT_ENABLED=true
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /proc/:/host/proc/:ro
      - /sys/fs/cgroup/:/host/sys/fs/cgroup:ro
    ports:
      - "8125:8125/udp"  # DogStatsD
      - "8126:8126"      # APM
EOF

docker-compose up -d datadog-agent

echo ""
echo -e "${GREEN}✅ Datadog Agent installed!${NC}"
echo ""

echo -e "${YELLOW}Step 2: Import Dashboard${NC}"
echo "1. Go to: https://app.datadoghq.com/dashboard/lists"
echo "2. Click 'New Dashboard'"
echo "3. Click 'Import Dashboard JSON'"
echo "4. Copy the content from: datadog/dashboards/golden-signals-dashboard.json"
echo ""

echo -e "${YELLOW}Step 3: Create Monitors${NC}"
echo "We'll create monitors via the API..."
echo ""

# Create a monitor using Datadog API
create_monitor() {
    local monitor_name=$1
    local query=$2
    local message=$3
    
    curl -X POST "https://api.datadoghq.com/api/v1/monitor" \
    -H "Content-Type: application/json" \
    -H "DD-API-KEY: ${DD_API_KEY}" \
    -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
    -d @- <<EOF
{
  "name": "${monitor_name}",
  "type": "metric alert",
  "query": "${query}",
  "message": "${message}",
  "tags": ["service:payment-demo", "env:demo"],
  "options": {
    "thresholds": {
      "critical": 1.0,
      "warning": 0.5
    },
    "notify_no_data": false,
    "notify_audit": false
  }
}
EOF
}

echo -e "${BLUE}Creating sample monitors...${NC}"

# High Error Rate Monitor
create_monitor \
  "Demo - High Error Rate" \
  "avg(last_5m):avg:docker.container.cpu.usage{container_name:payment-service} > 80" \
  "High CPU usage detected on payment service @slack-demo"

echo ""
echo -e "${GREEN}✅ Monitor created!${NC}"
echo ""

echo -e "${YELLOW}Step 4: Generate Custom Metrics${NC}"
echo "Sending sample metrics to Datadog..."

# Send custom metrics using dogstatsd
for i in {1..10}; do
    echo "payment.request.count:1|c|#service:payment,status:success" | nc -u -w0 127.0.0.1 8125
    echo "payment.request.latency:$((RANDOM % 500 + 100))|h|#service:payment" | nc -u -w0 127.0.0.1 8125
    sleep 1
done

echo ""
echo -e "${GREEN}✅ Metrics sent!${NC}"
echo ""

echo -e "${BLUE}📊 Your Datadog Setup is Complete!${NC}"
echo ""
echo "Check these in your Datadog account:"
echo "  • Infrastructure List: https://app.datadoghq.com/infrastructure"
echo "  • Metrics Explorer: https://app.datadoghq.com/metric/explorer"
echo "  • Monitors: https://app.datadoghq.com/monitors"
echo "  • Dashboards: https://app.datadoghq.com/dashboard/lists"
echo ""
echo "Next steps:"
echo "1. Import the dashboard JSON"
echo "2. Create an SLO from the UI"
echo "3. Set up a notification channel"
echo ""