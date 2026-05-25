variable "vpc_id" {
  description = "VPC ID where the RDS security group and subnet group will be created"
  type        = string
}

variable "sg_name" {
  description = "Name for the RDS security group"
  type        = string
}

variable "ingress_rules" {
  description = "Ingress rules for the RDS security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = string
    description = string
  }))
  default = []
}

variable "egress_rules" {
  description = "Egress rules for the RDS security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = string
    description = string
  }))
  default = []
}

variable "db_subnet_ids" {
  description = "Subnet IDs for the RDS subnet group (typically isolated subnets)"
  type        = list(string)
}

variable "db_instance_name" {
  description = "Identifier for the RDS instance"
  type        = string
}

variable "engine" {
  description = "Database engine"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = "17"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage in GB for autoscaling"
  type        = number
  default     = 100
}

variable "performance_insights_retention_period" {
  description = "Retention period for Performance Insights in days"
  type        = number
  default     = 7

  validation {
    condition     = contains([7, 31, 62, 93, 186, 372, 731], var.performance_insights_retention_period)
    error_message = "performance_insights_retention_period must be one of 7, 31, 62, 93, 186, 372, or 731."
  }
}


