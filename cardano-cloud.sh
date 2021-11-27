#!/bin/bash
# Generates Cloud-init YAML files based on the template files in /server

cardanoCloudInitGeneratorVersion="1.1.0"
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

BUILD_ID="0"

OUTPUT_PATH_DIR="$script_dir/out"

OUTPUT_DASHBOARD_YAML="no"
OUTPUT_RELAY_YAML="no"
OUTPUT_BLOCK_YAML="no"

NETWORK="testnet"
VERSION="latest"
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
CUSTOM_DB_PATH=""

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -id|--id)
      BUILD_ID="$2"
      shift
      ;;
    -n|--network)
      NETWORK="$2"
      shift
      ;;
    -ssh|--ssh-key)
      SSH_KEY="$2"
      shift
      ;;
    -ssh-p|--ssh-port)
      SSH_PORT="$2"
      shift
      ;;
    -v|--version)
      VERSION="$2"
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
    --output-dashboard)
      OUTPUT_DASHBOARD_YAML="yes"
      shift
      ;;
    --output-relay)
      OUTPUT_RELAY_YAML="yes"
      shift
      ;;
    --output-block)
      OUTPUT_BLOCK_YAML="yes"
      shift
      ;;
    --database-path)
      CUSTOM_DB_PATH="$2"
      shift
      ;;
    --output-path)
      OUTPUT_PATH_DIR="$2"
      shift
      ;;
    *) # unknown option
      shift
      ;;
  esac
done

if [ -z $VERSION ]; then 
VERSION="latest"
elif [ $VERSION == "1.30.0" ]; then 
VERSION="1.30.0"
BINARY_BUILD=7938912
CONFIG_BUILD_NUMBER=7926804
elif [ $VERSION == "1.29.0" ]; then 
VERSION="1.29.0"
BINARY_BUILD=7408438
CONFIG_BUILD_NUMBER=7578887
else
VERSION="latest"
fi 

