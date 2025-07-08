#!/usr/bin/env bash

# Prepare a "devnet" directory holding credentials, a dummy topology and
# "up-to-date" genesis files. If the directory exists, it is wiped out.
set -eo pipefail
SCRIPT_DIR=$(dirname $(realpath $0))

if [ -f "$SCRIPT_DIR/.env" ]; then
  echo "Reading configuration from .env file."
  source "$SCRIPT_DIR/.env"
fi

BLOCKFROST_BASEDIR="$SCRIPT_DIR/blockfrost-config"

if [ -z "$HYDRA_BASEDIR" ]; then
  echo "HYDRA_BASEDIR not set. Cloning from https://github.com/cardano-scaling/hydra.git"
  HYDRA_BASEDIR="$SCRIPT_DIR/hydra_src"
  if [ ! -d "$HYDRA_BASEDIR" ]; then
    git clone https://github.com/cardano-scaling/hydra.git "$HYDRA_BASEDIR"
  fi
  HYDRA_BASEDIR=$(realpath "$HYDRA_BASEDIR")
fi

TARGETDIR=${TARGETDIR:-devnet}

[ -d "$TARGETDIR" ] && { echo "Cleaning up directory $TARGETDIR" ; rm -rf $TARGETDIR ; }

cp -af "$HYDRA_BASEDIR/hydra-cluster/config/devnet" "$TARGETDIR"
chmod -R u+w  "$TARGETDIR"
cp -af "$HYDRA_BASEDIR/hydra-cluster/config/credentials" "$TARGETDIR"
chmod -R u+w "$TARGETDIR"

START_TIMESTAMP=$(date +%s)
START_DATETIME=$(date -u +%FT%TZ)

echo '{"Producers": []}' > "$TARGETDIR/topology.json"
sed -i.bak "s/\"startTime\": [0-9]*/\"startTime\": $START_TIMESTAMP/" "$TARGETDIR/genesis-byron.json" && \
sed -i.bak "s/\"systemStart\": \".*\"/\"systemStart\": \"$START_DATETIME\"/" "$TARGETDIR/genesis-shelley.json"

find $TARGETDIR -type f -name '*.skey' -exec chmod 0400 {} \;

mkdir "$TARGETDIR/ipc"

echo "Copying files from HYDRA source"
cp "$HYDRA_BASEDIR/demo/seed-devnet.sh" .
mkdir -p ./keys
cp $HYDRA_BASEDIR/demo/*.sk ./keys
cp $HYDRA_BASEDIR/demo/*.vk ./keys
# # also copy .env if it does not exist in the current directory
# if [ ! -f .env ]; then
#   cp "$HYDRA_BASEDIR/demo/.env" .
# fi

echo "Computing and adding genesis hashes to $TARGETDIR/cardano-node.json"
JSON_FILE="$TARGETDIR/cardano-node.json"
TMP_JSON_FILE="${JSON_FILE}.tmp"

# Calculate genesis hashes using appropriate cardano-cli commands
BYRON_HASH=$(cardano-cli byron genesis print-genesis-hash --genesis-json "$TARGETDIR/genesis-byron.json")
SHELLEY_HASH=$(cardano-cli hash genesis-file --genesis "$TARGETDIR/genesis-shelley.json")
ALONZO_HASH=$(cardano-cli hash genesis-file --genesis "$TARGETDIR/genesis-alonzo.json")
CONWAY_HASH=$(cardano-cli hash genesis-file --genesis "$TARGETDIR/genesis-conway.json")

# Add hashes to the JSON file using jq
jq \
  --arg byronHash "$BYRON_HASH" \
  --arg shelleyHash "$SHELLEY_HASH" \
  --arg alonzoHash "$ALONZO_HASH" \
  --arg conwayHash "$CONWAY_HASH" \
  '. + {
    "ByronGenesisHash": $byronHash,
    "ShelleyGenesisHash": $shelleyHash,
    "AlonzoGenesisHash": $alonzoHash,
    "ConwayGenesisHash": $conwayHash
  }' \
  "$JSON_FILE" > "$TMP_JSON_FILE" && mv "$TMP_JSON_FILE" "$JSON_FILE"

echo "Preparing Blockfrost config files"
mkdir -p $BLOCKFROST_BASEDIR
cp "$TARGETDIR/genesis-alonzo.json" $BLOCKFROST_BASEDIR/alonzo_genesis.json
cp "$TARGETDIR/genesis-byron.json" $BLOCKFROST_BASEDIR/byron_genesis.json
cp "$TARGETDIR/genesis-conway.json" $BLOCKFROST_BASEDIR/conway_genesis.json
cp "$TARGETDIR/genesis-shelley.json" $BLOCKFROST_BASEDIR/shelley_genesis.json

sed -i.bak "s/\"system_start\": [0-9]*/\"startTime\": $START_TIMESTAMP/" "$BLOCKFROST_BASEDIR/genesis.json" && \
sed -i.bak "s/\"epoch_length\": [0-9]*/\"epoch_length\": $(cat $BLOCKFROST_BASEDIR/shelley_genesis.json | jq -r ".epochLength")/" "$BLOCKFROST_BASEDIR/genesis.json" && \
sed -i.bak "s/\"slot_length\": [0-9\.]*/\"slot_length\": $(cat $BLOCKFROST_BASEDIR/shelley_genesis.json | jq -r ".slotLength")/" "$BLOCKFROST_BASEDIR/genesis.json"
sed -i.bak "s/\"active_slots_coefficient\": [0-9\.]*/\"active_slots_coefficient\": $(cat $BLOCKFROST_BASEDIR/shelley_genesis.json | jq -r ".activeSlotsCoeff")/" "$BLOCKFROST_BASEDIR/genesis.json"
sed -i.bak "s/\"max_lovelace_supply\": \"[0-9]*\"/\"max_lovelace_supply\": \"$(cat $BLOCKFROST_BASEDIR/shelley_genesis.json | jq -r ".maxLovelaceSupply")\"/" "$BLOCKFROST_BASEDIR/genesis.json" && \
sed -i.bak "s/\"max_kes_evolutions\": [0-9]*/\"max_kes_evolutions\": $(cat $BLOCKFROST_BASEDIR/shelley_genesis.json | jq -r ".maxKESEvolutions")/" "$BLOCKFROST_BASEDIR/genesis.json" && \
sed -i.bak "s/\"slots_per_kes_period\": [0-9]*/\"slots_per_kes_period\": $(cat $BLOCKFROST_BASEDIR/shelley_genesis.json | jq -r ".slotsPerKESPeriod")/" "$BLOCKFROST_BASEDIR/genesis.json" && \
sed -i.bak "s/\"network_magic\": [0-9]*/\"network_magic\": $(cat $BLOCKFROST_BASEDIR/shelley_genesis.json | jq -r ".networkMagic")/" "$BLOCKFROST_BASEDIR/genesis.json" && \
sed -i.bak "s/\"security_param\": [0-9]*/\"security_param\": $(cat $BLOCKFROST_BASEDIR/shelley_genesis.json | jq -r ".securityParam")/" "$BLOCKFROST_BASEDIR/genesis.json" && \
sed -i.bak "s/\"update_quorum\": [0-9]*/\"update_quorum\": $(cat $BLOCKFROST_BASEDIR/shelley_genesis.json | jq -r ".updateQuorum")/" "$BLOCKFROST_BASEDIR/genesis.json" && \

echo "Prepared devnet, you can start the cluster now"
