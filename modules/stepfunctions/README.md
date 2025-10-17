# AWS Step Functions Module

Terraform module for creating and managing AWS Step Functions state machines with support for Standard and Express workflows, service integrations, error handling, and comprehensive monitoring.

## Features

- **Multiple Workflow Types**: Standard and Express (Synchronous/Asynchronous)
- **Service Integrations**: Lambda, DynamoDB, SNS, SQS, ECS, Batch, Glue, and more
- **Error Handling**: Built-in retry and catch configurations
- **Parallel Execution**: Run tasks in parallel for better performance
- **Map State**: Process arrays and iterate over datasets
- **Choice State**: Conditional branching logic
- **Wait State**: Delays and scheduled execution
- **CloudWatch Integration**: Logging and metrics
- **X-Ray Tracing**: Distributed tracing support
- **Event Bridge Integration**: Trigger state machines from events
- **IAM Role Management**: Automatic role and policy creation
- **Tags**: Comprehensive resource tagging

## Usage

### Simple Lambda Orchestration

```hcl
module "simple_workflow" {
  source = "./modules/step-functions"

  name = "simple-lambda-workflow"
  type = "STANDARD"
  
  definition = {
    Comment = "A simple workflow that calls Lambda functions"
    StartAt = "ProcessData"
    States = {
      ProcessData = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = module.process_lambda.function_arn
          Payload = {
            "input.$" = "$"
          }
        }
        Next = "TransformData"
      }
      
      TransformData = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = module.transform_lambda.function_arn
          Payload = {
            "input.$" = "$.Payload"
          }
        }
        Next = "SaveResults"
      }
      
      SaveResults = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = module.save_lambda.function_arn
          Payload = {
            "input.$" = "$.Payload"
          }
        }
        End = true
      }
    }
  }
  
  tags = {
    Environment = "production"
  }
}
```

### Workflow with Error Handling

```hcl
module "resilient_workflow" {
  source = "./modules/step-functions"

  name = "resilient-workflow"
  type = "STANDARD"
  
  definition = {
    Comment = "Workflow with comprehensive error handling"
    StartAt = "ProcessRequest"
    States = {
      ProcessRequest = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = module.process_lambda.function_arn
          Payload = {
            "input.$" = "$"
          }
        }
        
        # Retry configuration
        Retry = [
          {
            ErrorEquals = ["Lambda.ServiceException", "Lambda.TooManyRequestsException"]
            IntervalSeconds = 2
            MaxAttempts     = 3
            BackoffRate     = 2.0
          },
          {
            ErrorEquals = ["States.TaskFailed"]
            IntervalSeconds = 1
            MaxAttempts     = 2
            BackoffRate     = 1.5
          }
        ]
        
        # Error handling
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "HandleError"
          }
        ]
        
        Next = "Success"
      }
      
      HandleError = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = module.error_handler_lambda.function_arn
          Payload = {
            "error.$"  = "$.error"
            "input.$"  = "$"
          }
        }
        Next = "NotifyFailure"
      }
      
      NotifyFailure = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = aws_sns_topic.alerts.arn
          Message = {
            "default.$" = "$.Payload"
          }
        }
        End = true
      }
      
      Success = {
        Type = "Succeed"
      }
    }
  }
  
  logging_configuration = {
    level                  = "ALL"
    include_execution_data = true
    log_destination        = "${aws_cloudwatch_log_group.step_functions.arn}:*"
  }
  
  tags = {
    Environment = "production"
  }
}
```

### Parallel Processing Workflow

