# ------------------------------------
# S3 - snowflakepipe連携
# ------------------------------------
module "s3_snowpipe" {
  source                 = "./modules/s3_snowpipe"
  project                = local.project
  aws_iam_role_principal = local.aws_iam_role_principal
  externalid             = local.externalid
  notification_channel   = local.notification_channel
}