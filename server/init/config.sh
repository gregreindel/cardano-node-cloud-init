blockIP=${BLOCK_NODE_IP}

relayIPs=$(echo [] | jq)
for host in ${RELAY_NODE_IP_1} ${RELAY_NODE_IP_2}; do
relayIPs=$( echo $relayIPs | jq -r '. += ["'${host}'"]')
done 

echo "
- path: ${NODE_HOME}/.config.json
  permissions: \"750\"
  content: |
        $(echo { \"extraParameters\": \"\", \"blockIP\": \"${blockIP}\", \"relayIPs\": ${relayIPs}, \"hostname\": \"${NODE_HOSTNAME}\" } )
"
