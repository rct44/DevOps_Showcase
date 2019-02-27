#!/bin/bash

# This script will download a lost of plugins from a running Jenkins that you can use for creating a Jenkins image

# curl -s -k "http:/${JENKINS_USER}:${JENKINS_PASS}@jenkins:8080/pluginManager/api/json?depth=1" \
#       | ./jq -r '.plugins[].shortName' | tee plugins.txt

JENKINS_URL=jenkins
JENKINS_PORT=8080
JENKINS_USER=jenkins
JENKINS_PASS=jenkins

curl -u $USER "$JENKINS_URL:$JENKINS_PORT/pluginManager/api/xml?depth=1&xpath=/*/*/shortName|/*/*/version&wrapper=plugins" \
    | perl -pe 's/.*?<shortName>([\w-]+).*?<version>([^<]+)()(<\/\w+>)+/\1 \2\n/g' | sed 's/ /:/' | tee plugins.txt

# To remove version numbers
printf "Removing version numbers...\n"
sed -i 's/:.*//' plugins.txt
