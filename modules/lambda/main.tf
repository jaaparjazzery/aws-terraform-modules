# modules/lambda/main.tf

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Lambda Function
resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  description      = var.description
  role             = var.create_role ? aws_iam_role.lambda[0].arn : var.role_arn
  handler          = var.handler
  runtime          = var.runtime
  timeout          = var.timeout
  memory_size      = var.memory_size
  publish          = var.publish
  layers           = var.layers
  architectures    = var.architectures
  
  filename         = var.filename
  source_code_hash = var.filename != null ? filebase64sha256(var.filename) : null
  
  s3_bucket        = var.s3_bucket
  s3_key           = var.s3_key
  s3_object_version = var.s3_object_version
  
  image_uri        = var.image_uri
  package_type     = var.package_type

  reserved_concurrent_executions = var.reserved_concurrent_executions

  environment {
    variables = var.environment_variables
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_target_arn != null ? [1] : []
    content {
      target_arn = var.dead_letter_target_arn
    }
  }

  dynamic "tracing_config" {
    for_each = var.tracing_mode != null ? [1] : []
    content {
      mode = var.tracing_mode
    }
  }

  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage_size != null ? [1] : []
    content {
      size = var.ephemeral_storage_size
    }
  }

  tags = var.tags
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda" {
  count = var.create_role ? 1 : 0

  name               = "${var.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role[0].json
  tags               = var.tags
}

data "aws_iam_policy_document" "lambda_assume_role" {
  count = var.create_role ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Attach basic execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  count = var.create_role ? 1 : 0

  role       = aws_iam_role.lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach VPC execution policy if VPC config is provided
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  count = var.create_role && var.vpc_config != null ? 1 : 0

  role       = aws_iam_role.lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Custom IAM policies
resource "aws_iam_role_policy" "lambda_custom" {
  count = var.create_role && var.custom_policies != null ? length(var.custom_policies) : 0

  name   = "${var.function_name}-policy-${count.index}"
  role   = aws_iam_role.lambda[0].id
  policy = var.custom_policies[count.index]
}

# Lambda Permission for triggers
resource "aws_lambda_permission" "this" {
  for_each = var.lambda_permissions

  statement_id  = each.key
  action        = each.value.action
  function_name = aws_lambda_function.this.function_name
  principal     = each.value.principal
  source_arn    = lookup(each.value, "source_arn", null)
  source_account = lookup(each.value, "source_account", null)
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda" {
  count = var.create_log_group ? 1 : 0

  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_id
  tags              = var.tags
}

# Lambda Alias
resource "aws_lambda_alias" "this" {
  for_each = var.aliases

  name             = each.key
  description      = lookup(each.value, "description", null)
  function_name    = aws_lambda_function.this.function_name
  function_version = lookup(each.value, "function_version", "$LATEST")

  dynamic "routing_config" {
    for_each = lookup(each.value, "routing_config", null) != null ? [each.value.routing_config] : []
    content {
      additional_version_weights = routing_config.value.additional_version_weights
    }
  }
}

# EventBridge Rule for scheduled invocations
resource "aws_cloudwatch_event_rule" "schedule" {
  for_each = var.schedules

  name                = "${var.function_name}-${each.key}"
  description         = lookup(each.value, "description", null)
  schedule_expression = each.value.schedule_expression
  is_enabled          = lookup(each.value, "enabled", true)
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "schedule" {
  for_each = var.schedules

  rule      = aws_cloudwatch_event_rule.schedule[each.key].name
  target_id = "lambda"
  arn       = aws_lambda_function.this.arn
  input     = lookup(each.value, "input", null)
}

resource "aws_lambda_permission" "eventbridge" {
  for_each = var.schedules

  statement_id  = "AllowExecutionFromEventBridge-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule[each.key].arn
}