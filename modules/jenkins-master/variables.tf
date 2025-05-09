variable "jenkins_ami" {
  description = "AMI ID for Jenkins master"
  type        = string
}

variable "jenkins_master_instance_type" {
  description = "EC2 instance type for Jenkins master"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name to use for Jenkins master instance"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to launch Jenkins master into"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID to attach to Jenkins master instance"
  type        = string
}

variable "user_data_path" {
  description = "Path to user data script for Jenkins master setup"
  type        = string
}
