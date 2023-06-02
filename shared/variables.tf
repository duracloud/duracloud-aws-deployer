variable "stack_name" {
  description = "The name of the duracloud stack."
}

variable "db_instance_class" {
  description = "The database instance class"
  default     = "db.t2.micro"
}

variable "db_allocated_storage" {
  description = "The amount of storage allocated in gigabytes."
  default     = 20
}

variable "db_deletion_protection_enabled" {
  description = "If true, deletion protection is enabled."
  default     = false
}

variable "db_multi_az_enabled" {
  description = "If true, enable multi A-Z for this database"
  default     = false
}

variable "db_username" {
  description = "database username"
  default     = "duracloud"
}

variable "ec2_keypair" {
  description = "The EC2 keypair to use in case you want to access the instance."
}
