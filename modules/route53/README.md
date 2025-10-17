# AWS Route53 Module

Terraform module for creating and managing Amazon Route53 hosted zones and DNS records with advanced features including health checks, traffic policies, failover routing, and DNSSEC.

## Features

- **Hosted Zones**: Public and private hosted zones
- **DNS Records**: All record types (A, AAAA, CNAME, MX, TXT, etc.)
- **Routing Policies**: Simple, weighted, latency, failover, geolocation, geoproximity, and multivalue
- **Health Checks**: HTTP, HTTPS, TCP, and calculated health checks
- **Traffic Flow**: Advanced traffic management policies
- **Alias Records**: Integration with AWS services (CloudFront, ALB, S3, etc.)
- **DNSSEC**: Domain name system security extensions
- **Query Logging**: CloudWatch Logs integration
- **VPC Association**: Private hosted zones for VPCs
- **Zone Delegation**: Subdomain delegation
- **TTL Management**: Configurable time-to-live values

## Usage

### Basic Public Hosted Zone

```hcl
module "domain" {
  source = "./modules/route53"

  domain_name = "example.com"
  zone_type   = "public"
  
  records = {
    root = {
      name = ""
      type = "A"
      ttl  = 300
      records = ["203.0.113.1"]
    }
    
    www = {
      name = "www"
      type = "CNAME"
      ttl  = 300
      records = ["example.com"]
    }
    
    mail = {
      name = ""
      type = "MX"
      ttl  = 3600
      records = [
        "10 mail1.example.com",
        "20 mail2.example.com"
      ]
    }
  }
  
  tags = {
    Environment = "production"
  }
}
```

### Alias Records for AWS Services

```hcl
module "app_domain" {
  source = "./modules/route53"

  domain_name = "app.example.com"
  zone_type   = "public"
  
  records = {
    # CloudFront distribution
    root = {
      name = ""
      type = "A"
      
      alias = {
        name                   = module.cdn.distribution_domain_name
        zone_id                = module.cdn.distribution_hosted_zone_id
        evaluate_target_health = false
      }
    }
    
    # Application Load Balancer
    api = {
      name = "api"
      type = "A"
      
      alias = {
        name                   = module.alb.dns_name
        zone_id                = module.alb.zone_id
        evaluate_target_health = true
      }
    }
    
    # S3 website
    static = {
      name = "static"
      type = "A"
      
      alias = {
        name                   = aws_s3_bucket.static.website_domain
        zone_id                = aws_s3_bucket.static.hosted_zone_id
        evaluate_target_health = false
      }
    }
  }
  
  tags = {
    Environment = "production"
  }
}
```

### Failover Routing with Health Checks

```hcl
module "ha_domain" {
  source = "./modules/route53"

  domain_name = "ha.example.com"
  zone_type   = "public"
  
  # Health checks
  health_checks = {
    primary = {
      type              = "HTTPS"
      resource_path     = "/health"
      fqdn              = "primary.example.com"
      port              = 443
      request_interval  = 30
      failure_threshold = 3
      
      alarm_name = "primary-endpoint-down"
      alarm_actions = [aws_sns_topic.alerts.arn]
    }
    
    secondary = {
      type              = "HTTPS"
      resource_path     = "/health"
      fqdn              = "secondary.example.com"
      port              = 443
      request_interval  = 30
      failure_threshold = 3
      
      alarm_name = "secondary-endpoint-down"
      alarm_actions = [aws_sns_topic.alerts.arn]
    }
  }
  
  # Failover records
  records = {
    primary = {
      name           = "www"
      type           = "A"
      ttl            = 60
      records        = ["203.0.113.1"]
      set_identifier = "primary"
      
      failover_routing_policy = {
        type = "PRIMARY"
      }
      
      health_check_id = "primary"
    }
    
    secondary = {
      name           = "www"
      type           = "A"
      ttl            = 60
      records        = ["203.0.113.2"]
      set_identifier = "secondary"
      
      failover_routing_policy = {
        type = "SECONDARY"
      }
      
      health_check_id = "secondary"
    }
  }
  
  tags = {
    Environment = "production"
    HA          = "true"
  }
}
```

### Weighted Routing for Canary Deployments

