output "vpc_a_id" {
  description = "VPC A ID"
  value       = var.vpc_a_id
}

output "vpc_b_id" {
  description = "VPC B ID"
  value       = var.vpc_b_id
}

output "peering_connection_id" {
  description = "VPC Peering Connection ID"
  value       = var.peering_connection_id
}

output "bastion_private_ip" {
  description = "Private IP of Bastion host"
  value       = var.bastion_private_ip
}

output "app_a_private_ip" {
  description = "Private IP of App-A host"
  value       = var.app_a_private_ip
}

output "app_b_instance_id" {
  description = "EC2 Instance ID of ewb-app-b"
  value       = aws_instance.ewb_app_b.id
}

output "app_b_private_ip" {
  description = "Private IP of ewb-app-b"
  value       = aws_instance.ewb_app_b.private_ip
}

output "app_b_security_group_id" {
  description = "Security Group ID for App-B"
  value       = aws_security_group.sg_app_b.id
}

output "ssh_proxyjump_app_b_example" {
  description = "Example command to SSH directly into App-B using Bastion ProxyJump"
  value       = "ssh -J ec2-user@<BASTION_PUBLIC_IP> -i ~/.ssh/ewb-lab.pem ec2-user@${aws_instance.ewb_app_b.private_ip}"
}
