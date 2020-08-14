provider "aws" {
  # access_key = var.aws_access_key
  # secret_key = var.aws_secret_key
  region     = var.aws_region
}

provider "tls" {
}

# Save Terraform State to S3 Bucket
terraform {
  backend "s3" {
    bucket = "pegasus-terraform-backend"
    key    = "terraform.tfstate"
    region = "us-east-2"
  }
}

# Rancher Comon Resources
module "rancher_common" {
  source = "../rancher-common"
  node_public_ip         = aws_instance.rancher_server.public_ip
  node_internal_ip       = aws_instance.rancher_server.private_ip
  node_username          = local.node_username
  # ssh_private_key_pem    = tls_private_key.global_key.private_key_pem
  ssh_private_key_pem    = file("~/.ssh/rancher")
  rke_kubernetes_version = var.rke_kubernetes_version
  cert_manager_version = var.cert_manager_version
  rancher_version      = var.rancher_version
  rancher_server_dns = join(".", ["rancher", aws_instance.rancher_server.public_ip, "xip.io"])
  admin_password     = var.rancher_server_admin_password
  workload_kubernetes_version = var.workload_kubernetes_version
  workload_cluster_name       = "quickstart-aws-custom"
}

# Outputs
output "rancher_server_url" {
  value = module.rancher_common.rancher_url
}

output "rancher_node_ip" {
  value = aws_instance.rancher_server.public_ip
}

output "workload_node_ip" {
  value = aws_instance.quickstart_node.public_ip
}
