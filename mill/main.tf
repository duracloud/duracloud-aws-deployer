resource "aws_efs_file_system" "duracloud_mill" {
   tags = { 
     Name = "${var.stack_name}-efs"
   } 
}

locals { 
  node_image_id =  "ami-005455a8cbc54a86a" 
  cloud_init_props = {
    aws_region = var.aws_region
    mill_s3_config_location = var.mill_s3_config_location
    efs_dns_name = aws_efs_file_system.duracloud_mill.dns_name	
    mill_docker_container = var.mill_docker_container
    mill_version = var.mill_version  
    instance_prefix = var.stack_name
    domain = "test.org" 
  }

}

data "aws_iam_instance_profile" "duracloud" {
  name = "duracloud-instance-profile"
}


data "aws_vpc" "duracloud" {

  tags = {
    Name = "${var.stack_name}-vpc"
  }
}

data "aws_subnet" "duracloud_a" {

  tags = {
    Name = "${var.stack_name}-subnet-a"
  }
}

data "aws_subnet" "duracloud_b" {

  tags = {
    Name = "${var.stack_name}-subnet-b"
  }
}

resource "aws_security_group" "mill_instance" {

  vpc_id = data.aws_vpc.duracloud.id

  ingress {
    cidr_blocks = ["10.0.0.0/16"]
    from_port   = 0 
    to_port     = 0 
    protocol    = "-1"
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.stack_name}-mill-instance-sg"
  }
}

resource "aws_sqs_queue" "audit" {
  name                      = "${var.stack_name}-audit"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 10

  tags = {
    "Name" = "${var.stack_name}-audit"
  }
}

resource "aws_sqs_queue" "bit" {
  name                      = "${var.stack_name}-bit"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 10

  tags = {
    "Name" = "${var.stack_name}-bit"
  }
}

resource "aws_sqs_queue" "high_priority_dup" {
  name                      = "${var.stack_name}-dup-high-priority"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 10

  tags = {
    "Name" = "${var.stack_name}-dup-high-priority"
  }
}

resource "aws_sqs_queue" "low_priority_dup" {
  name                      = "${var.stack_name}-dup-low-priority"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 10

  tags = {
    "Name" = "${var.stack_name}-dup-low-priority"
  }
}

resource "aws_sqs_queue" "bit_report" {
  name                      = "${var.stack_name}-bit-report"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 10

  tags = {
    "Name" = "${var.stack_name}-bit-report"
  }
}

resource "aws_sqs_queue" "bit_error" {
  name                      = "${var.stack_name}-bit-error"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 10

  tags = {
    "Name" = "${var.stack_name}-bit-error"
  }
}

resource "aws_sqs_queue" "storage-stats" {
  name                      = "${var.stack_name}-storage-stats"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 10

  tags = {
    "Name" = "${var.stack_name}-storage-stats"
  }
}

resource "aws_sqs_queue" "dead-letter" {
  name                      = "${var.stack_name}-dead-letter"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 10

  tags = {
    "Name" = "${var.stack_name}-dead-letter"
  }
}


# configure mill database users

data "aws_db_instance" "database" {
  db_instance_identifier =  "${var.stack_name}-db-instance"
}


resource "aws_launch_configuration" "audit_worker_launch_config" {
  name_prefix = "audit-worker-launch-config_"
  image_id      = local.node_image_id
  instance_type = var.worker_instance_class 
  iam_instance_profile = data.aws_iam_instance_profile.duracloud.name
  security_groups = [aws_security_group.mill_instance.id]
  key_name = var.ec2_keypair
  spot_price    = var.worker_spot_price 
  user_data = templatefile("${path.module}/resources/cloud-init.tpl", merge(local.cloud_init_props, { node_type = "audit-worker" } ))
  root_block_device {
    volume_type = "gp2"
    volume_size = 60	
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "audit_worker_asg" {
  name                 = "audit-worker-asg"
  launch_configuration = aws_launch_configuration.audit_worker_launch_config.name
  vpc_zone_identifier       = [data.aws_subnet.duracloud_a.id]
  max_size = 10 
  min_size = 1 
  //availability_zones = [data.aws_subnet.duracloud_a.availability_zone, data.aws_subnet.duracloud_b.availability_zone ]
}

resource "aws_autoscaling_policy" "audit_worker_scale_up" {
  name                   = "audit_worker_scale_up"
  scaling_adjustment     = 1 
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
  cooldown               = 900
  autoscaling_group_name = aws_autoscaling_group.audit_worker_asg.name
}

resource "aws_autoscaling_policy" "audit_worker_scale_down" {
  name                   = "audit_worker_scale_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
  cooldown               = 900
  autoscaling_group_name = aws_autoscaling_group.audit_worker_asg.name
}

resource "aws_cloudwatch_metric_alarm" "audit_worker_scale_up_alarm" {
  alarm_name          = "large-audit_queue-alarm"
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
  alarm_name          = "small-audit-queue-alarm"
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