```hcl
module "canary_domain" {
  source = "./modules/route53"

  domain_name = "api.example.com"
  zone_type   = "public"
  
  records = {
    stable = {
      name           = "api"
      type           = "A"
      set_identifier = "stable-version"
      
      alias = {
        name                   = module.alb_stable.dns_name
        zone_id                = module.alb_stable.zone_id
        evaluate_target_health = true
      }
      
      weighted_routing_policy = {
        weight = 90  # 90% traffic
      }
    }
    
    canary = {
      name           = "api"
      type           = "A"
      set_identifier = "canary-version"
      
      alias = {
        name                   = module.alb_canary.dns_name
        zone_id                = module.alb_canary.zone_id
        evaluate_target_health = true
      }
      
      weighted_routing_policy = {
        weight = 10  # 10% traffic
      }
    }
  }
  
  tags = {
    Environment = "production"
    Deployment  = "canary"
  }
}
```

### Geolocation Routing

```hcl
module "global_domain" {
  source = "./modules/route53"

  domain_name = "global.example.com"
  zone_type   = "public"
  
  records = {
    # US users
    us = {
      name           = "www"
      type           = "A"
      set_identifier = "US"
      
      alias = {
        name                   = module.alb_us.dns_name
        zone_id                = module.alb_us.zone_id
        evaluate_target_health = true
      }
      
      geolocation_routing_policy = {
        country = "US"
      }
    }
    
    # European users
    eu = {
      name           = "www"
      type           = "A"
      set_identifier = "EU"
      
      alias = {
        name                   = module.alb_eu.dns_name
        zone_id                = module.alb_eu.zone_id
        evaluate_target_health = true
      }
      
      geolocation_routing_policy = {
        continent = "EU"
      }
    }
    
    # Default for all other locations
    default = {
      name           = "www"
      type           = "A"
      set_identifier = "Default"
      
      alias = {
        name                   = module.alb_us.dns_name
        zone_id                = module.alb_us.zone_id
        evaluate_target_health = true
      }
      
      geolocation_routing_policy = {
        location = "*"  # Default
      }
    }
  }
  
  tags = {
    Environment = "production"
    Global      = "true"
  }
}
```

### Latency-Based Routing

```hcl
module "latency_domain" {
  source = "./modules/route53"

  domain_name = "fast.example.com"
  zone_type   = "public"
  
  records = {
    us_east = {
      name           = "api"
      type           = "A"
      set_identifier = "us-east-1"
      
      alias = {
        name                   = module.alb_us_east.dns_name
        zone_id                = module.alb_us_east.zone_id
        evaluate_target_health = true
      }
      
      latency_routing_policy = {
        region = "us-east-1"
      }
    }
    
    eu_west = {
      name           = "api"
      type           = "A"
      set_identifier = "eu-west-1"
      
      alias = {
        name                   = module.alb_eu_west.dns_name
        zone_id                = module.alb_eu_west.zone_id
        evaluate_target_health = true
      }
      
      latency_routing_policy = {
        region = "eu-west-1"
      }
    }
    
    ap_south = {
      name           = "api"
      type           = "A"
      set_identifier = "ap-south-1"
      
      alias = {
        name                   = module.alb_ap_south.dns_name
        zone_id                = module.alb_ap_south.zone_id
        evaluate_target_health = true
      }
      
      latency_routing_policy = {
        region = "ap-south-1"
      }
    }
  }
  
  tags = {
    Environment = "production"
    Routing     = "latency"
  }
}
```

### Private Hosted Zone

```hcl
module "internal_domain" {
  source = "./modules/route53"

  domain_name = "internal.example.com"
  zone_type   = "private"
  
  # Associate with VPCs
  vpc_associations = [
    {
      vpc_id     = module.vpc_us_east.vpc_id
      vpc_region = "us-east-1"
    },
    {
      vpc_id     = module.vpc_us_west.vpc_id
      vpc_region = "us-west-2"
    }
  ]
  
  records = {
    database = {
      name = "db"
      type = "CNAME"
      ttl  = 300
      records = [module.rds.endpoint]
    }
    
    cache = {
      name = "redis"
      type = "CNAME"
      ttl  = 300
      records = [module.elasticache.primary_endpoint_address]
    }
    
    api_internal = {
      name = "api"
      type = "A"
      
      alias = {
        name                   = module.internal_alb.dns_name
        zone_id                = module.internal_alb.zone_id
        evaluate_target_health = true
      }
    }
  }
  
  tags = {
    Environment = "production"
    Zone        = "private"
  }
}
```

