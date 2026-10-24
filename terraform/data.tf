# Reference existing AWS resources without modifying or recreating them

data "aws_vpc" "vpc_a" {
  id = var.vpc_a_id
}

data "aws_vpc" "vpc_b" {
  id = var.vpc_b_id
}

data "aws_subnet" "subnet_b_private" {
  id = var.subnet_b_private_id
}

# Fetch the official Amazon Linux 2023 AMI in the current region
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
