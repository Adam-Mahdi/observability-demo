#!/bin/bash

# Quick Setup Script for Live Demo
# This creates a WORKING observability stack in minutes

echo "🚀 Setting up Live Observability Demo"
echo "====================================="

# Check Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is required. Please install Docker first."
    exit 1
fi

# Create necessary directories
echo "📁 Creating directory structure..."
mkdir -p monitoring/grafana/dashboards
mkdir -p monitoring/grafana/datasources
mkdir -p demo-app
mkdir -p data/prometheus
mkdir -p data/grafana

# Create Prometheus config
echo "📝 Creating Prometheus configuration..."
cat > monitoring/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

rule_files:
  - '/etc/prometheus/alerts.yml'

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'payment-service'
    static_configs:
      - targets: ['payment-service:80']
    metrics_path: '/metrics'

  - job_name: 'order-service'
    static_configs:
      - targets: ['order-service:80']
    metrics_path: '/metrics'

  - job_name: 'redis'
    static_configs:
      - targets: ['redis:6379']
EOF

# Create Grafana datasource
echo "📊 Configuring Grafana datasources..."
cat > monitoring/grafana/datasources/prometheus.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true

  - name: Jaeger
    type: jaeger
    access: proxy
    url: http://jaeger:16686
    editable: true
EOF

# Create a sample Grafana dashboard
echo "📈 Creating Grafana dashboard..."
cat > monitoring/grafana/dashboards/dashboard.yml << 'EOF'
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    options:
      path: /etc/grafana/provisioning/dashboards
EOF

# Create sample app configs
echo "🔧 Setting up demo applications..."
cat > demo-app/payment.conf << 'EOF'
server {
    listen 80;
    server_name payment-service;

    location / {
        return 200 '{"service": "payment", "status": "healthy", "version": "2.3.0"}';
        add_header Content-Type application/json;
    }

    location /api/payment {
        # Simulate random latency and errors
        set $random $msec;
        if ($random ~ [0-2]$) {
            return 500 '{"error": "Payment processing failed"}';
        }
        if ($random ~ [3-4]$) {
            return 200 '{"status": "slow", "latency": "800ms"}';
        }
        return 200 '{"status": "success", "transaction_id": "$request_id"}';
        add_header Content-Type application/json;
    }

    location /metrics {
        return 200 '# HELP payment_requests_total Total payment requests
# TYPE payment_requests_total counter
payment_requests_total{status="success"} 1234
payment_requests_total{status="error"} 42
# HELP payment_latency_seconds Payment processing latency
# TYPE payment_latency_seconds histogram
payment_latency_seconds_bucket{le="0.1"} 1000
payment_latency_seconds_bucket{le="0.5"} 1200
payment_latency_seconds_bucket{le="1.0"} 1234
payment_latency_seconds_bucket{le="+Inf"} 1234
payment_latency_seconds_sum 234.5
payment_latency_seconds_count 1234
';
        add_header Content-Type text/plain;
    }
}
EOF

# Create Alert rules
echo "🚨 Setting up alert rules..."
cat > monitoring/alerts.yml << 'EOF'
groups:
  - name: payment-service
    interval: 30s
    rules:
      - alert: HighErrorRate
        expr: rate(payment_requests_total{status="error"}[5m]) > 0.01
        for: 1m
        labels:
          severity: critical
          service: payment-service
        annotations:
          summary: "High error rate detected"
          description: "Payment service error rate is {{ $value }}%"

      - alert: HighLatency
        expr: histogram_quantile(0.95, rate(payment_latency_seconds_bucket[5m])) > 0.5
        for: 2m
        labels:
          severity: warning
          service: payment-service
        annotations:
          summary: "High latency detected"
          description: "95th percentile latency is {{ $value }}s"
EOF

# Start the stack
echo ""
echo "🐳 Starting Docker containers..."
docker-compose up -d

# Wait for services to be ready
echo ""
echo "⏳ Waiting for services to start..."
sleep 10

# Show running services
echo ""
echo "✅ Services are running!"
echo ""
echo "📍 Access points:"
echo "   Grafana:     http://localhost:3000     (admin/admin)"
echo "   Prometheus:  http://localhost:9090"
echo "   Jaeger:      http://localhost:16686"
echo "   AlertManager: http://localhost:9093"
echo ""
echo "   Payment API: http://localhost:8081"
echo "   Order API:   http://localhost:8082"
echo ""

# Generate some traffic
echo "🔄 Generating sample traffic..."
for i in {1..10}; do
    curl -s http://localhost:8081/api/payment > /dev/null 2>&1
    curl -s http://localhost:8082/api/order > /dev/null 2>&1
done

echo ""
echo "🎯 Demo Ready!"
echo ""
echo "To simulate an incident:"
echo "  docker kill payment-service    # Kill the service"
echo "  docker start payment-service   # Recover the service"
echo ""
echo "To enable chaos engineering:"
echo "  docker-compose --profile chaos up -d"
echo ""
echo "To stop everything:"
echo "  docker-compose down"
echo ""