# Security Group for App-B in VPC B
resource "aws_security_group" "sg_app_b" {
  name        = "ewb-sg-app-b"
  description = "Security group for App-B in VPC B"
  vpc_id      = var.vpc_b_id

  # 1. SSH from Bastion private IP only (Least Privilege)
  ingress {
    description = "SSH from Bastion private IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.bastion_private_ip}/32"]
  }

  # 2. ICMP Echo Request from App-A private IP only
  ingress {
    description = "ICMP Echo Request from App-A"
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["${var.app_a_private_ip}/32"]
  }

  # Stateful outbound allow-all
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ewb-sg-app-b"
  }
}

# Add Missing Reverse ICMP Ingress to App-A's Security Group
# Required for App-B -> App-A reverse ping verification (Page 11 of workbook)
resource "aws_security_group_rule" "app_a_ingress_icmp_from_app_b" {
  type              = "ingress"
  security_group_id = var.sg_app_a_id
  description       = "ICMP Echo Request from App-B"
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  cidr_blocks       = ["${aws_instance.ewb_app_b.private_ip}/32"]
}
