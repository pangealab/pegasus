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

variable "prefix" {
  type        = string
  description = "Prefix added to names of all resources"
  default     = "quickstart"
}

variable "rancher_instance_type" {
  type        = string
  description = "Instance type used for all EC2 instances"
  default     = "r5a.xlarge"
}

variable "node_instance_type" {
  type        = string
  description = "Instance type used for all EC2 instances"
  default     = "r5a.xlarge"
}

variable "docker_version" {
  type        = string
  description = "Docker version to install on nodes"
  default     = "19.03"
}

variable "rke_kubernetes_version" {
  type        = string
  description = "Kubernetes version to use for Rancher server RKE cluster"
  default     = "v1.18.3-rancher2-2"
}

variable "workload_kubernetes_version" {
  type        = string
  description = "Kubernetes version to use for managed workload cluster"
  default     = "v1.17.6-rancher2-2"
}

variable "cert_manager_version" {
  type        = string
  description = "Version of cert-mananger to install alongside Rancher (format: 0.0.0)"
  default     = "0.12.0"
}

variable "rancher_version" {
  type        = string
  description = "Rancher server version (format: v0.0.0)"
  default     = "v2.4.5"
}

# Required
variable "rancher_server_admin_password" {
  type        = string
  description = "Admin password to use for Rancher server bootstrap"
  default = "changeit"
}

# VPC CIDR
variable "vpc_cidr" {
  description = "The CIDR block for the VPC, e.g: 13.0.0.0/16"
  default = "13.0.0.0/16"
}

# SUBNET CIDR
variable "subnet_cidr" {
  description = "The CIDR block for the public subnet, e.g: 13.0.1.0/24"
  default = "13.0.1.0/24"
}