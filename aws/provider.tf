provider "aws" {
  # access_key = var.aws_access_key
  # secret_key = var.aws_secret_key
  region     = var.aws_region
}

provider "tls" {
}

# Save Terraform State to S3 Bucket
# terraform {
#   backend "s3" {
#     bucket = "pegasus-terraform-backend"
#     key    = "terraform.tfstate"
#     region = "us-east-2"
#   }
# }
