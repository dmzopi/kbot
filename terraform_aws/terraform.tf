terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.45"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }  
    flux = {
      source  = "fluxcd/flux"
      version = "~> 1.8"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}