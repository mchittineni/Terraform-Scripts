output "cloudfront_url" {
  description = "CloudFront Distribution URL"
  value       = "https://${module.cloudfront.distribution_domain_name}"
}

output "s3_bucket_name" {
  description = "Primary S3 Bucket Name"
  value       = module.s3.bucket_name
}

output "secret_arn" {
  description = "Secrets Manager Secret ARN"
  value       = module.secrets.secret_arn
} 