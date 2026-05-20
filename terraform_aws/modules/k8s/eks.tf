module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = ">= 21.20"

  name    = var.cluster_name
  kubernetes_version = "1.35"

  # VPC
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # ACCESS MODEL
  # For demo purpose public=true
  endpoint_public_access  = true
  #endpoint_private_access = true
  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  # EKS ADDONS
  addons = {
    vpc-cni = {
      before_compute = true
    }
    eks-pod-identity-agent = {
      before_compute = true
    }
    coredns = {}
    kube-proxy = {}
  }

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    default = {
      name = "ng-eks"

      instance_types = [var.worker_nodes_type]

      min_size     = var.worker_nodes_min
      max_size     = var.worker_nodes_max
      desired_size = var.worker_nodes_desired
    }
  }

  tags = {
    Environment = "demo"
    Terraform   = "true"
  }
}

# Generate kubeconfig file
resource "local_file" "kubeconfig" {
   filename = "${path.root}/kubeconfig/${module.eks.cluster_name}"

  content = yamlencode({
    apiVersion = "v1"
    kind       = "Config"

    clusters = [{
      name = module.eks.cluster_name
      cluster = {
        server                   = module.eks.cluster_endpoint
        certificate-authority-data = module.eks.cluster_certificate_authority_data
      }
    }]

    contexts = [{
      name = module.eks.cluster_name
      context = {
        cluster = module.eks.cluster_name
        user    = "aws"
      }
    }]

    current-context = module.eks.cluster_name

    users = [{
      name = "aws"
      user = {
        exec = {
          apiVersion = "client.authentication.k8s.io/v1beta1"
          command     = "aws"
          args = [
            "eks",
            "get-token",
            "--cluster-name",
            module.eks.cluster_name,
            "--region",
            var.aws_region
          ]
        }
      }
    }]
  })
}