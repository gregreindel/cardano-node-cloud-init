#!/bin/bash

echo "#cloud-config"
echo "# date: $(date)"
echo "# node type: ${NODE_TYPE}"
echo "# network: ${NODE_NETWORK}"
echo "# cardano-node version: ${NODE_VERSION} build ${NODE_CONFIG_BUILD_NUMBER}"
if [[ ! -z $NODE_HOSTNAME ]]; then
echo "# hostname: ${NODE_HOSTNAME}"
fi 

echo "
# Instructions: 
# Make sure the node has finished setup using the user data script
# 1.) Create a file in the ${NODE_USER} user home directory (/home/${NODE_USER}/) named ${NODE_TYPE}-setup.yaml with the contents of this.
# 2.) Run the following commands:
#   sudo cloud-init --file ~/${NODE_TYPE}-setup.yaml single --name write_files --frequency once
#   sudo . ${NODE_SCRIPTS_PATH}/init/manualSetupHelper.sh
"
