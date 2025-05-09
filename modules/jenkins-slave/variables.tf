variable "jenkins_ami" {
  description = "AMI ID for Jenkins slave"
  type        = string
}

variable "jenkins_slave_instance_type" {
  description = "EC2 instance type for Jenkins slave"
  type        = string
}

variable "jenkins_slave_count" {
  description = "Number of Jenkins slaves to create"
  type        = number
}

variable "key_name" {
  description = "SSH key name for EC2 instances"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to launch Jenkins slave instances"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for Jenkins slaves"
  type        = string
}

variable "jenkins_url" {
  description = "Jenkins master URL for slave to connect"
  type        = string
}

variable "slave_script_path" {
  description = "Path to the Jenkins slave user-data template"
  type        = string
}
