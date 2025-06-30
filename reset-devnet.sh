#!/bin/bash

docker compose down
# Force remove volumes and ignore errors if they don't exist. Also fixed typo 'demno' -> 'demo'.
docker volume rm -f demo_db-sync-data demo_postgres demo_db-kupo || true

# Find TUI containers. If any exist, stop and remove them.
TUI_CONTAINERS=$(docker ps -a -q --filter "name=demo-hydra-tui-*")
if [ -n "$TUI_CONTAINERS" ]; then
  echo "Stopping and removing TUI containers..."
  docker stop $TUI_CONTAINERS && docker rm $TUI_CONTAINERS
fi

sudo rm -rf devnet
sudo rm -rf keys
