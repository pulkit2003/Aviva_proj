variable "region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name prefix for tagging and naming resources"
  type        = string
  default     = "ec2-s3-demo_v2"
}
