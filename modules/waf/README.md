# AWS WAF Module

Terraform module for creating and managing AWS WAF (Web Application Firewall) with advanced features including managed rules, custom rules, rate limiting, bot control, and comprehensive logging for protecting web applications and APIs.

## Features

- **AWS Managed Rules**: Pre-configured rule groups from AWS
- **Custom Rules**: Create custom security rules
- **Rate Limiting**: Request rate-based rules
- **IP Sets**: Allow/block lists for IP addresses
- **Geo Blocking**: Block traffic from specific countries
- **Bot Control**: Managed bot protection
- **Request/Response Inspection**: Header, body, and URI inspection
- **Rule Priorities**: Configurable rule ordering
- **Logging**: CloudWatch Logs, S3, or Kinesis Firehose
- **Metrics**: CloudWatch metrics and alarms
- **Scope**: CloudFront, ALB, API Gateway, and AppSync
- **Label-Based Rules**: Advanced rule grouping
- **Captcha**: Challenge suspicious requests

## Usage

### Basic WAF with Managed Rules

```hcl
module "basic_waf" {
  source = "./modules/waf"

  name        = "basic-waf"
  description = "Basic WAF with managed rules"
  scope       = "REGIONAL"  # REGIONAL for ALB/API Gateway, CLOUDFRONT for CloudFront
  
  # AWS Managed Rules
  managed_rule_groups = {
    core = {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = 10
      
      excluded_rules = [
        "SizeRestrictions_BODY",
        "GenericRFI_BODY"
      ]
    }
    
    sql_injection = {
      name     = "AWSManagedRulesSQLiRuleSet"
      priority = 20
    }
  }
  
  # Associate with ALB
  resource_arns = [module.alb.arn]
  
  tags = {
    Environment = "production"
  }
}
```

### WAF with Rate Limiting

```hcl
module "rate_limited_waf" {
  source = "./modules/waf"

  name        = "api-waf"
  description = "WAF with rate limiting for API"
  scope       = "REGIONAL"
  
  # Rate-based rule
  rate_based_rules = {
    rate_limit = {
      priority = 5
      limit    = 2000  # 2000 requests per 5 minutes
      
      action = "BLOCK"
      
      # Apply to specific URI path
      scope_down_statement = {
        byte_match_statement = {
          positional_constraint = "STARTS_WITH"
          search_string        = "/api/"
          field_to_match = {
            uri_path = {}
          }
          text_transformations = [
            {
              priority = 0
              type     = "LOWERCASE"
            }
          ]
        }
      }
    }
  }
  
  # AWS Managed Rules
  managed_rule_groups = {
    core = {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = 10
    }
  }
  
  resource_arns = [module.api_alb.arn]
  
  tags = {
    Environment = "production"
  }
}
```

### WAF with IP Blocking and Geo Restrictions

```hcl
module "geo_restricted_waf" {
  source = "./modules/waf"

  name        = "geo-waf"
  description = "WAF with IP and geo restrictions"
  scope       = "CLOUDFRONT"
  
  # IP Sets
  ip_sets = {
    blocked_ips = {
      addresses = [
        "198.51.100.0/24",
        "203.0.113.0/24"
      ]
      ip_address_version = "IPV4"
    }
    
    allowed_ips = {
      addresses = [
        "192.0.2.0/24"
      ]
      ip_address_version = "IPV4"
    }
  }
  
  # Custom rules
  custom_rules = {
    block_malicious_ips = {
      priority = 1
      action   = "BLOCK"
      
      ip_set_reference_statement = {
        arn = "blocked_ips"  # References ip_sets above
      }
    }
    
    allow_trusted_ips = {
      priority = 2
      action   = "ALLOW"
      
      ip_set_reference_statement = {
        arn = "allowed_ips"
      }
    }
    
    block_countries = {
      priority = 3
      action   = "BLOCK"
      
      geo_match_statement = {
        country_codes = ["CN", "RU", "KP"]  # Block China, Russia, North Korea
      }
    }
  }
  
  # AWS Managed Rules
  managed_rule_groups = {
    core = {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = 10
    }
  }
  
  resource_arns = [module.cloudfront.distribution_arn]
  
  tags = {
    Environment = "production"
  }
}
```

### WAF with Bot Control

