resource "kubernetes_namespace" "longhorn" {
  metadata {
    name = "longhorn-system"
  }
}

resource "kubectl_manifest" "longhorn_nixos_path_configmap" {
  depends_on = [kubernetes_namespace.longhorn]
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "longhorn-nixos-path"
      namespace = kubernetes_namespace.longhorn.metadata[0].name
    }
    data = {
      PATH = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/run/wrappers/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
    }
  })
}

resource "kubectl_manifest" "longhorn_nixos_path_policy" {
  depends_on = [kubectl_manifest.longhorn_nixos_path_configmap, helm_release.kyverno]
  yaml_body = yamlencode({
    apiVersion = "kyverno.io/v1"
    kind       = "ClusterPolicy"
    metadata = {
      name = "longhorn-add-nixos-path"
      annotations = {
        "policies.kyverno.io/title"       = "Add Environment Variables from ConfigMap"
        "policies.kyverno.io/subject"     = "Pod"
        "policies.kyverno.io/category"    = "Other"
        "policies.kyverno.io/description" = "Longhorn invokes executables on the host system, and needs to be aware of the host systems PATH. This modifies all deployments such that the PATH is explicitly set to support NixOS based systems."
      }
    }
    spec = {
      rules = [{
        name = "add-env-vars"
        match = {
          resources = {
            kinds      = ["Pod"]
            namespaces = ["longhorn-system"]
          }
        }
        mutate = {
          patchStrategicMerge = {
            spec = {
              initContainers = [{
                "(name)" = "*"
                envFrom = [{
                  configMapRef = {
                    name = "longhorn-nixos-path"
                  }
                }]
              }]
              containers = [{
                "(name)" = "*"
                envFrom = [{
                  configMapRef = {
                    name = "longhorn-nixos-path"
                  }
                }]
              }]
            }
          }
        }
      }]
    }
  })
}

resource "helm_release" "longhorn" {
  name       = "longhorn"
  namespace  = kubernetes_namespace.longhorn.metadata[0].name
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  version    = "1.8.1"
  depends_on = [kubectl_manifest.longhorn_nixos_path_policy]

  # Uncomment and modify the following values block if you need additional customization
  # values = [yamlencode({
  #   persistence = {
  #     defaultClassReplicaCount = 3
  #   }
  #   csi = {
  #     attacherReplicaCount = 3
  #     provisionerReplicaCount = 3
  #     resizerReplicaCount = 3
  #     snapshotterReplicaCount = 3
  #   }
  # })]
}
