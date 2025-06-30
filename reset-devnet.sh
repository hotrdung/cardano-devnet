#!/bin/bash

docker compose down
docker volume rm demo_db-sync-data demo_postgres demno_db-kupo

docker stop $(docker ps -a -q --filter "name=demo-hydra-tui-*")
docker rm $(docker ps -a -q --filter "name=demo-hydra-tui-*")

sudo rm -rf devnet
