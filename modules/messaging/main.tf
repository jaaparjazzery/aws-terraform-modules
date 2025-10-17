# modules/messaging/main.tf

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# SNS Topic
resource "aws_sns_topic" "this" {
  for_each = var.sns_topics

  name              = each.key
  display_name      = lookup(each.value, "display_name", null)
  fifo_topic        = lookup(each.value, "fifo_topic", false)
  content_based_deduplication = lookup(each.value, "content_based_deduplication", false)
  kms_master_key_id = lookup(each.value, "kms_master_key_id", null)
  delivery_policy   = lookup(each.value, "delivery_policy", null)

  tags = var.tags
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "this" {
  for_each = var.sns_topic_policies

  arn    = aws_sns_topic.this[each.key].arn
  policy = each.value
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "this" {
  for_each = var.sns_subscriptions

  topic_arn = aws_sns_topic.this[each.value.topic_name].arn
  protocol  = each.value.protocol
  endpoint  = each.value.endpoint
  
  filter_policy                       = lookup(each.value, "filter_policy", null)
  filter_policy_scope                 = lookup(each.value, "filter_policy_scope", null)
  raw_message_delivery                = lookup(each.value, "raw_message_delivery", false)
  redrive_policy                      = lookup(each.value, "redrive_policy", null)
  subscription_role_arn               = lookup(each.value, "subscription_role_arn", null)
  delivery_policy                     = lookup(each.value, "delivery_policy", null)
  endpoint_auto_confirms              = lookup(each.value, "endpoint_auto_confirms", false)
  confirmation_timeout_in_minutes     = lookup(each.value, "confirmation_timeout_in_minutes", 1)
}

# SQS Queue
resource "aws_sqs_queue" "this" {
  for_each = var.sqs_queues

  name                       = each.key
  fifo_queue                 = lookup(each.value, "fifo_queue", false)
  content_based_deduplication = lookup(each.value, "content_based_deduplication", false)
  delay_seconds              = lookup(each.value, "delay_seconds", 0)
  max_message_size           = lookup(each.value, "max_message_size", 262144)
  message_retention_seconds  = lookup(each.value, "message_retention_seconds", 345600)
  receive_wait_time_seconds  = lookup(each.value, "receive_wait_time_seconds", 0)
  visibility_timeout_seconds = lookup(each.value, "visibility_timeout_seconds", 30)
  kms_master_key_id          = lookup(each.value, "kms_master_key_id", null)
  kms_data_key_reuse_period_seconds = lookup(each.value, "kms_data_key_reuse_period_seconds", null)
  deduplication_scope        = lookup(each.value, "deduplication_scope", null)
  fifo_throughput_limit      = lookup(each.value, "fifo_throughput_limit", null)
  sqs_managed_sse_enabled    = lookup(each.value, "sqs_managed_sse_enabled", true)

  tags = var.tags
}

# SQS Dead Letter Queue
resource "aws_sqs_queue" "dlq" {
  for_each = var.sqs_dead_letter_queues

  name                      = each.key
  fifo_queue                = lookup(each.value, "fifo_queue", false)
  message_retention_seconds = lookup(each.value, "message_retention_seconds", 1209600)
  kms_master_key_id         = lookup(each.value, "kms_master_key_id", null)
  sqs_managed_sse_enabled   = lookup(each.value, "sqs_managed_sse_enabled", true)

  tags = var.tags
}

# SQS Queue Policy
resource "aws_sqs_queue_policy" "this" {
  for_each = var.sqs_queue_policies

  queue_url = aws_sqs_queue.this[each.key].url
  policy    = each.value
}

# SQS Queue Redrive Policy
resource "aws_sqs_queue_redrive_policy" "this" {
  for_each = var.sqs_redrive_policies

  queue_url = aws_sqs_queue.this[each.key].url
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[each.value.dlq_name].arn
    maxReceiveCount     = each.value.max_receive_count
  })
}

# SQS Queue Redrive Allow Policy
resource "aws_sqs_queue_redrive_allow_policy" "this" {
  for_each = var.sqs_redrive_allow_policies

  queue_url = aws_sqs_queue.dlq[each.key].url
  redrive_allow_policy = jsonencode({
    redrivePermission = each.value.redrive_permission
    sourceQueueArns   = [for queue_name in each.value.source_queue_names : aws_sqs_queue.this[queue_name].arn]
  })
}

# SNS to SQS Subscription
resource "aws_sns_topic_subscription" "sqs" {
  for_each = var.sns_to_sqs_subscriptions

  topic_arn = aws_sns_topic.this[each.value.topic_name].arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.this[each.value.queue_name].arn
  raw_message_delivery = lookup(each.value, "raw_message_delivery", false)
  filter_policy = lookup(each.value, "filter_policy", null)
}

# SQS Queue Policy for SNS
resource "aws_sqs_queue_policy" "sns_publish" {
  for_each = var.sns_to_sqs_subscriptions

  queue_url = aws_sqs_queue.this[each.value.queue_name].url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "sns.amazonaws.com"
      }
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.this[each.value.queue_name].arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_sns_topic.this[each.value.topic_name].arn
        }
      }
    }]
  })
}

# CloudWatch Alarms for SQS
resource "aws_cloudwatch_metric_alarm" "sqs_age" {
  for_each = var.create_sqs_alarms ? var.sqs_queues : {}

  alarm_name          = "${each.key}-message-age"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = lookup(each.value, "age_alarm_threshold", 3600)
  alarm_description   = "SQS message age too high"
  alarm_actions       = var.alarm_sns_topic_arns

  dimensions = {
    QueueName = each.key
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_depth" {
  for_each = var.create_sqs_alarms ? var.sqs_queues : {}

  alarm_name          = "${each.key}-queue-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = lookup(each.value, "depth_alarm_threshold", 1000)
  alarm_description   = "SQS queue depth too high"
  alarm_actions       = var.alarm_sns_topic_arns

  dimensions = {
    QueueName = each.key
  }
}