```hcl
module "parallel_workflow" {
  source = "./modules/step-functions"

  name = "parallel-processing"
  type = "STANDARD"
  
  definition = {
    Comment = "Process multiple tasks in parallel"
    StartAt = "ParallelProcessing"
    States = {
      ParallelProcessing = {
        Type = "Parallel"
        
        Branches = [
          {
            StartAt = "ProcessImages"
            States = {
              ProcessImages = {
                Type     = "Task"
                Resource = "arn:aws:states:::lambda:invoke"
                Parameters = {
                  FunctionName = module.image_processor.function_arn
                  Payload = {
                    "input.$" = "$"
                  }
                }
                End = true
              }
            }
          },
          {
            StartAt = "ProcessVideos"
            States = {
              ProcessVideos = {
                Type     = "Task"
                Resource = "arn:aws:states:::lambda:invoke"
                Parameters = {
                  FunctionName = module.video_processor.function_arn
                  Payload = {
                    "input.$" = "$"
                  }
                }
                End = true
              }
            }
          },
          {
            StartAt = "ProcessText"
            States = {
              ProcessText = {
                Type     = "Task"
                Resource = "arn:aws:states:::lambda:invoke"
                Parameters = {
                  FunctionName = module.text_processor.function_arn
                  Payload = {
                    "input.$" = "$"
                  }
                }
                End = true
              }
            }
          }
        ]
        
        Next = "AggregateResults"
      }
      
      AggregateResults = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = module.aggregator.function_arn
          Payload = {
            "results.$" = "$"
          }
        }
        End = true
      }
    }
  }
  
  tags = {
    Environment = "production"
    Pattern     = "parallel"
  }
}
```

### Map State for Batch Processing

```hcl
module "batch_workflow" {
  source = "./modules/step-functions"

  name = "batch-processing"
  type = "STANDARD"
  
  definition = {
    Comment = "Process items in batch using Map state"
    StartAt = "GetItems"
    States = {
      GetItems = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = module.get_items_lambda.function_arn
        }
        ResultPath = "$.items"
        Next       = "ProcessItems"
      }
      
      ProcessItems = {
        Type     = "Map"
        ItemsPath = "$.items.Payload"
        MaxConcurrency = 10
        
        Iterator = {
          StartAt = "ProcessSingleItem"
          States = {
            ProcessSingleItem = {
              Type     = "Task"
              Resource = "arn:aws:states:::lambda:invoke"
              Parameters = {
                FunctionName = module.process_item_lambda.function_arn
                Payload = {
                  "item.$" = "$"
                }
              }
              
              Retry = [
                {
                  ErrorEquals     = ["States.TaskFailed"]
                  IntervalSeconds = 2
                  MaxAttempts     = 3
                  BackoffRate     = 2.0
                }
              ]
              
              End = true
            }
          }
        }
        
        ResultPath = "$.processedItems"
        Next       = "SaveResults"
      }
      
      SaveResults = {
        Type     = "Task"
        Resource = "arn:aws:states:::dynamodb:putItem"
        Parameters = {
          TableName = aws_dynamodb_table.results.name
          Item = {
            id = {
              "S.$" = "$.executionId"
            }
            results = {
              "S.$" = "States.JsonToString($.processedItems)"
            }
          }
        }
        End = true
      }
    }
  }
  
  tags = {
    Environment = "production"
    Pattern     = "map-state"
  }
}
```

### Express Workflow (High-throughput)

```hcl
module "express_workflow" {
  source = "./modules/step-functions"

  name = "high-throughput-workflow"
  type = "EXPRESS"
  
  definition = {
    Comment = "Fast, high-throughput workflow"
    StartAt = "ValidateInput"
    States = {
      ValidateInput = {
        Type = "Choice"
        Choices = [
          {
            Variable      = "$.amount"
            NumericGreaterThan = 0
            Next          = "ProcessPayment"
          }
        ]
        Default = "InvalidInput"
      }
      
      ProcessPayment = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = module.payment_lambda.function_arn
          Payload = {
            "input.$" = "$"
          }
        }
        End = true
      }
      
      InvalidInput = {
        Type  = "Fail"
        Error = "InvalidInput"
        Cause = "Amount must be greater than 0"
      }
    }
  }
  
  logging_configuration = {
    level                  = "ERROR"
    include_execution_data = false
    log_destination        = "${aws_cloudwatch_log_group.express_workflow.arn}:*"
  }
  
  tags = {
    Environment = "production"
    WorkflowType = "express"
  }
}
```

### Advanced Production Workflow

