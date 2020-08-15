# AWS infrastructure resources

//  Define the VPC.
resource "aws_vpc" "rancher" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true

  //  Use our common tags and add a specific name.
  tags = merge(
    local.common_tags,
    map(
      "Name", "Rancher VPC"
    )
  )
}

//  Create an Internet Gateway for the VPC.
resource "aws_internet_gateway" "rancher" {
  vpc_id = aws_vpc.rancher.id

  //  Use our common tags and add a specific name.
  tags = merge(
    local.common_tags,
    map(
      "Name", "Rancher IGW"
    )
  )
}

//  Create a public subnet.
resource "aws_subnet" "public-subnet" {
  vpc_id = aws_vpc.rancher.id
  cidr_block = var.subnet_cidr
  availability_zone = data.aws_availability_zones.azs.names[0]
  map_public_ip_on_launch = true
  depends_on = [aws_internet_gateway.rancher]

  //  Use our common tags and add a specific name.
  tags = merge(
    local.common_tags,
    map(
      "Name", "Rancher Public Subnet"
    )
  )
}

//  Create a route table allowing all addresses access to the IGW.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.rancher.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rancher.id
  }

  //  Use our common tags and add a specific name.
  tags = merge(
    local.common_tags,
    map(
      "Name", "Rancher Public Route Table"
    )
  )
}

//  Now associate the route table with the public subnet - giving
//  all public subnet instances access to the internet.
resource "aws_route_table_association" "public-subnet" {
  subnet_id = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public.id
}

# resource "tls_private_key" "global_key" {
#   algorithm = "RSA"
#   rsa_bits  = 2048
# }

# resource "local_file" "ssh_private_key_pem" {
#   filename          = "${path.module}/id_rsa"
#   sensitive_content = tls_private_key.global_key.private_key_pem
#   file_permission   = "0600"
# }

# resource "local_file" "ssh_public_key_openssh" {
#   filename = "${path.module}/id_rsa.pub"
#   content  = tls_private_key.global_key.public_key_openssh
# }

# Temporary key pair used for SSH accesss
resource "aws_key_pair" "quickstart_key_pair" {
  key_name        = "rancher"
  public_key      = local.public_key
}

# Security group to allow all traffic
resource "aws_security_group" "rancher_sg_allowall" {
  name        = "${var.prefix}-rancher-allowall"
  description = "Rancher quickstart - allow all traffic"
  vpc_id = aws_vpc.rancher.id

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    map(
      "Name", "Rancher Allow All"
    )
  )
}

# AWS EC2 instance for creating a single node RKE cluster and installing the Rancher server
resource "aws_instance" "rancher_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  key_name        = aws_key_pair.quickstart_key_pair.key_name
  subnet_id       = aws_subnet.public-subnet.id
  vpc_security_group_ids = [aws_security_group.rancher_sg_allowall.id]

  user_data = templatefile(
    join("/", [path.module, "../cloud-common/files/userdata_rancher_server.template"]),
    {
      docker_version = var.docker_version
      username       = local.node_username
    }
  )

  root_block_device {
    volume_size = 16
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'",
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = local.node_username
      private_key = local.private_key
    }
  }

  tags = merge(
    local.common_tags,
    map(
      "Name", "Rancher Server"
    )
  )
}

# Rancher Elastic IP
resource "aws_eip" "rancher_eip" {
  instance = aws_instance.rancher_server.id
  vpc      = true
  tags = merge(
    local.common_tags,
    map(
      "Name", "Rancher Server"
    )
  )
}

# Rancher resources
module "rancher_common" {
  source = "../rancher-common"

  node_public_ip         = aws_instance.rancher_server.public_ip
  node_internal_ip       = aws_instance.rancher_server.private_ip
  node_username          = local.node_username
  ssh_private_key_pem    = local.private_key
  rke_kubernetes_version = var.rke_kubernetes_version

  cert_manager_version = var.cert_manager_version
  rancher_version      = var.rancher_version

  rancher_server_dns = join(".", ["rancher", aws_instance.rancher_server.public_ip, "xip.io"])

  admin_password     = var.rancher_server_admin_password

  workload_kubernetes_version = var.workload_kubernetes_version
  workload_cluster_name       = "quickstart-aws-custom"
}

# AWS EC2 instance for creating a single node workload cluster
resource "aws_instance" "quickstart_node" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  key_name        = aws_key_pair.quickstart_key_pair.key_name
  subnet_id       = aws_subnet.public-subnet.id
  vpc_security_group_ids = [aws_security_group.rancher_sg_allowall.id]

  user_data = templatefile(
    join("/", [path.module, "files/userdata_quickstart_node.template"]),
    {
      docker_version   = var.docker_version
      username         = local.node_username
      register_command = module.rancher_common.custom_cluster_command
    }
  )

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'",
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = local.node_username
      private_key = local.private_key
    }
  }

  tags = merge(
    local.common_tags,
    map(
      "Name", "Rancher Node"
    )
  )
}

# Node Elastic IP
resource "aws_eip" "node_eip" {
  instance = aws_instance.quickstart_node.id
  vpc      = true
  tags = merge(
    local.common_tags,
    map(
      "Name", "Rancher Node"
    )
  )
}
