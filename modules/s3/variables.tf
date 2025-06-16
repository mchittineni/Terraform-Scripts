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

variable "cloudfront_origin_access_identity_s3_canonical_user_id" {
  description = "The S3 canonical user ID for the CloudFront origin access identity"
  type        = string
} 