# config the sentinel
resource "aws_launch_template" "sentinel_launch_template" {
  name_prefix            = "${var.stack_name}-sentinel-launch-template_"
  image_id               = local.node_image_id
  instance_type          = var.sentinel_instance_class
  vpc_security_group_ids = [aws_security_group.mill_instance.id]
  key_name               = var.ec2_keypair
  user_data              = base64encode(templatefile("${path.module}/resources/cloud-init.tpl", merge(local.cloud_init_props, { node_type = "sentinel" })))
  update_default_version = true

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 20
      volume_type = "gp2"
    }
  }

  iam_instance_profile { name = data.aws_iam_instance_profile.duracloud.name }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "sentinel_asg" {
  name                = "${var.stack_name}-sentinel-asg"
  vpc_zone_identifier = [data.aws_subnet.duracloud_a.id, data.aws_subnet.duracloud_c.id, data.aws_subnet.duracloud_d.id]
  max_size            = 1
  min_size            = 1

  launch_template {
    id      = aws_launch_template.sentinel_launch_template.id
    version = aws_launch_template.sentinel_launch_template.latest_version
  }

  tag {
    key                 = "Name"
    value               = "${var.stack_name}-sentinel"
    propagate_at_launch = true
  }
}
