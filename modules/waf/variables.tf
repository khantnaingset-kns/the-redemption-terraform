variable "environment" {
  description = "The environment in which the resources are deployed"
  type        = string
}

variable "project_name" {
  description = "Project name used to prefix WAF resources"
  type        = string

  validation {
    condition     = length(var.project_name) > 0
    error_message = "project_name must not be empty."
  }
}

variable "alb_arn" {
  description = "ARN of the ALB to associate the WAF Web ACL with"
  type        = string
}

variable "trusted_ips" {
  description = "A list of IP addresses to allow for a production environment"
  type        = list(string)
  default     = []
}
