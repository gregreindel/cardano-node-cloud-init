# Cardano Cloud-init Generator
Generate Cloud-init YAML files that can be used for installing and setting up Cardano stake pool node servers.

Web UI - https://cardanocloudinit.com

Web UI GitHub - https://github.com/gregreindel/cardano-node-cloud-init-app
Web API GitHub - https://github.com/gregreindel/cardano-node-cloud-init-api

Install and Setup Cardano Stake Pool Node Using Cloud-init in Less Than 15 mins - YouTube
https://www.youtube.com/watch?v=ga1ofRRZuiA


**Note: This is in beta.**

----------------

# Goal 
The long-term goal of this project is to fully automate the deployment of a Cardano stake pool. This will enable highly-available systems, making the node servers disposable -  allowing you to quickly and automatically re-deploy parts or all of your pool. 

Once complete, users will be able to:
- Deploy a pool to any supported cloud providers via API with no configuration needed.
- Support a self-healing infrastructure.
- Support multi-provider failover.
- Have a UI for managing pool infrastructure.

Another goal of this project ia to make it easier for new stake pool operators to get their first pool online.

## To Do - coming soon
- UI for managing pool infrastructure.
- Look into platform compatibility with Google Cloud and any other provider-specific enhancements.

----------------

# Usage
Generate Cloud-init YAML files. 

**Example usage**
```
. /path/to/cardano-cloud.sh --version "1.30.0" --network "<testnet|mainnet>" --ssh-key "<ssh_key> --bundle"
```

**Basic Options**
```
-id                 Some unique id. You can use uuidgen if available. Or just pass some string.
--network           Whether using testnet or mainnet. Required.  
--version           Cardano-node version. Defaults to latest (1.29.0).  
--ssh-key           SSH key. Required so you can connect to the server.  
--ssh-port          SSH port. Defaults to 22.  
--bundle            (flag) Whether or not to bundle the config/setup scripts with the basic install user data for the output.  
--output-dashboard  (flag) If you want the output to include YAML for a monitoring dashboard node. 
--output-relay      (flag) If you want the output to include YAML for relay node(s). 
--output-block      (flag) If you want the output to include YAML for block node. 
```

