# AWS DynamoDB Table Module

Terraform module for creating and managing Amazon DynamoDB tables with advanced features including global tables, point-in-time recovery, encryption, auto-scaling, and stream configuration.

## Features

- **Flexible Capacity Modes**: On-demand and provisioned billing
- **Auto-Scaling**: Automatic scaling for provisioned capacity
- **Global Tables**: Multi-region replication for high availability
- **Point-in-Time Recovery**: Continuous backups with 35-day retention
- **Encryption**: Server-side encryption with AWS-managed or customer-managed KMS keys
- **DynamoDB Streams**: Change data capture for event-driven architectures
- **Time-to-Live (TTL)**: Automatic expiration of items
- **Global Secondary Indexes**: Additional query patterns with flexible key schemas
- **Local Secondary Indexes**: Alternative sort keys for the table
- **Contributor Insights**: Identify most accessed items
- **CloudWatch Alarms**: Built-in monitoring and alerting
- **Tags**: Comprehensive resource tagging support
- **Backup Integration**: AWS Backup service integration
- **Table Class**: Standard or Standard-IA (Infrequent Access)

## Usage

### Basic DynamoDB Table

```hcl
module "basic_table" {
  source = "./modules/dynamodb"

  table_name = "users"
  hash_key   = "user_id"
  
  attributes = {
    user_id = "S"  # String
  }
  
  tags = {
    Environment = "production"
    Application = "user-service"
  }
}
```

### Table with Sort Key

```hcl
module "orders_table" {
  source = "./modules/dynamodb"

  table_name = "orders"
  hash_key   = "customer_id"
  range_key  = "order_date"
  
  attributes = {
    customer_id = "S"
    order_date  = "S"
  }
  
  billing_mode = "PAY_PER_REQUEST"
  
  tags = {
    Environment = "production"
    Application = "order-service"
  }
}
```

### Table with Global Secondary Indexes

```hcl
module "products_table" {
  source = "./modules/dynamodb"

  table_name = "products"
  hash_key   = "product_id"
  
  attributes = {
    product_id   = "S"
    category     = "S"
    price        = "N"
    created_date = "S"
  }
  
  global_secondary_indexes = {
    category_index = {
      hash_key           = "category"
      range_key          = "price"
      projection_type    = "ALL"
      read_capacity      = 5
      write_capacity     = 5
    }
    date_index = {
      hash_key           = "category"
      range_key          = "created_date"
      projection_type    = "INCLUDE"
      non_key_attributes = ["product_name", "price"]
      read_capacity      = 5
      write_capacity     = 5
    }
  }
  
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  
  tags = {
    Environment = "production"
  }
}
```

### Table with Auto-Scaling

```hcl
module "autoscaling_table" {
  source = "./modules/dynamodb"

  table_name = "sessions"
  hash_key   = "session_id"
  
  attributes = {
    session_id = "S"
  }
  
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  
  # Auto-scaling configuration
  autoscaling_enabled = true
  
  autoscaling_read = {
    min_capacity       = 5
    max_capacity       = 100
    target_utilization = 70
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
  
  autoscaling_write = {
    min_capacity       = 5
    max_capacity       = 100
    target_utilization = 70
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
  
  tags = {
    Environment = "production"
  }
}
```

### Table with Streams and Lambda Trigger

```hcl
module "events_table" {
  source = "./modules/dynamodb"

  table_name = "events"
  hash_key   = "event_id"
  range_key  = "timestamp"
  
  attributes = {
    event_id  = "S"
    timestamp = "N"
  }
  
  # Enable DynamoDB Streams
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  
  billing_mode = "PAY_PER_REQUEST"
  
  tags = {
    Environment = "production"
    Application = "event-stream"
  }
}

# Lambda to process stream
resource "aws_lambda_event_source_mapping" "dynamodb_stream" {
  event_source_arn  = module.events_table.stream_arn
  function_name     = module.stream_processor.function_arn
  starting_position = "LATEST"
  batch_size        = 100
  
  maximum_batching_window_in_seconds = 5
  maximum_retry_attempts             = 3
  
  filter_criteria {
    filter {
      pattern = jsonencode({
        eventName = ["INSERT", "MODIFY"]
      })
    }
  }
}
```

### Global Table with Encryption

```hcl
module "global_table" {
  source = "./modules/dynamodb"

  table_name = "global-users"
  hash_key   = "user_id"
  
  attributes = {
    user_id = "S"
  }
  
  # Global table replication
  replica_regions = ["us-west-2", "eu-west-1", "ap-southeast-1"]
  
  # Encryption with customer-managed key
  server_side_encryption_enabled = true
  kms_key_arn                    = aws_kms_key.dynamodb.arn
  
  # Point-in-time recovery
  point_in_time_recovery_enabled = true
  
  billing_mode = "PAY_PER_REQUEST"
  
  tags = {
    Environment = "production"
    Scope       = "global"
  }
}
```

