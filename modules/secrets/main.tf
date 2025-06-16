resource "aws_kms_key" "secrets" {
  description             = "KMS CMK for encrypting Secrets Manager secrets"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Secrets Manager to use the key"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-KMSKey"
    Environment = var.environment_type
    Team        = var.team_name
    Project     = var.project_name
  }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.secret_name}-key"
  target_key_id = aws_kms_key.secrets.key_id
}

resource "aws_secretsmanager_secret" "website" {
  name        = var.secret_name
  description = "Stores CloudFront Distribution ID and S3 Bucket name"
  kms_key_id  = aws_kms_key.secrets.key_id

  recovery_window_in_days = 30

  tags = {
    Name        = "${var.project_name}-SecretsManagerSecret"
    Environment = var.environment_type
    Team        = var.team_name
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "website" {
  secret_id = aws_secretsmanager_secret.website.id
  secret_string = jsonencode({
    DistributionId = var.distribution_id
    S3Bucket      = var.s3_bucket_name
  })
}

resource "aws_secretsmanager_secret_rotation" "website" {
  secret_id           = aws_secretsmanager_secret.website.id
  rotation_lambda_arn = var.rotation_lambda_arn
  rotation_rules {
    automatically_after_days = 30
  }
}

resource "aws_secretsmanager_secret_policy" "website" {
  secret_arn = aws_secretsmanager_secret.website.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyPublicAccess"
        Effect = "Deny"
        Principal = {
          AWS = "*"
        }
        Action = "secretsmanager:*"
        Resource = "*"
        Condition = {
          Bool = {
            "aws:SecureTransport": "false"
          }
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {} 