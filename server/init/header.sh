#!/bin/bash

echo "#cloud-config"
echo "# date: $(date)"
echo "# node type: ${NODE_TYPE}"
echo "# network: ${NODE_NETWORK}"
echo "# cardano-node version: ${NODE_VERSION}"
if [[ ! -z $NODE_HOSTNAME ]]; then
echo "# hostname: ${NODE_HOSTNAME}"
fi 

echo "
# Instructions: 
# 1.) Input this file into the user data field when creating the ${NODE_TYPE} server

repo_update: true
repo_upgrade: all

packages:
  - fail2ban
  - git
  - jq
  - zip
  - rsync
  - htop
  - curl
  - wget
  - net-tools

power_state:
  mode: reboot
  condition: True
"

if [[ "${NODE_SWAP_SIZE}" -gt 0 ]]; then 
echo "
swap:
  filename: /swapfile
  size: ${NODE_SWAP_SIZE}
"
fi 