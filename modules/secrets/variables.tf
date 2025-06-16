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

variable "distribution_id" {
  description = "The ID of the CloudFront distribution"
  type        = string
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
} 

variable "rotation_lambda_arn" {
  description = "The name of the S3 bucket"
  type        = string
} 