variable "duracloud_s3_config_path" {
  default     = ""
  description = "An optional path within the bucket to a sub-directory containing your duracloud config files e.g. /optional/path"
}

variable "duracloud_zip" {
  description = "The path (not including the bucket) to the zipped duraacloud application."

}

variable "solution_stack" {
  description = "The AWS Solution Stack to use with the Elastic Beanstalk."
  default     = "64bit Amazon Linux 2 v4.3.7 running Tomcat 8.5 Corretto 11"
}

variable "duracloud_instance_class" {
  description = "The instance size of worker ec2 instance class"
  default     = "m5.large"
}

variable "ec2_keypair" {
  description = "The EC2 keypair to use in case you want to access the instance."
}

variable "stack_name" {
  description = "The name of the duracloud stack."
}

variable "minimum_instance_count" {
  description = "The minimum number of instances to run"
  default     = 2
}

variable "maximum_instance_count" {
  description = "The minimum number of instances to run"
  default     = 6
}
