terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.36.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "3.0.0-pre2"
    }

    kubectl = {
      source  = "alekc/kubectl"
      version = "2.1.3"
    }
  }
}
