#!/bin/bash

curl localhost:1337/health
curl localhost:3000/blocks/latest
curl localhost:1442/health


source <( cardano-address --bash-completion-script `which cardano-address`)

## GENERATE KEYS & ADDRESSES
# https://developers.cardano.org/docs/get-started/cardano-cli/get-started/#generating-keys-and-addresses
# https://github.com/IntersectMBO/cardano-addresses

# 1. Generate a mnemonic (15 or 24 words)
cardano-address recovery-phrase generate --size 24 > mnemonic.txt

# 2. Convert the mnemonic to a **E(X)tended root (PR)i(V)ate key**
cardano-address key from-recovery-phrase Shelley < mnemonic.txt > root.xsk
# cat root.xsk
# --> root_xsk16qtcxhmga666e0hshgktssad3hq8zygnjpf5say24ptf8uxh9prnlnsckdml00n0kppp3e2wtqv0zv8vl7glhhkdcnxt3muytl896uczgq7h5fdamvudlkaytjcjjz4c2xltja8mgjzceqqtnkepzd8j55ep5j9y

# 3. encode it back to Bech32 for display
bech32 xprv < root.xsk
# --> xprv16qtcxhmga666e0hshgktssad3hq8zygnjpf5say24ptf8uxh9prnlnsckdml00n0kppp3e2wtqv0zv8vl7glhhkdcnxt3muytl896uczgq7h5fdamvudlkaytjcjjz4c2xltja8mgjzceqqtnkepzd8j55jva356

# use the above value to init MeshWallet:
#   key: {
#     type: 'root',
#     bech32: 'xprv16qtcxhmga666e0hshgktssad3hq8zygnjpf5say24ptf8uxh9prnlnsckdml00n0kppp3e2wtqv0zv8vl7glhhkdcnxt3muytl896uczgq7h5fdamvudlkaytjcjjz4c2xltja8mgjzceqqtnkepzd8j55jva356',
#   },
# --> Mesh wallet changeAddress: addr_test1qpse7xqay7zjx8vrqkpuyxxkum70hcvz86jdxz9td5c8pxwz89h6y59fanmeweaj5wjn3gjsc5et5d4sd37dlfxlfj3swqwzjj
#                                (has both payment and stake parts)


# wallet & account IDs
# https://github.com/IntersectMBO/cardano-addresses?tab=readme-ov-file#how-to-generate-a-private-policy-key-policyxsk-a-public-policy-key-policyvk-and-its-hash-policyvkh
cardano-address key walletid < root.xsk
cardano-address key child 1852H/1815H/0H < root.xsk > acct.xsk
cardano-address key walletid < acct.xsk
# ---
cardano-address key child 1855H/1815H/0H < root.xsk > policy.xsk
cardano-address key child 1855H/1815H/0H < root.xsk | cardano-address key public --with-chain-code > policy.xvk
cardano-address key child 1855H/1815H/0H < root.xsk | cardano-address key public --without-chain-code > policy.vk

cardano-address key child 1852H/1815H/0H/0/0 < root.xsk | cardano-address key public --with-chain-code > addr.xvk
# 4. Derive child keys (e.g., e(X)tended (S)igning payment/stake (K)eys)
# From the root private key you can derive standard BIP-44 path
# acc:0 role:0(payment) keyIdx:0
cardano-address key child 1852H/1815H/0H/0/0 < root.xsk > addr.xsk
# --> addr_xsk13rwrae529xpuk40a6c4r4m3x5ce9tfnymyv0lvrq3dd92zkc9prc4afxvvm9lqjd3ru8tp0etzt57q908r7c7w8jf30pv59yzc8005j2vpf3u5exk65rury5790yuxk949qk0jf5cyd9957kxzc2tfkdm5nhuh6p
# acc:0 role:2(stake) keyIdx:0
cardano-address key child 1852H/1815H/0H/2/0 < root.xsk > stake.xsk
# --> stake_xsk1sznq5lkt733a02sk8u5uwf8edrgugld73klvamp72mxuuzwc9prsgcpwd73hhvx3e74f88kr0gwkxn936tl870zg4c4lktd4njaed42dwkvellyvf7t5xh6yv4jjdx6xs398aartrehgvq9a8pxyhcem7qms0ezq

