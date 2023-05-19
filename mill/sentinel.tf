# config the sentinel
resource "aws_launch_configuration" "sentinel_launch_config" {
  name_prefix          = "${var.stack_name}-sentinel-launch-config_"
  image_id             = local.node_image_id
  instance_type        = var.sentinel_instance_class
  iam_instance_profile = data.aws_iam_instance_profile.duracloud.name
  security_groups      = [aws_security_group.mill_instance.id]
  key_name             = var.ec2_keypair
  user_data            = templatefile("${path.module}/resources/cloud-init.tpl", merge(local.cloud_init_props, { node_type = "sentinel" }))
  root_block_device {
    volume_type = "gp2"
    volume_size = 20
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "sentinel_asg" {
  name                 = "${var.stack_name}-sentinel-asg"
  launch_configuration = aws_launch_configuration.sentinel_launch_config.name
  vpc_zone_identifier  = [data.aws_subnet.duracloud_a.id]
  max_size             = 1
  min_size             = 1
}