```hcl
module "bot_protected_waf" {
  source = "./modules/waf"

  name        = "bot-waf"
  description = "WAF with bot control"
  scope       = "REGIONAL"
  
  # Bot Control Managed Rule
  managed_rule_groups = {
    bot_control = {
      name     = "AWSManagedRulesBotControlRuleSet"
      priority = 5
      
      managed_rule_group_configs = [
        {
          aws_managed_rules_bot_control_rule_set = {
            inspection_level = "TARGETED"  # COMMON or TARGETED
          }
        }
      ]
    }
    
    core = {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = 10
    }
  }
  
  # Rate limit for suspicious bots
  rate_based_rules = {
    bot_rate_limit = {
      priority = 8
      limit    = 500
      action   = "CAPTCHA"
      
      scope_down_statement = {
        label_match_statement = {
          scope = "LABEL"
          key   = "awswaf:managed:aws:bot-control:bot:category:monitoring"
        }
      }
    }
  }
  
  resource_arns = [module.alb.arn]
  
  tags = {
    Environment = "production"
  }
}
```

### Advanced Custom Rules

```hcl
module "advanced_waf" {
  source = "./modules/waf"

  name        = "advanced-waf"
  description = "Advanced WAF with custom rules"
  scope       = "REGIONAL"
  
  # Custom rules
  custom_rules = {
    # Block requests with missing User-Agent
    require_user_agent = {
      priority = 1
      action   = "BLOCK"
      
      not_statement = {
        byte_match_statement = {
          positional_constraint = "CONTAINS"
          search_string        = "Mozilla"
          field_to_match = {
            single_header = {
              name = "user-agent"
            }
          }
          text_transformations = [
            {
              priority = 0
              type     = "LOWERCASE"
            }
          ]
        }
      }
    }
    
    # Block SQL injection in query strings
    sql_injection_qs = {
      priority = 2
      action   = "BLOCK"
      
      sqli_match_statement = {
        field_to_match = {
          query_string = {}
        }
        text_transformations = [
          {
            priority = 0
            type     = "URL_DECODE"
          },
          {
            priority = 1
            type     = "HTML_ENTITY_DECODE"
          }
        ]
      }
    }
    
    # Block XSS in request body
    xss_body = {
      priority = 3
      action   = "BLOCK"
      
      xss_match_statement = {
        field_to_match = {
          body = {
            oversize_handling = "MATCH"
          }
        }
        text_transformations = [
          {
            priority = 0
            type     = "URL_DECODE"
          },
          {
            priority = 1
            type     = "HTML_ENTITY_DECODE"
          }
        ]
      }
    }
    
    # Block large request bodies
    size_constraint = {
      priority = 4
      action   = "BLOCK"
      
      size_constraint_statement = {
        comparison_operator = "GT"
        size                = 8192  # 8KB
        field_to_match = {
          body = {
            oversize_handling = "MATCH"
          }
        }
        text_transformations = [
          {
            priority = 0
            type     = "NONE"
          }
        ]
      }
    }
    
    # Regex pattern matching
    block_malicious_patterns = {
      priority = 5
      action   = "BLOCK"
      
      regex_pattern_set_reference_statement = {
        arn = aws_wafv2_regex_pattern_set.malicious_patterns.arn
        field_to_match = {
          uri_path = {}
        }
        text_transformations = [
          {
            priority = 0
            type     = "LOWERCASE"
          }
        ]
      }
    }
  }
  
  # AWS Managed Rules
  managed_rule_groups = {
    core = {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = 10
    }
  }
  
  resource_arns = [module.alb.arn]
  
  tags = {
    Environment = "production"
  }
}

resource "aws_wafv2_regex_pattern_set" "malicious_patterns" {
  name  = "malicious-patterns"
  scope = "REGIONAL"
  
  regular_expression {
    regex_string = ".*\\.\\./"
  }
  
  regular_expression {
    regex_string = ".*\\.\\./\\.\\."
  }
  
  regular_expression {
    regex_string = ".*/etc/passwd"
  }
}
```

### Production WAF with Full Protection

