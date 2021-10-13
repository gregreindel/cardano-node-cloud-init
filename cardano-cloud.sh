#!/bin/bash
# Generates Cloud-init YAML files based on the template files in /server

cardanoCloudInitGeneratorVersion="1.1.0"
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

BUILD_ID="0"

HOSTNAME=""
NETWORK="testnet"
VERSION="1.30.0"
SSH_KEY=""
SSH_PORT="22"
BUNDLE_CONFIG="1"

BLOCK_NODE_SWAP_SIZE="0"
BLOCK_NODE_IP_1=""

RELAY_NODE_SWAP_SIZE="0"
RELAY_NODE_IP_1=""
RELAY_NODE_IP_2=""

RELAY_HOSTNAME_1=""
RELAY_HOSTNAME_2=""

AUTO_INIT="no"


# Get config latest build number
# CARDANO_CONFIG_LATEST_BUILD=$(curl --silent https://hydra.iohk.io/job/Cardano/iohk-nix/cardano-deployment/latest-finished/download/1/index.html | grep -e "build" | sed 's/.*build\/\([0-9]*\)\/download.*/\1/g')

# Get cardano-node latest build number
# CARDANO_NODE_LATEST_BUILD=$(curl --silent https://hydra.iohk.io/job/Cardano/cardano-node/cardano-node-linux/latest-finished/download/1/index.html | grep -e "build" | sed 's/.*build\/\([0-9]*\)\/download.*/\1/g')

# Get cardano-node latest build version number
# CARDANO_NODE_LATEST_VERSION=$(curl --silent https://hydra.iohk.io/build/$CARDANO_NODE_LATEST_BUILD | grep -e "<a href=\"https://hydra.iohk.io/build/$CARDANO_NODE_LATEST_BUILD/download/1/cardano-node-" | sed 's/^.*[^0-9]\([0-9]*\.[0-9]*\.[0-9]*\).*$/\1/')

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -id)
      BUILD_ID="$2"
      shift
      ;;
    -n|--network)
      NETWORK="$2"
      shift
      ;;
    -ssh|--ssh)
      SSH_KEY="$2"
      shift
      ;;
    -ssh-p|--ssh-port)
      SSH_PORT="$2"
      shift
      ;;
    -v|--ver)
      # VERSION="$2"
      shift
      ;;
    --bundle)
      BUNDLE_CONFIG="0"
      shift
      ;;
    --bnswap)
      BLOCK_NODE_SWAP_SIZE="$2"
      shift
      ;;
    --bnip1)
      BLOCK_NODE_IP_1="$2"
      shift
      ;;
    --rnswap)
      RELAY_NODE_SWAP_SIZE="$2"
      shift
      ;;
    --rnip1)
      RELAY_NODE_IP_1="$2"
      shift
      ;;
    --rnip2)
      RELAY_NODE_IP_2="$2"
      shift
      ;;
    --rnhost1)
      RELAY_HOSTNAME_1="$2"
      shift
      ;;
    --rnhost2)
      RELAY_HOSTNAME_2="$2"
      shift
      ;;
    --auto-init)
      AUTO_INIT="yes"
      shift
      ;;
    *) # unknown option
      shift
      ;;
  esac
done

