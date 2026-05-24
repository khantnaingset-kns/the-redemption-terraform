variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string

  validation {
    condition     = length(var.alb_name) > 0 && length(var.alb_name) <= 29
    error_message = "alb_name must be non-empty and no longer than 29 characters so target group names remain valid."
  }
}

variable "vpc_id" {
  description = "VPC ID where the ALB and target group are created"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs where the internet-facing ALB is deployed"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) > 0
    error_message = "At least one public subnet ID must be provided."
  }
}

variable "access_logs_bucket_name" {
  description = "S3 bucket name for ALB access logs"
  type        = string
}

variable "access_logs_prefix" {
  description = "S3 prefix for ALB access logs"
  type        = string
  default     = "alb"

  validation {
    condition     = !can(regex("(^|/)AWSLogs($|/)", var.access_logs_prefix))
    error_message = "access_logs_prefix must not include AWSLogs; ALB adds that path automatically."
  }
}

variable "allowed_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to access the ALB over HTTP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "target_port" {
  description = "Port used by the ALB target group"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "HTTP path used for target group health checks"
  type        = string
  default     = "/healthz"
}

variable "enable_deletion_protection" {
  description = "Whether deletion protection is enabled on the ALB"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to ALB resources"
  type        = map(string)
  default     = {}
}
