output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "eks_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.eks.cluster_oidc_issuer_url
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.alb.alb_zone_id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = module.alb.target_group_arn
}

# Kubectl configuration command
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_id}"
}

# CloudWatch Outputs
output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = module.cloudwatch.cloudwatch_dashboard_url
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log groups created"
  value = {
    eks_cluster     = module.cloudwatch.cloudwatch_log_group_eks_cluster
    eks_application = module.cloudwatch.cloudwatch_log_group_eks_application
    vpc_flow_logs   = module.cloudwatch.cloudwatch_log_group_vpc_flow_logs
    alb_access      = module.cloudwatch.cloudwatch_log_group_alb_access
    waf_logs        = module.cloudwatch.cloudwatch_log_group_waf
  }
}

# KMS Outputs
output "kms_key_id" {
  description = "ID of the KMS key for RDS encryption"
  value       = module.kms.kms_key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key for RDS encryption"
  value       = module.kms.kms_key_arn
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.rds_endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.rds.rds_port
}

output "rds_db_name" {
  description = "Name of the database"
  value       = module.rds.rds_db_name
}

output "rds_instance_id" {
  description = "ID of the RDS instance"
  value       = module.rds.rds_instance_id
}