```hcl
module "production_workflow" {
  source = "./modules/step-functions"

  name = "order-processing-workflow"
  type = "STANDARD"
  
  definition = {
    Comment = "Production order processing workflow"
    StartAt = "ValidateOrder"
    States = {
      ValidateOrder = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = module.validate_order.function_arn
          Payload = {
            "order.$" = "$"
          }
        }
        
        Retry = [
          {
            ErrorEquals     = ["States.TaskFailed"]
            IntervalSeconds = 2
            MaxAttempts     = 3
            BackoffRate     = 2.0
          }
        ]
        
        Catch = [
          {
            ErrorEquals = ["ValidationError"]
            ResultPath  = "$.error"
            Next        = "OrderRejected"
          }
        ]
        
        ResultPath = "$.validation"
        Next       = "CheckInventory"
      }
      
      CheckInventory = {
        Type = "Parallel"
        
        Branches = [
          {
            StartAt = "CheckWarehouse1"
            States = {
              CheckWarehouse1 = {
                Type     = "Task"
                Resource = "arn:aws:states:::lambda:invoke"
                Parameters = {
                  FunctionName = module.check_inventory.function_arn
                  Payload = {
                    "warehouse"  = "warehouse-1"
                    "order.$"    = "$.order"
                  }
                }
                End = true
              }
            }
          },
          {
            StartAt = "CheckWarehouse2"
            States = {
              CheckWarehouse2 = {
                Type     = "Task"
                Resource = "arn:aws:states:::lambda:invoke"
                Parameters = {
                  FunctionName = module.check_inventory.function_arn
                  Payload = {
                    "warehouse"  = "warehouse-2"
                    "order.$"    = "$.order"
                  }
                }
                End = true
              }
            }
          }
        ]
        
        ResultPath = "$.inventory"
        Next       = "DecideWarehouse"
      }
      
      DecideWarehouse = {
        Type = "Choice"
        Choices = [
          {
            Variable = "$.inventory[0].Payload.available"
            BooleanEquals = true
            Next     = "ProcessFromWarehouse1"
          },
          {
            Variable = "$.inventory[1].Payload.available"
            BooleanEquals = true
            Next     = "ProcessFromWarehouse2"
          }
        ]
        Default = "BackorderItem"
      }
      
      ProcessFromWarehouse1 = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = module.process_order.function_arn
          Payload = {
            "warehouse"  = "warehouse-1"
            "order.$"    = "$.order"
          }
        }
        Next = "ChargePayment"
      }
      
      ProcessFromWarehouse2 = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = module.process_order.function_arn
          Payload = {
            "warehouse"  = "warehouse-2"
            "order.$"    = "$.order"
          }
        }
        Next = "ChargePayment"
      }
      
      ChargePayment = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = module.charge_payment.function_arn
          Payload = {
            "order.$" = "$.order"
          }
        }
        
        Retry = [
          {
            ErrorEquals     = ["PaymentGatewayTimeout"]
            IntervalSeconds = 5
            MaxAttempts     = 3
            BackoffRate     = 2.0
          }
        ]
        
        Catch = [
          {
            ErrorEquals = ["PaymentFailed"]
            ResultPath  = "$.paymentError"
            Next        = "PaymentFailed"
          }
        ]
        
        Next = "SendConfirmation"
      }
      
      SendConfirmation = {
        Type = "Parallel"
        
        Branches = [
          {
            StartAt = "SendEmail"
            States = {
              SendEmail = {
                Type     = "Task"
                Resource = "arn:aws:states:::lambda:invoke"
                Parameters = {
                  FunctionName = module.send_email.function_arn
                  Payload = {
                    "order.$" = "$.order"
                  }
                }
                End = true
              }
            }
          },
          {
            StartAt = "SendSMS"
            States = {
              SendSMS = {
                Type     = "Task"
                Resource = "arn:aws:states:::sns:publish"
                Parameters = {
                  TopicArn = aws_sns_topic.sms.arn
                  Message = {
                    "default.$" = "States.Format('Order {} confirmed', $.order.id)"
                  }
                }
                End = true
              }
            }
          }
        ]
        
        Next = "OrderComplete"
      }
      
      BackorderItem = {
        Type     = "Task"
        Resource = "arn:aws:states:::sqs:sendMessage"
        Parameters = {
          QueueUrl    = aws_sqs_queue.backorder.url
          MessageBody = {
            "order.$" = "$.order"
          }
        }
        Next = "NotifyBackorder"
      }
      
      NotifyBackorder = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = module.notify_backorder.function_arn
          Payload = {
            "order.$" = "$.order"
          }
        }
        End = true
      }
      
      PaymentFailed = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = module.handle_payment_failure.function_arn
          Payload = {
            "order.$" = "$.order"
            "error.$" = "$.paymentError"
          }
        }
        End = true
      }
      
      OrderRejected = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = module.reject_order.function_arn
          Payload = {
            "order.$" = "$.order"
            "error.$" = "$.error"
          }
        }
        End = true
      }
      
      OrderComplete = {
        Type = "Succeed"
      }
    }
  }
  
  logging_configuration = {
    level                  = "ALL"
    include_execution_data = true
    log_destination        = "${aws_cloudwatch_log_group.workflows.arn}:*"
  }
  
  tracing_configuration = {
    enabled = true
  }
  
  tags = {
    Environment = "production"
    Application = "order-processing"
    Critical    = "true"
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
| name | Name of the state machine | `string` | n/a | yes |
| definition | State machine definition (ASL) | `any` | n/a | yes |
| type | Type of workflow (STANDARD or EXPRESS) | `string` | `"STANDARD"` | no |
| role_arn | Existing IAM role ARN (optional) | `string` | `null` | no |
| create_role | Create IAM role automatically | `bool` | `true` | no |
| logging_configuration | CloudWatch logging configuration | `object` | `null` | no |
| tracing_configuration | X-Ray tracing configuration | `object` | `null` | no |
| policy_statements | Additional IAM policy statements | `list(any)` | `[]` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| state_machine_id | ID of the state machine |
| state_machine_arn | ARN of the state machine |
| state_machine_name | Name of the state machine |
| state_machine_creation_date | Creation date of the state machine |
| state_machine_status | Current status of the state machine |
| role_arn | ARN of the IAM role |
| role_name | Name of the IAM role |

## Best Practices

### Design Patterns

- Use **Standard workflows** for long-running processes
- Use **Express workflows** for high-throughput, short-duration tasks
- Implement **error handling** with Retry and Catch
- Use **Parallel states** for independent tasks
- Use **Map states** for processing arrays
- Keep **state machine definitions** in version control
- Use **choice states** for conditional logic

### Performance

- Optimize **Lambda function** cold starts
- Use **Express workflows** for < 5 minute executions
- Limit **Map state** concurrency appropriately
- Use **pass states** to transform data when possible
- Minimize **state transitions** for better performance

### Security

- Follow **least privilege** for IAM roles
- Use **resource-based policies** when possible
- Enable **X-Ray tracing** for security insights
- Encrypt **sensitive data** in state
- Use **VPC endpoints** for private integrations
- Regularly review **CloudWatch logs**

### Cost Optimization

- Use **Express workflows** for high-volume workloads (cheaper)
- Minimize **state transitions** (charged per transition)
- Use **direct service integrations** instead of Lambda when possible
- Implement **appropriate timeouts**
- Clean up **old executions** data

### Reliability

- Implement **retry logic** for transient failures
- Use **exponential backoff** for retries
- Add **error handling** for all failure scenarios
- Monitor **execution failures**
- Set appropriate **timeouts**
- Test **failure scenarios**

## Cost Considerations

### Standard Workflows

- **State transitions**: $0.025 per 1,000 transitions
- **Minimum**: No minimum charges
- **Example**: 1M transitions = $25

### Express Workflows

- **Requests**: $1.00 per 1M requests
- **Duration**: $0.00001667 per GB-second
- **Example**: 1M requests, 128MB, 10s avg = $3.13

### Comparison

| Workflow Type | 1M Executions (5 states) | 1M Executions (20 states) |
|---------------|-------------------------|---------------------------|
| Standard | $125 | $500 |
| Express (1s) | ~$3 | ~$3 |
| Express (30s) | ~$9 | ~$9 |

**Note**: Express is more cost-effective for high-volume, short-duration workflows.

## Additional Resources

- [Step Functions Developer Guide](https://docs.aws.amazon.com/step-functions/latest/dg/)
- [Amazon States Language](https://states-language.net/spec.html)
- [Step Functions Best Practices](https://docs.aws.amazon.com/step-functions/latest/dg/bp-express.html)
- [Step Functions Pricing](https://aws.amazon.com/step-functions/pricing/)

## License

This module is licensed under the MIT License.