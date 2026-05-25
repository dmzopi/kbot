output "kubeconfig_path" {
  value = module.cluster_kind.kubeconfig_path
}
output "kubectl_use" {
  value = "KUBECONFIG=$(terraform output -raw kubeconfig_path) kubectl get nodes"
}