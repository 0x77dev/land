resource "kubernetes_namespace" "cilium" {
  metadata {
    name = "cilium"
  }
}

resource "helm_release" "cilium" {
  name       = "cilium"
  namespace  = kubernetes_namespace.cilium.metadata[0].name
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = "1.14.4" # Specify the desired Cilium version

  values = [yamlencode({
    # Core Cilium configuration
    k8sServiceHost = "localhost" # For K3s embedded etcd setup
    k8sServicePort = 6443

    # Disable kube-proxy
    kubeProxyReplacement = "strict"

    # Enable LoadBalancer IPAM for replacing MetalLB
    loadBalancer = {
      serviceTopology = true
      algorithm       = "maglev"
      mode            = "dsr" # Direct Server Return
    }

    # Configure LoadBalancer IPAM to replace MetalLB IP allocation
    ipam = {
      mode = "kubernetes"
      operator = {
        clusterPoolIPv4PodCIDRList = ["10.42.0.0/16"]
      }
    }

    # Enable BGP Control Plane
    bgpControlPlane = {
      enabled = true
    }

    # Enable Hubble for observability
    hubble = {
      enabled = true
      relay = {
        enabled = true
      }
      ui = {
        enabled = true
      }
    }
  })]
}

# # Create a CiliumLoadBalancerIPPool resource to replace MetalLB's IPAddressPool
# resource "kubectl_manifest" "cilium_lb_ip_pool" {
#   depends_on = [helm_release.cilium]

#   yaml_body = yamlencode({
#     apiVersion = "cilium.io/v2alpha1"
#     kind = "CiliumLoadBalancerIPPool"
#     metadata = {
#       name = "homelab-lb-pool"
#     }
#     spec = {
#       cidrs = [
#         {
#           cidr = "192.168.5.16/20"
#         }
#       ]
#     }
#   })
# }

# # BGP Peering configuration to replace MetalLB BGP Peer
# resource "kubectl_manifest" "cilium_bgp_peering" {
#   depends_on = [helm_release.cilium]

#   yaml_body = yamlencode({
#     apiVersion = "cilium.io/v2alpha1"
#     kind = "CiliumBGPPeeringPolicy"
#     metadata = {
#       name = "udm-se-router-peering"
#     }
#     spec = {
#       nodeSelector = {
#         matchLabels = {
#           "kubernetes.io/hostname" = "pickle"  # Apply to specific node
#         }
#       }
#       virtualRouters = [
#         {
#           localASN = 65001
#           exportPodCIDR = true
#           neighbors = [
#             {
#               peerAddress = "192.168.2.1"
#               peerASN = 65000
#             }
#           ]
#         }
#       ]
#     }
#   })
# }

# # BGP advertisement config for load balancer IP pool
# resource "kubectl_manifest" "cilium_lb_ip_advertisement" {
#   depends_on = [
#     helm_release.cilium,
#     kubectl_manifest.cilium_lb_ip_pool
#   ]

#   yaml_body = yamlencode({
#     apiVersion = "cilium.io/v2alpha1"
#     kind = "CiliumLoadBalancerIPPoolNodeSelector"
#     metadata = {
#       name = "homelab-pool-advertisement"
#     }
#     spec = {
#       serviceSelector = {
#         matchExpressions = [
#           {
#             key = "io.kubernetes.service.namespace"
#             operator = "NotIn"
#             values = ["kube-system"]
#           }
#         ]
#       }
#       poolSelector = {
#         matchLabels = {
#           "io.cilium.pool" = "homelab-lb-pool"
#         }
#       }
#       nodeSelector = {
#         matchExpressions = [
#           {
#             key = "kubernetes.io/hostname"
#             operator = "In"
#             values = ["pickle", "tomato"]
#           }
#         ]
#       }
#     }
#   })
# } 