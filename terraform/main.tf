# Local values and shared configuration
locals {
  common_tags = {
    Project   = var.project_name
    Student   = var.student_name
    ManagedBy = "Terraform"
  }
}
