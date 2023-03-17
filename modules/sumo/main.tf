module "common_parameters" {
  source = "../common_parameters"
}

resource "aws_s3_object" "sumo_properties" {
  bucket  = module.common_parameters.all["config_bucket"]
  key     = join("", ["/sumo.conf"])
  content = templatefile("${path.module}/resources/sumo.properties.tpl", module.common_parameters.all)
}
