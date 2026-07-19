# -------------------------------------------------------
# VPC
# -------------------------------------------------------

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-vpc"
  })
}


# -------------------------------------------------------
# Internet Gateway
# -------------------------------------------------------

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-igw"
  })
}


# -------------------------------------------------------
# Public Subnet
# -------------------------------------------------------

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-subnet"
    Tier = "Public"
  })
}


# -------------------------------------------------------
# Public Route Table
# -------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-route-table"
  })
}


# -------------------------------------------------------
# Public Subnet and Route Table Association
# -------------------------------------------------------

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


# -------------------------------------------------------
# Security Group
# -------------------------------------------------------

resource "aws_security_group" "ansible" {
  name        = "${var.project_name}-security-group"
  description = "Security group for the Ansible control and worker nodes"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH from administrator public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "SSH communication between Ansible lab instances"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "HTTP access for Nginx testing"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "Application access for Docker testing"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "Internal communication between Ansible lab instances"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-security-group"
  })
}


# -------------------------------------------------------
# SSH Private Key
# -------------------------------------------------------

resource "tls_private_key" "ansible" {
  algorithm = "ED25519"
}


# -------------------------------------------------------
# AWS EC2 Key Pair
# -------------------------------------------------------

resource "aws_key_pair" "ansible" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.ansible.public_key_openssh

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-key"
  })
}


# -------------------------------------------------------
# Save Private Key Locally
# -------------------------------------------------------

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.ansible.private_key_openssh
  filename        = "${path.module}/ansible-lab-key.pem"
  file_permission = "0600"
}


# -------------------------------------------------------
# Ansible Control Node
# -------------------------------------------------------

resource "aws_instance" "control" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ansible.id]
  key_name                    = aws_key_pair.ansible.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 12
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-control"
    Role = "Ansible-Control"
  })
}


# -------------------------------------------------------
# Ansible Worker Nodes
# -------------------------------------------------------

resource "aws_instance" "workers" {
  count = 2

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ansible.id]
  key_name                    = aws_key_pair.ansible.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 12
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-worker-${count.index + 1}"
    Role = "Ansible-Managed-Node"
  })
}
