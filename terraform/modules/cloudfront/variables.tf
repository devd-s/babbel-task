variable "environment" {
  description = "Environment name"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate"
  type        = string
}

variable "domain_names" {
  description = "List of domain names"
  type        = list(string)
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}

variable "origin_verify_secret" {
  description = "Secret header value to verify requests come from CloudFront"
  type        = string
  sensitive   = true
}

variable "blocked_countries" {
  description = "List of country codes to block"
  type        = list(string)
  default     = ["CN", "RU", "KP"]  # Example: Block China, Russia, North Korea
}

variable "rate_limit" {
  description = "Rate limit for CloudFront WAF (requests per 5 minutes)"
  type        = number
  default     = 10000
}

variable "cloudfront_waf_acl_id" {
  description = "CloudFront WAF ACL ID"
  type        = string
  default     = ""
}

variable "logs_bucket" {
  description = "S3 bucket for CloudFront logs"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}