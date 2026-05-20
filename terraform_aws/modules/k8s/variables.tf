variable "aws_region" {
  default = "eu-central-1"
}

variable "cluster_name" {
    type = string
}
variable "vpc_cidr" {
  description = "CIDR Block"
  type        = string
  default     = "10.0.100.0/22"
}

variable "private_subnets" {
  default = {
    "private_subnet_1" = 1
    "private_subnet_2" = 2
    "private_subnet_3" = 3
  }
}

variable "public_subnets" {
  default = {
    "public_subnet_1" = 1
    "public_subnet_2" = 2
    "public_subnet_3" = 3
  }
}

variable "worker_nodes_min" {
  type    = string
  default = "1"
}
variable "worker_nodes_max" {
  type    = string
  default = "1"
}
variable "worker_nodes_desired" {
  type    = string
  default = "1"
}
variable "worker_nodes_type" {
  type    = string
  default = "t3.medium"
}