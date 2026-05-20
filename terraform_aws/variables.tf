variable "aws_region" {
  type    = string
  default = "eu-central-1"
}
variable "cluster_name" {
  type    = string
  default = "k8s-flux"
}
variable "worker_nodes_min" {
  type    = string
  default = "1"
}
variable "worker_nodes_max" {
  type    = string
  default = "1"
}
variable "worker_nodes_desired" {
  type    = string
  default = "1"
}
variable "worker_nodes_type" {
  type    = string
  default = "t3.medium"
}
variable "GITHUB_OWNER" {
  type = string
}
variable "GITHUB_TOKEN" {
  type = string
}
variable "FLUX_GITHUB_REPO" {
  type = string
}