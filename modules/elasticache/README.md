# AWS ElastiCache Module

Terraform module for creating and managing Amazon ElastiCache clusters (Redis and Memcached) with advanced features including replication, clustering, automatic failover, encryption, and backup capabilities.

## Features

- **Multiple Engines**: Redis and Memcached support
- **Redis Modes**: Cluster mode and non-cluster mode
- **High Availability**: Multi-AZ with automatic failover
- **Replication**: Read replicas for Redis
- **Encryption**: At-rest and in-transit encryption
- **Authentication**: Redis AUTH and RBAC support
- **Backup and Restore**: Automatic snapshots and point-in-time recovery
- **CloudWatch Integration**: Comprehensive metrics and alarms
- **Parameter Groups**: Custom configuration parameters
- **Subnet Groups**: VPC subnet configuration
- **Security Groups**: Network access control
- **Scaling**: Vertical and horizontal scaling
- **Global Datastore**: Multi-region replication (Redis)

## Usage

### Simple Redis Cluster

```hcl
module "redis_cache" {
  source = "./modules/elasticache"

  cluster_id  = "app-cache"
  engine      = "redis"
  node_type   = "cache.t3.micro"
  num_cache_nodes = 1
  
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.redis.id]
  
  tags = {
    Environment = "production"
  }
}
```

### Redis with Replication and Automatic Failover

```hcl
module "redis_ha" {
  source = "./modules/elasticache"

  cluster_id           = "redis-ha"
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.r7g.large"
  
  # Multi-AZ with automatic failover
  multi_az_enabled       = true
  automatic_failover_enabled = true
  
  # 1 primary + 2 replicas
  num_cache_nodes        = 3
  
  # Network configuration
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.redis.id]
  
  # Maintenance window
  maintenance_window = "sun:05:00-sun:06:00"
  
  # Snapshot configuration
  snapshot_retention_limit = 5
  snapshot_window         = "03:00-04:00"
  
  tags = {
    Environment = "production"
    HA          = "true"
  }
}
```

### Redis Cluster Mode Enabled

```hcl
module "redis_cluster" {
  source = "./modules/elasticache"

  replication_group_id = "redis-cluster"
  description          = "Redis cluster mode enabled"
  
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.r7g.xlarge"
  
  # Cluster mode configuration
  cluster_mode_enabled = true
  num_node_groups      = 3  # Number of shards
  replicas_per_node_group = 2  # Replicas per shard
  
  # Automatic failover required for cluster mode
  automatic_failover_enabled = true
  multi_az_enabled          = true
  
  # Network
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.redis.id]
  
  # Parameter group for cluster mode
  parameter_group_family = "redis7.cluster.on"
  
  parameters = {
    "cluster-enabled"           = "yes"
    "maxmemory-policy"         = "allkeys-lru"
    "timeout"                  = "300"
  }
  
  tags = {
    Environment = "production"
    Mode        = "cluster"
  }
}
```

### Redis with Encryption and Authentication

```hcl
module "secure_redis" {
  source = "./modules/elasticache"

  replication_group_id = "secure-redis"
  description          = "Encrypted Redis with authentication"
  
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.r7g.large"
  num_cache_nodes      = 2
  
  # Multi-AZ
  automatic_failover_enabled = true
  multi_az_enabled          = true
  
  # Encryption at rest
  at_rest_encryption_enabled = true
  kms_key_id                = aws_kms_key.redis.arn
  
  # Encryption in transit
  transit_encryption_enabled = true
  
  # Authentication
  auth_token_enabled = true
  auth_token        = random_password.redis_auth.result
  
  # Network
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.redis.id]
  
  # Snapshot configuration
  snapshot_retention_limit = 7
  snapshot_window         = "03:00-05:00"
  
  # Notifications
  notification_topic_arn = aws_sns_topic.cache_events.arn
  
  tags = {
    Environment = "production"
    Security    = "high"
    Compliance  = "pci-dss"
  }
}

resource "random_password" "redis_auth" {
  length  = 32
  special = true
}
```

### Memcached Cluster

```hcl
module "memcached" {
  source = "./modules/elasticache"

  cluster_id     = "memcached-cluster"
  engine         = "memcached"
  engine_version = "1.6.17"
  node_type      = "cache.t3.medium"
  num_cache_nodes = 3
  
  # AZ placement
  az_mode                  = "cross-az"
  preferred_availability_zones = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c"
  ]
  
  # Network
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.memcached.id]
  
  # Parameter group
  parameter_group_family = "memcached1.6"
  
  parameters = {
    "max_item_size" = "5242880"  # 5MB
  }
  
  tags = {
    Environment = "production"
    Engine      = "memcached"
  }
}
```

### Redis Global Datastore (Multi-Region)

