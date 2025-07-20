output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront distribution hosted zone ID"
  value       = aws_cloudfront_distribution.main.hosted_zone_id
}

output "cloudfront_waf_acl_arn" {
  description = "CloudFront WAF ACL ARN"
  value       = aws_wafv2_web_acl.cloudfront.arn
}