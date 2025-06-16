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

variable "s3_bucket_domain_name" {
  description = "The domain name of the S3 bucket"
  type        = string
}

variable "logging_bucket_domain_name" {
  description = "The domain name of the S3 bucket for CloudFront logs"
  type        = string
} 

variable "response_headers_policy_id" {
  description = "The ID of the CloudFront response headers policy to attach to the distribution."
  type        = string
}

variable "geo_restriction_locations" {
  description = "List of country codes for CloudFront geo restriction"
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate to use for CloudFront"
  type        = string
}

variable "wafv2_web_acl_arn" {
  description = "The ARN of the WAFv2 Web ACL to associate with the CloudFront distribution"
  type        = string
  default     = null
}

variable "replication_role_arn" {
  description = "The ARN of the IAM role for S3 replication."
  type        = string
}

variable "replication_destination_bucket_arn" {
  description = "The ARN of the destination S3 bucket for replication."
  type        = string
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for S3 server-side encryption"
  type        = string
}