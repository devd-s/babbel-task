output "rds_instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.main.id
}

output "rds_instance_arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "rds_db_name" {
  description = "Name of the database"
  value       = aws_db_instance.main.db_name
}

output "rds_username" {
  description = "RDS instance master username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "rds_subnet_group_name" {
  description = "Name of the RDS subnet group"
  value       = aws_db_subnet_group.main.name
}

output "rds_parameter_group_name" {
  description = "Name of the RDS parameter group"
  value       = aws_db_parameter_group.main.name
}

output "rds_security_group_id" {
  description = "Security group ID attached to RDS"
  value       = var.rds_security_group_id
}