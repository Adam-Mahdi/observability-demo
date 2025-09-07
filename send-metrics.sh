#!/bin/bash

echo "📊 Sending payment metrics to Datadog..."
echo "======================================="
echo ""

# Check if Datadog agent is running
if ! docker ps | grep -q datadog; then
    echo "⚠️  Datadog agent not running!"
    echo "Start it with: docker start dd-agent"
    exit 1
fi

echo "Sending 50 payment transactions..."
echo ""

for i in {1..50}; do
    # 90% success rate
    if [ $((RANDOM % 10)) -lt 9 ]; then
        # Success metrics
        echo -n "metrics.payment.success:1|c|#env:production" > /dev/udp/127.0.0.1/8125
        echo -n "metrics.payment.latency:$((RANDOM % 300 + 50))|ms|#env:production" > /dev/udp/127.0.0.1/8125
        echo -n "metrics.payment.amount:$((RANDOM % 1000 + 100))|g|#env:production" > /dev/udp/127.0.0.1/8125
        echo "✅ Transaction $i: SUCCESS"
    else
        # Failure metrics
        echo -n "metrics.payment.failure:1|c|#env:production" > /dev/udp/127.0.0.1/8125
        echo "❌ Transaction $i: FAILED"
    fi
    
    # Also send generic counter
    echo -n "metrics.payment.total:1|c|#env:production" > /dev/udp/127.0.0.1/8125
    
    sleep 0.5
done

echo ""
echo "✅ Done! Check Datadog for 'metrics.payment.*' metrics"
echo ""
echo "Direct link to Metrics Explorer:"
echo "https://app.datadoghq.eu/metric/explorer?exp_metric=metrics.payment.total&exp_scope=env%3Aproduction&exp_agg=sum&exp_row_type=metric"