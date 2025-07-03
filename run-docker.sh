#!/usr/bin/env bash
#
# Prepare environment to run the demo cluster, then launches docker compose
# demo. If there's already a demo running, bail out.
set -e

SCRIPT_DIR=$(dirname $(realpath $0))

cd ${SCRIPT_DIR}

DOCKER_COMPOSE_CMD=
if docker compose --version > /dev/null 2>&1; then
  DOCKER_COMPOSE_CMD="docker compose"
else
  DOCKER_COMPOSE_CMD="docker-compose"
fi

# Sanity check to prevent accidentally tripping oneself with an existing demo
if ( ${DOCKER_COMPOSE_CMD} ps | grep hydra-node > /dev/null 2>&1 ); then
  echo >&2 -e "# Demo already in progress, exiting"
  echo >&2 -e "# To stop the demo use: ${DOCKER_COMPOSE_CMD} down"
  exit 1
fi

"${SCRIPT_DIR}/prepare-devnet.sh"

${DOCKER_COMPOSE_CMD} up -d cardano-node
${DOCKER_COMPOSE_CMD} up -d postgres

"${SCRIPT_DIR}/seed-devnet.sh"

${DOCKER_COMPOSE_CMD} up -d hydra-node-{1,2,3}

${DOCKER_COMPOSE_CMD} up -d cardano-db-sync

${DOCKER_COMPOSE_CMD} up -d blockfrost-ryo
${DOCKER_COMPOSE_CMD} up -d ogmios
${DOCKER_COMPOSE_CMD} up -d kupo

echo >&2 -e "\n# Launch TUI on hydra-node-1: ${DOCKER_COMPOSE_CMD} run hydra-tui-1"
echo >&2 -e "\n# Stop the demo: ${DOCKER_COMPOSE_CMD} down\n"
# ${DOCKER_COMPOSE_CMD} run hydra-tui-1

# # create alias `fix-db-sync`
# alias fix-db-sync="docker exec -e PGPASSWORD=$(< dbsync-config/secrets/postgres_password) demo-postgres-1 psql -U \$(< dbsync-config/secrets/postgres_user) -d \$(< dbsync-config/secrets/postgres_db) -c \"SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE query ILIKE '%CREATE INDEX IF NOT EXISTS idx_epoch_stake_pool_id ON epoch_stake(pool_id)%' AND state = 'active';\""

# echo >&2 -e "\n# Run this after 60s to fix DB-Sync hanging issue:"
# echo "docker exec -e PGPASSWORD=\$(< dbsync-config/secrets/postgres_password) demo-postgres-1 psql -U \$(< dbsync-config/secrets/postgres_user) -d \$(< dbsync-config/secrets/postgres_db) -c \"SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE query ILIKE '%CREATE INDEX IF NOT EXISTS idx_epoch_stake_pool_id ON epoch_stake(pool_id)%' AND state = 'active';\""
# echo -e "  -- OR --"
# echo "fix-db-sync"
# echo -e "\n\n"

