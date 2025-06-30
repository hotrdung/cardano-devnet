#/bin/bash

# for: https://hydra.family/head-protocol/docs/how-to/submit-transaction
cardano-cli conway transaction build-raw \
    --tx-in c9a5fb7ca6f55f07facefccb7c5d824eed00ce18719d28ec4c4a2e4041e85d97#0 \
    --tx-out addr_test1vp0yug22dtwaxdcjdvaxr74dthlpunc57cm639578gz7algset3fh+22000000 \
    --tx-out addr_test1vp5cxztpc6hep9ds7fjgmle3l225tk8ske3rmwr9adu0m6qchmx5z+78000000 \
    --fee 0 \
    --out-file tx.json

cardano-cli conway transaction sign \
    --tx-body-file tx.json \
    --signing-key-file devnet/credentials/alice-funds.sk \
    --out-file tx-signed.json

cat tx-signed.json | jq -c '{tag: "NewTx", transaction: .}' | websocat "ws://127.0.0.1:4001?history=no"



wget https://github.com/CardanoSolutions/kupo/releases/download/v2.11/kupo-v2.11.0-x86_64-linux.zip
unzip kupo-v2.11.0-x86_64-linux.zip
mv kupo ~
nano ~/.bashrc
# export PATH="~/kupo/bin:${PATH}"
# source ~/kupo/share/bash-completion/completions/kupo
source ~/.bashrc

kupo --hydra-host localhost --hydra-port 4001 --since origin --match "*" --in-memory

curl http://localhost:1442/matches/addr_test1vp5cxztpc6hep9ds7fjgmle3l225tk8ske3rmwr9adu0m6qchmx5z