# 5. Optional: Get extended public keys
cardano-address key public --with-chain-code < addr.xsk > addr.xvk
# --> addr_xvk1swrgqkjcfuqf0y6gacka25t7mypaktfycpymumk0s6y5y9zrlasy5cznrefjdd4g8cxffu27fcdvt22pvlynfsg62tfavv9s5knvmhg8erphq
cardano-address key public --with-chain-code < stake.xsk > stake.xvk
# --> stake_xvk1nzhvedrppt7nr4yurt8g4ft56tqdytl0zwnqzwaty0pdjm630dry6avenl7gcnuhgd05get9y6d5dpz20m6xk8nwscqt6wzvf03nhuqrsu5gg
# 
# -- or --
#
# Get non-extended public keys
cardano-address key public --without-chain-code < addr.xsk > addr.vk
# --> addr_vk1swrgqkjcfuqf0y6gacka25t7mypaktfycpymumk0s6y5y9zrlasq64ehz8
cardano-address key public --without-chain-code < stake.xsk > stake.vk
# --> stake_vk1nzhvedrppt7nr4yurt8g4ft56tqdytl0zwnqzwaty0pdjm630drqvylhsl


cardano-address key hash < addr.xvk > addr.vkh
cardano-address key hash < stake.xvk > stake.vkh
# note:
# ```bech32 < addr.vkh```
# is equivalent to:
# ```blake2b 224 $(cat addr.vk | bech32)```

# 6. Optional: Generate an address

## Enterprise address
# https://chatgpt.com/share/688425dc-b534-8007-a9f2-0804ef3ae234
# (vk is no longer supported)
cardano-address address payment --network-tag 0 < addr.xvk > payment.addr
# --> addr_test1vpse7xqay7zjx8vrqkpuyxxkum70hcvz86jdxz9td5c8pxg28sd08
bech32 <<< $(< payment.addr)
# --> (60)619f181d2785231d830583c218d6e6fcfbe1823ea4d308ab6d307099
# or
cardano-cli address build \
--payment-verification-key-file addr.vk \
--out-file payment.addr


## Base address
cardano-address address delegation $(cat stake.xvk) < payment.addr > base.addr
# or
cardano-cli address build \
--payment-verification-key-file addr.vk \
--stake-verification-key-file stake.vk \
--out-file base.addr


# https://github.com/IntersectMBO/cardano-addresses?tab=readme-ov-file#how-to-inspect-address
cat base.addr | cardano-address address inspect


export FAUCET_ADDR=$(cardano-cli conway address build --payment-verification-key-file ../devnet/credentials/faucet.vk)

cardano-cli conway transaction build \
  --tx-in $(cardano-cli conway query utxo --address $FAUCET_ADDR --output-json | jq -r 'keys[0]') \
  --tx-out $(< base.addr)+111000000 \
  --change-address $FAUCET_ADDR \
  --out-file transfer.tx

cardano-cli conway transaction sign \
  --tx-file transfer.tx \
  --signing-key-file ../devnet/credentials/faucet.sk \
  --out-file transfer.tx.signed

cardano-cli conway transaction submit --tx-file transfer.tx.signed


curl -s localhost:3000/addresses/addr_test1qpse7xqay7zjx8vrqkpuyxxkum70hcvz86jdxz9td5c8pxwz89h6y59fanmeweaj5wjn3gjsc5et5d4sd37dlfxlfj3swqwzjj | jq
curl -s localhost:3000/addresses/addr_test1vpse7xqay7zjx8vrqkpuyxxkum70hcvz86jdxz9td5c8pxg28sd08 | jq

curl -s localhost:1442/matches/addr_test1qpse7xqay7zjx8vrqkpuyxxkum70hcvz86jdxz9td5c8pxwz89h6y59fanmeweaj5wjn3gjsc5et5d4sd37dlfxlfj3swqwzjj | jq
curl -s localhost:1442/matches/addr_test1vpse7xqay7zjx8vrqkpuyxxkum70hcvz86jdxz9td5c8pxg28sd08 | jq


curl --location 'http://localhost:1337/' \
--header 'Content-Type: application/json' \
--data '{
    "jsonrpc": "2.0",
    "method": "queryLedgerState/rewardAccountSummaries",
    "params": {
        "keys": [
            "stake1ux3tylnpy36ky8lzt32p3y8qudt39lc9vmcce0lp6wcv23q2mlpa7"
        ]
    }
}'


curl --location 'http://localhost:1337/' \
--header 'Content-Type: application/json' \
--data '{
    "jsonrpc": "2.0",
    "method": "queryLedgerState/protocolParameters",
}'

