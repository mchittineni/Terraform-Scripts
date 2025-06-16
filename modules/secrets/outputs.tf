output "secret_arn" {
  description = "The ARN of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.website.arn
}

output "kms_key_arn" {
  description = "The ARN of the KMS key"
  value       = aws_kms_key.secrets.arn
}

output "kms_key_id" {
  description = "The ID of the KMS key"
  value       = aws_kms_key.secrets.key_id
} 