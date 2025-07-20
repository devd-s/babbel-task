# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.environment}-rds-subnet-group"
  })
}

# RDS Parameter Group
resource "aws_db_parameter_group" "main" {
  family = var.db_family
  name   = "${var.environment}-rds-parameter-group"

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-rds-parameter-group"
  })
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.environment}-rds-instance"

  # Database configuration
  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class
  
  # Database settings
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = var.db_port

  # Storage configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type         = var.storage_type
  storage_encrypted    = true
  kms_key_id          = var.kms_key_arn

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id]
  publicly_accessible   = false

  # Parameter and option groups
  parameter_group_name = aws_db_parameter_group.main.name

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window
  copy_tags_to_snapshot  = true

  # Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

  # Performance Insights
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id      = var.performance_insights_enabled ? var.kms_key_arn : null
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  # Security
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.environment}-rds-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Logging
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  tags = merge(var.tags, {
    Name = "${var.environment}-rds-instance"
  })

  depends_on = [aws_db_subnet_group.main, aws_db_parameter_group.main]
}

# IAM Role for Enhanced Monitoring (conditional)
resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0
  name  = "${var.environment}-rds-enhanced-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Role Policy Attachment for Enhanced Monitoring
resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count      = var.monitoring_interval > 0 ? 1 : 0
  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}