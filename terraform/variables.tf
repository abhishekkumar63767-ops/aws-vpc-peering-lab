variable "aws_region" {
  description = "Target AWS Region"
  type        = string
  default     = "ap-south-1"
}

variable "aws_profile" {
  description = "AWS CLI credentials profile name"
  type        = string
  default     = "vpc-lab-user"
}

variable "project_name" {
  description = "Project tag value"
  type        = string
  default     = "EWB-VPC-Peering"
}

variable "student_name" {
  description = "Student tag value"
  type        = string
  default     = "Abhishek"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the existing EC2 Key Pair in AWS"
  type        = string
  default     = "ewb-key"
}

# --- Existing Resource IDs (from live AWS discovery) ---

variable "vpc_a_id" {
  description = "VPC ID for VPC A"
  type        = string
  default     = "vpc-01f0e8c88b298c306"
}

variable "vpc_b_id" {
  description = "VPC ID for VPC B"
  type        = string
  default     = "vpc-0dadd7fa7f4a9bb7d"
}

variable "subnet_a_public_id" {
  description = "Subnet ID for VPC A public subnet (ewb-a-public)"
  type        = string
  default     = "subnet-079ecdc7496f1439f"
}

variable "subnet_a_private_id" {
  description = "Subnet ID for VPC A private subnet (ewb-a-private)"
  type        = string
  default     = "subnet-04cc52b263dd06181"
}

variable "subnet_b_private_id" {
  description = "Subnet ID for VPC B private subnet (ewb-b-private)"
  type        = string
  default     = "subnet-096079b93661389dd"
}

variable "peering_connection_id" {
  description = "Existing VPC Peering Connection ID (ewb-a-b-peer)"
  type        = string
  default     = "pcx-0ba60ebd3e4804132"
}

variable "route_table_a_public_id" {
  description = "Route Table ID for VPC A public subnet (ewb-rt-a-public)"
  type        = string
  default     = "rtb-082ac9b3f915c55eb"
}

variable "sg_app_a_id" {
  description = "Security Group ID for App-A (ewb-sg-app-a)"
  type        = string
  default     = "sg-01aa6d1dcbab7104e"
}

variable "bastion_private_ip" {
  description = "Observed private IP of ewb-bastion"
  type        = string
  default     = "10.10.1.205"
}

variable "app_a_private_ip" {
  description = "Observed private IP of ewb-app-a"
  type        = string
  default     = "10.10.2.186"
}

variable "app_b_private_ip" {
  description = "Desired static private IP for ewb-app-b (workbook default is 10.20.1.10, or leave empty for AWS assigned)"
  type        = string
  default     = "10.20.1.10"
}
