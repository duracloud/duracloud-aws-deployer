variable "aws_profile" {
  description = "name of the aws profile"
}

variable "aws_region" {
  description = "The aws region"
  default     = "us-east-1"
}

variable "duracloud_config_yaml" {
   description = "The path to a local yaml file containing the user configurable elements of duracloud"
}

variable "duracloud_s3_config_bucket" {
  description = "An S3 bucket containing duracloud config files"
}

variable "duracloud_s3_config_path" {
  default = "/"
  description = "An optional path within the above bucket ta sub-directory containing your duracloud config files e.g. /optional/path"
}

variable "duracloud_artifact_bucket" {
  description = "An S3 bucket containing the zipped  duracloud application"
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

