#!/bin/bash


### REF: https://github.com/IntersectMBO/cardano-cli/blob/master/cardano-cli/test/cardano-cli-golden/files/golden/help.cli


# docker exec -it demo-cardano-node-1 /bin/bash

# inside the container, run:
# >>>

export CARDANO_NODE_SOCKET_PATH=/devnet/node.socket
export CARDANO_NODE_NETWORK_ID=42
source <(cardano-cli --bash-completion-script cardano-cli)
cardano-cli conway query protocol-parameters --out-file pparams.json


export ADDR_ALICE=addr_test1vru2drx33ev6dt8gfq245r5k0tmy7ngqe79va69de9dxkrg09c7d3
export ADDR_ALICE_FUNDS=addr_test1vp5cxztpc6hep9ds7fjgmle3l225tk8ske3rmwr9adu0m6qchmx5z
export ADDR_BOB=addr_test1vqg9ywrpx6e50uam03nlu0ewunh3yrscxmjayurmkp52lfskgkq5k
export ADDR_BOB_FUNDS=addr_test1vp0yug22dtwaxdcjdvaxr74dthlpunc57cm639578gz7algset3fh
export ADDR_CAROL=addr_test1vqa25t3aayfmpad20elswmsj94ehmdfjnhc64yz3jg5yl6skf5cck
export ADDR_CAROL_FUNDS=addr_test1vqx5tu4nzz5cuanvac4t9an4djghrx7hkdvjnnhstqm9kegvm6g6c
export ADDR_FAUCET=addr_test1vztc80na8320zymhjekl40yjsnxkcvhu58x59mc2fuwvgkc332vxv

cardano-cli query tip

# stake.plutus
# {
#     "cborHex": "5906da5....",
#     "description": "",
#     "type": "PlutusScriptV3"
# }
# script hash
cardano-cli hash script --script-file stake.plutus
# script stake address
cardano-cli conway stake-address build --stake-script-file stake.plutus --testnet-magic 42


# utxos by address
cardano-cli query utxo --address $(cat /devnet/credentials/addr1)



###
###
# socat to connect to Cardano node preview on Kubernetes DEV .61.4
sudo mkdir -p /var/local/indexer/preview
sudo chown dunght:dunght /var/local/indexer/preview
# 
sudo apt-get install -y socat
#
socat UNIX-LISTEN:/var/local/indexer/preview/node.socket,fork,reuseaddr,unlink-early, TCP:172.16.61.4:3334 &
ll /var/local/indexer/preview/node.socket
#
export CARDANO_NODE_SOCKET_PATH=/var/local/indexer/preview/node.socket
export CARDANO_NODE_NETWORK_ID=2
source <(cardano-cli --bash-completion-script cardano-cli)
#
cardano-cli query utxo --address $(< payment.addr)
###
###

#############################

###
###
# https://developers.cardano.org/docs/get-started/cardano-cli/plutus-scripts/
export CARDANO_NODE_NETWORK_ID=2

nano fortytwotyped.plutus
cardano-cli address build --payment-script-file fortytwotyped.plutus --out-file script.addr
cat script.addr

nano datum.json

cardano-cli address key-gen --verification-key-file payment.vkey --signing-key-file payment.skey
cardano-cli address build --payment-verification-key-file payment.vkey --out-file paymentNoStake.addr
cat paymentNoStake.addr

cardano-cli conway stake-address key-gen --verification-key-file stake.vkey --signing-key-file stake.skey
cat stake.vkey
cat stake.skey

cardano-cli conway address build --payment-verification-key-file payment.vkey --stake-verification-key-file stake.vkey --out-file payment.addr
cat payment.addr

# >>> get test ADA from Faucet Preview for payment.addr
cardano-cli query utxo --address $(< payment.addr)

# >>> lock ADA from payment.addr to script.addr
cardano-cli conway transaction build --tx-in $(cardano-cli conway query utxo --address $(< payment.addr) --output-json | jq -r 'keys[0]') --tx-out $(< script.addr)+10000000 --tx-out-inline-datum-file datum.json --change-address $(< payment.addr) --out-file lock.tx
cardano-cli conway transaction sign --tx-file lock.tx --signing-key-file payment.skey --out-file lock.tx.signed
cardano-cli conway transaction submit --tx-file lock.tx.signed

