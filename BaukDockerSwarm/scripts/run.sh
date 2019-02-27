#!/usr/bin/env sh

export VERSION=${VERSION:-latest}

printf "
         RUNNING STACK
        ===============
    USING VERSION: $VERSION

"
docker-compose pull
docker stack deploy --compose-file docker-compose.yaml example
