#!/usr/bin/env bash


sync_repo() {
    cd ~/repodir_upload
    git commit --all --allow-empty-message
    git fetch
    git merge -m uploader origin/master
    git push
    sleep 10
}

while true; do
    sync_repo  > /var/log/$USER/repo_sync.lastlog   2>&1
    egrep -v  '(Already up-to-date|Everything up-to-date|# On branch master|nothing to commit, working directory clean)' \
        /var/log/$USER/repo_sync.lastlog >> /var/log/$USER/repo_sync.log
done
