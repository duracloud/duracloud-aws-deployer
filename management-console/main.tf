module "common_parameters" {
  source = "../modules/common_parameters"
}

locals { 
  cloud_init_props = {
    aws_region = var.aws_region
  }

}

resource "aws_s3_object" "mc_config_properties" {
  bucket = module.common_parameters.all["config_bucket"]
  key    = join("", [var.mc_s3_config_path, "management-console-config.properties"])
  content = templatefile("${path.module}/resources/duracloud-config.properties.tpl",
                  merge(local.cloud_init_props,
                        module.common_parameters.all,
                        { database_host = data.aws_db_instance.database.address,
                          database_port = data.aws_db_instance.database.port })) 
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

resource "aws_security_group" "mc_beanstalk" {

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

resource "aws_security_group" "mc_beanstalk_instance" {

  vpc_id = data.aws_vpc.duracloud.id

  ingress {
    from_port   = 80
    to_port     = 80 
    protocol    = "tcp"
    security_groups = [aws_security_group.mc_beanstalk.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.stack_name}-beanstalk-mc-sg"
  }
}

data "aws_iam_role" "beanstalk_service" {
  name = "aws-elasticbeanstalk-service-role"
  tags = {
    Name = "${var.stack_name}-beanstalk-service-role"
  }
}

resource "aws_elastic_beanstalk_application" "mc" {
  name        = "DuraCloud Management Console"
  description = "DuraCloud Management Console Beanstalk Application (${var.stack_name})"

  appversion_lifecycle {
    service_role          = data.aws_iam_role.beanstalk_service.arn
    max_count             = 128
    delete_source_from_s3 = true
  }

  tags = {
    Name = "${var.stack_name}-eb-mc-application"
  }
}

resource "aws_elastic_beanstalk_application_version" "default" {
  name        = var.mc_war
  application = aws_elastic_beanstalk_application.mc.name 
  description = "${var.mc_war} application"
  bucket      = module.common_parameters.all["artifact_bucket"]
  key         = var.mc_war
}


resource "aws_elastic_beanstalk_configuration_template" "config" {
  name                = "mc-config"
  application         = aws_elastic_beanstalk_application.mc.name
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
    value     = module.common_parameters.all["config_bucket"] 
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


resource "aws_elastic_beanstalk_environment" "mc" {
  name                = "${var.stack_name}-management-console"
  application         = aws_elastic_beanstalk_application.mc.name
  template_name       = aws_elastic_beanstalk_configuration_template.config.name
  version_label       = var.mc_war

  setting {
    namespace = "aws:elasticbeanstalk:container:tomcat:jvmoptions"
    name      = "JVM Options"
    value = "-Dmc.config.file=s3://${aws_s3_object.mc_config_properties.bucket}/${aws_s3_object.mc_config_properties.key} -Dlog.level=INFO"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name = "SSLCertificateArns"
    value = module.common_parameters.all["certificate_arn"]
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name = "Protocol"
    value = "HTTPS" 
  }


  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.mc_instance_class
  }

}
