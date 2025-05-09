variable "region" {
  default = "ap-south-1"
}

variable "vpc_cidr" {
  default = "10.10.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.10.1.0/24"
}

variable "private_subnet_cidr" {
  default = "10.10.2.0/24"
}

variable "availability_zone" {
  default = "ap-south-1a"
}

variable "jenkins_ami" {
  default = "ami-0e35ddab05955cf57"
}

variable "jenkins_master_instance_type" {
  default = "t2.medium"
}

variable "jenkins_slave_instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  default = "mumbaipemkey"
}

variable "jenkins_slave_count" {
  default = 1
}
