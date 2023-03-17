# config the high priority dup worker launch config, autoscaling group, alarms, etc

resource "aws_launch_configuration" "high_priority_dup_worker_launch_config" {
  name_prefix          = "high_priority_dup-worker-launch-config_"
  image_id             = local.node_image_id
  instance_type        = var.worker_instance_class
  iam_instance_profile = data.aws_iam_instance_profile.duracloud.name
  security_groups      = [aws_security_group.mill_instance.id]
  key_name             = var.ec2_keypair
  spot_price           = var.worker_spot_price
  user_data            = templatefile("${path.module}/resources/cloud-init.tpl", merge(local.cloud_init_props, { node_type = "dup-worker" }))
  root_block_device {
    volume_type = "gp2"
    volume_size = 60
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "high_priority_dup_worker_asg" {
  name                 = "high_priority_dup-worker-asg"
  launch_configuration = aws_launch_configuration.high_priority_dup_worker_launch_config.name
  vpc_zone_identifier  = [data.aws_subnet.duracloud_a.id]
  max_size             = 10
  min_size             = 0
  //availability_zones = [data.aws_subnet.duracloud_a.availability_zone, data.aws_subnet.duracloud_b.availability_zone ]
}

resource "aws_autoscaling_policy" "high_priority_dup_worker_scale_up" {
  name                   = "high_priority_dup_worker_scale_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.high_priority_dup_worker_asg.name
}

resource "aws_autoscaling_policy" "high_priority_dup_worker_scale_down" {
  name                   = "high_priority_dup_worker_scale_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
  cooldown               = 900
  autoscaling_group_name = aws_autoscaling_group.high_priority_dup_worker_asg.name
}

resource "aws_cloudwatch_metric_alarm" "high_priority_dup_worker_scale_up_alarm" {
  alarm_name          = "large-high_priority_dup_queue-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "500"

  dimensions = {
    QueueName = aws_sqs_queue.high_priority_dup.name
  }

  alarm_description = "This metric monitors high_priority_dup queue size"
  alarm_actions     = [aws_autoscaling_policy.high_priority_dup_worker_scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "high_priority_dup_worker_scale_down_alarm" {
  alarm_name          = "small-high_priority_dup-queue-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "4"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "100"

  dimensions = {
    QueueName = aws_sqs_queue.high_priority_dup.name
  }

  alarm_description = "This metric monitors high_priority_dup queue size"
  alarm_actions     = [aws_autoscaling_policy.high_priority_dup_worker_scale_down.arn]
}



