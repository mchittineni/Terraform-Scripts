variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "project_name" {
  description = "Name of the project this stack belongs to"
  type        = string
  default     = "Portfolio-Project"
}

variable "environment_type" {
  description = "Environment type (e.g., Dev, Qa, Prod)"
  type        = string
  default     = "Prod"
}

variable "team_name" {
  description = "Name of the team this stack belongs to"
  type        = string
  default     = "MC"
}

variable "secret_name" {
  description = "Name of the secret to store distribution and bucket info"
  type        = string
  default     = "PortfolioSecret"
} 

variable "rotation_lambda_arn" {
  description = "ARN of the Lambda function for secret rotation"
  type        = string
}

variable "logging_bucket_name" {
  description = "The name of the S3 bucket for storing access logs"
  type        = string
}

variable "replication_destination_bucket_arn" {
  description = "The ARN of the destination S3 bucket for replication"
  type        = string
}

variable "replication_kms_key_arn" {
  description = "The ARN of the KMS key used for replication encryption"
  type        = string
}

variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate to use for CloudFront"
  type        = string
}

variable "access_log_bucket" {
  description = "The name of the S3 bucket for CloudFront access logs"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key to use for encryption"
  type        = string
  default     = ""
}

variable "replication_role_arn" {
  description = "ARN of the IAM role used for replication"
  type        = string
}

variable "s3_event_notification_topic_arn" {
  description = "ARN of the SNS topic for S3 event notifications"
  type        = string
  default     = ""
}

variable "response_headers_policy_id" {
  description = "The ID of the CloudFront response headers policy"
  type        = string
}