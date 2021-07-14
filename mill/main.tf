resource "aws_efs_file_system" "duracloud_mill" {
   tags = { 
     Name = "${var.stack_name}-efs"
   } 
}

locals { 
  node_image_id =  "ami-008a8487adc2b32ec" 
  cloud_init_props = {
    aws_region = var.aws_region
    mill_s3_config_location = var.mill_s3_config_location
    efs_dns_name = aws_efs_file_system.duracloud_mill.dns_name	
    mill_version = var.mill_version  
    instance_prefix = var.stack_name
    domain = "test.org" 
  }

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

resource "aws_security_group" "duracloud_mill" {

  vpc_id = data.aws_vpc.duracloud.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22 
    to_port     = 22 
    protocol    = "tcp"
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.stack_name}-mill-security-group"
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
  name                      = "${var.stack_name}-high_priority-dup"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 10

  tags = {
    "Name" = "${var.stack_name}-high-priority-dup"
  }
}

resource "aws_sqs_queue" "low_priority_dup" {
  name                      = "${var.stack_name}-low_priority-dup"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 10

  tags = {
    "Name" = "${var.stack_name}-low-priority-dup"
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

resource "aws_sqs_queue" "storage-stats" {
  name                      = "${var.stack_name}-storage-stats"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 10

  tags = {
    "Name" = "${var.stack_name}-"
  }
}



resource "aws_launch_configuration" "audit_worker_launch_config" {
  name = "audit-worker-launch-config"
  image_id      = local.node_image_id
  instance_type = var.worker_instance_class 
  spot_price    = var.worker_spot_price 
  user_data = templatefile("${path.module}/resources/cloud-init.tpl", merge(local.cloud_init_props, { node_type = "audit_worker" } ))
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "audit_worker_asg" {
  name                 = "audit-worker-asg"
  launch_configuration = aws_launch_configuration.audit_worker_launch_config.name
  vpc_zone_identifier       = [data.aws_subnet.duracloud_a.id]
  max_size = 1
  min_size = 0 
}





