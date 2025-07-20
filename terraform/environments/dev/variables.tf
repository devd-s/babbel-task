variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "url-shortener"
}

# Networking Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# EKS Variables
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "eks_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "eks_public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_node_instance_types" {
  description = "List of instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "eks_node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 4
}

variable "eks_node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "eks_node_disk_size" {
  description = "Disk size for EKS nodes in GB"
  type        = number
  default     = 50
}

variable "eks_capacity_type" {
  description = "Type of capacity associated with the EKS Node Group"
  type        = string
  default     = "ON_DEMAND"
}

# ALB Variables
variable "certificate_arn" {
  description = "ARN of the SSL certificate"
  type        = string
  default     = ""
}

variable "domain_names" {
  description = "List of domain names for the ALB"
  type        = list(string)
  default     = ["dev.example.com"]
}

variable "alb_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "Rate limit for WAF rule (requests per 5 minutes)"
  type        = number
  default     = 2000
}

variable "cloudfront_ips" {
  description = "List of CloudFront IP ranges"
  type        = list(string)
  default = [
    "120.52.22.96/27",
    "205.251.249.0/24",
    "180.163.57.128/26",
    "204.246.168.0/22",
    "18.160.0.0/15",
    "205.251.252.0/23",
    "54.192.0.0/16",
    "204.246.173.0/24",
    "54.230.200.0/21",
    "120.253.240.192/26",
    "116.129.226.128/26",
    "130.176.0.0/17",
    "108.156.0.0/14",
    "99.86.0.0/16",
    "205.251.200.0/21",
    "13.32.0.0/15",
    "13.224.0.0/14",
    "70.132.0.0/18",
    "15.158.0.0/16",
    "13.249.0.0/16",
    "18.238.0.0/15",
    "18.244.0.0/15",
    "205.251.208.0/20",
    "65.9.128.0/18",
    "130.176.128.0/18",
    "58.254.138.0/25",
    "54.230.208.0/20",
    "116.129.226.0/25",
    "52.222.128.0/17",
    "18.164.0.0/15",
    "111.13.171.128/26",
    "204.246.172.0/24",
    "54.230.224.0/19",
    "71.152.0.0/17",
    "216.137.32.0/19",
    "204.246.164.0/22",
    "13.249.0.0/16",
    "54.239.128.0/18",
    "108.156.0.0/14",
    "18.172.0.0/15",
    "18.154.0.0/15",
    "54.240.128.0/18",
    "205.251.254.0/24",
    "54.182.0.0/16",
    "58.254.138.128/26",
    "120.253.245.128/26",
    "54.239.192.0/19",
    "18.68.0.0/16",
    "18.64.0.0/14",
    "120.52.39.128/27",
    "118.214.168.0/26",
    "204.246.174.0/23",
    "52.46.0.0/18",
    "52.82.128.0/19",
    "54.230.0.0/17",
    "54.230.128.0/18",
    "54.239.0.0/18",
    "130.176.192.0/18",
    "52.124.128.0/17",
    "204.246.176.0/20",
    "13.35.0.0/16",
    "204.246.170.0/23",
    "110.232.178.128/26",
    "52.15.127.128/26",
    "18.136.0.0/16",
    "114.108.7.192/26",
    "107.154.0.0/16",
    "99.79.0.0/16",
    "121.244.94.0/25",
    "52.47.139.0/24",
    "87.238.80.0/21",
    "54.240.192.0/18",
    "34.195.252.0/24",
    "35.158.136.0/24",
    "121.244.94.128/26",
    "111.13.185.32/27",
    "18.216.170.128/25",
    "111.13.185.0/27",
    "52.52.191.128/26",
    "204.246.169.0/24",
    "18.186.0.0/15",
    "112.78.112.192/26",
    "54.241.32.64/26",
    "99.83.128.0/17",
    "204.246.167.0/24"
  ]
}

# CloudWatch Variables
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "alert_email_addresses" {
  description = "List of email addresses for CloudWatch alerts"
  type        = list(string)
  default     = []
}

# KMS Variables
variable "kms_deletion_window_in_days" {
  description = "Number of days to wait before deleting KMS key"
  type        = number
  default     = 7
}

# RDS Variables
variable "rds_engine" {
  description = "Database engine"
  type        = string
  default     = "postgres"
}

variable "rds_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "15.4"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_db_name" {
  description = "Name of the database"
  type        = string
  default     = "urlshortener"
}

variable "rds_username" {
  description = "Database master username"
  type        = string
  default     = "dbadmin"
}

variable "rds_password" {
  description = "Database master password"
  type        = string
  default     = "change-me-in-production"
  sensitive   = true
}

variable "rds_allocated_storage" {
  description = "Initial allocated storage in GB"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Maximum allocated storage in GB (for autoscaling)"
  type        = number
  default     = 100
}

variable "rds_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "rds_deletion_protection" {
  description = "Enable deletion protection for RDS"
  type        = bool
  default     = false
}

variable "rds_skip_final_snapshot" {
  description = "Skip final snapshot when deleting RDS"
  type        = bool
  default     = true
}