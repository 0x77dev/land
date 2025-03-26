# MetalLB to Cilium Migration Plan

## Pre-Migration Tasks

1. Backup the entire cluster state
2. Document all current service IPs and BGP routes
3. Apply the NixOS configuration changes to all nodes
4. Rebuild and reboot nodes one at a time

## Migration Steps

1. Install Cilium CLI on the management system:

   ```bash
   curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz
   tar xzvf cilium-linux-amd64.tar.gz
   sudo mv cilium /usr/local/bin
   ```

2. Apply the Cilium Terraform configuration:

   ```bash
   terraform apply -target=kubernetes_namespace.cilium
   terraform apply -target=helm_release.cilium
   ```

3. Verify Cilium installation:

   ```bash
   cilium status
   ```

4. Apply Cilium LoadBalancer IPAM and BGP configuration:

   ```bash
   terraform apply -target=kubectl_manifest.cilium_lb_ip_pool
   terraform apply -target=kubectl_manifest.cilium_bgp_peering
   terraform apply -target=kubectl_manifest.cilium_lb_ip_advertisement
   ```

5. Test service connectivity with a test deployment.

6. Once everything is working correctly, remove the MetalLB resources:
   ```bash
   terraform destroy -target=kubectl_manifest.metallb_bgp_advertisement
   terraform destroy -target=kubectl_manifest.metallb_bgp_peer
   terraform destroy -target=kubectl_manifest.metallb_pool
   terraform destroy -target=helm_release.metallb
   terraform destroy -target=kubernetes_namespace.metallb
   ```

## Rollback Plan

If issues arise during migration:

1. Re-apply the MetalLB configuration:

   ```bash
   terraform apply -target=kubernetes_namespace.metallb
   terraform apply -target=helm_release.metallb
   terraform apply -target=kubectl_manifest.metallb_pool
   terraform apply -target=kubectl_manifest.metallb_bgp_peer
   terraform apply -target=kubectl_manifest.metallb_bgp_advertisement
   ```

2. Remove Cilium installation:

   ```bash
   terraform destroy -target=kubectl_manifest.cilium_lb_ip_advertisement
   terraform destroy -target=kubectl_manifest.cilium_bgp_peering
   terraform destroy -target=kubectl_manifest.cilium_lb_ip_pool
   terraform destroy -target=helm_release.cilium
   terraform destroy -target=kubernetes_namespace.cilium
   ```

3. Revert NixOS configuration changes and rebuild the nodes.