buildCloudConfiguration(){
NODE_TYPE=$1 # relay | block
NODE_NETWORK=$NETWORK # testnet | mainnet
NODE_VERSION=$VERSION # eg 1.29.0
NODE_HOSTNAME=$HOSTNAME # relay dns hostname

# Should have a map of allowed values based on version
NODE_BINARY_BUILD=7938912 # for binary 1.30.0
NODE_CONFIG_BUILD_NUMBER=7926804 # For json configs 1.30.0

SSH_KEY=$SSH_KEY
SSH_PORT=$SSH_PORT

# Do not change below
NODE_PORT=6000
NODE_USER=cardano
NODE_HOME=/opt/cardano-node

NODE_CONFIG_PATH="${NODE_HOME}/config"
NODE_DB_PATH="${NODE_HOME}/db"
NODE_LOG_PATH="${NODE_HOME}/log"
NODE_SOCKET_PATH="${NODE_DB_PATH}/socket"
NODE_PRIVATE_PATH="${NODE_HOME}/private"
NODE_SCRIPTS_PATH="${NODE_HOME}/scripts"

# Needed for cardano-cli
CARDANO_NODE_SOCKET_PATH="${NODE_SOCKET_PATH}"

CONFIG_TOPOLOGY="$NODE_CONFIG_PATH/$NODE_NETWORK-topology.json"
CONFIG_CONFIG="$NODE_CONFIG_PATH/$NODE_NETWORK-config.json"
CONFIG_SHELLY="$NODE_CONFIG_PATH/$NODE_NETWORK-shelley-genesis.json"
CONFIG_BYRON="$NODE_CONFIG_PATH/$NODE_NETWORK-byron-genesis.json"
CONFIG_ALONZO="$NODE_CONFIG_PATH/$NODE_NETWORK-alonzo-genesis.json"

if [ "$NODE_NETWORK" = mainnet ]; then
  NODE_NETWORK_FLAG="--mainnet"
else
  NODE_NETWORK_FLAG="--testnet-magic 1097911063"
fi

mkdir -p "$script_dir/out/${BUILD_ID}"

CONFIG_SCRIPT_PATH="$script_dir/out/${BUILD_ID}/${NODE_TYPE}-user-data.yaml"

# Write the header to the main user data file
echo "$(. "$script_dir/server/init/header.sh")" > "$script_dir/out/${BUILD_ID}/${NODE_TYPE}-user-data.yaml"

# If not bundling, that means were generating another file. write the header for that
if [ "$BUNDLE_CONFIG" = "1" ]; then
  CONFIG_SCRIPT_PATH="$script_dir/out/${BUILD_ID}/${NODE_TYPE}-setup.yaml"
  echo "$(. "$script_dir/server/config/header.sh")" > "$CONFIG_SCRIPT_PATH"
  echo "" >> "$CONFIG_SCRIPT_PATH"
fi 

# loop through the supported steps
for ELEMENT in "users" "write_files" "runcmd"; do

  # Write node user-data init script
  if [ -d "$script_dir/server/init/$ELEMENT" ]; then
  echo "$ELEMENT:" >> "$script_dir/out/${BUILD_ID}/${NODE_TYPE}-user-data.yaml"
    for f in `ls -1v $script_dir/server/init/$ELEMENT`; do
      cat "$script_dir/server/init/$ELEMENT/$f" >> "$script_dir/out/${BUILD_ID}/${NODE_TYPE}-user-data.yaml"
      echo "" >> "$script_dir/out/${BUILD_ID}/${NODE_TYPE}-user-data.yaml"
    done
  fi

  # if we're writing 2 files and a step exists, the file needs the step keyword defined
  if [ -d "$script_dir/server/config/${NODE_TYPE}/$ELEMENT" ] || 
     [ -d "$script_dir/server/config/shared/$ELEMENT" ]; then
    if [ "$BUNDLE_CONFIG" = "1" ]; then
        echo "$ELEMENT:" >> $CONFIG_SCRIPT_PATH
    fi 
  fi

  # Print out all the instructions from the node-specific template files
  if [ -d "$script_dir/server/config/${NODE_TYPE}/$ELEMENT" ]; then
    for f in `ls -1v "$script_dir/server/config/${NODE_TYPE}/$ELEMENT"`; do
      cat "$script_dir/server/config/${NODE_TYPE}/$ELEMENT/$f" >> "$CONFIG_SCRIPT_PATH"
      echo "" >> "$CONFIG_SCRIPT_PATH"
    done
  fi

  # Print out all the instructions from the node-shared template files
  if [ -d "$script_dir/server/config/shared/$ELEMENT" ]; then
    for f in `ls -1v "$script_dir/server/config/shared/$ELEMENT"`; do
      cat "$script_dir/server/config/shared/$ELEMENT/$f" >> "$CONFIG_SCRIPT_PATH"
      echo "" >> "$CONFIG_SCRIPT_PATH"
    done
  fi

  if [ $ELEMENT == "write_files" ]; then 
    echo "$(. "$script_dir/server/init/config.sh")" >> "$CONFIG_SCRIPT_PATH"
  fi

# Done loop through the supported steps
done

# if were writing 2 files, one will NOT be executed on create. so it doesnt support runcmd. 

# go through all the generated files and replace variables
for f in `ls -1v $script_dir/out/${BUILD_ID}`; do
  sed -i '' "s#\${NODE_TYPE}#${NODE_TYPE}#g" $script_dir/out/$BUILD_ID/$f
  sed -i '' "s#\${NODE_NETWORK}#${NODE_NETWORK}#g" $script_dir/out/$BUILD_ID/$f
  sed -i '' "s#\${NODE_NETWORK_FLAG}#${NODE_NETWORK_FLAG}#g" $script_dir/out/$BUILD_ID/$f
  sed -i '' "s#\${NODE_VERSION}#${NODE_VERSION}#g" $script_dir/out/$BUILD_ID/$f
  sed -i '' "s#\${NODE_BINARY_BUILD}#${NODE_BINARY_BUILD}#g" $script_dir/out/$BUILD_ID/$f
  sed -i '' "s#\${NODE_HOSTNAME}#${NODE_HOSTNAME}#g" $script_dir/out/$BUILD_ID/$f

  sed -i '' "s#\${SSH_KEY}#${SSH_KEY}#g" $script_dir/out/$BUILD_ID/$f
  sed -i '' "s#\${SSH_PORT}#${SSH_PORT}#g" $script_dir/out/$BUILD_ID/$f

  sed -i '' "s#\${NODE_PORT}#${NODE_PORT}#g" $script_dir/out/$BUILD_ID/$f
  sed -i '' "s#\${NODE_USER}#${NODE_USER}#g" $script_dir/out/$BUILD_ID/$f
  sed -i '' "s#\${NODE_HOME}#${NODE_HOME}#g" $script_dir/out/$BUILD_ID/$f
  sed -i '' "s#\${NODE_CONFIG_BUILD_NUMBER}#${NODE_CONFIG_BUILD_NUMBER}#g" $script_dir/out/$BUILD_ID/$f

  sed -i '' "s#\${NODE_CONFIG_PATH}#${NODE_CONFIG_PATH}#g" $script_dir/out/$BUILD_ID/$f
  sed -i '' "s#\${NODE_LOG_PATH}#${NODE_LOG_PATH}#g" $script_dir/out/$BUILD_ID/$f
  sed -i '' "s#\${NODE_DB_PATH}#${NODE_DB_PATH}#g" $script_dir/out/$BUILD_ID/$f
  sed -i '' "s#\${NODE_SOCKET_PATH}#${NODE_SOCKET_PATH}#g" $script_dir/out/$BUILD_ID/$f
  sed -i '' "s#\${CARDANO_NODE_SOCKET_PATH}#${CARDANO_NODE_SOCKET_PATH}#g" $script_dir/out/$BUILD_ID/$f
  sed -i '' "s#\${NODE_PRIVATE_PATH}#${NODE_PRIVATE_PATH}#g" $script_dir/out/$BUILD_ID/$f
  sed -i '' "s#\${NODE_SCRIPTS_PATH}#${NODE_SCRIPTS_PATH}#g" $script_dir/out/$BUILD_ID/$f

  sed -i '' "s#\${CONFIG_TOPOLOGY}#${CONFIG_TOPOLOGY}#g" $script_dir/out/$BUILD_ID/$f
  sed -i '' "s#\${CONFIG_CONFIG}#${CONFIG_CONFIG}#g" $script_dir/out/$BUILD_ID/$f
  sed -i '' "s#\${CONFIG_SHELLY}#${CONFIG_SHELLY}#g" $script_dir/out/$BUILD_ID/$f
  sed -i '' "s#\${CONFIG_BYRON}#${CONFIG_BYRON}#g" $script_dir/out/$BUILD_ID/$f
  sed -i '' "s#\${CONFIG_ALONZO}#${CONFIG_ALONZO}#g" $script_dir/out/$BUILD_ID/$f

  sed -i '' "s#\${BLOCK_NODE_SWAP_SIZE}#${BLOCK_NODE_SWAP_SIZE}#g" $script_dir/out/$BUILD_ID/$f
  sed -i '' "s#\${BLOCK_NODE_IP_1}#${BLOCK_NODE_IP_1}#g" $script_dir/out/$BUILD_ID/$f

  sed -i '' "s#\${RELAY_NODE_SWAP_SIZE}#${RELAY_NODE_SWAP_SIZE}#g" $script_dir/out/$BUILD_ID/$f
  sed -i '' "s#\${RELAY_NODE_IP_1}#${RELAY_NODE_IP_1}#g" $script_dir/out/$BUILD_ID/$f
  sed -i '' "s#\${RELAY_NODE_IP_2}#${RELAY_NODE_IP_2}#g" $script_dir/out/$BUILD_ID/$f

  sed -i '' "s#\${AUTO_INIT}#${AUTO_INIT}#g" $script_dir/out/$BUILD_ID/$f
done
}


buildCloudConfiguration "block"

buildCloudConfiguration "relay"

# if [ -z $RELAY_NODE_IP_2 ]; then 
#   buildCloudConfiguration "relay" $RELAY_HOSTNAME_2
# fi 