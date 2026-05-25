variable "cluster_name" {
  type    = string
  default = "k8s-flux"
}

variable "cluster_type" {
  type    = string
  default = "kind"
  validation {
    condition     = contains(["kind", "eks"], var.cluster_type)
    error_message = "cluster_type must be kind or eks"
  }
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
