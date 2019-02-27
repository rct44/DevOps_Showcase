ARG VERSION

FROM bauk/jenkins-ssh_slave:${VERSION}

RUN curl -fsSL https://get.docker.com | sh

ENV SSH_USER_GROUPS=docker

COPY ./setup_docker.sh /setup/

RUN yum install -y unzip

RUN curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
 && chmod +x /usr/local/bin/docker-compose \
 && docker-compose --version