```hcl
# Primary region (us-east-1)
module "redis_primary" {
  source = "./modules/elasticache"
  
  providers = {
    aws = aws.us-east-1
  }

  replication_group_id = "global-redis-primary"
  description          = "Primary Redis cluster for global datastore"
  
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.r7g.large"
  
  cluster_mode_enabled       = true
  num_node_groups           = 2
  replicas_per_node_group   = 1
  automatic_failover_enabled = true
  multi_az_enabled          = true
  
  # Enable global datastore
  global_replication_group_enabled = true
  
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  
  subnet_ids         = module.vpc_us_east.private_subnet_ids
  security_group_ids = [aws_security_group.redis_us_east.id]
  
  tags = {
    Environment = "production"
    Region      = "primary"
  }
}

# Secondary region (eu-west-1)
module "redis_secondary" {
  source = "./modules/elasticache"
  
  providers = {
    aws = aws.eu-west-1
  }

  replication_group_id = "global-redis-secondary"
  description          = "Secondary Redis cluster for global datastore"
  
  # Link to global datastore
  global_replication_group_id = module.redis_primary.global_replication_group_id
  
  subnet_ids         = module.vpc_eu_west.private_subnet_ids
  security_group_ids = [aws_security_group.redis_eu_west.id]
  
  tags = {
    Environment = "production"
    Region      = "secondary"
  }
}
```

### Advanced Production Redis

