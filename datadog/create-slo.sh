#!/bin/bash

# Create a real SLO in Datadog
# This shows you understand SLO-driven reliability

echo "🎯 Creating SLO in Datadog"
echo "========================="
echo ""

# API Keys for demo account
DD_API_KEY="your-api-key-here"
DD_APP_KEY="your-app-key-here"

echo ""
echo "Creating Payment Service Availability SLO..."

curl -X POST "https://api.datadoghq.eu/api/v1/slo" \
-H "Content-Type: application/json" \
-H "DD-API-KEY: ${DD_API_KEY}" \
-H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
-d @- <<'EOF'
{
  "name": "Payment Service - 99.9% Availability",
  "description": "Ensures payment service maintains 99.9% availability with multi-window burn rate alerts",
  "tags": [
    "service:payment-service",
    "team:platform",
    "env:demo"
  ],
  "thresholds": [
    {
      "timeframe": "30d",
      "target": 99.9,
      "warning": 99.95
    },
    {
      "timeframe": "7d",
      "target": 99.9,
      "warning": 99.95
    }
  ],
  "type": "metric",
  "query": {
    "numerator": "sum:metrics.payment.success{*}.as_count()",
    "denominator": "sum:metrics.payment.total{*}.as_count()"
  }
}
EOF

echo ""
echo "✅ SLO Created!"
echo ""
echo "View your SLO at:"
echo "https://app.datadoghq.eu/slo/manage"
echo ""

echo "Creating Error Budget Alert..."

curl -X POST "https://api.datadoghq.eu/api/v1/monitor" \
-H "Content-Type: application/json" \
-H "DD-API-KEY: ${DD_API_KEY}" \
-H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
-d @- <<'EOF'
{
  "name": "Payment Service - Error Budget Burn Rate Alert",
  "type": "slo alert",
  "query": "burn_rate(\"slo_id\").over(\"time_window\") > burn_rate_threshold",
  "message": "🔥 **ERROR BUDGET BURN RATE ALERT**\n\nService: Payment Service\nBurn Rate: {{value}}x normal\nTime Window: {{time_window}}\n\n**Error Budget Status**:\nRemaining: {{error_budget_remaining}}%\n\n{{#is_alert}}\n🚫 FEATURE FREEZE RECOMMENDED\n{{/is_alert}}\n\n@slack-platform-team",
  "tags": ["slo:payment-availability", "team:platform"],
  "options": {
    "thresholds": {
      "critical": 14.4,
      "warning": 6
    }
  }
}
EOF

echo ""
echo "✅ Burn Rate Alert Created!"
echo ""
echo "Your SLO-driven reliability setup is complete!"
