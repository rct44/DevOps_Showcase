#!/usr/bin/env sh

export VERSION=${VERSION:-`git describe --tags`}
export VERSION=${VERSION:-DEV}

./scripts/build.sh

printf "
         RUNNING LOCAL BUILD
        =====================
    USING VERSION: $VERSION

"
sudo rm -rf mounts
cp -r mounts-keep mounts

docker stack deploy --compose-file docker-compose.yaml example
