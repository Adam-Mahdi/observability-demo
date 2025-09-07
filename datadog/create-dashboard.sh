#!/bin/bash

# Create Dashboard in Datadog via API
echo "📊 Creating Golden Signals Dashboard in Datadog"
echo "============================================="
echo ""

# API Keys for demo account
DD_API_KEY="cebd641eea33f26fe551354ad85ed530"
DD_APP_KEY="c863c255c718ba4788d901b34741af94a63c2fb9"

echo ""
echo "Creating dashboard with system metrics..."

# Create a simplified dashboard with available system metrics
curl -X POST "https://api.datadoghq.eu/api/v1/dashboard" \
-H "Content-Type: application/json" \
-H "DD-API-KEY: ${DD_API_KEY}" \
-H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
-d @- <<'EOF'
{
  "title": "Golden Signals - Production Services",
  "description": "Real-time monitoring of system health and performance",
  "widgets": [
    {
      "definition": {
        "title": "CPU Usage by Core",
        "type": "timeseries",
        "requests": [
          {
            "q": "avg:system.cpu.user{*} by {cpu}",
            "display_type": "line",
            "style": {
              "palette": "dog_classic"
            }
          }
        ]
      },
      "layout": {
        "x": 0,
        "y": 0,
        "width": 6,
        "height": 3
      }
    },
    {
      "definition": {
        "title": "System Load Average",
        "type": "timeseries",
        "requests": [
          {
            "q": "avg:system.load.1{*}, avg:system.load.5{*}, avg:system.load.15{*}",
            "display_type": "line"
          }
        ]
      },
      "layout": {
        "x": 6,
        "y": 0,
        "width": 6,
        "height": 3
      }
    },
    {
      "definition": {
        "title": "CPU System vs User",
        "type": "timeseries",
        "requests": [
          {
            "q": "avg:system.cpu.system{*}",
            "display_type": "area",
            "style": {
              "palette": "orange"
            }
          },
          {
            "q": "avg:system.cpu.user{*}",
            "display_type": "area",
            "style": {
              "palette": "blue"
            }
          }
        ]
      },
      "layout": {
        "x": 0,
        "y": 3,
        "width": 6,
        "height": 3
      }
    },
    {
      "definition": {
        "title": "IO Wait Time",
        "type": "timeseries",
        "requests": [
          {
            "q": "avg:system.cpu.iowait{*}",
            "display_type": "line",
            "style": {
              "palette": "warm"
            }
          }
        ]
      },
      "layout": {
        "x": 6,
        "y": 3,
        "width": 6,
        "height": 3
      }
    },
    {
      "definition": {
        "title": "CPU Idle %",
        "type": "query_value",
        "requests": [
          {
            "q": "avg:system.cpu.idle{*}",
            "aggregator": "avg"
          }
        ],
        "custom_unit": "%",
        "precision": 1
      },
      "layout": {
        "x": 0,
        "y": 6,
        "width": 3,
        "height": 2
      }
    },
    {
      "definition": {
        "title": "Number of CPUs",
        "type": "query_value",
        "requests": [
          {
            "q": "avg:system.cpu.num_cores{*}",
            "aggregator": "last"
          }
        ],
        "precision": 0
      },
      "layout": {
        "x": 3,
        "y": 6,
        "width": 3,
        "height": 2
      }
    },
    {
      "definition": {
        "title": "Network Traffic",
        "type": "timeseries",
        "requests": [
          {
            "q": "avg:system.net.bytes_sent{*}.as_rate()",
            "display_type": "line",
            "style": {
              "palette": "green"
            }
          },
          {
            "q": "avg:system.net.bytes_rcvd{*}.as_rate()",
            "display_type": "line",
            "style": {
              "palette": "blue"
            }
          }
        ]
      },
      "layout": {
        "x": 6,
        "y": 6,
        "width": 6,
        "height": 3
      }
    }
  ],
  "layout_type": "ordered",
  "notify_list": [],
  "reflow_type": "fixed"
}
EOF

echo ""
echo "✅ Dashboard created!"
echo ""
echo "View your dashboard at:"
echo "https://app.datadoghq.eu/dashboard/lists"
echo ""
echo "Next steps:"
echo "1. The dashboard is created with system metrics"
echo "2. You can add more widgets from the UI"
echo "3. Create monitors for alerting"
echo "4. Set up an SLO"