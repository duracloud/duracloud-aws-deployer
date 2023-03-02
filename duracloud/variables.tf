variable "duracloud_s3_config_path" {
  default = ""
  description = "An optional path within the bucket to a sub-directory containing your duracloud config files e.g. /optional/path"
}

variable "duracloud_zip" {
  description = "The path (not including the bucket) to the zipped duraacloud application."

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
