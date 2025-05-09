variable "region" {
  description = "The AWS region to launch resources in"
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  default     = "10.10.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  default     = "10.10.2.0/24"
}

variable "availability_zone" {
  description = "Availability zone for subnet placement"
  default     = "ap-south-1a"
}

variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
  default     = "RSP-IOT"
}