**Advanced Options** - Use these in addition with the basic options as needed. These are all optional, and most useful when re-deploying an existing pool
```
--bnswap     Number of bytes for block node swap file. Defaults to 0, which will disable the swap file.
--rnswap     Number of bytes for relay node swap file. Defaults to 0, which will disable the swap file.
--bnip1      IP address of the block node. Recommend a floating IP. Optional. Must be a valid IPv4 address.
--rnip1      IP address of the relay 1 node. Recommend a floating IP. Optional. Must be a valid IPv4 address.
--rnip2      IP address of the relay 2 node. Recommend a floating IP. Optional. Must be a valid IPv4 address.
--rnhost1    DNS hostname for relay node 1. Optional. Must be a valid hostname without a protocol.
--rnhost2    DNS hostname for relay node 2. Optional. Must be a valid hostname without a protocol.
--auto-init  (flag) Pass flag to tell setup scripts to run directly after the node setup. Can only be used when re-deploying an existing pool.
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
|- /home/cardano/scripts/getTxInfo.sh
|- /home/cardano/scripts/task/rotateKES.sh
|- /home/cardano/scripts/task/regeneratePoolCertificate.sh
|- /home/cardano/scripts/init/create.sh
|- /home/cardano/scripts/init/s3Sync.sh
|- /home/cardano/scripts/init/registerAddress.sh
|- /home/cardano/scripts/init/registerKeys.sh
|- /home/cardano/scripts/init/registerTopology.sh
|- /home/cardano/scripts/init/registerPoolGetId.sh
|- /home/cardano/scripts/init/manualSetupHelper.sh
|- /home/cardano/scripts/utils/generatePoolCertificate.sh
|- /home/cardano/scripts/utils/generatePoolCertificateTransaction.sh
|- /home/cardano/scripts/utils/generatePoolMeta.sh
|- /home/cardano/scripts/utils/verifyPoolMeta.sh
|- /home/cardano/scripts/utils/cleanFirewallForPort.sh

Relay Node Setup  
|- /home/cardano/.environment-relay.sh  
|- /opt/cardano-node/scripts/topologyPull.sh  
|- /opt/cardano-node/scripts/init/create.sh  
|- /opt/cardano-node/scripts/init/registerTopology.sh   
|- /opt/cardano-node/scripts/init/topologyUpdater.sh  
|- /opt/cardano-node/scripts/init/manualSetupHelper.sh
|- /home/cardano/scripts/utils/cleanFirewallForPort.sh

Monitoring Dashboard Node Setup  
|- /home/cardano/.environment-dashboard.sh  
|- /opt/cardano-node/scripts/init/create.sh  
|- /opt/cardano-node/scripts/init/configure.sh  

Available On All Setup Nodes (Relay,Block,Dashboard)
|- /home/cardano/scripts/utils/cleanFirewallForPort.sh
|- /home/cardano/scripts//init/manualSetupHelperShared.sh
|- /home/cardano/scripts/updateConfigIP.yml
|- /home/cardano/scripts/updateTopologyIP.sh
|- /home/cardano/scripts/toLovelace.sh
|- /home/cardano/scripts/toADA.sh
|- /home/cardano/scripts/finish.sh


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
- Take the contents of the file named "User Data" and input into the user data section when creating your server.

**Step 2**  
- Allow the instance to boot. Once it does, it will begin running the Cloud-init configuration.
- Login to your server by running the following command:  
`ssh cardano@the-server-ip-address -p the-port-you-chose`
- Once connected, run this command to watch the Cloud-init process in the logs:  
`sudo tail -f /var/log/cloud-init-output.log`
- Wait until it says "Cloud-init v. xxxx-ubuntu1~20.04.2 finished..." at the bottom of the log file and/or the server reboots.

Once the Cloud-init log says "Cloud-init v. xxxx-ubuntu1~20.04.2 finished..." at the bottom, the installation is complete. It should take no longer than 5 minutes.

**Step 3**  
- Verify the installation by running the following command: `logs`
- This will display the logs for cardano-node. You should see logs similar to "Chain extended, new tip: xxxx at slot xxx" That means you are syncing with the blockchain.

For complete instructions on how to setup and configure the relay and block nodes visit this link - https://app.cardanocloudinit.com/help/basic

----------------

# Installing a cardano-node Monitoring Dashboard Server
Note: It's recommended to use Ubuntu 20.04 x64.

**Step 1**  
- Take the contents of the file named "User Data" and input into the user data section when creating your server.

**Step 2**  
- Allow the instance to boot. Once it does, it will begin running the Cloud-init configuration.
- Login to your server by running the following command:  
`ssh cardano@the-server-ip-address -p the-port-you-chose`
- Once connected, run this command to watch the Cloud-init process in the logs:  
`sudo tail -f /var/log/cloud-init-output.log`
- Wait until it says "Cloud-init v. xxxx-ubuntu1~20.04.2 finished..." at the bottom of the log file and/or the server reboots.

Once the Cloud-init log says "Cloud-init v. xxxx-ubuntu1~20.04.2 finished..." at the bottom, the installation is complete. It should take no longer than 3 minutes.

**Step 3**  
- Verify the installation by running the following command: `status`. You should see Grafana and Prometheus running

For complete instructions on how to setup and configure the monitoring node visit this link - https://app.cardanocloudinit.com/help/dashboard
----------------

# Known Issues & Limitations 
- Possible compatibility Google Cloud - does not use `systemctl enable`, can't use `swap`.

----------------

# Warranty
There is no warranty. Use at your own risk. The code is public and fully auditable by you, and its your responsibility to do so.