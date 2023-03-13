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

variable "ec2_keypair" {
  description = "The EC2 keypair to use in case you want to access the instance."
}
