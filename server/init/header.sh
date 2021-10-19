#!/bin/bash

echo "#cloud-config"
echo "# date: $(date)"
echo "# node type: ${NODE_TYPE}"
echo "# network: ${NODE_NETWORK}"
echo "# cardano-node version: ${NODE_VERSION} build ${NODE_CONFIG_BUILD_NUMBER}"
if [[ ! -z ${NODE_HOSTNAME} ]]; then
echo "# hostname: ${NODE_HOSTNAME}"
fi 

if [ ${NODE_TYPE} == "block" ]; then 
NODE_SWAP_SIZE=${BLOCK_NODE_SWAP_SIZE}

elif  [ ${NODE_TYPE} == "relay" ]; then 
NODE_SWAP_SIZE=${RELAY_NODE_SWAP_SIZE}
fi 

packagesToInstall="packages:
  - fail2ban
  - git
  - jq
  - zip
  - chrony
  - rsync
  - htop
  - curl
  - wget
  - net-tools"

if [ ${NODE_TYPE} == "dashboard" ]; then
packagesToInstall="$packagesToInstall
  - prometheus"
else 
packagesToInstall="$packagesToInstall
  - prometheus-node-exporter"
fi

if [[ ! -z ${USE_AWS_CLI} ]]; then
packagesToInstall="$packagesToInstall
  - awscli"
fi

fqdn="${NODE_NETWORK}-${NODE_TYPE}-${NODE_NUMBER}-v${NODE_VERSION}"

echo "
# Instructions: 
# 1.) Input this file into the user data field when creating the ${NODE_TYPE} server

fqdn: ${fqdn//./-}

repo_update: true
repo_upgrade: all

$packagesToInstall

power_state:
  mode: reboot
  condition: True
"

echo "
mounts:
- [ none, /run/shm, \"tmpfs\", \"defaults,ro\", \"0\", \"0\" ]
"

if [[ "${NODE_SWAP_SIZE}" -gt 0 ]]; then 
echo "
swap:
  filename: /swapfile
  size: ${NODE_SWAP_SIZE}
"
fi