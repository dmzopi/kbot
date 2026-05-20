data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  name       = "${var.cluster_name}-vpc"
  vpc_cidr   = "10.0.0.0/16"

  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = local.name
  cidr = local.vpc_cidr

  azs = local.azs

  # ----------------------------
  # AUTO-CALCULATED SUBNETS
  # ----------------------------

  private_subnets = [
    for i, az in local.azs :
    cidrsubnet(local.vpc_cidr, 8, i)
  ]

  public_subnets = [
    for i, az in local.azs :
    cidrsubnet(local.vpc_cidr, 8, i + 10)
  ]

  # ----------------------------
  # EKS REQUIREMENTS
  # ----------------------------

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames  = true
  enable_dns_support    = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}