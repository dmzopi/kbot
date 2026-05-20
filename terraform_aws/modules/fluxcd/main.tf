resource "flux_bootstrap_git" "this" {
  path = "clusters/${var.cluster_name}"
}