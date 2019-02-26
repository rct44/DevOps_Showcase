#!/usr/bin/env sh

# # # # # Load any container environmental variables
cat /proc/1/environ |tr '\0' '\n' | sed "s/^/export /g" > /tmp/env
source /tmp/env
rm -f /tmp/env

# # # # # Config
SCRIPT_DIR=/setup
SECRETS_DIR=/run/secrets

# # # # # Setup 
export SSH_USER=${SSH_USER:-user}
export SSH_USER_ID=${SSH_USER_ID:-1000}
export SSH_USER_EXTRA_DIRS=${SSH_USER_EXTRA_DIRS:-}
export SSH_DIR=/home/$SSH_USER/.ssh
export SSH_USER_GROUP=${SSH_USER_GROUP:-}
export SSH_USER_GROUPS=${SSH_USER_GROUPS:-}

printf "Starting the setup script...\n"

# # # # # Get options : This does not work as this is now a service
if [[ "$1" == "help" ]]
then
    printf "
        SECRETS / ENVIRONMENT
       =======================
        - SSH_PUBLIC_KEY            # To set the ssh public key
        - SSH_PUBLIC_KEY_[A-Z0-9]*  # If you need to add more public keys
    "
    exit
fi
# # # # #  Load any variables given to container

# # # # # Get any docker secrets
if [[ -d "$SECRETS_DIR" ]]
then
    cd $SECRETS_DIR
    for secret in *
    do
        eval export $secret=\"$(cat $secret)\"
        rm $secret
    done
fi


# # # # # Load all the setup scripts
for script in $SCRIPT_DIR/*
do
    chmod +x $script
    $script
done

