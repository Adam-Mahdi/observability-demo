terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
  
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "observability/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Team        = "platform"
      ManagedBy   = "terraform"
      Project     = "observability-excellence"
    }
  }
}

provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  api_url = "https://api.datadoghq.com/"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Data sources
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

# EKS Cluster Configuration (if creating new)
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"
  
  cluster_name    = var.cluster_name
  cluster_version = "1.28"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  cluster_endpoint_public_access = true
  
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }
  
  eks_managed_node_groups = {
    platform = {
      desired_size = 3
      min_size     = 3
      max_size     = 10
      
      instance_types = ["t3.large"]
      
      k8s_labels = {
        Environment = var.environment
        Team        = "platform"
      }
      
      tags = {
        "k8s.io/cluster-autoscaler/enabled"             = "true"
        "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      }
    }
  }
  
  manage_aws_auth_configmap = true
}

# VPC Configuration
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  
  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"
  
  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  
  enable_nat_gateway = true
  enable_vpn_gateway = true
  enable_dns_hostnames = true
  
  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
  
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
  
  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

# RDS for Payment Database
module "payment_db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"
  
  identifier = "${var.cluster_name}-payment-db"
  
  engine            = "postgres"
  engine_version    = "15.4"
  instance_class    = "db.r6g.large"
  allocated_storage = 100
  storage_encrypted = true
  
  db_name  = "paymentdb"
  username = "payment_admin"
  port     = "5432"
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  
  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"
  
  backup_retention_period = 30
  
  enabled_cloudwatch_logs_exports = ["postgresql"]
  
  create_monitoring_role = true
  monitoring_interval    = "30"
  monitoring_role_name   = "${var.cluster_name}-payment-db-monitoring"
  
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  
  tags = {
    Service = "payment-service"
  }
}

# ElastiCache for Redis
module "payment_cache" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "~> 1.0"
  
  cluster_id           = "${var.cluster_name}-payment-cache"
  engine              = "redis"
  node_type           = "cache.r6g.large"
  num_cache_nodes     = 1
  parameter_group_name = "default.redis7"
  engine_version      = "7.0"
  port                = 6379
  
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.redis.id]
  
  snapshot_retention_limit = 5
  snapshot_window         = "03:00-05:00"
  
  tags = {
    Service = "payment-service"
  }
}

# Security Groups
resource "aws_security_group" "rds" {
  name_prefix = "${var.cluster_name}-rds-"
  vpc_id      = module.vpc.vpc_id
  
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "redis" {
  name_prefix = "${var.cluster_name}-redis-"
  vpc_id      = module.vpc.vpc_id
  
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Datadog Agent Helm Chart
resource "helm_release" "datadog_agent" {
  name       = "datadog-agent"
  repository = "https://helm.datadoghq.com"
  chart      = "datadog"
  namespace  = "datadog"
  version    = "3.50.0"
  
  create_namespace = true
  
  set {
    name  = "datadog.apiKey"
    value = var.datadog_api_key
  }
  
  set {
    name  = "datadog.appKey"
    value = var.datadog_app_key
  }
  
  set {
    name  = "datadog.site"
    value = "datadoghq.com"
  }
  
  set {
    name  = "datadog.logs.enabled"
    value = "true"
  }
  
  set {
    name  = "datadog.logs.containerCollectAll"
    value = "true"
  }
  
  set {
    name  = "datadog.apm.enabled"
    value = "true"
  }
  
  set {
    name  = "datadog.processAgent.enabled"
    value = "true"
  }
  
  set {
    name  = "datadog.kubeStateMetricsCore.enabled"
    value = "true"
  }
  
  set {
    name  = "datadog.orchestratorExplorer.enabled"
    value = "true"
  }
  
  set {
    name  = "datadog.networkMonitoring.enabled"
    value = "true"
  }
}

# OpenTelemetry Collector
resource "helm_release" "otel_collector" {
  name       = "opentelemetry-collector"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  namespace  = "monitoring"
  
  create_namespace = true
  
  values = [
    file("${path.module}/otel-collector-values.yaml")
  ]
}

# Fluent Bit for log forwarding
resource "helm_release" "fluent_bit" {
  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  namespace  = "monitoring"
  
  values = [
    templatefile("${path.module}/fluent-bit-values.yaml", {
      datadog_api_key = var.datadog_api_key
    })
  ]
}

# Litmus Chaos
resource "helm_release" "litmus" {
  name       = "litmus"
  repository = "https://litmuschaos.github.io/litmus-helm/"
  chart      = "litmus"
  namespace  = "litmus"
  version    = "3.0.0"
  
  create_namespace = true
  
  set {
    name  = "portal.server.service.type"
    value = "LoadBalancer"
  }
}

# Create Datadog Monitors
resource "datadog_monitor" "payment_service_error_rate" {
  name    = "Payment Service - High Error Rate"
  type    = "metric alert"
  message = <<-EOF
    {{#is_alert}}
    Alert: Payment service error rate is above 1%
    Service: payment-service
    Environment: ${var.environment}
    Current Value: {{value}}%
    
    Runbook: https://github.com/company/runbooks/payment-service.md
    Dashboard: https://app.datadoghq.com/dashboard/payment-service
    
    @slack-platform-team @pagerduty-platform
    {{/is_alert}}
    
    {{#is_recovery}}
    Recovered: Payment service error rate back to normal
    {{/is_recovery}}
  EOF
  
  query = "sum(last_5m):sum:trace.http.request.errors{service:payment-service,env:${var.environment}}.as_rate() / sum:trace.http.request.hits{service:payment-service,env:${var.environment}}.as_rate() * 100 > 1"
  
  monitor_thresholds {
    critical = 1
    warning  = 0.5
  }
  
  notify_no_data    = true
  no_data_timeframe = 10
  
  tags = [
    "service:payment-service",
    "env:${var.environment}",
    "team:platform",
    "severity:P1"
  ]
}

# Create Datadog SLO
resource "datadog_service_level_objective" "payment_availability" {
  name        = "Payment Service Availability"
  type        = "monitor"
  description = "99.9% availability for payment service"
  
  monitor_ids = [datadog_monitor.payment_service_error_rate.id]
  
  thresholds {
    timeframe = "30d"
    target    = 99.9
    warning   = 99.95
  }
  
  tags = [
    "service:payment-service",
    "env:${var.environment}",
    "team:platform"
  ]
}

# IAM Roles for Service Accounts
resource "aws_iam_role" "payment_service" {
  name = "${var.cluster_name}-payment-service-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:production:payment-service"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "payment_service" {
  name = "${var.cluster_name}-payment-service-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "kms:Decrypt"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::payment-service-data/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "payment_service" {
  policy_arn = aws_iam_policy.payment_service.arn
  role       = aws_iam_role.payment_service.name
}