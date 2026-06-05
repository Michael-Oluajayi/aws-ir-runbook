terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# SNS topic for IR alerts
resource "aws_sns_topic" "ir_alerts" {
  name = "ir-incident-alerts"

  tags = {
    Name = "ir-incident-alerts"
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.ir_alerts.arn
  protocol  = "email"
  endpoint  = "oluajayimichael25@gmail.com"
}

# S3 bucket for IR evidence collection
resource "aws_s3_bucket" "evidence" {
  bucket        = "ir-evidence-${random_id.suffix.hex}"
  force_destroy = true

  tags = {
    Name = "ir-evidence-bucket"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_public_access_block" "evidence" {
  bucket                  = aws_s3_bucket.evidence.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning on evidence bucket — preserves all evidence
resource "aws_s3_bucket_versioning" "evidence" {
  bucket = aws_s3_bucket.evidence.id

  versioning_configuration {
    status = "Enabled"
  }
}

# KMS key for encrypting evidence
resource "aws_kms_key" "ir" {
  description             = "KMS key for IR evidence encryption"
  deletion_window_in_days = 10

  tags = {
    Name = "ir-evidence-kms-key"
  }
}

# Encrypt evidence bucket with KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "evidence" {
  bucket = aws_s3_bucket.evidence.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.ir.arn
    }
  }
}

# CloudWatch log group for IR events
resource "aws_cloudwatch_log_group" "ir" {
  name              = "/ir/incident-response"
  retention_in_days = 365

  tags = {
    Name = "ir-incident-response-logs"
  }
}

# CloudWatch alarm — detects unauthorized API calls
resource "aws_cloudwatch_metric_alarm" "unauthorized_api" {
  alarm_name          = "ir-unauthorized-api-calls"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ErrorCount"
  namespace           = "CloudTrailMetrics"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "IR Alert — unauthorized API calls detected"
  alarm_actions       = [aws_sns_topic.ir_alerts.arn]

  tags = {
    Name = "ir-unauthorized-api-alarm"
  }
}

# CloudWatch alarm — detects console login without MFA
resource "aws_cloudwatch_metric_alarm" "no_mfa_login" {
  alarm_name          = "ir-console-login-no-mfa"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ConsoleSignInWithoutMfaCount"
  namespace           = "CloudTrailMetrics"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "IR Alert — console login without MFA detected"
  alarm_actions       = [aws_sns_topic.ir_alerts.arn]

  tags = {
    Name = "ir-no-mfa-login-alarm"
  }
}

# CloudWatch alarm — detects root account usage
resource "aws_cloudwatch_metric_alarm" "root_usage" {
  alarm_name          = "ir-root-account-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RootAccountUsage"
  namespace           = "CloudTrailMetrics"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "IR Alert — root account usage detected"
  alarm_actions       = [aws_sns_topic.ir_alerts.arn]

  tags = {
    Name = "ir-root-usage-alarm"
  }
}

# IAM role for IR responder — read only during investigation
resource "aws_iam_role" "ir_responder" {
  name = "ir-responder-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "ir-responder-role"
  }
}

resource "aws_iam_role_policy_attachment" "ir_responder" {
  role       = aws_iam_role.ir_responder.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}