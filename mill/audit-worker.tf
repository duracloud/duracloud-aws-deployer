# config the audit worker launch config, autoscaling group, alarms, etc

resource "aws_launch_template" "audit_worker_launch_template" {
  name_prefix            = "${var.stack_name}-audit-worker-launch-template_"
  image_id               = local.node_image_id
  instance_type          = var.worker_instance_class
  vpc_security_group_ids = [aws_security_group.mill_instance.id]
  key_name               = var.ec2_keypair
  user_data              = base64encode(templatefile("${path.module}/resources/cloud-init.tpl", merge(local.cloud_init_props, { node_type = "audit-worker" })))
  update_default_version = true

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 60
      volume_type = "gp2"
    }
  }

  iam_instance_profile { name = data.aws_iam_instance_profile.duracloud.name }

  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = var.worker_spot_price
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "audit_worker_asg" {
  name                = "${var.stack_name}-audit-worker-asg"
  vpc_zone_identifier = [data.aws_subnet.duracloud_a.id, data.aws_subnet.duracloud_c.id, data.aws_subnet.duracloud_d.id]
  max_size            = var.audit_worker_max
  min_size            = 1

  launch_template {
    id      = aws_launch_template.audit_worker_launch_template.id
    version = aws_launch_template.audit_worker_launch_template.latest_version
  }

  tag {
    key                 = "Name"
    value               = "${var.stack_name}-audit-worker"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "audit_worker_scale_up" {
  name                   = "${var.stack_name}-audit_worker_scale_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
  cooldown               = 900
  autoscaling_group_name = aws_autoscaling_group.audit_worker_asg.name
}

resource "aws_autoscaling_policy" "audit_worker_scale_down" {
  name                   = "${var.stack_name}-audit_worker_scale_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
  cooldown               = 900
  autoscaling_group_name = aws_autoscaling_group.audit_worker_asg.name
}

resource "aws_cloudwatch_metric_alarm" "audit_worker_scale_up_alarm" {
  alarm_name          = "${var.stack_name}-large-audit_queue-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "1000"

  dimensions = {
    QueueName = aws_sqs_queue.audit.name
  }

  alarm_description = "This metric monitors audit queue size"
  alarm_actions     = [aws_autoscaling_policy.audit_worker_scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "audit_worker_scale_down_alarm" {
  alarm_name          = "${var.stack_name}-small-audit-queue-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "4"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "500"

  dimensions = {
    QueueName = aws_sqs_queue.audit.name
  }

  alarm_description = "This metric monitors audit queue size"
  alarm_actions     = [aws_autoscaling_policy.audit_worker_scale_down.arn]
}



