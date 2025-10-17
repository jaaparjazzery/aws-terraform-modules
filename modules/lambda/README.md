# AWS Lambda Function Module

Terraform module for creating and managing AWS Lambda functions with advanced configuration options including VPC integration, environment variables, layers, and event source mappings.

## Features

- **Multiple Runtime Support**: Python, Node.js, Java, Go, Ruby, .NET, and custom runtimes
- **Deployment Options**: Direct code, S3 bucket, container images
- **VPC Integration**: Deploy Lambda functions within VPC with subnet and security group configuration
- **Layer Support**: Attach multiple Lambda layers for shared code and dependencies
- **Dead Letter Queue**: Automatic DLQ configuration for failed executions
- **Event Source Mappings**: Built-in support for SQS, Kinesis, DynamoDB Streams, and MSK
- **Environment Variables**: Secure configuration with optional KMS encryption
- **CloudWatch Integration**: Automatic log group creation with configurable retention
- **IAM Roles**: Managed execution role with customizable policies
- **Reserved Concurrency**: Control function scaling and limit concurrent executions
- **Provisioned Concurrency**: Reduce cold start latency for critical functions
- **X-Ray Tracing**: Built-in support for AWS X-Ray distributed tracing
- **Code Signing**: Support for code signing configurations
- **File System Integration**: Mount EFS file systems to Lambda functions
- **Async Configuration**: Configure retry attempts and maximum age for async invocations

## Usage

### Basic Lambda Function

```hcl
module "simple_lambda" {
  source = "./modules/lambda"

  function_name = "my-function"
  description   = "Processes incoming requests"
  handler       = "index.handler"
  runtime       = "python3.11"
  
  source_code_path = "./lambda-code"
  
  environment_variables = {
    ENVIRONMENT = "production"
    LOG_LEVEL   = "INFO"
  }

  tags = {
    Environment = "production"
    Team        = "backend"
  }
}
```

### Lambda with VPC Configuration

```hcl
module "vpc_lambda" {
  source = "./modules/lambda"

  function_name = "vpc-function"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  
  source_code_path = "./lambda-code"
  
  # VPC Configuration
  vpc_config = {
    subnet_ids         = module.vpc.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }
  
  # Increased timeout for VPC cold starts
  timeout = 30
  
  tags = {
    Environment = "production"
  }
}
```

### Lambda with S3 Deployment

```hcl
module "s3_lambda" {
  source = "./modules/lambda"

  function_name = "s3-deployed-function"
  handler       = "app.handler"
  runtime       = "python3.11"
  
  # Deploy from S3
  s3_bucket = "my-lambda-deployments"
  s3_key    = "functions/my-function-v1.0.0.zip"
  
  memory_size = 512
  timeout     = 60
  
  tags = {
    Environment = "production"
  }
}
```

### Lambda with Layers and Event Source

```hcl
module "advanced_lambda" {
  source = "./modules/lambda"

  function_name = "data-processor"
  description   = "Processes messages from SQS queue"
  handler       = "processor.handler"
  runtime       = "python3.11"
  
  source_code_path = "./lambda-code"
  
  # Lambda Layers
  layer_arns = [
    "arn:aws:lambda:us-east-1:123456789012:layer:shared-utils:1",
    "arn:aws:lambda:us-east-1:901920374956:layer:aws-otel-python-amd64-ver-1-11-1:4"
  ]
  
  # SQS Event Source Mapping
  event_source_mappings = {
    sqs = {
      event_source_arn = aws_sqs_queue.queue.arn
      batch_size       = 10
      enabled          = true
    }
  }
  
  # Enhanced configuration
  memory_size           = 1024
  timeout               = 300
  reserved_concurrent_executions = 10
  
  # X-Ray tracing
  tracing_mode = "Active"
  
  # Dead Letter Queue
  dead_letter_config = {
    target_arn = aws_sqs_queue.dlq.arn
  }
  
  environment_variables = {
    TABLE_NAME = aws_dynamodb_table.data.name
    QUEUE_URL  = aws_sqs_queue.queue.url
  }
  
  tags = {
    Environment = "production"
    Application = "data-pipeline"
  }
}
```

