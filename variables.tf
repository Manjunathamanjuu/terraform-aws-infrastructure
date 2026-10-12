variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
  default     = "376159574623"
}
variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string

  # IMPORTANT:
  # Replace this with the actual valid AMI ID available in us-east-1.
  default = "ami-0b6d9d3d33ba97d99"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name of the existing AWS EC2 key pair"
  type        = string
  default     = "terraform-key-pair"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "terraform-practice"
}

variable "owner" {
  description = "Resource owner"
  type        = string
  default     = "cloudops"
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to access EC2 through SSH"
  type        = list(string)

  # For production, replace with your public IP:
  # ["YOUR_PUBLIC_IP/32"]
  default = ["0.0.0.0/0"]
}

variable "jenkins_allowed_cidr" {
  description = "CIDR allowed to access Jenkins port 8080"
  type        = list(string)

  # Prefer restricting this instead of exposing 8080 publicly.
  default = ["0.0.0.0/0"]
}