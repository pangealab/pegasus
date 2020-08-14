//  Define the VPC.
resource "aws_vpc" "rancher" {
  cidr_block           = var.vpc_cidr
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
  vpc_id                  = aws_vpc.rancher.id
  cidr_block              = var.subnet_cidr
  availability_zone       = data.aws_availability_zones.azs.names[0]
  map_public_ip_on_launch = true
  depends_on              = [aws_internet_gateway.rancher]

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
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public.id
}

# Security group to allow all traffic
resource "aws_security_group" "rancher_sg_allowall" {
  name        = "rancher-allowall"
  description = "Rancher SG Allow All Traffic"

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

# AWS Keypair
resource "aws_key_pair" "rancher_key_pair" {
  key_name = "rancher"
  public_key = local.public_key
}

# Rancher Server
resource "aws_instance" "rancher_server" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.rancher_instance_type
  key_name = aws_key_pair.rancher_key_pair.key_name
  subnet_id = aws_subnet.public-subnet.id
  vpc_security_group_ids = [aws_security_group.rancher_sg_allowall.id]
  user_data = templatefile(
    join("/", [path.module, "files/userdata_rancher_server.template"]),
    {
      docker_version = var.docker_version
      rke_version = var.rke_version
      kubectl_version = var.kubectl_version
      helm_version = var.helm_version
      username = local.node_username
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

# Rancher Server EIP
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