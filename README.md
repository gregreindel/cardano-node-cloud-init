# Cardano Cloud-init
Generate Cloud-init files for creating Cardano stake pool node servers

Visit here to generate via web - https://app.cardanocloudinit.com/

Note: This is in beta

# Goal 
The goal of this project is to fully automate the deployment of a Cardano stake pool. This will enable highly-available systems, allowing you to quickly and automatically re-deploy parts or all of your pool. The node servers should be disposable, as long as you have predictable IP's and an easy+safe way to pull the 3 required certificate/keys for the block-producers.

- Deploy a pool to any supported cloud providers via API with no configuration needed.
- Support a self-healing infrastructure.
- Support multi-provider failover.
- UI for managing pool infrastructure


## To Do 
- Allow passing in block & relay IP's into user data, to help with re-deploying a pool that was already setup, and you have dedicated/floating IP's.
- Allow passing in other settings into config which will make for less questions while performing the node configuration 
- Add utility to fetch db copy from volume
- UI for managing pool infrastructure
- Look into how to make work with Google Cloud (they don't use `systemctl enable`)


# Usage
Generate Cloud-init files

``
. /path/to/cardano-cloud.sh -b --ver "1.29.0" --network "<testnet|mainnet>" --ssh "<ssh_key>"
``

Outputs to /out/${id}/*.yaml

*--id* - Some unique id. You can use uuidgen if available. Or just pass some string.
*--ver* - Cardano-node version. Defaults to latest (1.29.0).
*--network* - Whether using testnet or mainnet. Required.
*--ssh* - SSH key. Required so you can connect to the server.
*--ssh-p* - SSH port. Defaults to 22.
*-b* - Whether or not to bundle the config/setup scripts with the basic install user data for the output.


----------------


# Cloud-init Overview 

## Files Written

Configuration
|- /etc/ssh/sshd_config
|- /etc/fail2ban/jail.local
|- /home/cardano/.environment.sh
|- /home/cardano/.environment-[block|relay].sh
|- /etc/systemd/system/cardano-node.service
|- /opt/cardano-node/scripts/startNode.sh
|- /opt/cardano-node/scripts/liveView.sh
|- /opt/cardano-node/.config.json

Block Node Setup
|- /home/cardano/.environment-block.sh
|- /opt/cardano-node/scripts/init/create.sh
|- /opt/cardano-node/scripts/init/registerAddress
|- /opt/cardano-node/scripts/init/registerKeys.sh
|- /opt/cardano-node/scripts/init/registerPool.sh
|- /opt/cardano-node/scripts/init/registerPoolGetId.sh
|- /opt/cardano-node/scripts/init/registerPoolPledge.sh
|- /opt/cardano-node/scripts/init/cleanup.sh
|- /opt/cardano-node/scripts/init/registerTopology.sh 
|- /opt/cardano-node/scripts/init/s3Sync.sh
|- /opt/cardano-node/scripts/getTxInfo.sh

Relay Node Setup
|- /home/cardano/.environment-relay.sh
|- /opt/cardano-node/scripts/init/create.sh
|- /opt/cardano-node/scripts/init/registerTopology.sh 
|- /opt/cardano-node/scripts/init/topologyUpdater.sh
|- /opt/cardano-node/scripts/topologyPull.sh


## Useful Paths

Node Database Path 
/opt/cardano-node/db

Node Socket Path 
/opt/cardano-node/db/socket 

Node Private Path - Used for keys
/opt/cardano-node/private 

Node Scripts Path - Used for setup and utility scripts
/opt/cardano-node/scripts 

Node Config Path - Used for config and topology files 
/opt/cardano-node/config 

## Custom Alias & Shortcuts

`start` - starts the cardano-node service

`stop` - stops the cardano-node service

`restart` - restarts the cardano-node service

`status` - show the cardano-node service status

`logs` - show cardano-node logs

`view` - show cardano-node live view


# Known Issues & Limitations 
- Might not work with Google Cloud - does not use systemctl enable.


# Warranty
There is no warranty. Use at your own risk. The code is public and fully auditable by you, and its your responsibility to do so.