cardano-cli query utxo --address $(< script.addr) --output-json

# >>> unlock ADA from script.addr to payment.addr
cardano-cli conway transaction build 
  --tx-in $(cardano-cli conway query utxo --address $(< script.addr) --output-json | jq -r 'keys[0]') 
  --tx-in-collateral $(cardano-cli conway query utxo --address $(< payment.addr) --output-json | jq -r 'keys[0]') 
  --tx-in-script-file fortytwotyped.plutus 
  --tx-in-inline-datum-present 
  --tx-in-redeemer-value 57 
  --change-address $(< payment.addr) 
  --out-file unlock.tx
cardano-cli conway transaction sign --tx-file unlock.tx --signing-key-file payment.skey --out-file unlock.tx.signed
cardano-cli conway transaction submit --tx-file unlock.tx.signed
#
cardano-cli conway transaction build 
  --tx-in $(cardano-cli conway query utxo --address $(< script.addr) --output-json | jq -r 'keys[0]') 
  --tx-in-collateral $(cardano-cli conway query utxo --address $(< payment.addr) --output-json | jq -r 'keys[0]') 
  --tx-in-script-file fortytwotyped.plutus 
  --tx-in-inline-datum-present 
  --tx-in-redeemer-value 42 
  --change-address $(< payment.addr) 
  --out-file unlock.tx
cardano-cli conway transaction sign --tx-file unlock.tx --signing-key-file payment.skey --out-file unlock.tx.signed
cardano-cli conway transaction submit --tx-file unlock.tx.signed
# -> error (no datum / incorrectly submitted by s/o else)
#
cardano-cli conway query utxo --address $(< script.addr) --output-json
cardano-cli conway transaction build 
  --tx-in $(cardano-cli conway query utxo --address $(< script.addr) --output-json | jq -r 'keys[1]') 
  --tx-in-collateral $(cardano-cli conway query utxo --address $(< payment.addr) --output-json | jq -r 'keys[0]') 
  --tx-in-script-file fortytwotyped.plutus 
  --tx-in-inline-datum-present 
  --tx-in-redeemer-value 42 
  --change-address $(< payment.addr) 
  --out-file unlock.tx
# -> error
#
cardano-cli conway transaction build 
  --tx-in $(cardano-cli conway query utxo --address $(< script.addr) --output-json | jq -r 'keys[2]') 
  --tx-in-collateral $(cardano-cli conway query utxo --address $(< payment.addr) --output-json | jq -r 'keys[0]') 
  --tx-in-script-file fortytwotyped.plutus 
  --tx-in-inline-datum-present 
  --tx-in-redeemer-value 42 
  --change-address $(< payment.addr) 
  --out-file unlock.tx
cardano-cli conway transaction sign --tx-file unlock.tx --signing-key-file payment.skey --out-file unlock.tx.signed
cardano-cli conway transaction submit --tx-file unlock.tx.signed
###
###

#############################

###
###
# https://developers.cardano.org/docs/get-started/cardano-cli/native-assets/#minting-a-new-native-token
cardano-cli address key-gen \
    --verification-key-file policy.vkey \
    --signing-key-file policy.skey
