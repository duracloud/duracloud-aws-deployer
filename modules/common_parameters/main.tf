data "aws_ssm_parameter" "artifact_bucket" {
  name = "duracloud_artifact_bucket"
}

data "aws_ssm_parameter" "config_bucket" {
  name = "duracloud_config_bucket"
}

data "aws_ssm_parameter" "db_password" {
  name = "duracloud_master_database_password"
}

data "aws_ssm_parameter" "sumo_access_id" {
  name = "duracloud_sumo_access_id"
}

data "aws_ssm_parameter" "sumo_access_key" {
  name = "duracloud_sumo_access_key"
}


data "aws_ssm_parameter" "mill_db_user" {
  name = "duracloud_mill_db_user"
}

data "aws_ssm_parameter" "mill_db_password" {
  name = "duracloud_mill_db_password"
}

data "aws_ssm_parameter" "account_db_user" {
  name = "duracloud_account_db_user"
}

data "aws_ssm_parameter" "account_db_password" {
  name = "duracloud_account_db_password"
}

data "aws_ssm_parameter" "notification_recipients" {
  name = "duracloud_notification_recipients"
}

data "aws_ssm_parameter" "notification_recipients_non_tech" {
  name = "duracloud_notification_recipients_non_tech"
}

data "aws_ssm_parameter" "notification_user" {
  name = "duracloud_notification_user"
}

data "aws_ssm_parameter" "notification_password" {
  name = "duracloud_notification_password"
}

data "aws_ssm_parameter" "notification_sender" {
  name = "duracloud_notification_sender"
}

data "aws_ssm_parameter" "notification_from_address" {
  name = "duracloud_notification_from_address"
}

data "aws_ssm_parameter" "notification_admin_address" {
  name = "duracloud_notification_admin_address"
}

data "aws_ssm_parameter" "mc_host" {
  name = "duracloud_mc_host"
}

data "aws_ssm_parameter" "mc_domain" {
  name = "duracloud_mc_domain"
}

data "aws_ssm_parameter" "certificate_arn" {
  name = "duracloud_certificate_arn"
}

data "aws_ssm_parameter" "recaptcha_sitekey" {
  name = "recaptcha_sitekey"
}

data "aws_ssm_parameter" "recaptcha_secret" {
  name = "recaptcha_secret"
}

locals {
  common_parameters = {
    artifact_bucket                  = data.aws_ssm_parameter.artifact_bucket.value
    config_bucket                    = data.aws_ssm_parameter.config_bucket.value
    db_password                      = data.aws_ssm_parameter.db_password.value
    sumo_access_id                   = data.aws_ssm_parameter.sumo_access_id.value
    sumo_access_key                  = data.aws_ssm_parameter.sumo_access_key.value
    mill_db_user                     = data.aws_ssm_parameter.mill_db_user.value
    mill_db_password                 = data.aws_ssm_parameter.mill_db_password.value
    account_db_user                  = data.aws_ssm_parameter.account_db_user.value
    account_db_password              = data.aws_ssm_parameter.account_db_password.value
    notification_recipients          = data.aws_ssm_parameter.notification_recipients.value
    notification_recipients_non_tech = data.aws_ssm_parameter.notification_recipients_non_tech.value
    notification_user                = data.aws_ssm_parameter.notification_user.value
    notification_from_address        = data.aws_ssm_parameter.notification_from_address.value
    notification_admin_address       = data.aws_ssm_parameter.notification_admin_address.value
    notification_password            = data.aws_ssm_parameter.notification_password.value
    notification_sender              = data.aws_ssm_parameter.notification_sender.value
    mc_host                          = data.aws_ssm_parameter.mc_host.value
    mc_port                          = 443
    mc_context                       = ""
    mc_domain                        = data.aws_ssm_parameter.mc_domain.value
    certificate_arn                  = data.aws_ssm_parameter.certificate_arn.value
    recaptcha_sitekey                = data.aws_ssm_parameter.recaptcha_sitekey.value
    recaptcha_secret                 = data.aws_ssm_parameter.recaptcha_secret.value
  }
}
