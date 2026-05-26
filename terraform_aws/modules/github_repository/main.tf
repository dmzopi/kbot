resource "github_repository" "this" {
  name       = var.repository_name
  visibility = var.repository_visibility
  auto_init  = true
  lifecycle {
  ignore_changes = all
}
}

resource "github_repository_deploy_key" "this" {
  title      = var.public_key_openssh_title
  repository = github_repository.this.name
  key        = var.public_key_openssh
  read_only  = false
}