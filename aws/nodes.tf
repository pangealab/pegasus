# SSH key pair
resource "tls_private_key" "global_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "ssh_private_key_pem" {
  filename          = "${path.module}/id_rsa"
  sensitive_content = tls_private_key.global_key.private_key_pem
  file_permission   = "0600"
}

resource "local_file" "ssh_public_key_openssh" {
  filename = "${path.module}/id_rsa.pub"
  content  = tls_private_key.global_key.public_key_openssh
}

# Temporary key pair used for SSH accesss
resource "aws_key_pair" "quickstart_key_pair" {
  key_name_prefix = "${var.prefix}-rancher-"
  public_key      = tls_private_key.global_key.public_key_openssh
}

# AWS EC2 instance for creating a single node RKE cluster and installing the Rancher server
resource "aws_instance" "rancher_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.rancher_instance_type

  key_name        = aws_key_pair.quickstart_key_pair.key_name

  # security_groups = [aws_security_group.rancher_sg_allowall.name]
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
      private_key = tls_private_key.global_key.private_key_pem
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

# AWS EC2 instance for creating a single node workload cluster
resource "aws_instance" "quickstart_node" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.node_instance_type

  key_name        = aws_key_pair.quickstart_key_pair.key_name

  # security_groups = [aws_security_group.rancher_sg_allowall.name]
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
      private_key = tls_private_key.global_key.private_key_pem
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
