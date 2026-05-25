variable "name" {
  type = string
}
# pathexpand("${path.root}/kubeconfig/${var.name}") = ~
# path.root = /full/path/to/terraform_kind
locals {
  kubeconfig_path = "${path.root}/kubeconfig/${var.name}"
}

resource "local_file" "kubeconfig" {
  filename = local.kubeconfig_path
  content  = kind_cluster.this.kubeconfig
  lifecycle {
    prevent_destroy = true
  }
}


resource "kind_cluster" "this" {
  name           = var.name
  wait_for_ready = true
  kubeconfig_path = local.kubeconfig_path
}

