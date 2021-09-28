# Cardano Cloud-init
Generate Cloud-init YAML files that can be used for installing and setting up Cardano stake pool node servers.

Visit here to generate via web - https://app.cardanocloudinit.com/

**Note: This is in beta.**

----------------

# Goal 
The goal of this project is to fully automate the deployment of a Cardano stake pool. This will enable highly-available systems, allowing you to quickly and automatically re-deploy parts or all of your pool. The node servers should be disposable, as long as you have predictable IP's and an easy+safe way to pull the 3 required certificate/keys for the block-producers. 

Enabling you to:
- Deploy a pool to any supported cloud providers via API with no configuration needed.
- Support a self-healing infrastructure.
- Support multi-provider failover.
- UI for managing pool infrastructure

This should also help make it quite a bit easier for new stake pool operators to get their first pool on testnet faster.


## To Do - coming soon
- Allow passing in block & relay IP's into user data, to help with re-deploying a pool that was already setup, and you have dedicated/floating IP's.
- Allow passing in other settings into config which will make for less questions while performing the node configuration 
- Add utility to fetch db copy from volume
- UI for managing pool infrastructure
- Look into how to make work with Google Cloud (they don't use `systemctl enable`)

----------------

# Usage
Generate Cloud-init files. 


```
. /path/to/cardano-cloud.sh -b --ver "1.29.0" --network "<testnet|mainnet>" --ssh "<ssh_key>"
```


```
*--id* - Some unique id. You can use uuidgen if available. Or just pass some string.  
*--ver* - Cardano-node version. Defaults to latest (1.29.0).  
*--network* - Whether using testnet or mainnet. Required.  
*--ssh* - SSH key. Required so you can connect to the server.  
*--ssh-p* - SSH port. Defaults to 22.  
*-b* - Whether or not to bundle the config/setup scripts with the basic install user data for the output.  
```
Outputs to /out/$id/file-name.yaml

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

`/opt/cardano-node/db` - Node Database Path 

`/opt/cardano-node/db/socket ` - Node Socket Path 

`/opt/cardano-node/private ` - Node Private Path - Used for keys

`/opt/cardano-node/scripts ` - Node Scripts Path - Used for setup and utility scripts

`/opt/cardano-node/config ` - Node Config Path - Used for config and topology files 


## Custom Alias & Shortcuts

`start` - starts the cardano-node service

`stop` - stops the cardano-node service

`restart` - restarts the cardano-node service

`status` - show the cardano-node service status

`logs` - show cardano-node logs

`view` - show cardano-node live view

----------------

# Installing a cardano-node Server
Note: It's recommended to use Ubuntu 20.04 x64.

**Step 1**  
- Take the file contents of the file named "User Data" and input that when creating your server.

**Step 2**  
- Allow the instance to boot. Once it does, it will begin running the Cloud-init configuration.
- You can log into your server by running the following command:  
`ssh cardano@the-server-ip-address -p the-port-you-chose`
- Once you connect, run this command to watch the Cloud-init logs:  
`sudo tail -f /var/log/cloud-init-output.log`
- Wait until it says "Cloud-init v. xxxx-ubuntu1~20.04.2 finished..." at the bottom of the log file, and/or the server reboots.

Once the Cloud-init log says "finished" at the bottom, the installation is complete. It should take no longer than 5 minutes.

**Step 3**  
- Verify the installation by running the following command: `logs`
- This will display the logs for cardano-node. You should see logs similar to "Chain extended, new tip: xxxx at slot xxx" That means you are syncing with the blockchain.

----------------

# Known Issues & Limitations 
- Might not work with Google Cloud - does not use systemctl enable.

----------------

# Warranty
There is no warranty. Use at your own risk. The code is public and fully auditable by you, and its your responsibility to do so.