# Kubernetes
## Provider config
provider "aws" {
  region = var.aws_region
}
# Cluster rollout
module "k8s" {
  source       = "./modules/k8s"
  cluster_name = var.cluster_name
}

# Generate TLS
module "tls_private_key" {
  source = "./modules/tls_private_key"
}

# GitHub repo provision
provider "github" {
  owner = var.GITHUB_OWNER
  token = var.GITHUB_TOKEN
}
module "github_repository" {
  source                   = "./modules/github_repository"
  github_owner             = var.GITHUB_OWNER
  github_token             = var.GITHUB_TOKEN
  repository_name          = var.FLUX_GITHUB_REPO
  public_key_openssh       = module.tls_private_key.public_key_openssh
  public_key_openssh_title = "flux0"
  depends_on = [module.tls_private_key]
}

# FluxCD
## Provider config
provider "flux" {
  kubernetes = {
    config_path = module.k8s.kubeconfig_path
  }

  git = {
    url = "ssh://git@github.com/${var.GITHUB_OWNER}/${var.FLUX_GITHUB_REPO}.git"

    ssh = {
      username    = "git"
      private_key = module.tls_private_key.private_key_pem
    }
  }
}
# Bootstrap FluxCD
module "fluxcd" {
  source       = "./modules/fluxcd"
  cluster_name = var.cluster_name
  depends_on = [
    module.k8s,
    module.github_repository,
    module.tls_private_key
  ]
}

####### SOPS

# AWS KMS key for SOPS

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "flux_sops" {
  description             = "KMS key for Flux SOPS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "EnableRoot"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "flux_sops" {
  name          = "alias/flux-sops-eks"
  target_key_id = aws_kms_key.flux_sops.key_id
}

# IAM policy restricted to only key
resource "aws_iam_policy" "flux_kms" {
  name = "flux-kms"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.flux_sops.arn
      }
    ]
  })
}

# IAM Role for Service Account (IRSA)
module "irsa_flux_kustomize" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.6.0"
  name = "flux-kustomize"
  oidc_providers = {
    eks = {
      provider_arn               = module.k8s.oidc_provider_arn
      namespace_service_accounts = ["flux-system:kustomize-controller"]
    }
  }
  policies = {
    kms = aws_iam_policy.flux_kms.arn
  }
}

/*
# Imperative way: Annotate Flux Service Account, so to connect k8s workload to an AWS identity in AWS IAM via IRSA.
# Annotation survives Flux reconiles normally, until flux reinstall, gotk-componets reapplied.action 
# Recomended Declarative way: fetch output "iam_policy_flux_arn", put ./manifests/flux-system to fluxcd repo on github

#provider "kubernetes" {
#  config_path = module.k8s.kubeconfig_path
#}

resource "kubernetes_annotations" "flux_sa_patch" {
  api_version = "v1"
  kind        = "ServiceAccount"
  metadata {
    name      = "kustomize-controller"
    namespace = "flux-system"
  }
  annotations = {
    "eks.amazonaws.com/role-arn" = module.irsa_flux_kustomize.arn
  }
  depends_on = [
    module.fluxcd, module.k8s
  ]
}
*/

/*
# 
# Imperative way: patch controler to support decryption
# Put manifests from ./manifests/flux-system to fluxcd repo on github
resource "null_resource" "patch_flux" {
  provisioner "local-exec" {
    command = <<EOT
export KUBECONFIG=${module.k8s.kubeconfig_path}
kubectl patch kustomization flux-system -n flux-system \
  --type merge \
  -p '{"spec":{"decryption":{"provider":"sops"}}}'
EOT
  }
}
*/