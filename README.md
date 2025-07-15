# cardano-devnet

This is based on Hydra demo project: https://github.com/cardano-scaling/hydra/tree/master/demo

## Reset / Cleanup
```
./reset-devnet.sh
```

## Start services
### normal
```
./run-docker.sh
```

### with Hydra
```
./run-docker.sh --hydra
```

## Using Cardano-CLI
**NOTE**: `~/node.socket` will be overwritten
```
export CARDANO_NODE_SOCKET_PATH=~/node.socket
export CARDANO_NODE_NETWORK_ID=42
source <(cardano-cli --bash-completion-script cardano-cli)
```

## Usages
* https://github.com/hotrdung/aiken-tutor/blob/master/hello-world/ccli.sh
