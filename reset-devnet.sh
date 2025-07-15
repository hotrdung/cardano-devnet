#!/bin/bash

docker compose down

# Force remove volumes and ignore errors if they don't exist. Also fixed typo 'demno' -> 'demo'.
echo "Removing volumes...."
docker volume rm -f demo_db-sync-data demo_postgres demo_db-kupo demo_db-wallet || true

# Find TUI containers. If any exist, stop and remove them.
TUI_CONTAINERS=$(docker ps -a -q --filter "name=demo-hydra-tui-*")
if [ -n "$TUI_CONTAINERS" ]; then
  echo "Stopping and removing TUI containers..."
  docker stop $TUI_CONTAINERS && docker rm $TUI_CONTAINERS
fi

TARGETDIR=${TARGETDIR:-devnet}

if [ -d "${TARGETDIR}" ] || [ -d "keys" ]; then
  sudo rm -rf "$TARGETDIR" keys
fi

BLOCKFROST_BASEDIR="blockfrost-config"
rm -f $BLOCKFROST_BASEDIR/*_genesis.json
