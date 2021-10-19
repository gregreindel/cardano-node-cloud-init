echo "
- path: /etc/prometheus/prometheus.yml
  permissions: \"750\"
  content: |
    global:
      scrape_interval: 15s
    scrape_configs:
      - job_name: 'prometheus'"
if [ ! -z $BLOCK_NODE_IP_1 ]; then 
echo "
        static_configs:
          - targets: ['${BLOCK_NODE_IP_1}:9100']
            labels:
              alias: 'block-producer-node'
              type:  'cardano-node'

        - targets: ['${BLOCK_NODE_IP_1}:12798']
            labels:
              alias: 'block-producer-node'
              type:  'cardano-node'"
fi
if [ ! -z $RELAY_NODE_IP_1 ]; then 
echo "
        static_configs:
          - targets: ['${RELAY_NODE_IP_1}:9100']
            labels:
              alias: 'relay-node-1'
              type:  'cardano-node'

        - targets: ['${RELAY_NODE_IP_1}:12798']
            labels:
              alias: 'relay-node-1'
              type:  'cardano-node'"
fi
if [ ! -z $RELAY_NODE_IP_2 ]; then 
echo "
        static_configs:
          - targets: ['${RELAY_NODE_IP_2}:9100']
            labels:
              alias: 'relay-node-2'
              type:  'cardano-node'

        - targets: ['${RELAY_NODE_IP_2}:12798']
            labels:
              alias: 'relay-node-2'
              type:  'cardano-node'"
fi