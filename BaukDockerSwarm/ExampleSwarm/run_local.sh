#!/usr/bin/env sh

echo "Jenkins provisioning!"


cd BaukDockerSwarm/ExampleSwarm/

ls -lrt 

export VERSION=${VERSION:-latest}
docker-compose build
docker stack deploy --compose-file docker-compose.yaml example
docker run -p 8080:8080 -d bauk/jenkins-master:latest

docker run -d bauk/jenkins-ssh_slave:latest

docker run -d bauk/jenkins-ssh_slave-docker:latest