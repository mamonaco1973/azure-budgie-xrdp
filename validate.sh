#!/bin/bash
# --------------------------------------------------------------------------------
# Description:
#   Queries Azure for public IP resources in a target resource group and prints
#   their fully qualified DNS names. Replaces AWS EC2 lookups with Azure CLI.
#
# Requirements:
#   - Azure CLI installed and logged in
#   - Public IPs must exist in RG: budgie-project-rg
#   - Public IP resource names:
#       * windows-vm-public-ip
#       * budgie-public-ip
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------------------
RESOURCE_GROUP="budgie-project-rg"

# --------------------------------------------------------------------------------
# Lookup Windows VM Public FQDN
# --------------------------------------------------------------------------------
windows_dns=$(az network public-ip show \
  --resource-group "$RESOURCE_GROUP" \
  --name "windows-vm-public-ip" \
  --query "dnsSettings.fqdn" \
  --output tsv 2>/dev/null)

if [ -z "$windows_dns" ]; then
  echo "ERROR: No DNS label found for windows-vm-public-ip"
else
  echo "NOTE: Windows Admin Instance FQDN: $windows_dns"
fi

# --------------------------------------------------------------------------------
# Lookup BUDGIE Public FQDN
# --------------------------------------------------------------------------------
budgie_dns=$(az network public-ip show \
  --resource-group "$RESOURCE_GROUP" \
  --name "budgie-public-ip" \
  --query "dnsSettings.fqdn" \
  --output tsv 2>/dev/null)

if [ -z "$budgie_dns" ]; then
  echo "ERROR: No DNS label found for budgie-public-ip"
else
  echo "NOTE: Budgie Desktop Instance FQDN: $budgie_dns"

  # ------------------------------------------------------------------------
  # Wait for SSH (port 22) on BUDGIE instance
  # ------------------------------------------------------------------------
  max_attempts=60
  attempt=1
  sleep_secs=10

  echo "NOTE: Waiting for SSH (port 22) on $budgie_dns ..."

  while [ "$attempt" -le "$max_attempts" ]; do
    if timeout 5 bash -c "echo > /dev/tcp/$budgie_dns/22" 2>/dev/null; then
      echo "NOTE: SSH is reachable on $budgie_dns:22"
      break
    fi

    echo "WARNING: Attempt $attempt/$max_attempts - SSH not ready, sleeping ${sleep_secs}s ..."
    attempt=$((attempt + 1))
    sleep "$sleep_secs"
  done

  if [ "$attempt" -gt "$max_attempts" ]; then
    echo "ERROR: Timed out waiting for SSH on $budgie_dns:22"
  fi
fi