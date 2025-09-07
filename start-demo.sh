#!/bin/bash

echo "🚀 Starting Demo Environment"
echo "============================"
echo ""

# Start payment service
echo "Starting payment service..."
docker run -d --name demo-payment-service \
  -p 8080:80 \
  --label com.datadoghq.ad.logs='[{"source": "nginx", "service": "payment-service"}]' \
  nginx:alpine

echo "✅ Service running on http://localhost:8080"
echo ""

# Send metrics continuously in background
echo "📊 Sending metrics to Datadog (running in background)..."
(
while true; do
  # 90% success rate
  if [ $((RANDOM % 10)) -lt 9 ]; then
    echo "payment.transaction.count:1|c|#status:success,service:payment,env:demo" | nc -u -w0 127.0.0.1 8125
    echo "payment.transaction.amount:$((RANDOM % 1000 + 100))|g|#service:payment,env:demo" | nc -u -w0 127.0.0.1 8125
  else
    echo "payment.transaction.count:1|c|#status:failed,service:payment,env:demo" | nc -u -w0 127.0.0.1 8125
  fi
  
  # Random latency
  latency=$((RANDOM % 500 + 50))
  echo "payment.transaction.latency:${latency}|h|#service:payment,env:demo" | nc -u -w0 127.0.0.1 8125
  
  sleep 2
done
) &

METRICS_PID=$!
echo "Metrics generator PID: $METRICS_PID"
echo "To stop metrics: kill $METRICS_PID"
echo ""

echo "✅ Demo environment ready!"
echo ""
echo "Next steps:"
echo "1. Check Datadog Metrics Explorer for 'payment.*' metrics"
echo "2. View your dashboard: https://app.datadoghq.eu/dashboard/gwx-a2j-ibv/"
echo "3. Run ./simulate-outage.sh to demo incident response"
echo ""
echo "To stop everything:"
echo "  docker stop demo-payment-service"
echo "  kill $METRICS_PID"