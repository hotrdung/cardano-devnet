#!/usr/bin/env bash
#
# Prepare environment to run the demo cluster, then launches docker compose
# demo. If there's already a demo running, bail out.
set -e

SCRIPT_DIR=$(dirname $(realpath $0))

if [ -f "$SCRIPT_DIR/.env" ]; then
  echo "Reading configuration from .env file."
  source "$SCRIPT_DIR/.env"
fi

# Check for --hydra flag
with_hydra=false
for arg in "$@"; do
  if [[ "$arg" == "--hydra" ]]; then
    with_hydra=true
    break
  fi
done

cd ${SCRIPT_DIR}

TARGETDIR=${TARGETDIR:-devnet}
# echo $TARGETDIR

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

if [ "$with_hydra" = true ]; then
  echo "Running with Hydra nodes."

  "${SCRIPT_DIR}/seed-devnet.sh"

  ${DOCKER_COMPOSE_CMD} up -d hydra-node-{1,2,3}
fi

${DOCKER_COMPOSE_CMD} up -d cardano-db-sync

${DOCKER_COMPOSE_CMD} up -d blockfrost-ryo
${DOCKER_COMPOSE_CMD} up -d ogmios
${DOCKER_COMPOSE_CMD} up -d kupo
${DOCKER_COMPOSE_CMD} up -d cardano-wallet

if [ -n "${TX_WATCHER_IMAGE}" ]; then
  echo "TX_WATCHER_IMAGE is set, starting tx-watcher and its dependencies..."
  ${DOCKER_COMPOSE_CMD} up -d tx-watcher-mysql
  ${DOCKER_COMPOSE_CMD} up -d zookeeper kafka tx-watcher-seeding
  ${DOCKER_COMPOSE_CMD} up -d tx-watcher
else
  echo "TX_WATCHER_IMAGE is not set, skipping tx-watcher services."
fi

echo >&2 -e "\n# Launch TUI on hydra-node-1: ${DOCKER_COMPOSE_CMD} run hydra-tui-1"
echo >&2 -e "\n# Stop the demo: ${DOCKER_COMPOSE_CMD} down\n"
# ${DOCKER_COMPOSE_CMD} run hydra-tui-1

sudo chown $(whoami):$(whoami) $TARGETDIR/node.socket
rm -f ~/node.socket
ln -s ${SCRIPT_DIR}/${TARGETDIR}/node.socket ~/node.socket

# echo this paragraph to the console:
echo >&2 -e "\n# Run these commands to init your terminal to work with Cardano CLI:"
echo 'export CARDANO_NODE_SOCKET_PATH=~/node.socket'
echo 'export CARDANO_NODE_NETWORK_ID=42'
echo 'source <(cardano-cli --bash-completion-script cardano-cli)'

echo >&2 -e "\n# Watch (Ogmios):        watch -n1 'curl -s localhost:1337/health | jq'"
echo >&2 -e "\n# Watch (Blockfrost):    watch -n1 'curl -s localhost:3000/epochs/latest | jq'"
echo >&2 -e "\n# Inspect (Kupo) faucet: curl -s localhost:1442/matches/addr_test1vztc80na8320zymhjekl40yjsnxkcvhu58x59mc2fuwvgkc332vxv | jq '.[] | select(.spent_at == null)'"
echo >&2 -e "\n# Cardano wallet:        curl -s localhost:8090/v2/network/information | jq"

echo -e "\n\n"
