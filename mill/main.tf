data "aws_region" "current" {}

module "common_parameters" {
  source = "../modules/common_parameters"
}



resource "aws_efs_file_system" "duracloud_mill" {
  tags = {
    Name = "${var.stack_name}-efs"
  }
}

resource "aws_efs_mount_target" "mount_target_a" {
  file_system_id  = aws_efs_file_system.duracloud_mill.id
  subnet_id       = data.aws_subnet.duracloud_a.id
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_efs_mount_target" "mount_target_b" {
  file_system_id  = aws_efs_file_system.duracloud_mill.id
  subnet_id       = data.aws_subnet.duracloud_b.id
  security_groups = [aws_security_group.efs_sg.id]
}


resource "aws_security_group" "efs_sg" {
  name   = "efs_sg"
  vpc_id = data.aws_vpc.duracloud.id

  ingress {
    description     = "from mill sg"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.mill_instance.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.stack_name}-efs-security-group"
  }
}

data "aws_ami" "docker_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["aws-elasticbeanstalk-amzn-2018.03.0.x86_64-docker-hvm-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"] # amazon

}


locals {
  node_image_id = data.aws_ami.docker_ami.id
  cloud_init_props = {
    aws_region              = data.aws_region.current.name
    mill_s3_config_location = join("", [module.common_parameters.all["config_bucket"], var.mill_s3_config_path])
    efs_dns_name            = aws_efs_file_system.duracloud_mill.dns_name
    mill_docker_container   = var.mill_docker_container
    mill_version            = var.mill_version
    instance_prefix         = var.stack_name
    domain                  = "test.org"
  }
}

resource "aws_s3_object" "mill_config_properties" {
  bucket = module.common_parameters.all["config_bucket"]
  key    = join("", [var.mill_s3_config_path, "/mill-config.properties"])
  content = templatefile("${path.module}/resources/mill-config.properties.tpl",
    merge(local.cloud_init_props,
      module.common_parameters.all,
      { database_host                = data.aws_db_instance.database.address,
        database_port                = data.aws_db_instance.database.port,
        audit_queue_name             = aws_sqs_queue.audit.name,
        bit_queue_name               = aws_sqs_queue.bit.name,
        dup_high_priority_queue_name = aws_sqs_queue.high_priority_dup.name,
        dup_low_priority_queue_name  = aws_sqs_queue.low_priority_dup.name,
        bit_report_queue_name        = aws_sqs_queue.bit_report.name,
        bit_error_queue_name         = aws_sqs_queue.bit_error.name,
        dead_letter_queue_name       = aws_sqs_queue.dead_letter.name,
  storage_stats_queue_name = aws_sqs_queue.storage_stats.name }))
}


data "aws_iam_instance_profile" "duracloud" {
  name = "${var.stack_name}-dc-ip"
}


data "aws_vpc" "duracloud" {

  tags = {
    Name = "${var.stack_name}-vpc"
  }
}

data "aws_subnet" "duracloud_a" {
  vpc_id = data.aws_vpc.duracloud.id
  tags = {
    Name = "${var.stack_name}-subnet-a"
  }
}

data "aws_subnet" "duracloud_b" {
  vpc_id = data.aws_vpc.duracloud.id

  tags = {
    Name = "${var.stack_name}-subnet-b"
  }
}

data "aws_subnet" "duracloud_c" {
  vpc_id = data.aws_vpc.duracloud.id
  tags = {
    Name = "${var.stack_name}-subnet-c"
  }
}

data "aws_subnet" "duracloud_d" {
  vpc_id = data.aws_vpc.duracloud.id

  tags = {
    Name = "${var.stack_name}-subnet-d"
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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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

resource "aws_sqs_queue" "storage_stats" {
  name                      = "${var.stack_name}-storage-stats"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 10

  tags = {
    "Name" = "${var.stack_name}-storage-stats"
  }
}

resource "aws_sqs_queue" "dead_letter" {
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
  db_instance_identifier = "${var.stack_name}-db-instance"
}
