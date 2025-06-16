output "distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.id
}

output "distribution_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "origin_access_identity_iam_arn" {
  description = "The IAM ARN of the CloudFront origin access identity"
  value       = aws_cloudfront_origin_access_identity.website.iam_arn
}

output "origin_access_identity_s3_canonical_user_id" {
  description = "The S3 canonical user ID of the CloudFront origin access identity"
  value       = aws_cloudfront_origin_access_identity.website.s3_canonical_user_id
} 