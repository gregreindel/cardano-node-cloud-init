blockIP=${BLOCK_NODE_IP_1}

relayIPs=$(echo [] | jq)
for host in ${RELAY_NODE_IP_1} ${RELAY_NODE_IP_2}; do
relayIPs=$( echo $relayIPs | jq -c '. += ["'${host}'"]')
done 

hostname=${NODE_HOSTNAME}

[ ${NODE_TYPE} == "block" ] && echo "
- path: ${NODE_HOME}/.config.json
  permissions: \"750\"
  content: |
    { \"extraParameters\": \"\", \"relayIPs\": ${relayIPs} }
"

[ ${NODE_TYPE} == "relay" ] && echo "
- path: ${NODE_HOME}/.config.json
  permissions: \"750\"
  content: |
    { \"extraParameters\": \"\", \"blockIP\": \"${blockIP}\", \"hostname\": \"$hostname\" }
"

[ ${NODE_TYPE} == "dashboard" ] && echo "
- path: ${NODE_HOME}/.config.json
  permissions: \"750\"
  content: |
    { \"blockIP\": \"${blockIP}\", \"relayIPs\": ${relayIPs}, \"hostname\": \"$hostname\" }
"