# MINT >>>
cardano-cli address key-hash --payment-verification-key-file policy.vkey
nano policy.script
# {
#   "keyHash": "3c293ef7fa09577e8a656016d59abe042ed9fe38cdfd9d81568450c6",
#   "type": "sig"
# }
cat policy.script
#
# policyId
cardano-cli hash script --script-file policy.script
# asset name
echo -n "pokemoney" | xxd -ps
#
cardano-cli query protocol-parameters --out-file pparams.json
#
cardano-cli conway transaction build --tx-in $(cardano-cli conway query utxo --address $(< payment.addr) --output-json | jq -r 'keys[2]') --tx-out $(< payment.addr)+10000000+"9191 7414fa48f5b31f0a4ff57b05f934116540076d4b4970de3ae9ad14c1.706f6b656d6f6e6579" --mint "9191 7414fa48f5b31f0a4ff57b05f934116540076d4b4970de3ae9ad14c1.706f6b656d6f6e6579" --mint-script-file policy.script --change-address $(< payment.addr) --out-file mint-tx.raw
cardano-cli conway transaction sign --tx-file mint-tx.raw --signing-key-file policy.skey --signing-key-file payment.skey --out-file mint-tx.signed
cardano-cli debug transaction view --tx-file mint-tx.signed
cardano-cli conway transaction submit --tx-file mint-tx.signed
cardano-cli query utxo --address $(< payment.addr)
# 
# TRANSFER >>>
cardano-cli conway transaction calculate-min-required-utxo --protocol-params-file pparams.json --tx-out addr_test1qpuktx90cvmc0vy6qdnz9ka6t53s67wrsvnn06p5c4gf6pkecmllpm3xpffylwhj9gjztqxfer2mv7p47txj0hy22p7slc3qkg+"9100 7414fa48f5b31f0a4ff57b05f934116540076d4b4970de3ae9ad14c1.706f6b656d6f6e6579"
cardano-cli conway transaction build
  --tx-in 9c5cc125a15ed267b90f0142f63c4eb996498b36bb7e34641696486a394ae173#0 --tx-out addr_test1qpuktx90cvmc0vy6qdnz9ka6t53s67wrsvnn06p5c4gf6pkecmllpm3xpffylwhj9gjztqxfer2mv7p47txj0hy22p7slc3qkg+1168010+"9100 7414fa48f5b31f0a4ff57b05f934116540076d4b4970de3ae9ad14c1.706f6b656d6f6e6579" --tx-out $(< payment.addr)+8831990+"91 7414fa48f5b31f0a4ff57b05f934116540076d4b4970de3ae9ad14c1.706f6b656d6f6e6579"  --change-address $(< payment.addr) --out-file transfer.raw
cardano-cli conway transaction build --tx-in 9c5cc125a15ed267b90f0142f63c4eb996498b36bb7e34641696486a394ae173#1 
  --tx-in 9c5cc125a15ed267b90f0142f63c4eb996498b36bb7e34641696486a394ae173#0 --tx-out addr_test1qpuktx90cvmc0vy6qdnz9ka6t53s67wrsvnn06p5c4gf6pkecmllpm3xpffylwhj9gjztqxfer2mv7p47txj0hy22p7slc3qkg+1168010+"9100 7414fa48f5b31f0a4ff57b05f934116540076d4b4970de3ae9ad14c1.706f6b656d6f6e6579" --tx-out $(< payment.addr)+8831990+"91 7414fa48f5b31f0a4ff57b05f934116540076d4b4970de3ae9ad14c1.706f6b656d6f6e6579"  --change-address $(< payment.addr) --out-file transfer.raw
