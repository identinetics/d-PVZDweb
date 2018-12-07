#!/usr/bin/env bash

# script to create an ssh acoount with a git shell with access to the shared
# metadata repository
# r2h2 2016-01-13

if (( "$#" != 3 )); then
    echo "usage: $0 username groupname ssh_pubkey_file"
    exit 1
else
    username=$1
    groupname=$2
    keyfile=$3
fi

if (( "$(id -u)" != 0 )); then
   echo "This script must be run as root" 1>&2
   exit 1
fi

adduser -g $groupname --create-home --skel /dev/null --shell /usr/bin/git-shell $username
mkdir -p /home/${username}/.ssh /home/${username}/git-shell-commands
chmod 750 /home/${username}/.ssh
cp $keyfile /home/${username}/.ssh/authorized_keys
chown $username /home/${username}/.ssh/authorized_keys
chmod 640 /home/${username}/.ssh/authorized_keys
chown -R $username /home/${username}
