variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Optional EC2 Key Pair name for SSH"
  type        = string
  default     = null
}

variable "ssh_ingress_cidr" {
  description = "CIDR to allow SSH access from"
  type        = string
  default     = "0.0.0.0/0"
}

variable "dockerhub_username" {
  description = "DockerHub username that hosts images"
  type        = string
}

variable "image_tag" {
  description = "Image tag to deploy (e.g., latest or git sha)"
  type        = string
  default     = "latest"
}

variable "allowed_client_cidr" {
  description = "CIDR allowed to access exposed services"
  type        = string
  default     = "0.0.0.0/0"
}

