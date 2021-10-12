blockIP=${BLOCK_NODE_IP}

relayIPs=$(echo [] | jq)
for host in ${RELAY_NODE_IP_1} ${RELAY_NODE_IP_2}; do
relayIPs=$( echo $relayIPs | jq -r '. += ["'${host}'"]')
done 

hostname=${NODE_HOSTNAME}

[ ${NODE_TYPE} == "block" ] && echo "
- path: ${NODE_HOME}/.config.json
  permissions: \"750\"
  content: |
    { \"extraParameters\": \"\", \"relayIPs\": ${relayIPs} }
" || echo "
- path: ${NODE_HOME}/.config.json
  permissions: \"750\"
  content: |
    { \"extraParameters\": \"\", \"blockIP\": \"${blockIP}\", \"hostname\": \"$hostname\" }
"