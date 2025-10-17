# modules/stepfunctions/main.tf

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Step Functions State Machine
resource "aws_sfn_state_machine" "this" {
  name       = var.name
  role_arn   = var.create_role ? aws_iam_role.sfn[0].arn : var.role_arn
  definition = var.definition
  type       = var.type

  dynamic "logging_configuration" {
    for_each = var.logging_configuration != null ? [var.logging_configuration] : []
    content {
      log_destination        = "${aws_cloudwatch_log_group.sfn[0].arn}:*"
      include_execution_data = lookup(logging_configuration.value, "include_execution_data", false)
      level                  = lookup(logging_configuration.value, "level", "OFF")
    }
  }

  dynamic "tracing_configuration" {
    for_each = var.tracing_enabled ? [1] : []
    content {
      enabled = true
    }
  }

  tags = var.tags
}

# IAM Role for Step Functions
resource "aws_iam_role" "sfn" {
  count = var.create_role ? 1 : 0

  name               = "${var.name}-sfn-role"
  assume_role_policy = data.aws_iam_policy_document.sfn_assume_role[0].json

  tags = var.tags
}

data "aws_iam_policy_document" "sfn_assume_role" {
  count = var.create_role ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Custom IAM policies
resource "aws_iam_role_policy" "sfn_custom" {
  count = var.create_role && var.custom_policies != null ? length(var.custom_policies) : 0

  name   = "${var.name}-policy-${count.index}"
  role   = aws_iam_role.sfn[0].id
  policy = var.custom_policies[count.index]
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "sfn" {
  count = var.create_log_group ? 1 : 0

  name              = "/aws/vendedlogs/states/${var.name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_id

  tags = var.tags
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "execution_failed" {
  count = var.create_alarms ? 1 : 0

  alarm_name          = "${var.name}-execution-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsFailed"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Step Functions execution failed"
  alarm_actions       = var.alarm_sns_topic_arns

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.this.arn
  }
}

resource "aws_cloudwatch_metric_alarm" "execution_throttled" {
  count = var.create_alarms ? 1 : 0

  alarm_name          = "${var.name}-execution-throttled"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionThrottled"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Step Functions execution throttled"
  alarm_actions       = var.alarm_sns_topic_arns

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.this.arn
  }
}

# EventBridge Rule to trigger Step Functions
resource "aws_cloudwatch_event_rule" "trigger" {
  for_each = var.event_triggers

  name                = "${var.name}-${each.key}"
  description         = lookup(each.value, "description", null)
  event_pattern       = lookup(each.value, "event_pattern", null)
  schedule_expression = lookup(each.value, "schedule_expression", null)
  is_enabled          = lookup(each.value, "enabled", true)

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "trigger" {
  for_each = var.event_triggers

  rule      = aws_cloudwatch_event_rule.trigger[each.key].name
  target_id = "StepFunctions"
  arn       = aws_sfn_state_machine.this.arn
  role_arn  = aws_iam_role.eventbridge_sfn[0].arn
  input     = lookup(each.value, "input", null)
}

# IAM Role for EventBridge to invoke Step Functions
resource "aws_iam_role" "eventbridge_sfn" {
  count = length(var.event_triggers) > 0 ? 1 : 0

  name               = "${var.name}-eventbridge-role"
  assume_role_policy = data.aws_iam_policy_document.eventbridge_assume_role[0].json

  tags = var.tags
}

data "aws_iam_policy_document" "eventbridge_assume_role" {
  count = length(var.event_triggers) > 0 ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "eventbridge_sfn" {
  count = length(var.event_triggers) > 0 ? 1 : 0

  name   = "${var.name}-eventbridge-policy"
  role   = aws_iam_role.eventbridge_sfn[0].id
  policy = data.aws_iam_policy_document.eventbridge_sfn_policy[0].json
}

data "aws_iam_policy_document" "eventbridge_sfn_policy" {
  count = length(var.event_triggers) > 0 ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["states:StartExecution"]
    resources = [aws_sfn_state_machine.this.arn]
  }
}