### Lambda with Container Image

```hcl
module "container_lambda" {
  source = "./modules/lambda"

  function_name = "container-function"
  package_type  = "Image"
  
  # Container image from ECR
  image_uri = "${aws_ecr_repository.lambda.repository_url}:latest"
  
  memory_size = 2048
  timeout     = 900
  
  environment_variables = {
    MODEL_PATH = "/opt/ml/model"
  }
  
  tags = {
    Environment = "production"
  }
}
```

### Lambda with EFS Integration

```hcl
module "efs_lambda" {
  source = "./modules/lambda"

  function_name = "ml-inference"
  handler       = "inference.handler"
  runtime       = "python3.11"
  
  source_code_path = "./lambda-code"
  
  # VPC required for EFS
  vpc_config = {
    subnet_ids         = module.vpc.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }
  
  # EFS File System
  file_system_config = {
    arn              = aws_efs_access_point.lambda.arn
    local_mount_path = "/mnt/models"
  }
  
  memory_size = 3008
  timeout     = 900
  
  tags = {
    Environment = "production"
    UseCase     = "ml-inference"
  }
}
```

### Lambda with Provisioned Concurrency

```hcl
module "low_latency_lambda" {
  source = "./modules/lambda"

  function_name = "api-handler"
  handler       = "api.handler"
  runtime       = "nodejs18.x"
  
  source_code_path = "./lambda-code"
  
  # Publish version for provisioned concurrency
  publish = true
  
  # Provisioned concurrency for low latency
  provisioned_concurrent_executions = 5
  
  memory_size = 512
  timeout     = 30
  
  tags = {
    Environment = "production"
    CriticalPath = "true"
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
| function_name | Name of the Lambda function | `string` | n/a | yes |
| handler | Function entrypoint (e.g., index.handler) | `string` | n/a | yes (for Zip) |
| runtime | Lambda runtime (e.g., python3.11, nodejs18.x) | `string` | n/a | yes (for Zip) |
| description | Description of the Lambda function | `string` | `""` | no |
| source_code_path | Path to Lambda function source code directory | `string` | `null` | no |
| s3_bucket | S3 bucket containing Lambda deployment package | `string` | `null` | no |
| s3_key | S3 key of Lambda deployment package | `string` | `null` | no |
| s3_object_version | S3 object version of deployment package | `string` | `null` | no |
| package_type | Lambda deployment package type (Zip or Image) | `string` | `"Zip"` | no |
| image_uri | ECR image URI (for container-based Lambda) | `string` | `null` | no |
| memory_size | Amount of memory in MB (128-10240) | `number` | `128` | no |
| timeout | Function timeout in seconds (1-900) | `number` | `3` | no |
| publish | Publish a new version | `bool` | `false` | no |
| reserved_concurrent_executions | Reserved concurrent executions (-1 or 0-1000) | `number` | `-1` | no |
| provisioned_concurrent_executions | Provisioned concurrent executions | `number` | `null` | no |
| environment_variables | Environment variables | `map(string)` | `{}` | no |
| kms_key_arn | KMS key ARN for environment variable encryption | `string` | `null` | no |
| layer_arns | List of Lambda Layer ARNs | `list(string)` | `[]` | no |
| vpc_config | VPC configuration | `object` | `null` | no |
| dead_letter_config | Dead letter queue configuration | `object` | `null` | no |
| tracing_mode | X-Ray tracing mode (Active or PassThrough) | `string` | `"PassThrough"` | no |
| file_system_config | EFS file system configuration | `object` | `null` | no |
| event_source_mappings | Event source mapping configurations | `map(any)` | `{}` | no |
| log_retention_days | CloudWatch Logs retention in days | `number` | `7` | no |
| architectures | Instruction set architecture (x86_64 or arm64) | `list(string)` | `["x86_64"]` | no |
| code_signing_config_arn | Code signing configuration ARN | `string` | `null` | no |
| ephemeral_storage_size | Ephemeral storage size in MB (512-10240) | `number` | `512` | no |
| execution_role_arn | Existing IAM role ARN (optional) | `string` | `null` | no |
| create_execution_role | Create IAM execution role | `bool` | `true` | no |
| policy_attachments | Additional IAM policy ARNs to attach | `list(string)` | `[]` | no |
| inline_policies | Inline IAM policies | `map(string)` | `{}` | no |
| async_config | Asynchronous invocation configuration | `object` | `null` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| function_arn | ARN of the Lambda function |
| function_name | Name of the Lambda function |
| function_qualified_arn | Qualified ARN of the Lambda function |
| function_version | Latest published version |
| function_invoke_arn | Invoke ARN for API Gateway integration |
| function_role_arn | ARN of the function's IAM role |
| function_role_name | Name of the function's IAM role |
| log_group_name | Name of the CloudWatch Log Group |
| log_group_arn | ARN of the CloudWatch Log Group |

## Examples

### API Gateway Integration

```hcl
module "api_lambda" {
  source = "./modules/lambda"

