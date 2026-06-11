resource "aws_security_group" "rds_sg" {
  vpc_id      = var.vpc_id
  name        = var.sg_name
  description = "Security Group for RDS - ${var.sg_name}"

  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = var.sg_name
  }
}

resource "aws_security_group_rule" "ingress_rules" {
  count = length(var.ingress_rules)

  security_group_id = aws_security_group.rds_sg.id
  type              = "ingress"
  from_port         = var.ingress_rules[count.index].from_port
  to_port           = var.ingress_rules[count.index].to_port
  protocol          = var.ingress_rules[count.index].protocol
  cidr_blocks       = [var.ingress_rules[count.index].cidr_blocks]
  description       = var.ingress_rules[count.index].description
}

resource "aws_security_group_rule" "egress_rules" {
  count = length(var.egress_rules)

  security_group_id = aws_security_group.rds_sg.id
  type              = "egress"
  from_port         = var.egress_rules[count.index].from_port
  to_port           = var.egress_rules[count.index].to_port
  protocol          = var.egress_rules[count.index].protocol
  cidr_blocks       = [var.egress_rules[count.index].cidr_blocks]
  description       = var.egress_rules[count.index].description
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.db_instance_name}-db-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "${var.db_instance_name}-db-subnet-group"
  }
}

resource "aws_db_parameter_group" "pg_parameter_group" {
  name   = "${var.db_instance_name}-pg-params"
  family = "postgres${var.engine_version}"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  parameter {
    name  = "password_encryption"
    value = "scram-sha-256"
  }
}

resource "aws_db_instance" "rds" {
  identifier                  = var.db_instance_name
  engine                      = var.engine
  engine_version              = var.engine_version
  instance_class              = var.instance_class
  db_name                     = var.db_name
  username                    = var.db_username
  manage_master_user_password = true

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  parameter_group_name   = aws_db_parameter_group.pg_parameter_group.name

  multi_az = true

  performance_insights_enabled          = true
  performance_insights_retention_period = var.performance_insights_retention_period

  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.db_instance_name}-final-snapshot"
  deletion_protection       = false
  apply_immediately         = true

  lifecycle {
    ignore_changes = [tags]
  }

  depends_on = [
    aws_db_parameter_group.pg_parameter_group,
    aws_db_subnet_group.db_subnet_group
  ]
}

