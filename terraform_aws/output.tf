output "cluster_name" {
  value = var.cluster_name
}
output "kubeconfig_path" {
  value = module.k8s.kubeconfig_path
}
output "kubectl_use" {
  value = "KUBECONFIG=$(terraform output -raw kubeconfig_path) kubectl get nodes"
}
output "kms_key_arn" {
  value = resource.aws_kms_key.flux_sops.arn
  }
