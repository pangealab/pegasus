# Local variables used to reduce repetition
locals {
  node_username = "ubuntu"
  private_key = file(var.private_key)
  public_key = file(join(".", [var.private_key,"pub"]))
  common_tags = map(
    "Project", "rancher",
    "Creator", "rancher-quickstart"
  )
}

# Variables
variable "private_key" {
  description = "The local public key , e.g. ~/.ssh/rancher"
  default     = "~/.ssh/rancher"
}

variable "aws_region" {
  type        = string
  description = "AWS region used for all resources"
  default     = "us-east-2"
}

# VPC CIDR
variable "vpc_cidr" {
  description = "The CIDR block for the VPC, e.g: 13.0.0.0/16"
  default = "13.0.0.0/16"
}

# Subnet CIDR
variable "subnet_cidr" {
  description = "The CIDR block for the public subnet, e.g: 13.0.1.0/24"
  default = "13.0.1.0/24"
}

# Rancher Cluster AMI size
variable "rancher_instance_type" {
  type        = string
  description = "Instance type used for all EC2 instances"
  default     = "r5a.xlarge"
}

# Rancher Workload AMI size
variable "workload_instance_type" {
  type        = string
  description = "Instance type used for all EC2 instances"
  default     = "r5a.xlarge"
}