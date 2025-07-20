# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection       = var.deletion_protection
  enable_cross_zone_load_balancing = true
  enable_http2                     = true

  drop_invalid_header_fields = true

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "alb-access-logs"
    enabled = true
  }

  # Send access logs to CloudWatch
  enable_waf_fail_open = false

  tags = merge(var.tags, {
    Name = "${var.environment}-alb"
  })

  depends_on = [aws_s3_bucket_policy.alb_logs]
}

# S3 Bucket for ALB Logs
resource "aws_s3_bucket" "alb_logs" {
  bucket        = "${var.environment}-alb-access-logs-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = var.tags
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_encryption" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Policy ALB  Logs
data "aws_elb_service_account" "main" {}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/alb-access-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/alb-access-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.alb_logs.arn
      }
    ]
  })
}

# HTTP Listener (redirecting to HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = var.tags
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Default ALB Response"
      status_code  = "200"
    }
  }

  tags = var.tags
}

# Target Group for URL Shortener
resource "aws_lb_target_group" "url_shortener" {
  name     = "${var.environment}-url-shortener-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/login"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  target_type = "ip"

  tags = merge(var.tags, {
    Name = "${var.environment}-url-shortener-tg"
  })
}

# Listener Rule for URL Shortener
resource "aws_lb_listener_rule" "url_shortener" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.url_shortener.arn
  }

  condition {
    host_header {
      values = var.domain_names
    }
  }

  tags = var.tags
}

# WAF Web ACL for ALB 
resource "aws_wafv2_web_acl" "alb" {
  name  = "${var.environment}-alb-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # AWS Managed Rule - Common Rule Sets for WAF
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rule - Known Bad Inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rate Limit Rule
  rule {
    name     = "RateLimitRule"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  # CloudFront IP Whitelisting Rule
  rule {
    name     = "CloudFrontIPWhitelist"
    priority = 4

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.cloudfront_ips.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CloudFrontIPWhitelist"
      sampled_requests_enabled   = true
    }
  }

  tags = var.tags

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.environment}ALBWebACL"
    sampled_requests_enabled   = true
  }
}

# IP Set for CloudFront IPs
resource "aws_wafv2_ip_set" "cloudfront_ips" {
  name               = "${var.environment}-cloudfront-ips"
  description        = "IP set containing CloudFront IP ranges"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"

  addresses = var.cloudfront_ips

  tags = var.tags
}

# Associate WAF with ALB
resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.main.arn
  web_acl_arn  = aws_wafv2_web_acl.alb.arn
}