variable "origin_shield_region" {
  description = "The AWS region where Origin Shield is enabled"
  type        = string
  default     = "us-east-1"
}

variable "access_log_bucket" {
  description = "The name of the S3 bucket for access logs"
  type        = string
}

variable "s3_event_notification_topic_arn" {
  description = "The ARN of the SNS topic for S3 event notifications"
  type        = string
}

resource "aws_cloudfront_origin_access_identity" "website" {
  comment = "OAI for ${var.project_name} CloudFront distribution"
}

resource "aws_s3_bucket" "failover" {
  bucket = "${var.project_name}-failover"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = var.kms_key_arn
      }
    }
  }

  logging {
    target_bucket = var.access_log_bucket
    target_prefix = "failover-bucket-logs/"
  }

  tags = {
    Name        = "${var.project_name}-FailoverBucket"
    Environment = var.environment_type
    Team        = var.team_name
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "failover" {
  bucket = aws_s3_bucket.failover.id

  rule {
    id     = "expire-old-objects"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_replication_configuration" "failover" {
  bucket = aws_s3_bucket.failover.id
  role   = var.replication_role_arn

  rule {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket        = var.replication_destination_bucket_arn
      storage_class = "STANDARD"
    }

    filter {}
  }
}

# S3 bucket notification configuration for failover bucket
resource "aws_s3_bucket_notification" "failover" {
  bucket = aws_s3_bucket.failover.id

  # Example: S3 event notification to SNS topic (replace with your actual SNS topic ARN)
  topic {
    topic_arn = var.s3_event_notification_topic_arn
    events    = ["s3:ObjectCreated:*"]
  }
}

resource "aws_s3_bucket_public_access_block" "failover" {
  bucket                  = aws_s3_bucket.failover.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_identity" "failover" {
  comment = "OAI for ${var.project_name} CloudFront failover"
}

resource "aws_cloudfront_origin_group" "website" {
  origin_id = "OriginGroup1"

  failover_criteria {
    status_codes = [403, 404, 500, 502, 503, 504]
  }

  member {
    origin_id = "S3Origin"
  }

  member {
    origin_id = "FailoverOrigin"
  }
}

resource "aws_cloudfront_distribution" "website" {
  # checkov:skip=CKV2_AWS_47: ADD REASON
  # checkov:skip=CKV2_AWS_32: ADD REASON
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  http_version        = "http2"
  wait_for_deployment = true

  origin {
    domain_name = var.s3_bucket_domain_name
    origin_id   = "S3Origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.website.cloudfront_access_identity_path
    }

    origin_shield {
      enabled              = true
      origin_shield_region = var.origin_shield_region
    }
  }

  origin {
    domain_name = aws_s3_bucket.failover.bucket_regional_domain_name
    origin_id   = "FailoverOrigin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.failover.cloudfront_access_identity_path
    }

    origin_shield {
      enabled              = true
      origin_shield_region = var.origin_shield_region
    }
  }

  origin_group {
    origin_id = aws_cloudfront_origin_group.website.origin_id

    failover_criteria {
      status_codes = [403, 404, 500, 502, 503, 504]
    }

    member {
      origin_id = "S3Origin"
    }

    member {
      origin_id = "FailoverOrigin"
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized

    response_headers_policy_id = var.response_headers_policy_id != "" ? var.response_headers_policy_id : "67f7725c-6f97-4210-82d7-5512b31e9d03" # Default SecurityHeadersPolicy
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = var.geo_restriction_locations
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  web_acl_id = var.wafv2_web_acl_arn 
  
  logging_config {
    include_cookies = false
    bucket          = var.logging_bucket_domain_name
    prefix          = "cloudfront-logs/"
  }

  tags = {
    Name        = "${var.project_name}-CloudFrontDistribution"
    Environment = var.environment_type
    Team        = var.team_name
    Project     = var.project_name
  }
}