### Table with Time-to-Live

```hcl
module "ttl_table" {
  source = "./modules/dynamodb"

  table_name = "temporary-data"
  hash_key   = "record_id"
  
  attributes = {
    record_id = "S"
  }
  
  # TTL configuration
  ttl_enabled        = true
  ttl_attribute_name = "expiration_time"
  
  billing_mode = "PAY_PER_REQUEST"
  
  tags = {
    Environment = "production"
    DataType    = "temporary"
  }
}
```

### Advanced Production Table

```hcl
module "production_table" {
  source = "./modules/dynamodb"

  table_name = "transactions"
  hash_key   = "transaction_id"
  range_key  = "timestamp"
  
  attributes = {
    transaction_id = "S"
    timestamp      = "N"
    user_id        = "S"
    status         = "S"
  }
  
  # Global Secondary Indexes
  global_secondary_indexes = {
    user_transactions = {
      hash_key           = "user_id"
      range_key          = "timestamp"
      projection_type    = "ALL"
      read_capacity      = 10
      write_capacity     = 10
    }
    status_index = {
      hash_key           = "status"
      range_key          = "timestamp"
      projection_type    = "KEYS_ONLY"
      read_capacity      = 5
      write_capacity     = 5
    }
  }
  
  # Capacity and scaling
  billing_mode   = "PROVISIONED"
  read_capacity  = 25
  write_capacity = 25
  
  autoscaling_enabled = true
  autoscaling_read = {
    min_capacity       = 25
    max_capacity       = 500
    target_utilization = 70
  }
  autoscaling_write = {
    min_capacity       = 25
    max_capacity       = 500
    target_utilization = 70
  }
  
  # Streams for change data capture
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  
  # Security and compliance
  server_side_encryption_enabled = true
  kms_key_arn                    = aws_kms_key.dynamodb.arn
  point_in_time_recovery_enabled = true
  
  # TTL for automatic cleanup
  ttl_enabled        = true
  ttl_attribute_name = "ttl"
  
  # Table class (use Standard-IA for infrequent access)
  table_class = "STANDARD"
  
  # Contributor Insights
  contributor_insights_enabled = true
  
  tags = {
    Environment      = "production"
    Application      = "payment-service"
    CriticalityLevel = "high"
    Compliance       = "pci-dss"
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
| table_name | Name of the DynamoDB table | `string` | n/a | yes |
| hash_key | Hash key (partition key) attribute name | `string` | n/a | yes |
| range_key | Range key (sort key) attribute name | `string` | `null` | no |
| attributes | Map of attribute names to types (S, N, B) | `map(string)` | n/a | yes |
| billing_mode | Billing mode (PROVISIONED or PAY_PER_REQUEST) | `string` | `"PAY_PER_REQUEST"` | no |
| read_capacity | Read capacity units (provisioned mode) | `number` | `5` | no |
| write_capacity | Write capacity units (provisioned mode) | `number` | `5` | no |
| global_secondary_indexes | Map of global secondary index configurations | `map(any)` | `{}` | no |
| local_secondary_indexes | Map of local secondary index configurations | `map(any)` | `{}` | no |
| stream_enabled | Enable DynamoDB Streams | `bool` | `false` | no |
| stream_view_type | Stream view type (KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES) | `string` | `"NEW_AND_OLD_IMAGES"` | no |
| ttl_enabled | Enable Time-to-Live | `bool` | `false` | no |
| ttl_attribute_name | TTL attribute name | `string` | `"ttl"` | no |
| server_side_encryption_enabled | Enable server-side encryption | `bool` | `true` | no |
| kms_key_arn | KMS key ARN for encryption | `string` | `null` | no |
| point_in_time_recovery_enabled | Enable point-in-time recovery | `bool` | `true` | no |
| replica_regions | List of regions for global table replication | `list(string)` | `[]` | no |
| table_class | Table class (STANDARD or STANDARD_IA) | `string` | `"STANDARD"` | no |
| contributor_insights_enabled | Enable CloudWatch Contributor Insights | `bool` | `false` | no |
| autoscaling_enabled | Enable auto-scaling for provisioned capacity | `bool` | `false` | no |
| autoscaling_read | Auto-scaling configuration for read capacity | `object` | `null` | no |
| autoscaling_write | Auto-scaling configuration for write capacity | `object` | `null` | no |
| deletion_protection_enabled | Enable deletion protection | `bool` | `false` | no |
| restore_to_point_in_time | Restore from point-in-time | `object` | `null` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| table_id | ID of the DynamoDB table |
| table_name | Name of the DynamoDB table |
| table_arn | ARN of the DynamoDB table |
| stream_arn | ARN of the DynamoDB stream |
| stream_label | Stream label of the DynamoDB table |
| hash_key | Hash key of the table |
| range_key | Range key of the table |

## Examples

### Single-Table Design Pattern

```hcl
module "single_table" {
  source = "./modules/dynamodb"

