provider "aws" {
  region = var.aws_region
}

module "s3" {
  source = "./modules/s3"

  bucket_name     = var.bucket_name
  project_name    = var.project_name
  environment_type = var.environment_type
  team_name       = var.team_name
  cloudfront_origin_access_identity_s3_canonical_user_id = module.cloudfront.origin_access_identity_s3_canonical_user_id

  logging_bucket_name                 = var.logging_bucket_name
  replication_destination_bucket_arn = var.replication_destination_bucket_arn
  replication_kms_key_arn            = var.replication_kms_key_arn
}

module "cloudfront" {
  source = "./modules/cloudfront"

  project_name = var.project_name
  environment_type = var.environment_type
  team_name = var.team_name
  s3_bucket_domain_name = module.s3.bucket_domain_name
  logging_bucket_domain_name = module.s3.bucket_domain_name
  acm_certificate_arn                = var.acm_certificate_arn
  access_log_bucket                  = var.access_log_bucket
  kms_key_arn                        = var.kms_key_arn
  replication_role_arn               = var.replication_role_arn
  s3_event_notification_topic_arn    = var.s3_event_notification_topic_arn
  response_headers_policy_id         = var.response_headers_policy_id
  replication_destination_bucket_arn = var.replication_destination_bucket_arn
}

module "secrets" {
  source = "./modules/secrets"

  project_name = var.project_name
  environment_type = var.environment_type
  team_name = var.team_name
  secret_name = var.secret_name
  distribution_id = module.cloudfront.distribution_id
  s3_bucket_name = module.s3.bucket_name
  rotation_lambda_arn = var.rotation_lambda_arn
} 