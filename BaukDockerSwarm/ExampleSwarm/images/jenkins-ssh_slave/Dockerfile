FROM centos/systemd

# # # # # Install dependencies
RUN yum -y install openssh-server java-1.8.0-openjdk java-1.8.0-openjdk-devel git which \
 && ln -s /bin/git /usr/local/bin/git

# # # # # Enable the ssh daemon
RUN systemctl enable sshd

# # # # # Add the setup service
COPY setup.service /etc/systemd/system/
COPY setup.sh /
RUN systemctl enable setup \
 && chmod +x /setup.sh

# # # # # Add the ssh setup script
RUN mkdir /setup/
COPY ssh_setup.sh /setup/00_ssh_setup.sh