  function_name = "api-endpoint"
  handler       = "api.handler"
  runtime       = "python3.11"
  
  source_code_path = "./api-code"
  
  memory_size = 256
  timeout     = 29  # API Gateway timeout is 30s
  
  tags = {
    Environment = "production"
  }
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.api_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
```

### Scheduled Lambda (EventBridge)

```hcl
module "scheduled_lambda" {
  source = "./modules/lambda"

  function_name = "daily-report"
  handler       = "report.handler"
  runtime       = "python3.11"
  
  source_code_path = "./report-code"
  timeout          = 300
  
  tags = {
    Environment = "production"
  }
}

resource "aws_cloudwatch_event_rule" "daily" {
  name                = "daily-report-trigger"
  description         = "Trigger daily report"
  schedule_expression = "cron(0 8 * * ? *)"  # 8 AM UTC daily
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.daily.name
  target_id = "TriggerLambda"
  arn       = module.scheduled_lambda.function_arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.scheduled_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily.arn
}
```

## Best Practices

### Performance Optimization

- Use **Graviton2 (arm64)** architecture for better price-performance
- Set appropriate **memory size** (affects CPU allocation)
- Use **provisioned concurrency** for latency-sensitive applications
- Leverage **Lambda layers** for shared dependencies
- Enable **X-Ray tracing** for performance insights

### Security

- Always use **VPC** for functions accessing private resources
- Enable **KMS encryption** for sensitive environment variables
- Use **IAM least privilege** principle
- Enable **code signing** for production functions
- Never hardcode secrets - use **AWS Secrets Manager** or **Parameter Store**

### Cost Optimization

- Use **arm64 architecture** (up to 34% better price-performance)
- Right-size **memory allocation**
- Optimize **timeout** values
- Use **reserved concurrency** to prevent runaway costs
- Consider **Lambda SnapStart** for Java functions

### Reliability

- Configure **Dead Letter Queues** for failed invocations
- Set appropriate **retry policies**
- Use **async invocation** for non-critical operations
- Monitor **CloudWatch metrics** and alarms
- Implement **idempotency** in function code

## Cost Considerations

### Pricing Components

- **Requests**: $0.20 per 1M requests
- **Duration**: 
  - x86_64: $0.0000166667 per GB-second
  - arm64: $0.0000133334 per GB-second (20% cheaper)
- **Provisioned Concurrency**: $0.0000041667 per GB-second
- **Ephemeral Storage**: $0.0000000309 per GB-second (over 512 MB)

### Example Costs

| Configuration | Monthly Invocations | Avg Duration | Monthly Cost |
|---------------|---------------------|--------------|--------------|
| 128 MB, x86_64 | 1M | 200ms | ~$5 |
| 512 MB, x86_64 | 10M | 500ms | ~$52 |
| 1024 MB, arm64 | 100M | 1s | ~$353 |
| 2048 MB + Provisioned (5) | 10M | 300ms | ~$142 |

**Note**: Prices are approximate and vary by region. Always monitor actual costs using AWS Cost Explorer.

## Additional Resources

- [AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)
- [Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [Lambda Pricing](https://aws.amazon.com/lambda/pricing/)
- [Lambda Powertools](https://awslabs.github.io/aws-lambda-powertools-python/)

## License

This module is licensed under the MIT License.