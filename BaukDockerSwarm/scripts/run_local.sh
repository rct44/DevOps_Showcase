#!/usr/bin/env sh

./scripts/build.sh


export VERSION=${VERSION:-`git describe --tags`}

printf "
         RUNNING LOCAL BUILD
        =====================
    USING VERSION: $VERSION

"
cp -r mounts-keep mounts
docker stack deploy --compose-file docker-compose.yaml example
