#!/usr/bin/env sh

export VERSION=${VERSION:-`git describe --tags`}

printf "
            BUILDING
           ==========
    USING VERSION: $VERSION

"

docker-compose -f docker-compose.yaml -f docker-compose-build.yaml build jenkins_slave # This is needed first as others depend on it
docker-compose -f docker-compose.yaml -f docker-compose-build.yaml build

