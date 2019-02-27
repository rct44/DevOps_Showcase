#!/usr/bin/env sh

export VERSION=${VERSION:-latest}

printf "
         RUNNING STACK
        ===============
    USING VERSION: $VERSION

"

docker-compose pull

sudo rm -rf /tmp/mounts
cp -r mounts-keep /tmp/mounts

docker stack deploy --compose-file docker-compose.yaml example
