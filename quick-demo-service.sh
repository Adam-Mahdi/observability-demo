#!/bin/bash

# Quick service that generates metrics for Datadog
echo "🚀 Starting demo payment service..."

# Run a simple web server that we can monitor
docker run -d --name demo-payment-service \
  -p 8080:80 \
  --label com.datadoghq.ad.logs='[{"source": "nginx", "service": "payment-service"}]' \
  nginx:alpine

echo "✅ Service running on http://localhost:8080"
echo ""
echo "📊 Sending custom metrics to Datadog..."

# Send custom business metrics to Datadog
for i in {1..100}; do
  # Random success/failure (90% success rate)
  if [ $((RANDOM % 10)) -lt 9 ]; then
    echo "payment.transaction.count:1|c|#status:success,service:payment,env:demo" | nc -u -w0 127.0.0.1 8125
    echo "payment.transaction.amount:$((RANDOM % 1000 + 100))|g|#service:payment,env:demo" | nc -u -w0 127.0.0.1 8125
  else
    echo "payment.transaction.count:1|c|#status:failed,service:payment,env:demo" | nc -u -w0 127.0.0.1 8125
  fi
  
  # Random latency
  latency=$((RANDOM % 500 + 50))
  echo "payment.transaction.latency:${latency}|h|#service:payment,env:demo" | nc -u -w0 127.0.0.1 8125
  
  echo "Sent transaction $i (latency: ${latency}ms)"
  sleep 2
done

echo ""
echo "✅ Metrics sent to Datadog!"
echo "Check your dashboard for payment.transaction.* metrics"