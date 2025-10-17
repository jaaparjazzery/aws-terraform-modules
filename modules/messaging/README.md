# AWS SNS/SQS Module

Terraform module for creating and managing Amazon Simple Notification Service (SNS) topics and Simple Queue Service (SQS) queues with advanced features including dead letter queues, FIFO queues, SNS-SQS fanout patterns, and encryption.

## Features

- **SNS Topics**: Standard and FIFO topics with multiple subscription types
- **SQS Queues**: Standard and FIFO queues with configurable parameters
- **Dead Letter Queues**: Automatic DLQ creation and configuration
- **Encryption**: Server-side encryption with AWS-managed or customer-managed KMS keys
- **SNS-SQS Integration**: Automatic fanout pattern setup
- **Message Filtering**: Content-based message filtering
- **Access Policies**: Fine-grained access control
- **Delivery Policies**: Retry and backoff configuration
- **CloudWatch Alarms**: Built-in monitoring and alerting
- **FIFO Support**: Ordered message delivery and deduplication
- **Cross-Account Access**: Share topics and queues across accounts
- **Redrive Policies**: Automatic message reprocessing

## Usage

### Basic SNS Topic

```hcl
module "notifications" {
  source = "./modules/messaging"

  create_sns_topic = true
  sns_topic_name   = "app-notifications"
  
  # Email subscription
  sns_subscriptions = {
    email = {
      protocol = "email"
      endpoint = "team@example.com"
    }
  }
  
  tags = {
    Environment = "production"
  }
}
```

### Basic SQS Queue

```hcl
module "task_queue" {
  source = "./modules/messaging"

  create_sqs_queue = true
  sqs_queue_name   = "task-queue"
  
  # Queue configuration
  visibility_timeout_seconds = 300
  message_retention_seconds  = 86400  # 1 day
  max_message_size          = 262144  # 256 KB
  receive_wait_time_seconds = 20      # Long polling
  
  tags = {
    Environment = "production"
  }
}
```

### SQS Queue with Dead Letter Queue

```hcl
module "reliable_queue" {
  source = "./modules/messaging"

  create_sqs_queue = true
  sqs_queue_name   = "order-processing"
  
  # Queue settings
  visibility_timeout_seconds = 300
  message_retention_seconds  = 345600  # 4 days
  
  # Dead Letter Queue
  create_dlq             = true
  dlq_name               = "order-processing-dlq"
  max_receive_count      = 3
  dlq_message_retention  = 1209600  # 14 days
  
  tags = {
    Environment = "production"
  }
}
```

### FIFO Queue with Content Deduplication

```hcl
module "fifo_queue" {
  source = "./modules/messaging"

  create_sqs_queue = true
  sqs_queue_name   = "transactions.fifo"
  fifo_queue       = true
  
  # FIFO settings
  content_based_deduplication = true
  deduplication_scope        = "messageGroup"
  fifo_throughput_limit      = "perMessageGroupId"
  
  # Queue configuration
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600
  
  # Dead Letter Queue
  create_dlq        = true
  dlq_name          = "transactions-dlq.fifo"
  max_receive_count = 5
  
  tags = {
    Environment = "production"
    Ordering    = "strict"
  }
}
```

### SNS-SQS Fanout Pattern

```hcl
module "event_fanout" {
  source = "./modules/messaging"

  # SNS Topic
  create_sns_topic = true
  sns_topic_name   = "order-events"
  
  # Multiple SQS Queue subscriptions
  create_sqs_queues = true
  sqs_queues = {
    inventory = {
      name                       = "inventory-updates"
      visibility_timeout_seconds = 300
      create_dlq                 = true
      max_receive_count          = 3
      
      # Message filtering
      filter_policy = {
        event_type = ["order_created", "order_cancelled"]
        priority   = ["high", "medium"]
      }
    }
    
    shipping = {
      name                       = "shipping-notifications"
      visibility_timeout_seconds = 300
      create_dlq                 = true
      max_receive_count          = 3
      
      filter_policy = {
        event_type = ["order_created", "order_shipped"]
      }
    }
    
    analytics = {
      name                       = "analytics-events"
      visibility_timeout_seconds = 60
      message_retention_seconds  = 1209600  # 14 days
      
      filter_policy = {
        event_type = ["order_created", "order_completed", "order_cancelled"]
      }
    }
  }
  
  tags = {
    Environment = "production"
    Pattern     = "fanout"
  }
}
```

### Encrypted SNS and SQS

```hcl
module "secure_messaging" {
  source = "./modules/messaging"

  # SNS Topic with encryption
  create_sns_topic = true
  sns_topic_name   = "secure-notifications"
  
  sns_kms_master_key_id = aws_kms_key.sns.id
  
  # SQS Queue with encryption
  create_sqs_queue = true
  sqs_queue_name   = "secure-queue"
  
  sqs_kms_master_key_id                 = aws_kms_key.sqs.id
  sqs_kms_data_key_reuse_period_seconds = 300
  
  tags = {
    Environment = "production"
    Security    = "high"
  }
}
```

