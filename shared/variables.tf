variable "aws_profile" {
  description = "name of the aws profile"
}

variable "aws_region" {
  description = "The aws region"
  default     = "us-east-1"
}

variable "stack_name" {
  description = "The name of the duracloud stack."
}

variable "db_instance_class" {
  description = "The database instance class"
  default     = "db.t2.micro"
}

variable "db_username" {
  description = "database username"
  default     = "duracloud"
}

variable "db_password" {
  description = "database password"
  default     = "duracloud-pw"
}

variable "ec2_keypair" {
  description = "The EC2 keypair to use in case you want to access the instance."
}

variable "backend_bucket" { 
   description = "The S3 bucket where terraform state is stored."
}
