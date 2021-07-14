resource "aws_iam_role" "duracloud" {

  name                  = "duracloud-role"
  force_detach_policies = true
  assume_role_policy    = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name = "${var.stack_name}-role"
  }
}

resource "aws_iam_instance_profile" "duracloud" {

  name = "duracloud-instance-profile"
  role = aws_iam_role.duracloud.name

  tags = {
    Name = "${var.stack_name}-instance-profile"
  }
}

resource "aws_vpc" "duracloud" {
 cidr_block           = "10.0.0.0/16"
 enable_dns_hostnames =  true

 tags = {
    Name = "${var.stack_name}-vpc"
  }
}

resource "aws_subnet" "duracloud_subnet_a" {

 vpc_id            = aws_vpc.duracloud.id
 cidr_block        = "10.0.0.0/24"
 availability_zone = "${var.aws_region}a"

 tags = { 
    Name = "${var.stack_name}-subnet-a"
  }
}

resource "aws_route_table" "duracloud" {

  vpc_id = aws_vpc.duracloud.id

  tags = { 
    Name = "${var.stack_name}-route-table"
  }
}

resource "aws_route_table_association" "duracloud" {

  subnet_id      = aws_subnet.duracloud_subnet_a.id
  route_table_id = aws_route_table.duracloud.id
}

resource "aws_route" "route2igc" {

  route_table_id            = aws_route_table.duracloud.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.duracloud.id
}

resource "aws_internet_gateway" "duracloud" {

  vpc_id = aws_vpc.duracloud.id

  tags = {
    Name = "${var.stack_name}-internet-gateway"
  }
}
