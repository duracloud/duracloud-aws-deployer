resource "aws_efs_file_system" "duracloud_mill" {
   tags = { 
     Name = "${var.stack_name}-efs"
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
    aws_region = var.aws_region
    mill_s3_config_location = join("", [var.mill_s3_config_bucket,var.mill_s3_config_path])
    efs_dns_name = aws_efs_file_system.duracloud_mill.dns_name	
    mill_docker_container = var.mill_docker_container
    mill_version = var.mill_version  
    instance_prefix = var.stack_name
    domain = "test.org" 
  }

  mill_config_map = yamldecode(file(var.mill_config_yaml))

}


resource "local_file" "sumo_properties" {
    content     = templatefile("${path.module}/resources/sumo.properties.tpl", local.mill_config_map)
    filename = "${path.module}/output/sumo.properties"
}

resource "aws_s3_object" "sumo_properties" {
  bucket = var.mill_s3_config_bucket
  key    = join("", [var.mill_s3_config_path, "/sumo.properties"])
  source = local_file.sumo_properties.filename
}

resource "local_file" "mill_config_properties" {
    content     = templatefile("${path.module}/resources/mill-config.properties.tpl", 
                  merge(local.cloud_init_props, 
                        local.mill_config_map, 
                        { database_host = data.aws_db_instance.database.address,  
                          database_port = data.aws_db_instance.database.port,  
                          audit_queue_name = aws_sqs_queue.audit.name, 
                          bit_queue_name = aws_sqs_queue.bit.name, 
                          dup_high_priority_queue_name = aws_sqs_queue.high_priority_dup.name, 
                          dup_low_priority_queue_name = aws_sqs_queue.low_priority_dup.name,
                          bit_report_queue_name = aws_sqs_queue.bit_report.name,
                          bit_error_queue_name = aws_sqs_queue.bit_error.name,
                          dead_letter_queue_name = aws_sqs_queue.dead_letter.name,
                          storage_stats_queue_name = aws_sqs_queue.storage_stats.name }))
    filename = "${path.module}/output/mill-config.properties"
}

resource "aws_s3_object" "mill_config_properties" {
  bucket = var.mill_s3_config_bucket
  key    = join("", [var.mill_s3_config_path, "/mill-config.properties"])
  source = local_file.mill_config_properties.filename
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
  db_instance_identifier =  "${var.stack_name}-db-instance"
}
