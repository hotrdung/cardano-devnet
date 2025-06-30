#!/usr/bin/env bash

# Prepare a "devnet" directory holding credentials, a dummy topology and
# "up-to-date" genesis files. If the directory exists, it is wiped out.
set -eo pipefail
SCRIPT_DIR=$(dirname $(realpath $0))

if [ -f "$SCRIPT_DIR/.env" ]; then
  echo "Reading configuration from .env file."
  source "$SCRIPT_DIR/.env"
fi

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

echo '{"Producers": []}' > "$TARGETDIR/topology.json"
sed -i.bak "s/\"startTime\": [0-9]*/\"startTime\": $(date +%s)/" "$TARGETDIR/genesis-byron.json" && \
sed -i.bak "s/\"systemStart\": \".*\"/\"systemStart\": \"$(date -u +%FT%TZ)\"/" "$TARGETDIR/genesis-shelley.json"

find $TARGETDIR -type f -name '*.skey' -exec chmod 0400 {} \;

mkdir "$TARGETDIR/ipc"

echo "Computing and adding genesis hashes to $TARGETDIR/cardano-node.json"
JSON_FILE="$TARGETDIR/cardano-node.json"
TMP_JSON_FILE="${JSON_FILE}.tmp"

# echo "Copying files from HYDRA source"
# cp "$HYDRA_BASEDIR/demo/seed-devnet.sh" .
# # also copy .env if it does not exist in the current directory
# if [ ! -f .env ]; then
#   cp "$HYDRA_BASEDIR/demo/.env" .
# fi

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

echo "Prepared devnet, you can start the cluster now"
