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

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-S3KMSKey"
    Environment = var.environment_type
    Team        = var.team_name
    Project     = var.project_name
  }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.project_name}-s3-key"
  target_key_id = aws_kms_key.s3.key_id
}

resource "aws_s3_bucket" "website" {
  # checkov:skip=CKV2_AWS_62: ADD REASON
  bucket = var.bucket_name

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.s3.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  logging {
    target_bucket = var.logging_bucket_name
    target_prefix = "${var.bucket_name}/logs/"
  }

  versioning {
    enabled = true
  }

  # Replication configuration moved to aws_s3_bucket_replication_configuration resource below

  tags = {
    Name        = "${var.project_name}-S3Bucket"
    Environment = var.environment_type
    Team        = var.team_name
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    id     = "DeleteOldObjects"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 365
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = {
          CanonicalUser = var.cloudfront_origin_access_identity_s3_canonical_user_id
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_replication_configuration" "website" {
  bucket = aws_s3_bucket.website.id
  role   = aws_iam_role.s3_replication.arn

  rule {
    id     = "replication-rule"
    status = "Enabled"

    destination {
      bucket        = var.replication_destination_bucket_arn
      storage_class = "STANDARD"
      encryption_configuration {
        replica_kms_key_id = var.replication_kms_key_arn
      }
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        enabled = true
      }
    }
  }
}

resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_intelligent_tiering_configuration" "website" {
  bucket = aws_s3_bucket.website.id
  name   = "EntireBucket"

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 90
  }
  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 30
  }
  status = "Enabled"
}

resource "aws_iam_role" "s3_replication" {
  name = "${var.project_name}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-S3ReplicationRole"
    Environment = var.environment_type
    Team        = var.team_name
    Project     = var.project_name
  }
}

resource "aws_iam_policy" "s3_replication" {
  name = "${var.project_name}-s3-replication-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.website.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${aws_s3_bucket.website.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "${var.replication_destination_bucket_arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_replication" {
  role       = aws_iam_role.s3_replication.name
  policy_arn = aws_iam_policy.s3_replication.arn
}