cardano-cli conway transaction sign --signing-key-file payment.vkey --out-file transfer.signed
cardano-cli conway transaction sign --signing-key-file payment.vkey --tx-file transfer.raw --out-file transfer.signed
cardano-cli conway transaction sign --tx-file transfer.raw --signing-key-file payment.skey --out-file transfer.signed
cardano-cli conway transaction submit --tx-file transfer.signed
cardano-cli query utxo --address $(< payment.addr)
#
# BURN >>>
cardano-cli conway transaction build --tx-in e1fa13314e3dbcdd286df7f91f06dc8d31a9175442e58f77d52f3faf4e73d33a#2 --tx-in e1fa13314e3dbcdd286df7f91f06dc8d31a9175442e58f77d52f3faf4e73d33a#1 --mint="-72 7414fa48f5b31f0a4ff57b05f934116540076d4b4970de3ae9ad14c1.706f6b656d6f6e6579" --tx-out $(< payment.addr)+8831990+"19 7414fa48f5b31f0a4ff57b05f934116540076d4b4970de3ae9ad14c1.706f6b656d6f6e6579" --change-address $(< payment.addr) --out-file burn.raw
cardano-cli conway transaction build --tx-in e1fa13314e3dbcdd286df7f91f06dc8d31a9175442e58f77d52f3faf4e73d33a#2 --tx-in e1fa13314e3dbcdd286df7f91f06dc8d31a9175442e58f77d52f3faf4e73d33a#1 --mint="-72 7414fa48f5b31f0a4ff57b05f934116540076d4b4970de3ae9ad14c1.706f6b656d6f6e6579" --mint-script-file policy.script --tx-out $(< payment.addr)+8831990+"19 7414fa48f5b31f0a4ff57b05f934116540076d4b4970de3ae9ad14c1.706f6b656d6f6e6579" --change-address $(< payment.addr) --out-file burn.raw
cardano-cli conway transaction sign --tx-file burn.raw --signing-key-file policy.skey --signing-key-file payment.skey --out-file burn.signed
cardano-cli conway transaction submit --tx-file burn.signed
cardano-cli query utxo --address $(< payment.addr)
###
###

#############################

###
###
# https://developers.cardano.org/docs/get-started/cardano-cli/simple-scripts/#example-of-using-a-script-for-multi-signatures
cardano-cli address key-hash --payment-verification-key-file alice.vk
cardano-cli address key-hash --payment-verification-key-file bob.vk
cardano-cli address key-hash --payment-verification-key-file carol.vk
code allMultiSigScript.json
cardano-cli address build --payment-script-file allMultiSigScript.json --out-file allMultiSigScript.addr
cat allMultiSigScript.addr
#
cardano-cli query utxo --address $(< payment.addr) --output-json
#
cardano-cli conway transaction build 
  --tx-in 650183cd364227506278dfe420c2896f3caf67b2d5649c21e920edfd14251455#0 
  --tx-in-script-file allMultiSigScript.json 
  --tx-out "addr_test1qpuktx90cvmc0vy6qdnz9ka6t53s67wrsvnn06p5c4gf6pkecmllpm3xpffylwhj9gjztqxfer2mv7p47txj0hy22p7slc3qkg+$((99123456))" 
  --change-address $(< payment.addr) 
  --out-file txbody2
cardano-cli conway transaction build 
  --tx-in 650183cd364227506278dfe420c2896f3caf67b2d5649c21e920edfd14251455#0 
  --tx-in-script-file allMultiSigScript.json 
  --tx-out "addr_test1qpuktx90cvmc0vy6qdnz9ka6t53s67wrsvnn06p5c4gf6pkecmllpm3xpffylwhj9gjztqxfer2mv7p47txj0hy22p7slc3qkg+$((99123456-181385))" 
  --change-address $(< payment.addr) 
  --out-file txbody2
cardano-cli conway transaction build 
  --tx-in 650183cd364227506278dfe420c2896f3caf67b2d5649c21e920edfd14251455#0 
  --tx-in-script-file allMultiSigScript.json 
  --tx-out "addr_test1qpuktx90cvmc0vy6qdnz9ka6t53s67wrsvnn06p5c4gf6pkecmllpm3xpffylwhj9gjztqxfer2mv7p47txj0hy22p7slc3qkg+$((99123456-181385-176))" 
  --change-address $(< payment.addr) 
  --out-file txbody2
cardano-cli debug transaction view --tx-body-file txbody2
#
cardano-cli conway transaction witness --tx-body-file txbody2 --signing-key-file alice.sk --out-file tx2witness1
cardano-cli conway transaction witness --tx-body-file txbody2 --signing-key-file bob.sk   --out-file tx2witness2
cardano-cli conway transaction witness --tx-body-file txbody2 --signing-key-file carol.sk --out-file tx2witness3
#
cardano-cli conway transaction assemble 
  --tx-body-file txbody2 
  --witness-file tx2witness1 
  --witness-file tx2witness2 
  --witness-file tx2witness3 
  --out-file spendMultiSig
cardano-cli conway transaction submit --tx-file spendMultiSig

