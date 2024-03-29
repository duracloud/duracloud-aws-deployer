variable "mill_docker_container" {
  description = "The docker container of DuraCloud Mill"
  default     = "ghcr.io/duracloud/mill"
}

variable "mill_version" {
  description = "The docker version of DuraCloud Mill"
  default     = "latest"
}

variable "log_level" {
  description = "The java logging level for the mill nodes."
  default     = "INFO"
}

variable "mill_s3_config_path" {
  default     = "/"
  description = "An optional path within the config bucket to a sub-directory containing your mill config files e.g. /optional/path"
}


variable "sentinel_instance_class" {
  description = "The sentinel's ec2 instance class"
  default     = "t3.small"
}

variable "worker_instance_class" {
  description = "The instance size of worker ec2 instance class"
  default     = "m6i.large"
}

variable "worker_spot_price" {
  description = "The max spot price for work instances"
  default     = ".12"
}

variable "ec2_keypair" {
  description = "The EC2 keypair to use in case you want to access the instance."
}

variable "stack_name" {
  description = "The name of the duracloud stack."
}

variable "dup_frequency" {
  description = "The frequency of the start of a duplication run. Format  [0-9][d - day, m - month].  So a frequency of 1 month would be 1m."
  default     = "1m"
}

variable "bit_frequency" {
  description = "The frequency of the start of a bit integrity check run. Format  [0-9][d - day, m - month].  So a frequency of 1 month would be 1m."
  default     = "3m"
}

variable "audit_worker_max" {
  description = "The max number of audit worker instances that the mill should scale up to."
  default     = 10
}

variable "bit_worker_max" {
  description = "The max number of bit worker instances that the mill should scale up to."
  default     = 10
}

variable "high_priority_dup_worker_max" {
  description = "The max number of high priority duplication worker instances that the mill should scale up to."
  default     = 10
}

variable "low_priority_dup_worker_max" {
  description = "The max number of low priority duplication worker instances that the mill should scale up to."
  default     = 10
}

variable "max_worker_threads" {
  description = "The default max number of concurrent worker threads in a worker instance"
  default     = 20
}

variable "bit_report_max_worker_threads" {
  description = "The max number of worker threads for a bit report worker instance"
  default     = 4
}
