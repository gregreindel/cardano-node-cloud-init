

# If address balance is not enough for transaction + fee ...
if [ ${total_balance} -lt ${stakePoolDeposit} ]; then
echo "Not enough ADA. You need to send funds to your payment address.
echo "Deposit |  ${stakePoolDeposit} ($(. ${NODE_SCRIPTS_PATH}/toADA.sh ${stakePoolDeposit}) ADA)"
echo "----------------""
echo "Total   |  $( ${stakePoolDeposit}+${fee} ) ($(. ${NODE_SCRIPTS_PATH}/toADA.sh $( ${stakePoolDeposit}+${fee} )) ADA)"
"
You have ${total_balance} ($(. ${NODE_SCRIPTS_PATH}/toADA.sh ${total_balance}) ADA)"
echo "Send at least ${stakePoolDeposit} lovelace ($(. ${NODE_SCRIPTS_PATH}/toADA.sh ${stakePoolDeposit}) ADA) to $(cat ${NODE_PRIVATE_PATH}/payment.addr)"
return
fi