```hcl
module "production_redis" {
  source = "./modules/elasticache"

  replication_group_id = "prod-redis"
  description          = "Production Redis cluster"
  
  # Engine configuration
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.r7g.2xlarge"
  
  # Cluster mode for horizontal scaling
  cluster_mode_enabled       = true
  num_node_groups           = 4
  replicas_per_node_group   = 2
  automatic_failover_enabled = true
  multi_az_enabled          = true
  
  # Security
  at_rest_encryption_enabled = true
  kms_key_id                = aws_kms_key.redis.arn
  transit_encryption_enabled = true
  auth_token_enabled        = true
  auth_token                = data.aws_secretsmanager_secret_version.redis_auth.secret_string
  
  # Network
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.redis.id]
  
  # Parameter group
  parameter_group_family = "redis7.cluster.on"
  
  parameters = {
    "cluster-enabled"           = "yes"
    "maxmemory-policy"         = "allkeys-lru"
    "maxmemory-samples"        = "10"
    "timeout"                  = "300"
    "tcp-keepalive"            = "300"
    "notify-keyspace-events"   = "Ex"
    "slowlog-log-slower-than"  = "10000"
    "slowlog-max-len"          = "128"
  }
  
  # Backup and recovery
  snapshot_retention_limit = 14
  snapshot_window         = "03:00-05:00"
  final_snapshot_identifier = "prod-redis-final-snapshot"
  
  # Maintenance
  maintenance_window = "sun:05:00-sun:07:00"
  
  # Auto minor version upgrade
  auto_minor_version_upgrade = true
  
  # Notifications
  notification_topic_arn = aws_sns_topic.elasticache_events.arn
  
  # Log delivery
  log_delivery_configuration = {
    slow_log = {
      destination      = aws_cloudwatch_log_group.redis_slow_log.name
      destination_type = "cloudwatch-logs"
      log_format       = "json"
    }
    engine_log = {
      destination      = aws_cloudwatch_log_group.redis_engine_log.name
      destination_type = "cloudwatch-logs"
      log_format       = "json"
    }
  }
  
  # CloudWatch alarms
  create_cloudwatch_alarms = true
  
  alarm_cpu_threshold            = 75
  alarm_memory_threshold         = 90
  alarm_swap_usage_threshold     = 50000000  # 50MB
  alarm_evictions_threshold      = 1000
  alarm_replication_lag_threshold = 30
  
  alarm_actions = [aws_sns_topic.cloudwatch_alarms.arn]
  
  tags = {
    Environment      = "production"
    ManagedBy        = "terraform"
    CriticalityLevel = "high"
    Backup           = "required"
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
| cluster_id | Cluster identifier (Memcached or single-node Redis) | `string` | `null` | no |
| replication_group_id | Replication group ID (Redis with replication) | `string` | `null` | no |
| description | Description of the cluster | `string` | `""` | no |
| engine | Cache engine (redis or memcached) | `string` | `"redis"` | no |
| engine_version | Engine version | `string` | `null` | no |
| node_type | Node instance type | `string` | n/a | yes |
| num_cache_nodes | Number of cache nodes | `number` | `1` | no |
| cluster_mode_enabled | Enable Redis cluster mode | `bool` | `false` | no |
| num_node_groups | Number of node groups (shards) | `number` | `null` | no |
| replicas_per_node_group | Number of replicas per shard | `number` | `null` | no |
| automatic_failover_enabled | Enable automatic failover | `bool` | `false` | no |
| multi_az_enabled | Enable Multi-AZ | `bool` | `false` | no |
| at_rest_encryption_enabled | Enable encryption at rest | `bool` | `false` | no |
| kms_key_id | KMS key ID for encryption | `string` | `null` | no |
| transit_encryption_enabled | Enable encryption in transit | `bool` | `false` | no |
| auth_token_enabled | Enable Redis AUTH | `bool` | `false` | no |
| auth_token | Redis AUTH token | `string` | `null` | no |
| subnet_ids | List of subnet IDs | `list(string)` | n/a | yes |
| security_group_ids | List of security group IDs | `list(string)` | n/a | yes |
| parameter_group_family | Parameter group family | `string` | `null` | no |
| parameters | Map of parameters | `map(string)` | `{}` | no |
| snapshot_retention_limit | Number of days to retain snapshots | `number` | `0` | no |
| snapshot_window | Snapshot window | `string` | `null` | no |
| maintenance_window | Maintenance window | `string` | `null` | no |
| notification_topic_arn | SNS topic ARN for notifications | `string` | `null` | no |
| create_cloudwatch_alarms | Create CloudWatch alarms | `bool` | `false` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | Cluster identifier |
| cluster_arn | Cluster ARN |
| cluster_address | Cluster endpoint address |
| cluster_port | Cluster port |
| configuration_endpoint | Configuration endpoint (cluster mode) |
| reader_endpoint | Reader endpoint (Redis) |
| primary_endpoint_address | Primary endpoint address |
| member_clusters | List of cluster members |

## Best Practices

### Redis Configuration

- Use **cluster mode** for horizontal scaling (> 250GB or > 90% CPU)
- Enable **Multi-AZ** for production workloads
- Use **r7g instances** (Graviton2) for better price-performance
- Set appropriate **maxmemory-policy** (typically allkeys-lru)
- Enable **persistence** (AOF or RDB) for data durability
- Use **read replicas** for read-heavy workloads

### Security

- Always enable **encryption at rest** for production
- Enable **encryption in transit** (TLS)
- Use **Redis AUTH** tokens
- Implement **least privilege** security groups
- Use **VPC** deployment (never use public endpoints)
- Regularly rotate **AUTH tokens**
- Use **AWS Secrets Manager** for credential management

### Performance

- Choose **appropriate node type** based on workload
- Monitor **CPU, memory, and network** metrics
- Use **pipelining** for batch operations
- Implement **connection pooling** in applications
- Enable **cluster mode** for datasets > 250GB
- Use **reserved nodes** for cost savings

### High Availability

- Enable **automatic failover**
- Use **Multi-AZ** deployment
- Configure **multiple read replicas**
- Set up **CloudWatch alarms**
- Test **failover scenarios**
- Use **Global Datastore** for multi-region

### Cost Optimization

- Use **Graviton2 instances** (r7g) for 35% better price-performance
- Right-size **node types** based on usage
- Use **reserved instances** (1-year or 3-year)
- Enable **Auto Discovery** for Memcached
- Clean up **unused clusters**
- Monitor and optimize **data size**

### Monitoring

Monitor these key metrics:
- **CPUUtilization**: Should be < 75%
- **DatabaseMemoryUsagePercentage**: Should be < 90%
- **SwapUsage**: Should be near zero
- **Evictions**: Should be minimal
- **CurrConnections**: Monitor for connection leaks
- **ReplicationLag**: Should be < 30 seconds

## Cost Considerations

### Pricing Components

**On-Demand Pricing (per hour):**
- cache.t3.micro: ~$0.017
- cache.t3.medium: ~$0.068
- cache.r7g.large: ~$0.151
- cache.r7g.xlarge: ~$0.302
- cache.r7g.4xlarge: ~$1.209

**Reserved Instances (1-year, all upfront):**
- Savings: ~35% compared to on-demand
- cache.r7g.large: ~$0.098/hour

**Backup Storage:**
- Free up to cluster size
- Additional: $0.085 per GB per month

### Example Monthly Costs

| Configuration | Monthly Cost |
|--------------|--------------|
| 1x cache.t3.micro (dev) | ~$12 |
| 1x cache.r7g.large + 1 replica | ~$220 |
| Cluster mode (3 shards, 2 replicas each) | ~$2,700 |
| Enterprise (12 shards, r7g.4xlarge) | ~$52,000 |

**Cost Optimization:**
- Use t3/t4g for dev/test
- Use r7g (Graviton) for production
- Purchase reserved instances
- Right-size based on metrics

## Additional Resources

- [ElastiCache for Redis Guide](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/)
- [ElastiCache for Memcached Guide](https://docs.aws.amazon.com/AmazonElastiCache/latest/mem-ug/)
- [ElastiCache Best Practices](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/BestPractices.html)
- [ElastiCache Pricing](https://aws.amazon.com/elasticache/pricing/)
- [Redis Documentation](https://redis.io/documentation)

## License

This module is licensed under the MIT License.