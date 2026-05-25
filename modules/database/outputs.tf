output "secrets_manager_secret_arn" {
  value       = aws_db_instance.rds.master_user_secret[0].secret_arn
  description = "ARN of the Secrets Manager secret storing the RDS master credentials"
}

output "db_endpoint" {
  value       = aws_db_instance.rds.endpoint
  description = "RDS instance endpoint"
}

output "db_port" {
  value       = aws_db_instance.rds.port
  description = "RDS instance port"
}

output "db_instance_arn" {
  value       = aws_db_instance.rds.arn
  description = "ARN of the RDS instance"
}

output "db_instance_id" {
  value       = aws_db_instance.rds.id
  description = "ID of the RDS instance"
}

output "security_group_id" {
  value       = aws_security_group.rds_sg.id
  description = "ID of the RDS security group"
}

output "db_subnet_group_name" {
  value       = aws_db_subnet_group.db_subnet_group.name
  description = "Name of the DB subnet group"
}

output "parameter_group_name" {
  value       = aws_db_parameter_group.pg_parameter_group.name
  description = "Name of the DB parameter group"
}
