# config the bit_report worker launch config, autoscaling group, alarms, etc

resource "aws_launch_template" "bit_report_worker_launch_template" {
  name_prefix            = "${var.stack_name}-bit_report-worker-launch-template_"
  image_id               = local.node_image_id
  instance_type          = var.worker_instance_class
  vpc_security_group_ids = [aws_security_group.mill_instance.id]
  key_name               = var.ec2_keypair
  user_data = base64encode(templatefile("${path.module}/resources/cloud-init.tpl",
    merge(local.cloud_init_props, {
      node_type          = "bit-report-worker"
      max_worker_threads = var.bit_report_max_worker_threads
  })))
  update_default_version = true

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 20
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

resource "aws_autoscaling_group" "bit_report_worker_asg" {
  name                = "${var.stack_name}-bit_report-worker-asg"
  vpc_zone_identifier = [data.aws_subnet.duracloud_a.id, data.aws_subnet.duracloud_c.id, data.aws_subnet.duracloud_d.id]
  max_size            = 1
  min_size            = 0

  launch_template {
    id      = aws_launch_template.bit_report_worker_launch_template.id
    version = aws_launch_template.bit_report_worker_launch_template.latest_version
  }

  tag {
    key                 = "Name"
    value               = "${var.stack_name}-bit-report-worker"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "bit_report_worker_scale_up" {
  name                   = "${var.stack_name}-bit_report_worker_scale_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.bit_report_worker_asg.name
}

resource "aws_autoscaling_policy" "bit_report_worker_scale_down" {
  name                   = "${var.stack_name}-bit_report_worker_scale_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.bit_report_worker_asg.name
}

resource "aws_cloudwatch_metric_alarm" "bit_report_worker_scale_up_alarm" {
  alarm_name          = "${var.stack_name}-non-empty-bit_report_queue-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "0.5"

  dimensions = {
    QueueName = aws_sqs_queue.bit_report.name
  }

  alarm_description = "This metric monitors bit_report queue size"
  alarm_actions     = [aws_autoscaling_policy.bit_report_worker_scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "bit_report_worker_scale_down_alarm" {
  alarm_name          = "${var.stack_name}-empty-bit_report-queue-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "6"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "3600"
  statistic           = "Average"
  threshold           = "0"

  dimensions = {
    QueueName = aws_sqs_queue.bit_report.name
  }

  alarm_description = "This metric monitors bit_report queue size"
  alarm_actions     = [aws_autoscaling_policy.bit_report_worker_scale_down.arn]
}
