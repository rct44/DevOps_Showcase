#!/usr/bin/env sh


# # # # # Add the ssh user
USERADD="useradd --uid $SSH_USER_ID -m $SSH_USER"
USERADD="$USERADD -o" # To allow users with same id
[[ "$SSH_USER_GROUP"  ]] && USERADD="$USERADD -g $SSH_USER_GROUP"
[[ "$SSH_USER_GROUPS" ]] && USERADD="$USERADD -G $SSH_USER_GROUPS"
$USERADD
mkdir -p $SSH_DIR $SSH_USER_EXTRA_DIRS

# # # # # Add any public keys
if [[ "$SSH_PUBLIC_KEY" ]]
then
    echo "$SSH_PUBLIC_KEY" >> $SSH_DIR/authorized_keys
fi
for key in $(env | sed -n "s/^SSH_PUBLIC_KEY_[A-Z0-9]*=//p")
do
    echo "$key" >> $SSH_DIR/authorized_keys
done

# # # # # Permission fixes
chown -R $SSH_USER_ID /home/$SSH_USER $SSH_USER_EXTRA_DIRS
chmod -R 700 $SSH_DIR

# # # # # Login fix
if [[ -f /run/nologin ]]
then
    mv /run/nologin /run/nologin-bak
fi