```hcl
module "production_waf" {
  source = "./modules/waf"

  name        = "production-waf"
  description = "Production WAF with comprehensive protection"
  scope       = "REGIONAL"
  
  # Default action for requests that don't match any rules
  default_action = "ALLOW"
  
  # IP Sets
  ip_sets = {
    admin_ips = {
      addresses = [
        "203.0.113.0/24"
      ]
      ip_address_version = "IPV4"
    }
    
    blocked_ips = {
      addresses = [
        "198.51.100.42/32",
        "198.51.100.43/32"
      ]
      ip_address_version = "IPV4"
    }
  }
  
  # Custom rules
  custom_rules = {
    # Allow admin IPs full access
    allow_admin = {
      priority = 1
      action   = "ALLOW"
      
      ip_set_reference_statement = {
        arn = "admin_ips"
      }
    }
    
    # Block known malicious IPs
    block_malicious = {
      priority = 2
      action   = "BLOCK"
      
      ip_set_reference_statement = {
        arn = "blocked_ips"
      }
    }
    
    # Geo blocking
    geo_block = {
      priority = 3
      action   = "BLOCK"
      
      geo_match_statement = {
        country_codes = ["CN", "RU"]
      }
    }
  }
  
  # Rate-based rules
  rate_based_rules = {
    # General rate limit
    global_rate_limit = {
      priority = 5
      limit    = 10000
      action   = "BLOCK"
    }
    
    # API endpoint rate limit
    api_rate_limit = {
      priority = 6
      limit    = 2000
      action   = "CAPTCHA"
      
      scope_down_statement = {
        byte_match_statement = {
          positional_constraint = "STARTS_WITH"
          search_string        = "/api/"
          field_to_match = {
            uri_path = {}
          }
          text_transformations = [
            {
              priority = 0
              type     = "LOWERCASE"
            }
          ]
        }
      }
    }
    
    # Login endpoint rate limit
    login_rate_limit = {
      priority = 7
      limit    = 100
      action   = "BLOCK"
      
      scope_down_statement = {
        byte_match_statement = {
          positional_constraint = "EXACTLY"
          search_string        = "/login"
          field_to_match = {
            uri_path = {}
          }
          text_transformations = [
            {
              priority = 0
              type     = "LOWERCASE"
            }
          ]
        }
      }
    }
  }
  
  # AWS Managed Rule Groups
  managed_rule_groups = {
    # Core rule set
    core = {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = 10
      
      excluded_rules = [
        "SizeRestrictions_BODY",
        "GenericRFI_BODY"
      ]
    }
    
    # Known bad inputs
    known_bad_inputs = {
      name     = "AWSManagedRulesKnownBadInputsRuleSet"
      priority = 20
    }
    
    # SQL injection protection
    sql_injection = {
      name     = "AWSManagedRulesSQLiRuleSet"
      priority = 30
    }
    
    # Linux operating system protection
    linux_os = {
      name     = "AWSManagedRulesLinuxRuleSet"
      priority = 40
    }
    
    # POSIX operating system protection
    unix_os = {
      name     = "AWSManagedRulesUnixRuleSet"
      priority = 50
    }
    
    # PHP application protection
    php_app = {
      name     = "AWSManagedRulesPHPRuleSet"
      priority = 60
    }
    
    # WordPress application protection
    wordpress = {
      name     = "AWSManagedRulesWordPressRuleSet"
      priority = 70
    }
    
    # Bot control
    bot_control = {
      name     = "AWSManagedRulesBotControlRuleSet"
      priority = 80
      
      managed_rule_group_configs = [
        {
          aws_managed_rules_bot_control_rule_set = {
            inspection_level = "TARGETED"
          }
        }
      ]
    }
    
    # Amazon IP reputation list
    ip_reputation = {
      name     = "AWSManagedRulesAmazonIpReputationList"
      priority = 90
    }
    
    # Anonymous IP list
    anonymous_ip = {
      name     = "AWSManagedRulesAnonymousIpList"
      priority = 100
    }
  }
  
  # Logging configuration
  logging_configuration = {
    log_destination = aws_kinesis_firehose_delivery_stream.waf_logs.arn
    
    redacted_fields = [
      {
        single_header = {
          name = "authorization"
        }
      },
      {
        single_header = {
          name = "cookie"
        }
      }
    ]
    
    logging_filter = {
      default_behavior = "KEEP"
      
      filters = [
        {
          behavior    = "DROP"
          requirement = "MEETS_ALL"
          
          conditions = [
            {
              action_condition = {
                action = "ALLOW"
              }
            }
          ]
        }
      ]
    }
  }
  
  # CloudWatch metrics
  cloudwatch_metrics_enabled = true
  sampled_requests_enabled  = true
  
  # Associate with resources
  resource_arns = [
    module.alb.arn,
    module.api_gateway.arn
  ]
  
  tags = {
    Environment      = "production"
    ManagedBy        = "terraform"
    Compliance       = "pci-dss"
    CriticalityLevel = "high"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the WAF web ACL | `string` | n/a | yes |
| description | Description of the WAF web ACL | `string` | `""` | no |
| scope | Scope of the WAF (REGIONAL or CLOUDFRONT) | `string` | `"REGIONAL"` | no |
| default_action | Default action for requests (ALLOW or BLOCK) | `string` | `"ALLOW"` | no |
| ip_sets | Map of IP set configurations | `map(any)` | `{}` | no |
| custom_rules | Map of custom rule configurations | `map(any)` | `{}` | no |
| rate_based_rules | Map of rate-based rule configurations | `map(any)` | `{}` | no |
| managed_rule_groups | Map of managed rule group configurations | `map(any)` | `{}` | no |
| logging_configuration | Logging configuration | `object` | `null` | no |
| cloudwatch_metrics_enabled | Enable CloudWatch metrics | `bool` | `true` | no |
| sampled_requests_enabled | Enable sampled requests | `bool` | `true` | no |
| resource_arns | List of resource ARNs to associate | `list(string)` | `[]` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| web_acl_id | ID of the WAF web ACL |
| web_acl_arn | ARN of the WAF web ACL |
| web_acl_name | Name of the WAF web ACL |
| web_acl_capacity | Capacity units used by the web ACL |
| ip_set_arns | Map of IP set ARNs |

## Best Practices

### Security Configuration

- Start with **AWS Managed Rules** as baseline
- Add **custom rules** for specific threats
- Implement **rate limiting** to prevent abuse
- Use **geo-blocking** for compliance
- Enable **bot control** for public applications
- Test rules in **COUNT mode** before blocking
- Regular review and update **IP sets**

### Rule Management

- Use appropriate **rule priorities**
- Test rules in **staging environment**
- Monitor **sampled requests**
- Use **labels** for complex logic
- Implement **CAPTCHA** before blocking
- Document all **custom rules**
- Keep rules **simple and maintainable**

### Performance

- Minimize **rule complexity**
- Use **IP sets** instead of multiple IP rules
- Optimize **text transformations**
- Monitor **WAF capacity units** (max 5000)
- Use **rate-based rules** efficiently
- Cache **regex patterns** where possible

### Monitoring

- Enable **CloudWatch metrics**
- Monitor **blocked requests**
- Track **sampled requests**
- Set up **alarms** for anomalies
- Review **logs** regularly
- Monitor **false positives**
- Track **capacity units** usage

### Cost Optimization

- Use **managed rules** instead of custom (when possible)
- Consolidate **IP addresses** into IP sets
- Optimize **rule count**
- Use **appropriate scope** (REGIONAL vs CLOUDFRONT)
- Monitor and remove **unused rules**
- Use **rate limiting** strategically

## Cost Considerations

### Pricing Components

**Web ACL:**
- $5.00 per month per Web ACL
- $1.00 per million requests

**Rules:**
- $1.00 per month per rule
- Rate-based rules: $2.00 per month

**Managed Rule Groups:**
- AWS Managed Rules: $0-$10 per month
- Bot Control: $10.00 per month
- Account Takeover Prevention: $10.00 per month
- Fraud Control: $15.00 per month

**Requests:**
- $0.60 per million requests (beyond base)

**IP Sets:**
- Included in rule cost

### Example Monthly Costs

| Configuration | Cost |
|--------------|------|
| Basic (5 rules, 1M requests) | ~$11 |
| Standard (10 rules + managed, 10M requests) | ~$32 |
| Advanced (20 rules + bot control, 100M requests) | ~$112 |
| Enterprise (50 rules + all managed, 1B requests) | ~$710 |

**Cost Optimization:**
- Consolidate rules where possible
- Use managed rules efficiently
- Monitor request volume
- Remove unused rules
- Optimize rate limits

## Additional Resources

- [AWS WAF Developer Guide](https://docs.aws.amazon.com/waf/latest/developerguide/)
- [AWS WAF Best Practices](https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html)
- [AWS WAF Pricing](https://aws.amazon.com/waf/pricing/)
- [AWS Managed Rules](https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups.html)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

## License

This module is licensed under the MIT License.