### Advanced Production Configuration

```hcl
module "production_dns" {
  source = "./modules/route53"

  domain_name = "example.com"
  zone_type   = "public"
  
  # Enable DNSSEC
  enable_dnssec = true
  
  # Enable query logging
  enable_query_logging = true
  query_log_retention_days = 7
  
  # Health checks for all endpoints
  health_checks = {
    web_primary = {
      type              = "HTTPS"
      resource_path     = "/"
      fqdn              = "web1.example.com"
      port              = 443
      request_interval  = 30
      failure_threshold = 3
      measure_latency   = true
      
      alarm_name    = "web-primary-down"
      alarm_actions = [aws_sns_topic.critical_alerts.arn]
    }
    
    web_secondary = {
      type              = "HTTPS"
      resource_path     = "/"
      fqdn              = "web2.example.com"
      port              = 443
      request_interval  = 30
      failure_threshold = 3
      measure_latency   = true
      
      alarm_name    = "web-secondary-down"
      alarm_actions = [aws_sns_topic.critical_alerts.arn]
    }
    
    api_us = {
      type              = "HTTPS"
      resource_path     = "/health"
      fqdn              = "api-us.example.com"
      port              = 443
      request_interval  = 30
      failure_threshold = 2
      measure_latency   = true
      
      alarm_name    = "api-us-down"
      alarm_actions = [aws_sns_topic.alerts.arn]
    }
    
    api_eu = {
      type              = "HTTPS"
      resource_path     = "/health"
      fqdn              = "api-eu.example.com"
      port              = 443
      request_interval  = 30
      failure_threshold = 2
      measure_latency   = true
      
      alarm_name    = "api-eu-down"
      alarm_actions = [aws_sns_topic.alerts.arn]
    }
  }
  
  records = {
    # Root domain with failover
    root_primary = {
      name           = ""
      type           = "A"
      set_identifier = "root-primary"
      
      alias = {
        name                   = module.cloudfront_primary.distribution_domain_name
        zone_id                = module.cloudfront_primary.distribution_hosted_zone_id
        evaluate_target_health = false
      }
      
      failover_routing_policy = {
        type = "PRIMARY"
      }
      
      health_check_id = "web_primary"
    }
    
    root_secondary = {
      name           = ""
      type           = "A"
      set_identifier = "root-secondary"
      
      alias = {
        name                   = module.cloudfront_secondary.distribution_domain_name
        zone_id                = module.cloudfront_secondary.distribution_hosted_zone_id
        evaluate_target_health = false
      }
      
      failover_routing_policy = {
        type = "SECONDARY"
      }
      
      health_check_id = "web_secondary"
    }
    
    # WWW subdomain
    www = {
      name = "www"
      type = "CNAME"
      ttl  = 300
      records = ["example.com"]
    }
    
    # API with latency-based routing
    api_us_east = {
      name           = "api"
      type           = "A"
      set_identifier = "api-us-east-1"
      
      alias = {
        name                   = module.api_alb_us_east.dns_name
        zone_id                = module.api_alb_us_east.zone_id
        evaluate_target_health = true
      }
      
      latency_routing_policy = {
        region = "us-east-1"
      }
      
      health_check_id = "api_us"
    }
    
    api_eu_west = {
      name           = "api"
      type           = "A"
      set_identifier = "api-eu-west-1"
      
      alias = {
        name                   = module.api_alb_eu_west.dns_name
        zone_id                = module.api_alb_eu_west.zone_id
        evaluate_target_health = true
      }
      
      latency_routing_policy = {
        region = "eu-west-1"
      }
      
      health_check_id = "api_eu"
    }
    
    # Email records
    mx = {
      name = ""
      type = "MX"
      ttl  = 3600
      records = [
        "1 aspmx.l.google.com",
        "5 alt1.aspmx.l.google.com",
        "5 alt2.aspmx.l.google.com",
        "10 alt3.aspmx.l.google.com",
        "10 alt4.aspmx.l.google.com"
      ]
    }
    
    # SPF record
    spf = {
      name = ""
      type = "TXT"
      ttl  = 300
      records = ["v=spf1 include:_spf.google.com ~all"]
    }
    
    # DKIM record
    dkim = {
      name = "google._domainkey"
      type = "TXT"
      ttl  = 300
      records = ["v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC..."]
    }
    
    # DMARC record
    dmarc = {
      name = "_dmarc"
      type = "TXT"
      ttl  = 300
      records = ["v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com"]
    }
    
    # CAA record for certificate authority
    caa = {
      name = ""
      type = "CAA"
      ttl  = 300
      records = [
        "0 issue \"amazon.com\"",
        "0 issuewildcard \"amazon.com\"",
        "0 iodef \"mailto:security@example.com\""
      ]
    }
  }
  
  tags = {
    Environment      = "production"
    ManagedBy        = "terraform"
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
| domain_name | Domain name for hosted zone | `string` | n/a | yes |
| zone_type | Type of hosted zone (public or private) | `string` | `"public"` | no |
| vpc_associations | VPC associations for private zones | `list(object)` | `[]` | no |
| records | Map of DNS record configurations | `map(any)` | `{}` | no |
| health_checks | Map of health check configurations | `map(any)` | `{}` | no |
| enable_dnssec | Enable DNSSEC | `bool` | `false` | no |
| enable_query_logging | Enable query logging | `bool` | `false` | no |
| query_log_retention_days | Query log retention in days | `number` | `7` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| zone_id | Hosted zone ID |
| zone_arn | Hosted zone ARN |
| name_servers | List of name servers |
| zone_name | Hosted zone name |
| health_check_ids | Map of health check IDs |

## Best Practices

### DNS Configuration

- Use **low TTL values** during migrations (60-300s)
- Use **higher TTL values** for stable records (3600s+)
- Implement **health checks** for critical endpoints
- Use **alias records** for AWS resources (no charge)
- Enable **DNSSEC** for enhanced security
- Test **DNS changes** before applying

### High Availability

- Use **failover routing** for DR
- Implement **health checks** with alarms
- Use **multiple regions** with latency routing
- Test **failover scenarios** regularly
- Monitor **health check status**

### Performance

- Use **latency-based routing** for global apps
- Enable **query logging** for analysis
- Use **geolocation routing** for compliance
- Minimize **DNS lookups** (CNAMEs)
- Use **alias records** when possible

### Security

- Enable **DNSSEC** for production domains
- Use **CAA records** to restrict CAs
- Implement **SPF, DKIM, DMARC** for email
- Use **private hosted zones** for internal DNS
- Restrict **zone transfers**
- Monitor **query patterns** for DDoS

### Cost Optimization

- Use **alias records** (free queries)
- Consolidate **hosted zones** where possible
- Use **longer TTL** values to reduce queries
- Delete **unused zones**
- Monitor **query counts**

## Cost Considerations

### Pricing Components

**Hosted Zones:**
- First 25 zones: $0.50 per month each
- Additional zones: $0.10 per month each

**Standard Queries:**
- First 1B queries/month: $0.40 per million
- Over 1B queries/month: $0.20 per million

**Alias Queries:** Free

**Latency-Based Routing:**
- $0.60 per million queries

**Geo DNS Queries:**
- $0.70 per million queries

**Health Checks:**
- AWS endpoints: $0.50 per month
- Non-AWS endpoints: $0.75 per month
- HTTPS: Additional $1.00 per month

### Example Monthly Costs

| Configuration | Cost |
|--------------|------|
| 1 zone, 10M queries (standard) | ~$4.50 |
| 5 zones, 100M queries | ~$42.50 |
| 10 zones, 1B queries, 5 health checks | ~$407.50 |
| Enterprise (50 zones, 10B queries) | ~$2,015 |

**Cost Optimization:**
- Use alias records (free)
- Increase TTL values
- Use standard routing when possible
- Consolidate zones

## Additional Resources

- [Route53 Developer Guide](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/)
- [Route53 Best Practices](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/best-practices.html)
- [Route53 Pricing](https://aws.amazon.com/route53/pricing/)
- [DNS Best Practices](https://www.rfc-editor.org/rfc/rfc1912)

## License

This module is licensed under the MIT License.