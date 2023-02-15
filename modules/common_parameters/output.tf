output all {
  value = local.common_parameters
}

output db_password {
  value = data.aws_ssm_parameter.db_password.value
}

output sumo_access_id {
  value = data.aws_ssm_parameter.sumo_access_id.value
}

output sumo_access_key {
  value = data.aws_ssm_parameter.sumo_access_key.value
}
