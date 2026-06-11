resource "aws_wafv2_ip_set" "trusted_ips" {
  count = var.environment == "prod" ? 1 : 0

  name               = "trusted-ips-for-${var.project_name}-${var.environment}"
  description        = "IPs to be allowed for ${var.environment}"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.trusted_ips
}

resource "aws_wafv2_web_acl" "this" {
  name        = "${var.project_name}-waf-${var.environment}"
  description = "WAF for ${var.project_name} ALB"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 0

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesLinuxRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesLinuxRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            allow {}
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  dynamic "rule" {
    for_each = var.environment == "prod" && length(var.trusted_ips) > 0 ? [1] : []

    content {
      name     = "AllowTrustedIPs"
      priority = 3

      action {
        allow {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.trusted_ips[0].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "AllowTrustedIPs"
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = var.environment == "prod" ? [1] : []

    content {
      name     = "Deny-All-For-Notification-Endpoints"
      priority = 5

      action {
        block {}
      }

      statement {
        or_statement {
          statement {
            byte_match_statement {
              search_string = "/notification/api/v1/notifications/topup-result-notification"
              field_to_match {
                uri_path {}
              }
              text_transformation {
                priority = 0
                type     = "NONE"
              }
              positional_constraint = "EXACTLY"
            }
          }
          statement {
            byte_match_statement {
              search_string = "/notification/api/v1/notifications/withdrawal-result-notification"
              field_to_match {
                uri_path {}
              }
              text_transformation {
                priority = 0
                type     = "NONE"
              }
              positional_constraint = "EXACTLY"
            }
          }
          statement {
            byte_match_statement {
              search_string = "/notification/api/v1/notifications/remittance-result-notification"
              field_to_match {
                uri_path {}
              }
              text_transformation {
                priority = 0
                type     = "NONE"
              }
              positional_constraint = "EXACTLY"
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "Deny-All-For-Notification-Endpoints"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "alb_waf_associate" {
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}

resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-${aws_wafv2_web_acl.this.name}"
  retention_in_days = 14
}

resource "aws_wafv2_web_acl_logging_configuration" "waf_logging" {
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.this.arn
}
