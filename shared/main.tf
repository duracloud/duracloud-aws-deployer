data "aws_region" "current" {}

module "common_parameters" {
  source = "../modules/common_parameters"
}

module "sumo" {
  source = "../modules/sumo"
}

resource "aws_iam_policy" "policy_one" {
  name = "${var.stack_name}-policy-618033"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "*"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = {
    Name = "${var.stack_name}-iam-policy"
  }
}

resource "aws_iam_role" "beanstalk_service_role" {
  name                  = "${var.stack_name}-bs-srv-role"
  force_detach_policies = true
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "${var.stack_name}-beanstalk-service-role"
  }
}

resource "aws_iam_policy_attachment" "beanstalk_enhanced_health" {
  name       = "enhanced_health_attachement"
  roles      = [aws_iam_role.beanstalk_service_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_policy_attachment" "beanstalk_service_policy" {
  name       = "beanstalk_service_policy"
  roles      = [aws_iam_role.beanstalk_service_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

resource "aws_iam_policy_attachment" "beanstalk_managed_updates_customer_role_policy" {
  name       = "beanstalk_managed_updates_customer_role_policy"
  roles      = [aws_iam_role.beanstalk_service_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy"
}

resource "aws_iam_role" "duracloud_role" {

  name                  = "${var.stack_name}-duracloud-role"
  force_detach_policies = true
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [aws_iam_policy.policy_one.arn]

  tags = {
    Name = "${var.stack_name}-role"
  }
}

resource "aws_iam_instance_profile" "duracloud_instance_profile" {

  name = "${var.stack_name}-dc-ip"
  role = aws_iam_role.duracloud_role.name

  tags = {
    Name = "${var.stack_name}-duracloud-instance-profile"
  }
}

resource "aws_vpc" "duracloud" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.stack_name}-vpc"
  }
}

resource "aws_subnet" "duracloud_public_subnet_a" {

  vpc_id                  = aws_vpc.duracloud.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "${data.aws_region.current.name}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.stack_name}-public-subnet-a"
  }
}

resource "aws_subnet" "duracloud_public_subnet_b" {

  vpc_id                  = aws_vpc.duracloud.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "${data.aws_region.current.name}c"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.stack_name}-public-subnet-b"
  }
}

resource "aws_subnet" "duracloud_subnet_a" {

  vpc_id            = aws_vpc.duracloud.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${data.aws_region.current.name}a"


  tags = {
    Name = "${var.stack_name}-subnet-a"
  }
}

resource "aws_subnet" "duracloud_subnet_b" {

  vpc_id            = aws_vpc.duracloud.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${data.aws_region.current.name}b"

  tags = {
    Name = "${var.stack_name}-subnet-b"
  }
}

resource "aws_subnet" "duracloud_subnet_c" {

  vpc_id            = aws_vpc.duracloud.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${data.aws_region.current.name}c"

  tags = {
    Name = "${var.stack_name}-subnet-c"
  }
}

resource "aws_subnet" "duracloud_subnet_d" {

  vpc_id            = aws_vpc.duracloud.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "${data.aws_region.current.name}d"

  tags = {
    Name = "${var.stack_name}-subnet-d"
  }
}

resource "aws_route_table" "duracloud_nat" {

  vpc_id = aws_vpc.duracloud.id

  tags = {
    Name = "${var.stack_name}-nat-route-table"
  }
}

resource "aws_route_table" "duracloud" {
  vpc_id = aws_vpc.duracloud.id

  tags = {
    Name = "${var.stack_name}-route-table"
  }
}

resource "aws_route_table_association" "duracloud_nat_a" {
  subnet_id      = aws_subnet.duracloud_public_subnet_a.id
  route_table_id = aws_route_table.duracloud_nat.id
}

resource "aws_route_table_association" "duracloud_nat_b" {
  subnet_id      = aws_subnet.duracloud_public_subnet_b.id
  route_table_id = aws_route_table.duracloud_nat.id
}

resource "aws_route_table_association" "duracloud_a" {
  subnet_id      = aws_subnet.duracloud_subnet_a.id
  route_table_id = aws_route_table.duracloud.id
}