if [ $VERSION == "latest" ]; then 
# Get config latest build number
CONFIG_BUILD_NUMBER=$(curl --silent https://hydra.iohk.io/job/Cardano/iohk-nix/cardano-deployment/latest-finished/download/1/index.html | grep -e "build" | sed 's/.*build\/\([0-9]*\)\/download.*/\1/g')
# Get cardano-node latest build number
BINARY_BUILD=$(curl --silent https://hydra.iohk.io/job/Cardano/cardano-node/cardano-node-linux/latest-finished/download/1/index.html | grep -e "build" | sed 's/.*build\/\([0-9]*\)\/download.*/\1/g')
# Get cardano-node latest build version number
VERSION=$(curl --silent https://hydra.iohk.io/build/$BINARY_BUILD | grep -e "<a href=\"https://hydra.iohk.io/build/$BINARY_BUILD/download/1/cardano-node-" | sed 's/^.*[^0-9]\([0-9]*\.[0-9]*\.[0-9]*\).*$/\1/')
fi


buildCloudConfiguration(){
NODE_TYPE=$1 # relay | block
[ ! -z $2 ] && NODE_NUMBER="$2" || NODE_NUMBER="1"
NODE_HOSTNAME="" # relay dns hostname
NODE_NETWORK=$NETWORK # testnet | mainnet
NODE_VERSION=$VERSION # eg 1.29.0

NODE_BINARY_BUILD=$BINARY_BUILD
NODE_CONFIG_BUILD_NUMBER=$CONFIG_BUILD_NUMBER

SSH_KEY=$SSH_KEY
SSH_PORT=$SSH_PORT

NODE_PORT=6000
NODE_USER=cardano
NODE_HOME=/opt/cardano-node

NODE_CONFIG_PATH="${NODE_HOME}/config"
[ ! -z $CUSTOM_DB_PATH ] && NODE_DB_PATH=$CUSTOM_DB_PATH || NODE_DB_PATH="${NODE_HOME}/db"
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

OUTPUT_PATH="$OUTPUT_PATH_DIR/$BUILD_ID"
mkdir -p $OUTPUT_PATH

if [ "${NODE_TYPE}" == "relay" ] && [ "${NODE_NUMBER}" -eq 1 ]; then 
  NODE_HOSTNAME=$RELAY_HOSTNAME_1
elif [ "${NODE_TYPE}" == "relay" ] && [ "${NODE_NUMBER}" -eq 2 ]; then 
  NODE_HOSTNAME=$RELAY_HOSTNAME_2
fi 

[ "$BUNDLE_CONFIG" = "1" ] && [ ! "$NODE_TYPE" == "dashboard" ] && filename="user-data" || filename="user-data-combined"
[ "$NODE_TYPE" == "dashboard" ] && filenamePart1="${NODE_TYPE}" || filenamePart1="${NODE_TYPE}-${NODE_NUMBER}"
[ "$NODE_TYPE" == "dashboard" ] && filename="user-data" || filename=$filename

USER_DATA_YAML_OUT="$OUTPUT_PATH/$filenamePart1-${filename}.yaml"

# Write the header to the main user data file
echo "$(. "$script_dir/server/init/header.sh")" > $USER_DATA_YAML_OUT

SETUP_SCRIPTS_YAML_OUT="$OUTPUT_PATH/$filenamePart1-${filename}.yaml"
# If not bundling, that means were generating another file. write the header for that
if [ "$BUNDLE_CONFIG" = "1" ] && [ ! "$NODE_TYPE" == "dashboard" ]; then
  SETUP_SCRIPTS_YAML_OUT="$OUTPUT_PATH/$filenamePart1-setup.yaml"
  echo "$(. "$script_dir/server/config/header.sh")" > "$SETUP_SCRIPTS_YAML_OUT"
  echo "" >> "$SETUP_SCRIPTS_YAML_OUT"
fi 

if [ "${NODE_TYPE}" == "dashboard" ]; then 
serverTypePath="server/init/dashboard"
else 
serverTypePath="server/init/node"
fi 

# loop through the supported steps
for ELEMENT in "users" "write_files" "runcmd"; do

  # Write node user-data init script
  if [ -d "$script_dir/${serverTypePath}/$ELEMENT" ] || [ -d "$script_dir/server/init/shared/$ELEMENT" ]; then
    echo "$ELEMENT:" >> $USER_DATA_YAML_OUT
    echo "## Start $ELEMENT ##" >> $USER_DATA_YAML_OUT
    if [ -d "$script_dir/server/init/shared/$ELEMENT" ]; then
      for f in `ls -1v $script_dir/server/init/shared/$ELEMENT`; do
        if [ "${f: -3}" == ".sh" ]; then
          echo "$(. "$script_dir/server/init/shared/$ELEMENT/$f")" >> $USER_DATA_YAML_OUT
        else 
          cat "$script_dir/server/init/shared/$ELEMENT/$f" >> $USER_DATA_YAML_OUT
        fi
        echo "" >> $USER_DATA_YAML_OUT
      done
    fi
    for f in `ls -1v $script_dir/${serverTypePath}/$ELEMENT`; do
      if [ "${f: -3}" == ".sh" ]; then
        echo "$(. "$script_dir/${serverTypePath}/$ELEMENT/$f")" >> $USER_DATA_YAML_OUT
      else 
        cat "$script_dir/${serverTypePath}/$ELEMENT/$f" >> $USER_DATA_YAML_OUT
      fi
      echo "" >> $USER_DATA_YAML_OUT
    done
  fi


  # if [ "${NODE_TYPE}" == "block" ] || [ "${NODE_TYPE}" == "relay" ]; then 
    # if we're writing 2 files and a step exists, the file needs the step keyword defined
    if [ -d "$script_dir/server/config/${NODE_TYPE}/$ELEMENT" ] || 
      [ -d "$script_dir/server/config/shared/$ELEMENT" ]; then
      if [ "$BUNDLE_CONFIG" = "1" ] && [ ! "$NODE_TYPE" == "dashboard" ]; then
        echo "$ELEMENT:" >> $SETUP_SCRIPTS_YAML_OUT
      fi 
    fi

    # Print out all the instructions from the node-specific template files
    if [ -d "$script_dir/server/config/${NODE_TYPE}/$ELEMENT" ]; then
      for f in `ls -1v "$script_dir/server/config/${NODE_TYPE}/$ELEMENT"`; do
        cat "$script_dir/server/config/${NODE_TYPE}/$ELEMENT/$f" >> "$SETUP_SCRIPTS_YAML_OUT"
        echo "" >> "$SETUP_SCRIPTS_YAML_OUT"
      done
    fi

    # Print out all the instructions from the node-shared template files
    if [ -d "$script_dir/server/config/shared/$ELEMENT" ]; then
      for f in `ls -1v "$script_dir/server/config/shared/$ELEMENT"`; do
        cat "$script_dir/server/config/shared/$ELEMENT/$f" >> "$SETUP_SCRIPTS_YAML_OUT"
        echo "" >> "$SETUP_SCRIPTS_YAML_OUT"
      done
    fi
  # fi 
    echo "## End $ELEMENT ##" >> $SETUP_SCRIPTS_YAML_OUT
done

# if were writing 2 files, one will NOT be executed on create. so it doesnt support runcmd. 

# go through all the generated files and replace variables
for f in `ls -1v $OUTPUT_PATH`; do
  sed -i '' "s#\${NODE_TYPE}#${NODE_TYPE}#g" $OUTPUT_PATH/$f
  sed -i '' "s#\${NODE_NETWORK}#${NODE_NETWORK}#g" $OUTPUT_PATH/$f
  sed -i '' "s#\${NODE_NETWORK_FLAG}#${NODE_NETWORK_FLAG}#g" $OUTPUT_PATH/$f
  sed -i '' "s#\${NODE_VERSION}#${NODE_VERSION}#g" $OUTPUT_PATH/$f
  sed -i '' "s#\${NODE_BINARY_BUILD}#${NODE_BINARY_BUILD}#g" $OUTPUT_PATH/$f
  sed -i '' "s#\${NODE_HOSTNAME}#${NODE_HOSTNAME}#g" $OUTPUT_PATH/$f

  sed -i '' "s#\${SSH_KEY}#${SSH_KEY}#g" $OUTPUT_PATH/$f
  sed -i '' "s#\${SSH_PORT}#${SSH_PORT}#g" $OUTPUT_PATH/$f

  sed -i '' "s#\${NODE_PORT}#${NODE_PORT}#g" $OUTPUT_PATH/$f
  sed -i '' "s#\${NODE_USER}#${NODE_USER}#g" $OUTPUT_PATH/$f
  sed -i '' "s#\${NODE_HOME}#${NODE_HOME}#g" $OUTPUT_PATH/$f
  sed -i '' "s#\${NODE_CONFIG_BUILD_NUMBER}#${NODE_CONFIG_BUILD_NUMBER}#g" $OUTPUT_PATH/$f

  sed -i '' "s#\${NODE_CONFIG_PATH}#${NODE_CONFIG_PATH}#g" $OUTPUT_PATH/$f
  sed -i '' "s#\${NODE_LOG_PATH}#${NODE_LOG_PATH}#g" $OUTPUT_PATH/$f
  sed -i '' "s#\${NODE_DB_PATH}#${NODE_DB_PATH}#g" $OUTPUT_PATH/$f
  sed -i '' "s#\${NODE_SOCKET_PATH}#${NODE_SOCKET_PATH}#g" $OUTPUT_PATH/$f
  sed -i '' "s#\${CARDANO_NODE_SOCKET_PATH}#${CARDANO_NODE_SOCKET_PATH}#g" $OUTPUT_PATH/$f
  sed -i '' "s#\${NODE_PRIVATE_PATH}#${NODE_PRIVATE_PATH}#g" $OUTPUT_PATH/$f
  sed -i '' "s#\${NODE_SCRIPTS_PATH}#${NODE_SCRIPTS_PATH}#g" $OUTPUT_PATH/$f

  sed -i '' "s#\${CONFIG_TOPOLOGY}#${CONFIG_TOPOLOGY}#g" $OUTPUT_PATH/$f
  sed -i '' "s#\${CONFIG_CONFIG}#${CONFIG_CONFIG}#g" $OUTPUT_PATH/$f
  sed -i '' "s#\${CONFIG_SHELLY}#${CONFIG_SHELLY}#g" $OUTPUT_PATH/$f
  sed -i '' "s#\${CONFIG_BYRON}#${CONFIG_BYRON}#g" $OUTPUT_PATH/$f
  sed -i '' "s#\${CONFIG_ALONZO}#${CONFIG_ALONZO}#g" $OUTPUT_PATH/$f

  sed -i '' "s#\${BLOCK_NODE_SWAP_SIZE}#${BLOCK_NODE_SWAP_SIZE}#g" $OUTPUT_PATH/$f
  sed -i '' "s#\${BLOCK_NODE_IP_1}#${BLOCK_NODE_IP_1}#g" $OUTPUT_PATH/$f

  sed -i '' "s#\${RELAY_NODE_SWAP_SIZE}#${RELAY_NODE_SWAP_SIZE}#g" $OUTPUT_PATH/$f
  sed -i '' "s#\${RELAY_NODE_IP_1}#${RELAY_NODE_IP_1}#g" $OUTPUT_PATH/$f
  sed -i '' "s#\${RELAY_NODE_IP_2}#${RELAY_NODE_IP_2}#g" $OUTPUT_PATH/$f

  sed -i '' "s#\${AUTO_INIT}#${AUTO_INIT}#g" $OUTPUT_PATH/$f
  sed -i '' "s#\${NODE_NUMBER}#${NODE_NUMBER}#g" $OUTPUT_PATH/$f
done
}

if [ $OUTPUT_DASHBOARD_YAML == "yes" ]; then 
buildCloudConfiguration "dashboard"
fi 

if [ $OUTPUT_RELAY_YAML == "yes" ]; then 
buildCloudConfiguration "relay"
fi 

if [ $OUTPUT_BLOCK_YAML == "yes" ]; then 
buildCloudConfiguration "block"
fi 
