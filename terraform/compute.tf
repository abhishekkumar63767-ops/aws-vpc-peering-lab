# App-B EC2 Instance in VPC B Private Subnet
resource "aws_instance" "ewb_app_b" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_b_private_id
  vpc_security_group_ids      = [aws_security_group.sg_app_b.id]
  key_name                    = var.key_name
  associate_public_ip_address = false
  private_ip                  = var.app_b_private_ip != "" ? var.app_b_private_ip : null

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
    encrypted             = true
    tags = {
      Name = "ewb-app-b-root"
    }
  }

  tags = {
    Name = "ewb-app-b"
  }
}