### SNS with Multiple Subscription Types

```hcl
module "multi_subscription" {
  source = "./modules/messaging"

  create_sns_topic = true
  sns_topic_name   = "alerts"
  
  sns_subscriptions = {
    email = {
      protocol = "email"
      endpoint = "alerts@example.com"
    }
    
    sms = {
      protocol = "sms"
      endpoint = "+1234567890"
    }
    
    lambda = {
      protocol = "lambda"
      endpoint = module.alert_handler.function_arn
    }
    
    https = {
      protocol = "https"
      endpoint = "https://webhook.example.com/alerts"
      
      delivery_policy = {
        healthyRetryPolicy = {
          minDelayTarget     = 20
          maxDelayTarget     = 20
          numRetries         = 3
          numMaxDelayRetries = 0
          numNoDelayRetries  = 0
          numMinDelayRetries = 0
          backoffFunction    = "linear"
        }
      }
    }
    
    sqs = {
      protocol            = "sqs"
      endpoint            = module.alert_queue.queue_arn
      raw_message_delivery = true
    }
  }
  
  tags = {
    Environment = "production"
  }
}
```

### Advanced Production Setup

```hcl
module "production_messaging" {
  source = "./modules/messaging"

  # SNS Topic Configuration
  create_sns_topic      = true
  sns_topic_name        = "production-events"
  sns_display_name      = "Production Event Notifications"
  sns_kms_master_key_id = aws_kms_key.sns.id
  
  # SNS Topic Policy
  sns_topic_policy = {
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPublishFromServices"
        Effect = "Allow"
        Principal = {
          Service = [
            "events.amazonaws.com",
            "s3.amazonaws.com",
            "cloudwatch.amazonaws.com"
          ]
        }
        Action   = "SNS:Publish"
        Resource = "*"
      }
    ]
  }
  
  # Multiple SQS Queues
  create_sqs_queues = true
  sqs_queues = {
    processing = {
      name                       = "event-processing"
      visibility_timeout_seconds = 900
      message_retention_seconds  = 345600
      max_message_size          = 262144
      receive_wait_time_seconds = 20
      delay_seconds             = 0
      
      # Encryption
      kms_master_key_id                 = aws_kms_key.sqs.id
      kms_data_key_reuse_period_seconds = 300
      
      # Dead Letter Queue
      create_dlq        = true
      dlq_name          = "event-processing-dlq"
      max_receive_count = 5
      dlq_kms_key_id    = aws_kms_key.sqs.id
      
      # Queue Policy
      policy = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "AllowSNS"
            Effect = "Allow"
            Principal = {
              Service = "sns.amazonaws.com"
            }
            Action   = "SQS:SendMessage"
            Resource = "*"
            Condition = {
              ArnEquals = {
                "aws:SourceArn" = module.production_messaging.sns_topic_arn
              }
            }
          }
        ]
      }
      
      # Message filtering
      filter_policy = {
        event_type = ["user_created", "user_updated", "user_deleted"]
        environment = ["production"]
      }
      
      filter_policy_scope = "MessageAttributes"
    }
    
    notifications = {
      name                       = "user-notifications"
      visibility_timeout_seconds = 300
      message_retention_seconds  = 86400
      receive_wait_time_seconds = 20
      
      create_dlq        = true
      dlq_name          = "user-notifications-dlq"
      max_receive_count = 3
      
      filter_policy = {
        notification_type = ["email", "sms", "push"]
        priority         = ["high", "urgent"]
      }
    }
    
    audit = {
      name                      = "audit-log-queue"
      visibility_timeout_seconds = 60
      message_retention_seconds = 1209600  # 14 days
      
      # No DLQ for audit logs - retain all
      create_dlq = false
      
      # Capture everything
      filter_policy = null
    }
  }
  
  # CloudWatch Alarms
  create_cloudwatch_alarms = true
  
  sqs_alarms = {
    processing = {
      age_threshold    = 300     # Alert if message age > 5 minutes
      depth_threshold  = 1000    # Alert if queue depth > 1000
      dlq_depth_threshold = 10   # Alert if DLQ has > 10 messages
    }
    
    notifications = {
      age_threshold    = 600
      depth_threshold  = 5000
      dlq_depth_threshold = 50
    }
  }
  
  alarm_sns_topic_arn = aws_sns_topic.cloudwatch_alarms.arn
  
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
| create_sns_topic | Create SNS topic | `bool` | `false` | no |
| sns_topic_name | Name of the SNS topic | `string` | `null` | no |
| sns_display_name | Display name for SNS topic | `string` | `null` | no |
| sns_kms_master_key_id | KMS key ID for SNS encryption | `string` | `null` | no |
| sns_topic_policy | SNS topic policy | `any` | `null` | no |
| sns_subscriptions | Map of SNS subscriptions | `map(any)` | `{}` | no |
| create_sqs_queue | Create single SQS queue | `bool` | `false` | no |
| sqs_queue_name | Name of the SQS queue | `string` | `null` | no |
| fifo_queue | Create FIFO queue | `bool` | `false` | no |
| content_based_deduplication | Enable content-based deduplication (FIFO) | `bool` | `false` | no |
| visibility_timeout_seconds | Visibility timeout in seconds | `number` | `30` | no |
| message_retention_seconds | Message retention period in seconds | `number` | `345600` | no |
| max_message_size | Maximum message size in bytes | `number` | `262144` | no |
| delay_seconds | Delay seconds for messages | `number` | `0` | no |
| receive_wait_time_seconds | Long polling wait time | `number` | `0` | no |
| create_dlq | Create dead letter queue | `bool` | `false` | no |
| dlq_name | Name of dead letter queue | `string` | `null` | no |
| max_receive_count | Max receive count before DLQ | `number` | `3` | no |
| sqs_kms_master_key_id | KMS key ID for SQS encryption | `string` | `null` | no |
| create_sqs_queues | Create multiple SQS queues | `bool` | `false` | no |
| sqs_queues | Map of SQS queue configurations | `map(any)` | `{}` | no |
| create_cloudwatch_alarms | Create CloudWatch alarms | `bool` | `false` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| sns_topic_arn | ARN of the SNS topic |
| sns_topic_id | ID of the SNS topic |
| sqs_queue_id | ID of the SQS queue |
| sqs_queue_arn | ARN of the SQS queue |
| sqs_queue_url | URL of the SQS queue |
| dlq_arn | ARN of the dead letter queue |
| dlq_url | URL of the dead letter queue |
| sqs_queues | Map of created SQS queues |

## Best Practices

### Queue Design

- Use **FIFO queues** for ordered processing
- Enable **long polling** (receive_wait_time_seconds > 0) to reduce costs
- Set appropriate **visibility timeout** (6x Lambda timeout)
- Use **dead letter queues** for failed messages
- Implement **message deduplication** for FIFO queues
- Set reasonable **message retention** periods

### Performance

- Use **batch operations** for sending/receiving messages
- Enable **long polling** to reduce empty receives
- Use **multiple consumers** for parallel processing
- Optimize **visibility timeout** for your workload
- Consider **FIFO throughput limits** (300 TPS standard, 3000 with batching)

### Security

- Enable **encryption at rest** with KMS
- Use **encryption in transit** (HTTPS)
- Implement **least privilege** IAM policies
- Use **VPC endpoints** for private access
- Enable **server-side encryption** for SNS
- Regularly rotate **KMS keys**

### Cost Optimization

- Use **long polling** to reduce requests
- Implement **batch operations** (up to 10 messages)
- Set appropriate **message retention** (default 4 days)
- Clean up **unused queues** and topics
- Use **SNS message filtering** to reduce SQS costs
- Monitor and optimize **API calls**

### Reliability

- Always use **dead letter queues**
- Set **max receive count** appropriately (3-5)
- Monitor **DLQ depth**
- Implement **exponential backoff** in consumers
- Use **message attributes** for metadata
- Test **failure scenarios**

### Monitoring

- Monitor **queue depth** (ApproximateNumberOfMessages)
- Track **message age** (ApproximateAgeOfOldestMessage)
- Alert on **DLQ messages**
- Monitor **empty receives** for cost optimization
- Track **sent/received message** metrics

## Cost Considerations

### SQS Pricing

**Standard Queue:**
- First 1M requests/month: Free
- After: $0.40 per 1M requests
- Data transfer: Standard AWS rates

**FIFO Queue:**
- First 1M requests/month: Free
- After: $0.50 per 1M requests

### SNS Pricing

**Standard Topics:**
- First 1M requests: Free
- After: $0.50 per 1M requests

**SNS to SQS:** Free
**Email/SMS:** Varies by destination

### Example Costs

| Service | Monthly Usage | Cost |
|---------|--------------|------|
| SQS Standard | 10M requests | $3.60 |
| SQS FIFO | 10M requests | $4.50 |
| SNS Standard | 10M publishes | $4.50 |
| SNS → SQS | 10M messages | $0 |
| SNS → Email | 1000 emails | $2 |

**Cost Optimization Tips:**
- Use SNS → SQS (free)
- Enable long polling
- Use batch operations
- Set appropriate retention
- Clean up old queues

## Additional Resources

- [SNS Developer Guide](https://docs.aws.amazon.com/sns/latest/dg/)
- [SQS Developer Guide](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/)
- [SNS Pricing](https://aws.amazon.com/sns/pricing/)
- [SQS Pricing](https://aws.amazon.com/sqs/pricing/)
- [Message Filtering](https://docs.aws.amazon.com/sns/latest/dg/sns-message-filtering.html)

## License

This module is licensed under the MIT License.
