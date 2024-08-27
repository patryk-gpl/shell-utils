if [[ -n "$ZSH_VERSION" ]]; then
  source "$(dirname "$0")/../shared.sh"
else
  source "$(dirname "${BASH_SOURCE[0]}")/../shared.sh"
fi

prevent_to_execute_directly

az_aks_list() {
  local OPTIND
  local count=""
  local subscription=""
  local full_output=false
  local help=false

  while getopts "c:s:fh" opt; do
    case $opt in
      c) count=$OPTARG ;;
      s) subscription="--subscription $OPTARG" ;;
      f) full_output=true ;;
      h) help=true ;;
      *)
        echo "Invalid option: -$OPTARG" >&2
        return 1
        ;;
    esac
  done

  if [ "$help" = true ]; then
    echo "Usage: az_aks_list [-c count] [-s subscription] [-f] [-h]"
    echo "  -c count         Limit the number of clusters returned"
    echo "  -s subscription  Specify the subscription to use"
    echo "  -f               Use full output (all fields)"
    echo "  -h               Display this help message"
    return 0
  fi

  local query_limit=""
  if [ -n "$count" ]; then
    query_limit="[0:$count]"
  fi

  local fields
  if [ "$full_output" = true ]; then
    fields='{
            Name:name,
            ResourceGroup:resourceGroup,
            Location:location,
            K8sVersion:kubernetesVersion,
            SKU:sku.tier,
            NodeCount:agentPoolProfiles[0].count,
            NodeSize:agentPoolProfiles[0].vmSize,
            NodeOS:agentPoolProfiles[0].osType,
            NodeOSDiskSize:agentPoolProfiles[0].osDiskSizeGb,
            NodeFQDN:fqdn,
            NodeMaxPods:agentPoolProfiles[0].maxPods,
            NodeStorageProfile:agentPoolProfiles[0].storageProfile,
            NodeVNetRG:agentPoolProfiles[0].vnetResourceGroup,
            NodeVNet:agentPoolProfiles[0].vnetVirtualNetwork,
            NodeVNetSubnet:agentPoolProfiles[0].vnetSubnetName,
            NodeVNetCidr:agentPoolProfiles[0].vnetCidr,
            NodePodCidr:agentPoolProfiles[0].podCidr,
            NodeServiceCidr:agentPoolProfiles[0].serviceCidr,
            NodeDockerBridgeCidr:agentPoolProfiles[0].dockerBridgeCidr,
            NodeDnsServiceIP:agentPoolProfiles[0].dnsServiceIp,
            NodeAvailabilityZones:agentPoolProfiles[0].availabilityZones,
            NodeTaints:agentPoolProfiles[0].nodeTaints,
            NodeTags:agentPoolProfiles[0].tags
        }'
  else
    fields='{
            Name:name,
            ResourceGroup:resourceGroup,
            Location:location,
            K8sVersion:kubernetesVersion,
            NodeCount:agentPoolProfiles[0].count,
            NodeSize:agentPoolProfiles[0].vmSize,
            NodeOS:agentPoolProfiles[0].osType
        }'
  fi

  # shellcheck disable=SC1087
  az aks list "$subscription" --query "$query_limit[].$fields" --output table
}
