output "kubeconfig_path" {
  value = local_file.kubeconfig.filename
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}
