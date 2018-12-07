#!/bin/bash

# test authentication and privilege of git client

ssh -T pvzdfe_ssh_alias  > /var/log/test_git_client.log 2>&1 || rc=$?

# ssh with non-interactive git-shell should return 1 on success, 255 if ssh is not privileged

if (( $rc == 0)) || (($rc == 1 )) || (( $rc == 255 )); then
    git clone -v pvzdfe_ssh_alias:/var/lib/git/pvzd/repodir_bare  > /var/log/test_git_client.log 2>&1
else
    echo 'connecting ssh client failed' > /var/log/test_git_client.log
    exit $rc
fi
