provider "kubernetes" {
  config_path    = "./secrets/k3s.yaml"
  config_context = "default"
}

provider "helm" {
  kubernetes = {
    config_path    = "./secrets/k3s.yaml"
    config_context = "default"
  }
}
