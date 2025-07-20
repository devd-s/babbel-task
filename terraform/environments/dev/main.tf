terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
#For backend state management
  backend "s3" {
    # Configure your S3 backend here
    # bucket = "your-terraform-state-bucket"
    # key    = "dev/terraform.tfstate"
    # region = "us-west-2"
    # encrypt = true
    # dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment   = var.environment
      Project       = var.project_name
      Owner         = "DevOps Team"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Local values
locals {
  cluster_name = "${var.project_name}-${var.environment}-eks"
  
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Owner       = "DevOps"
  }

  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  environment         = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = local.availability_zones
  public_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, 8, 1),
    cidrsubnet(var.vpc_cidr, 8, 2),
    cidrsubnet(var.vpc_cidr, 8, 3)
  ]
  private_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, 8, 11),
    cidrsubnet(var.vpc_cidr, 8, 12),
    cidrsubnet(var.vpc_cidr, 8, 13)
  ]

  cloudwatch_log_group_vpc_flow_logs_arn = module.cloudwatch.cloudwatch_log_group_vpc_flow_logs

  tags = local.common_tags

  depends_on = [module.cloudwatch]
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security-groups"

  environment      = var.environment
  vpc_id          = module.networking.vpc_id
  vpc_cidr_block  = module.networking.vpc_cidr_block
  cloudfront_ips  = var.cloudfront_ips

  tags = local.common_tags
}

# EKS Module
module "eks" {
  source = "../../modules/eks"

  environment               = var.environment
  cluster_name             = local.cluster_name
  kubernetes_version       = var.kubernetes_version
  private_subnet_ids       = module.networking.private_subnet_ids
  cluster_security_group_id = module.security_groups.eks_cluster_security_group_id
  nodes_security_group_id  = module.security_groups.eks_nodes_security_group_id
  
  endpoint_public_access   = var.eks_endpoint_public_access
  public_access_cidrs     = var.eks_public_access_cidrs
  
  node_instance_types     = var.eks_node_instance_types
  node_desired_size       = var.eks_node_desired_size
  node_max_size          = var.eks_node_max_size
  node_min_size          = var.eks_node_min_size
  node_disk_size         = var.eks_node_disk_size
  capacity_type          = var.eks_capacity_type

  tags = local.common_tags
}

# ALB Module
module "alb" {
  source = "../../modules/alb"

  environment           = var.environment
  vpc_id               = module.networking.vpc_id
  public_subnet_ids    = module.networking.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_security_group_id
  certificate_arn      = var.certificate_arn
  domain_names         = var.domain_names
  deletion_protection  = var.alb_deletion_protection
  rate_limit          = var.waf_rate_limit
  cloudfront_ips      = var.cloudfront_ips

  tags = local.common_tags
}

# CloudWatch Module
module "cloudwatch" {
  source = "../../modules/cloudwatch"

  environment           = var.environment
  cluster_name         = local.cluster_name
  alb_name            = module.alb.alb_dns_name
  log_retention_days  = var.log_retention_days
  alert_email_addresses = var.alert_email_addresses

  tags = local.common_tags
}

# KMS Module
module "kms" {
  source = "../../modules/kms"

  environment              = var.environment
  deletion_window_in_days = var.kms_deletion_window_in_days

  tags = local.common_tags
}

# RDS Module
module "rds" {
  source = "../../modules/rds"

  environment           = var.environment
  private_subnet_ids   = module.networking.private_subnet_ids
  rds_security_group_id = module.security_groups.rds_security_group_id
  kms_key_arn          = module.kms.kms_key_arn
  
  # Database configuration
  db_engine           = var.rds_engine
  db_engine_version   = var.rds_engine_version
  db_instance_class   = var.rds_instance_class
  db_name            = var.rds_db_name
  db_username        = var.rds_username
  db_password        = var.rds_password
  
  # Storage configuration
  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage
  
  # Backup and monitoring
  backup_retention_period = var.rds_backup_retention_period
  deletion_protection    = var.rds_deletion_protection
  skip_final_snapshot   = var.rds_skip_final_snapshot

  tags = local.common_tags

  depends_on = [module.kms, module.security_groups]
}

