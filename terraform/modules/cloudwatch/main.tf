# CloudWatch Log Groups for EKS
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.cloudwatch.arn

  tags = merge(var.tags, {
    Name = "${var.environment}-eks-cluster-logs"
  })
}

resource "aws_cloudwatch_log_group" "eks_application" {
  name              = "/aws/eks/${var.cluster_name}/application"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.cloudwatch.arn

  tags = merge(var.tags, {
    Name = "${var.environment}-eks-application-logs"
  })
}

resource "aws_cloudwatch_log_group" "eks_host" {
  name              = "/aws/eks/${var.cluster_name}/host"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.cloudwatch.arn

  tags = merge(var.tags, {
    Name = "${var.environment}-eks-host-logs"
  })
}

resource "aws_cloudwatch_log_group" "eks_dataplane" {
  name              = "/aws/eks/${var.cluster_name}/dataplane"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.cloudwatch.arn

  tags = merge(var.tags, {
    Name = "${var.environment}-eks-dataplane-logs"
  })
}

# CloudWatch Log Groups for ALB
resource "aws_cloudwatch_log_group" "alb_access" {
  name              = "/aws/alb/${var.environment}/access"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.cloudwatch.arn

  tags = merge(var.tags, {
    Name = "${var.environment}-alb-access-logs"
  })
}

# CloudWatch Log Groups for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${var.environment}/flowlogs"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.cloudwatch.arn

  tags = merge(var.tags, {
    Name = "${var.environment}-vpc-flow-logs"
  })
}

# CloudWatch Log Groups for WAF
resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "/aws/waf/${var.environment}/logs"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.cloudwatch.arn

  tags = merge(var.tags, {
    Name = "${var.environment}-waf-logs"
  })
}

# CloudWatch Log Groups for CloudFront
resource "aws_cloudwatch_log_group" "cloudfront_logs" {
  name              = "/aws/cloudfront/${var.environment}/logs"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.cloudwatch.arn

  tags = merge(var.tags, {
    Name = "${var.environment}-cloudfront-logs"
  })
}

# KMS Key for CloudWatch Logs Encryption
resource "aws_kms_key" "cloudwatch" {
  description             = "KMS key for CloudWatch logs encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.environment}-cloudwatch-kms-key"
  })
}

resource "aws_kms_alias" "cloudwatch" {
  name          = "alias/${var.environment}-cloudwatch-logs"
  target_key_id = aws_kms_key.cloudwatch.key_id
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.environment}-infrastructure-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EKS", "cluster_failed_request_count", "ClusterName", var.cluster_name],
            [".", "cluster_request_count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "EKS Cluster Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_name],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "ALB Metrics"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 24
        height = 6

        properties = {
          query   = "SOURCE '/aws/eks/${var.cluster_name}/cluster' | fields @timestamp, @message | sort @timestamp desc | limit 100"
          region  = data.aws_region.current.name
          title   = "EKS Cluster Logs"
        }
      }
    ]
  })
}

# CloudWatch Alarms for EKS
resource "aws_cloudwatch_metric_alarm" "eks_cluster_failed_requests" {
  alarm_name          = "${var.environment}-eks-cluster-failed-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "cluster_failed_request_count"
  namespace           = "AWS/EKS"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors EKS cluster failed requests"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = var.tags
}

# CloudWatch Alarms for ALB
resource "aws_cloudwatch_metric_alarm" "alb_response_time" {
  alarm_name          = "${var.environment}-alb-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors ALB response time"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.environment}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors ALB 5XX errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_name
  }

  tags = var.tags
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name              = "${var.environment}-infrastructure-alerts"
  kms_master_key_id = aws_kms_key.cloudwatch.arn

  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = length(var.alert_email_addresses)
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email_addresses[count.index]
}

# CloudWatch Log Streams
resource "aws_cloudwatch_log_stream" "url_shortener_app" {
  name           = "url-shortener-application"
  log_group_name = aws_cloudwatch_log_group.eks_application.name
}

# CloudWatch Log Metric Filters
resource "aws_cloudwatch_log_metric_filter" "error_count" {
  name           = "${var.environment}-application-errors"
  log_group_name = aws_cloudwatch_log_group.eks_application.name
  pattern        = "ERROR"

  metric_transformation {
    name      = "ApplicationErrorCount"
    namespace = "URLShortener/${var.environment}"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "warning_count" {
  name           = "${var.environment}-application-warnings"
  log_group_name = aws_cloudwatch_log_group.eks_application.name
  pattern        = "WARN"

  metric_transformation {
    name      = "ApplicationWarningCount"
    namespace = "URLShortener/${var.environment}"
    value     = "1"
  }
}

# CloudWatch Insights Queries (Saved Queries)
resource "aws_cloudwatch_query_definition" "error_analysis" {
  name = "${var.environment}-error-analysis"

  log_group_names = [
    aws_cloudwatch_log_group.eks_application.name,
    aws_cloudwatch_log_group.eks_cluster.name
  ]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
EOF
}

resource "aws_cloudwatch_query_definition" "performance_analysis" {
  name = "${var.environment}-performance-analysis"

  log_group_names = [
    aws_cloudwatch_log_group.eks_application.name
  ]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /response_time/
| stats avg(response_time) by bin(5m)
| sort @timestamp desc
EOF
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}