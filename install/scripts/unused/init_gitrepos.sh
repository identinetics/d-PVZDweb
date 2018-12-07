#!/usr/bin/env bash

# make a bare repo into repodir_bare
# clone it to repodir_upload, and add the directory structure

if (( $(id -u) == 0 )); then
    echo 'Execute this only as $CONTAINERUSER!'
    exit 1
fi


# bare (headless) repo
cd   # home dir of CONTAINERUSER
mkdir -p pvzd/repodir_bare
cd pvzd/repodir_bare
git init --bare --shared=group
git config --global push.default simple
git config --global user.email "repoowner@pvzdfe"
git config --global user.name "Repowwner PVZD Frontened"


# checkout repo for webapp
mkdir ~/repodir_upload
cd ~/repodir_upload
git clone ~/pvzd/repodir_bare .
mkdir -p policydir published rejected request_queue
echo 'Portalverbund Zentrale Dienste/Metadaten Registrierung' > /var/lib/git/repodir_upload/.git/description
for dir in *; do
    touch $dir/.keep
done
cp /opt/webapp/README.md .



