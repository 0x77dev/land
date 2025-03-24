resource "kubernetes_namespace" "metallb" {
  metadata {
    name = "metallb"
  }
}

resource "helm_release" "metallb" {
  name       = "metallb"
  namespace = kubernetes_namespace.metallb.metadata[0].name
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
}
