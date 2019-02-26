ARG VERSION

FROM bauk/jenkins-ssh_slave:${VERSION}

RUN curl -fsSL https://get.docker.com | sh

ENV SSH_USER_GROUPS=docker


COPY ./setup_docker.sh /setup/
