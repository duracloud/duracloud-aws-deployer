locals { 
  node_image_id =  "ami-005455a8cbc54a86a" 
  cloud_init_props = {
    aws_region = var.aws_region
    duracloud_version = var.duracloud_version  
    instance_prefix = var.stack_name
    domain = "test.org" 
  }

  duracloud_config_map = yamldecode(file(var.duracloud_config_yaml))

}


resource "local_file" "sumo_properties" {
    content     = templatefile("${path.module}/resources/sumo.properties.tpl", local.duracloud_config_map)
    filename = "${path.module}/output/sumo.properties"
}

resource "aws_s3_bucket_object" "sumo_properties" {
  bucket = var.duracloud_s3_config_bucket
  key    = join("", [var.duracloud_s3_config_path, "/sumo.properties"])
  source = local_file.sumo_properties.filename
}

resource "local_file" "duracloud_config_properties" {
    content     = templatefile("${path.module}/resources/duracloud-config.properties.tpl", 
                  merge(local.cloud_init_props, 
                        local.mill_config_map, 
                        { database_host = data.aws_db_instance.database.address,  
                          database_port = data.aws_db_instance.database.port }))
    filename = "${path.module}/output/duracloud-config.properties"
}

resource "aws_s3_bucket_object" "mill_config_properties" {
  bucket = var.mill_s3_config_bucket
  key    = join("", [var.duracloud_s3_config_path, "/duracloud-config.properties"])
  source = local_file.duracloud_config_properties.filename
}


data "aws_iam_instance_profile" "duracloud" {
  name = "duracloud-instance-profile"
}


data "aws_vpc" "duracloud" {

  tags = {
    Name = "${var.stack_name}-vpc"
  }
}

data "aws_subnet" "duracloud_public_subnet" {

  tags = {
    Name = "${var.stack_name}-public-subnet"
  }
}

# configure database users

data "aws_db_instance" "database" {
  db_instance_identifier =  "${var.stack_name}-db-instance"
}


resource "aws_security_group" "duracloud_load_balancer" {

  vpc_id = data.aws_vpc.duracloud.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80 
    protocol    = "tcp"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22 
    to_port     = 22
    protocol    = "ssh"
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.stack_name}-load-balancer-sg"
  }
}

resource "aws_security_group" "duracloud_beanstalk" {

  vpc_id = data.aws_vpc.duracloud.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
    protocol    = "http"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443 
    to_port     = 443
    protocol    = "https"
  }


  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.stack_name}-load-balancer-sg"
  }
}

resource "aws_security_group" "duracloud_beanstalk_instance" {

  vpc_id = data.aws_vpc.duracloud.id

  ingress {
    from_port   = 80
    to_port     = 80 
    protocol    = "http"
    security_groups = [aws_security_group.duracloud_beanstalk_instance.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.stack_name}-beanstalk-instance-sg"
  }
}

data "aws_iam_role" "beanstalk_service" {
  name = "aws-elasticbeanstalk-service-role"
}

data "aws_vpc" "duracloud" {
 tags = {
    Name = "${var.stack_name}-vpc"
  }
}


data "aws_subnet" "duracloud_public_subnet" {
 tags = {
    Name = "${var.stack_name}-public-subnet"
  }
}

resource "aws_elastic_beanstalk_application" "duracloud" {
  name        = "DuraCloud"
  description = "DuraCloud Beanstalk Application (${var.stack_name})"

  appversion_lifecycle {
    service_role          = aws_iam_role.beanstalk_service.arn
    max_count             = 128
    delete_source_from_s3 = true
  }

  tags = {
    Name = "${var.stack_name}-eb-application"
  }
}

resource "aws_elastic_beanstalk_configuration_template" "config" {
  name                = duracloud-config"
  application         = aws_elastic_beanstalk_application.duracloud.name
  solution_stack_name = "64bit Amazon Linux 2 v4.2.12 running Tomcat 8.5 Corretto 11"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = data.aws_vpc.duracloud.id
  }
  
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = data.aws_subnet.duracloud_public.id
  }
}


resource "aws_elastic_beanstalk_environment" "duracloud" {
  name                = "tf-test-name"
  application         = aws_elastic_beanstalk_application.duracloud.name
  template_name       = aws_elastic_beanstalk_configuration_template.config.name

  tags = {
    Name = "${var.stack_name}-eb-environment"
  }
}
