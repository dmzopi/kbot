output "cluster_name" {
  value = var.cluster_name
}
output "kubeconfig_path" {
  value = module.k8s.kubeconfig_path
}
output "kubectl_use" {
  value = "KUBECONFIG=$(terraform output -raw kubeconfig_path) kubectl get nodes"
}