  table_name = "app-data"
  hash_key   = "PK"
  range_key  = "SK"
  
  attributes = {
    PK          = "S"
    SK          = "S"
    GSI1PK      = "S"
    GSI1SK      = "S"
    GSI2PK      = "S"
    GSI2SK      = "S"
  }
  
  global_secondary_indexes = {
    gsi1 = {
      hash_key        = "GSI1PK"
      range_key       = "GSI1SK"
      projection_type = "ALL"
    }
    gsi2 = {
      hash_key        = "GSI2PK"
      range_key       = "GSI2SK"
      projection_type = "ALL"
    }
  }
  
  billing_mode = "PAY_PER_REQUEST"
  
  point_in_time_recovery_enabled = true
  server_side_encryption_enabled = true
  
  tags = {
    Environment = "production"
    Pattern     = "single-table-design"
  }
}
```

## Best Practices

### Design Patterns

- Use **single-table design** for better performance and cost efficiency
- Design **partition keys** to distribute data evenly
- Use **composite sort keys** for hierarchical data
- Leverage **sparse indexes** for optional attributes
- Use **GSI overloading** for multiple access patterns

### Performance

- Keep **item sizes under 4KB** for better performance
- Use **batch operations** (BatchGetItem, BatchWriteItem)
- Implement **exponential backoff** for retries
- Use **projection expressions** to retrieve only needed attributes
- Consider **DAX** (DynamoDB Accelerator) for read-heavy workloads

### Cost Optimization

- Use **PAY_PER_REQUEST** for unpredictable workloads
- Use **PROVISIONED** with auto-scaling for steady traffic
- Consider **Standard-IA** table class for infrequent access
- Use **TTL** to automatically delete expired items
- Optimize **GSI projection types** (KEYS_ONLY when possible)
- Archive old data to **S3** using DynamoDB exports

### Security

- Enable **encryption at rest** with customer-managed keys
- Use **IAM policies** for fine-grained access control
- Enable **VPC endpoints** for private access
- Enable **CloudTrail** for audit logging
- Use **point-in-time recovery** for data protection
- Enable **deletion protection** for production tables

### Monitoring

- Monitor **ConsumedReadCapacityUnits** and **ConsumedWriteCapacityUnits**
- Set alarms for **UserErrors** and **SystemErrors**
- Monitor **throttled requests** (ThrottledRequests metric)
- Track **table size** and **item count**
- Use **CloudWatch Contributor Insights** for hot partitions

## Cost Considerations

### Pricing Components

**On-Demand Mode:**
- Write: $1.25 per million write request units
- Read: $0.25 per million read request units

**Provisioned Mode:**
- Write: $0.00065 per WCU per hour
- Read: $0.00013 per RCU per hour

**Storage:**
- $0.25 per GB per month (Standard)
- $0.10 per GB per month (Standard-IA)

**Additional Features:**
- Streams: $0.02 per 100,000 read requests
- Backups: $0.10 per GB per month
- Global Tables: Replicated write cost
- Point-in-time Recovery: Continuous backups storage cost

### Example Costs

| Configuration | Write/Read Requests | Storage | Monthly Cost |
|---------------|---------------------|---------|--------------|
| Small on-demand | 1M/10M per month | 1 GB | ~$4 |
| Medium on-demand | 100M/500M per month | 10 GB | ~$250 |
| Provisioned 10/50 WCU/RCU | Always available | 50 GB | ~$65 |
| Global table (3 regions) | 100M writes | 20 GB | ~$500 |

**Note**: Actual costs vary by region and usage patterns.

## Additional Resources

- [DynamoDB Developer Guide](https://docs.aws.amazon.com/dynamodb/latest/developerguide/)
- [Best Practices for DynamoDB](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)
- [DynamoDB Pricing](https://aws.amazon.com/dynamodb/pricing/)
- [Single-Table Design Guide](https://www.alexdebrie.com/posts/dynamodb-single-table/)

## License

This module is licensed under the MIT License.