resource "aws_route_table_association" "duracloud_b" {
  subnet_id      = aws_subnet.duracloud_subnet_b.id
  route_table_id = aws_route_table.duracloud.id
}

resource "aws_route_table_association" "duracloud_c" {
  subnet_id      = aws_subnet.duracloud_subnet_c.id
  route_table_id = aws_route_table.duracloud.id
}

resource "aws_route_table_association" "duracloud_d" {
  subnet_id      = aws_subnet.duracloud_subnet_d.id
  route_table_id = aws_route_table.duracloud.id
}

resource "aws_route" "route2igc" {
  route_table_id         = aws_route_table.duracloud_nat.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.duracloud.id
}

resource "aws_route" "route2nat" {

  route_table_id         = aws_route_table.duracloud.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.duracloud_nat.id
}


resource "aws_nat_gateway" "duracloud_nat" {
  allocation_id = aws_eip.duracloud_nat.id
  subnet_id     = aws_subnet.duracloud_public_subnet_a.id

  tags = {
    Name = "${var.stack_name}-nat-gateway"
  }

  depends_on = [aws_internet_gateway.duracloud]
}


resource "aws_internet_gateway" "duracloud" {

  vpc_id = aws_vpc.duracloud.id

  tags = {
    Name = "${var.stack_name}-internet-gateway"
  }
}

# https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/master/modules/vpc-endpoints
module "endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "3.19.0"

  vpc_id = aws_vpc.duracloud.id

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = toset([aws_route_table.duracloud_nat.id, aws_route_table.duracloud.id])
    },
  }

  tags = {
    Name = "${var.stack_name}-s3-endpoint"
  }
}

resource "aws_eip" "duracloud_nat" {
  vpc = true

  tags = {
    Name = "${var.stack_name}-nat-eip"
  }
}

resource "aws_db_subnet_group" "duracloud_db_subnet_group" {

  name       = "${var.stack_name}-duracloud-db-subnet-group"
  subnet_ids = [aws_subnet.duracloud_subnet_a.id, aws_subnet.duracloud_subnet_b.id]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.stack_name}-db-subnet-group"
  }
}

resource "aws_security_group" "duracloud_database" {

  vpc_id = aws_vpc.duracloud.id
  name   = "${var.stack_name}-duracloud-db-sg"

  ingress {
    cidr_blocks = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24"]
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "duracloud-${var.stack_name}-db-sg"
  }
}


resource "aws_db_instance" "duracloud" {
  db_name                   = "duracloud"
  identifier                = "${var.stack_name}-db-instance"
  allocated_storage         = var.db_allocated_storage
  storage_type              = "gp2"
  engine                    = "mysql"
  engine_version            = "8.0"
  port                      = 3306
  instance_class            = var.db_instance_class
  username                  = var.db_username
  password                  = module.common_parameters.db_password
  db_subnet_group_name      = aws_db_subnet_group.duracloud_db_subnet_group.name
  vpc_security_group_ids    = [aws_security_group.duracloud_database.id]
  skip_final_snapshot       = "true"
  deletion_protection       = var.db_deletion_protection_enabled
  multi_az                  = var.db_multi_az_enabled
  final_snapshot_identifier = "final-duracloud-${var.stack_name}"

  tags = {
    Name = "${var.stack_name}-db-instance"
  }
}

resource "aws_security_group" "duracloud_bastion" {

  vpc_id = aws_vpc.duracloud.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.stack_name}-bastion-sg"
  }
}

data "aws_ami" "amazon_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.*-gp2"]
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

resource "aws_sns_topic" "duracloud_account" {
  name = "${var.stack_name}-duracloud-account-sns-topic"
  tags = {
    Name = "${var.stack_name}-account-sns-topic"
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_2.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.duracloud_bastion.id]
  subnet_id                   = aws_subnet.duracloud_public_subnet_a.id
  key_name                    = var.ec2_keypair
  tags = {
    Name = "${var.stack_name}-bastion"
  }
}
