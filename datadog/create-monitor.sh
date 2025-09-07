#!/bin/bash

# Create Monitor in Datadog via API
echo "🚨 Creating Monitors in Datadog"
echo "================================"
echo ""

# API Keys for demo account
DD_API_KEY="cebd641eea33f26fe551354ad85ed530"
DD_APP_KEY="c863c255c718ba4788d901b34741af94a63c2fb9"

echo ""
echo "Creating High CPU Usage Monitor..."

# Create CPU monitor
curl -X POST "https://api.datadoghq.eu/api/v1/monitor" \
-H "Content-Type: application/json" \
-H "DD-API-KEY: ${DD_API_KEY}" \
-H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
-d @- <<'EOF'
{
  "name": "High CPU Usage Alert",
  "type": "metric alert",
  "query": "avg(last_5m):avg:system.cpu.user{*} + avg:system.cpu.system{*} > 80",
  "message": "⚠️ **HIGH CPU USAGE DETECTED**\n\nCPU usage is above 80%\n\nCurrent value: {{value}}%\nThreshold: 80%\n\n**Recommended Actions:**\n1. Check running processes with `top` or `htop`\n2. Identify resource-intensive applications\n3. Consider scaling horizontally if sustained\n\n@slack-platform-team",
  "tags": ["env:production", "team:platform", "severity:warning"],
  "options": {
    "thresholds": {
      "critical": 90,
      "warning": 80
    },
    "notify_no_data": false,
    "notify_audit": false,
    "new_group_delay": 60,
    "evaluation_delay": 60
  }
}
EOF

echo ""
echo "Creating High Load Average Monitor..."

# Create load average monitor
curl -X POST "https://api.datadoghq.eu/api/v1/monitor" \
-H "Content-Type: application/json" \
-H "DD-API-KEY: ${DD_API_KEY}" \
-H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
-d @- <<'EOF'
{
  "name": "High System Load Alert",
  "type": "metric alert",
  "query": "avg(last_5m):avg:system.load.5{*} > 4",
  "message": "🔥 **HIGH SYSTEM LOAD**\n\n5-minute load average is above 4\n\nCurrent value: {{value}}\nThreshold: 4\n\n**Investigation Steps:**\n1. Check CPU and memory usage\n2. Review running processes\n3. Check for IO bottlenecks\n4. Consider emergency scaling\n\n{{#is_alert}}🚫 CRITICAL: Immediate action required{{/is_alert}}\n\n@slack-platform-team",
  "tags": ["env:production", "team:platform", "severity:critical"],
  "options": {
    "thresholds": {
      "critical": 4,
      "warning": 3
    },
    "notify_no_data": true,
    "no_data_timeframe": 10
  }
}
EOF

echo ""
echo "Creating Network Traffic Anomaly Monitor..."

# Create network anomaly monitor
curl -X POST "https://api.datadoghq.eu/api/v1/monitor" \
-H "Content-Type: application/json" \
-H "DD-API-KEY: ${DD_API_KEY}" \
-H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
-d @- <<'EOF'
{
  "name": "Network Traffic Anomaly Detection",
  "type": "query alert",
  "query": "avg(last_5m):anomalies(avg:system.net.bytes_sent{*}.as_rate(), 'basic', 2) >= 1",
  "message": "🌐 **NETWORK TRAFFIC ANOMALY**\n\nUnusual network traffic pattern detected\n\n**Potential Causes:**\n• DDoS attack\n• Data exfiltration\n• Backup or sync job\n• Traffic spike\n\nPlease investigate immediately.\n\n@slack-security-team @slack-platform-team",
  "tags": ["env:production", "team:platform", "type:anomaly"],
  "options": {
    "thresholds": {
      "critical": 1,
      "warning": 0.5
    },
    "notify_no_data": false,
    "require_full_window": false
  }
}
EOF

echo ""
echo "✅ All monitors created!"
echo ""
echo "View your monitors at:"
echo "https://app.datadoghq.eu/monitors/manage"
echo ""
echo "Monitor Summary:"
echo "• High CPU Usage Alert (>80%)"
echo "• High System Load Alert (>4)"  
echo "• Network Traffic Anomaly Detection"
echo ""
echo "These monitors will alert you to critical system issues!"