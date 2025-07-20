output "cloudwatch_log_group_eks_cluster" {
  description = "CloudWatch log group for EKS cluster"
  value       = aws_cloudwatch_log_group.eks_cluster.name
}

output "cloudwatch_log_group_eks_application" {
  description = "CloudWatch log group for EKS applications"
  value       = aws_cloudwatch_log_group.eks_application.name
}

output "cloudwatch_log_group_vpc_flow_logs" {
  description = "CloudWatch log group for VPC flow logs"
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}

output "cloudwatch_log_group_alb_access" {
  description = "CloudWatch log group for ALB access logs"
  value       = aws_cloudwatch_log_group.alb_access.name
}

output "cloudwatch_log_group_waf" {
  description = "CloudWatch log group for WAF logs"
  value       = aws_cloudwatch_log_group.waf_logs.name
}

output "cloudwatch_kms_key_arn" {
  description = "KMS key ARN for CloudWatch logs encryption"
  value       = aws_kms_key.cloudwatch.arn
}

output "sns_topic_alerts_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}