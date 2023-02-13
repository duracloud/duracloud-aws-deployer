module "common_parameters" {
  source = "../common_parameters"
}

resource "aws_s3_object" "sumo_properties" {
  bucket = var.bucket
  key    = join("", [var.path, "/sumo.properties"])
  content = templatefile("${path.module}/resources/sumo.properties.tpl", module.common_parameters.all)
}
