locals { 
  cloud_init_props = {
    aws_region = var.aws_region
  }

  duracloud_config_map = yamldecode(file(var.duracloud_config_yaml))

}


resource "local_file" "sumo_conf" {
    content     = templatefile("${path.module}/resources/sumo.conf.tpl", local.duracloud_config_map)
    filename = "${path.module}/output/sumo.conf"
}

resource "aws_s3_object" "sumo_conf" {
  bucket = var.duracloud_s3_config_bucket
  key    = join("", [var.duracloud_s3_config_path, "sumo.conf"])
  source = local_file.sumo_conf.filename
}

resource "local_file" "duracloud_config_properties" {
    content     = templatefile("${path.module}/resources/duracloud-config.properties.tpl", 
                  merge(local.cloud_init_props, 
                        local.duracloud_config_map, 
                        { database_host = data.aws_db_instance.database.address,  
                          database_port = data.aws_db_instance.database.port }))
    filename = "${path.module}/output/duracloud-config.properties"
}

resource "aws_s3_object" "duracloud_config_properties" {
  bucket = var.duracloud_s3_config_bucket
  key    = join("", [var.duracloud_s3_config_path, "duracloud-config.properties"])
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

data "aws_subnet" "duracloud_public_a" {

  tags = {
    Name = "${var.stack_name}-public-subnet-a"
  }
}

data "aws_subnet" "duracloud_public_b" {

  tags = {
    Name = "${var.stack_name}-public-subnet-b"
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
    protocol    = "tcp"
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
    protocol    = "tcp"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443 
    to_port     = 443
    protocol    = "tcp"
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
    protocol    = "tcp"
    security_groups = [aws_security_group.duracloud_beanstalk.id]
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
  tags = {
    Name = "${var.stack_name}-beanstalk-service-role"
  }
}

resource "aws_elastic_beanstalk_application" "duracloud" {
  name        = "DuraCloud"
  description = "DuraCloud Beanstalk Application (${var.stack_name})"

  appversion_lifecycle {
    service_role          = data.aws_iam_role.beanstalk_service.arn
    max_count             = 128
    delete_source_from_s3 = true
  }

  tags = {
    Name = "${var.stack_name}-eb-application"
  }
}

resource "aws_elastic_beanstalk_application_version" "default" {
  name        = var.duracloud_zip
  application = aws_elastic_beanstalk_application.duracloud.name 
  description = "${var.duracloud_zip} application"
  bucket      = var.duracloud_artifact_bucket
  key         = var.duracloud_zip
}


resource "aws_elastic_beanstalk_configuration_template" "config" {
  name                = "duracloud-config"
  application         = aws_elastic_beanstalk_application.duracloud.name
  solution_stack_name = "64bit Amazon Linux 2 v4.2.16 running Tomcat 8.5 Corretto 11"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = data.aws_vpc.duracloud.id
  }
  
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${data.aws_subnet.duracloud_public_a.id},${data.aws_subnet.duracloud_public_b.id}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile" 
    value     =  data.aws_iam_instance_profile.duracloud.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = var.ec2_keypair 
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "S3_CONFIG_BUCKET"
    value     = var.duracloud_s3_config_bucket
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:proxy"
    name      = "ProxyServer"
    value     = "apache"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }
}


resource "aws_elastic_beanstalk_environment" "duracloud" {
  name                = "${var.stack_name}-core"
  application         = aws_elastic_beanstalk_application.duracloud.name
  template_name       = aws_elastic_beanstalk_configuration_template.config.name
  version_label       = var.duracloud_zip

  setting {
    namespace = "aws:elasticbeanstalk:container:tomcat:jvmoptions"
    name      = "JVM Options"
    value = "-Dduracloud.config.file=s3://${aws_s3_object.duracloud_config_properties.bucket}/${aws_s3_object.duracloud_config_properties.key} -Dlog.level=INFO"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name = "SSLCertificateArns"
    value = local.duracloud_config_map["certificate_arn"]
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name = "Protocol"
    value = "HTTPS"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.duracloud_instance_class
  }
 
}

resource "aws_alb_target_group" "duracloud" {
  name        = "duracloud-alb-target-group"
  target_type = "alb"
  port        = 80
  protocol    = "TCP"
  vpc_id      = data.aws_vpc.duracloud.id
  stickiness {
      type        = "app_cookie"
      cookie_name = "jsessionid"
  }
}

resource "aws_alb_target_group_attachment" "duracloud" {
  target_group_arn = aws_alb_target_group.duracloud.arn
  target_id        = aws_elastic_beanstalk_environment.duracloud.load_balancers[0]
  port             = 80
}
