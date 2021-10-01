
blockIPs=$(echo [] | jq)
for ip in ${BLOCK_NODE_IP_1} ${BLOCK_NODE_IP_2}; do
blockIPs=$( echo $blockIPs | jq -r '. += ["'${ip}'"]')
done 

relayIPs=$(echo [] | jq)
for ip in ${RELAY_NODE_1} ${RELAY_NODE_2} ${RELAY_NODE_3} ${RELAY_NODE_4}; do
relayIPs=$( echo $blockIPs | jq -r '. += ["'${ip}'"]')
done 

echo "
- path: ${NODE_HOME}/.config.json
  permissions: \"750\"
  content: |
        $(echo { \"extraParameters\": \"\", \"blockIPs\": ${blockIPs}, \"relayIps\": ${relayIPs} } )
"
