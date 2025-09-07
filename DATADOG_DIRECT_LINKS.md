# Datadog Direct Links for Demo

## Dashboard
**Golden Signals Dashboard**: https://app.datadoghq.eu/dashboard/gwx-a2j-ibv/golden-signals---production-services

## Monitors
**All Monitors**: https://app.datadoghq.eu/monitors/manage
- High System Load Alert (ID: 87373088)
- Network Traffic Anomaly Detection (ID: 87373089)

## Metrics (Direct Links That Work)

### Payment Metrics
**Payment Total**: 
https://app.datadoghq.eu/metric/explorer?from_ts=1757165719944&to_ts=1757169319944&paused=false&exp_metric=metrics.payment.total&exp_scope=env%3Aproduction

**Payment Success**:
https://app.datadoghq.eu/metric/explorer?exp_metric=metrics.payment.success&exp_scope=env%3Aproduction

**Payment Failure**:
https://app.datadoghq.eu/metric/explorer?exp_metric=metrics.payment.failure&exp_scope=env%3Aproduction

**Payment Latency**:
https://app.datadoghq.eu/metric/explorer?exp_metric=metrics.payment.latency&exp_scope=env%3Aproduction

**Payment Amount**:
https://app.datadoghq.eu/metric/explorer?exp_metric=metrics.payment.amount&exp_scope=env%3Aproduction

### System Metrics
**CPU Usage**:
https://app.datadoghq.eu/metric/explorer?exp_metric=system.cpu.user

**System Load**:
https://app.datadoghq.eu/metric/explorer?exp_metric=system.load.5

**Network Traffic**:
https://app.datadoghq.eu/metric/explorer?exp_metric=system.net.bytes_sent

## Demo Flow Links (In Order)

1. **Start Here - Dashboard**: Show real-time metrics flowing
   https://app.datadoghq.eu/dashboard/gwx-a2j-ibv/

2. **Show Payment Metrics**: Demonstrate business KPIs
   https://app.datadoghq.eu/metric/explorer?exp_metric=metrics.payment.total&exp_scope=env%3Aproduction

3. **Show Monitors**: Proactive alerting
   https://app.datadoghq.eu/monitors/manage

4. **Create SLO** (if time): 
   https://app.datadoghq.eu/slo/new

## Talking Points for Each Link

### Dashboard
"This dashboard shows our Four Golden Signals - latency, traffic, errors, and saturation in real-time."

### Payment Metrics
"Here you can see actual payment transaction metrics - we're tracking success rates, latency, and transaction values."

### Monitors
"I've set up intelligent alerting with multi-severity thresholds to reduce false positives."


