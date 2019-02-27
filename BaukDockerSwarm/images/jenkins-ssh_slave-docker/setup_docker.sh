#!/usr/bin/env sh


# # # # # Setup the docker group to match the host docker group
if [[ -S "/var/run/docker.sock" ]]
then
    DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)
    groupmod -g $DOCKER_GID docker
fi


