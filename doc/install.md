# Installation

## Git repo setup
### Parent repository
The user pvzdfe owns the bare git repo. 

### Client accounts
Account wanting to access the repo need to: 
- have repousers as their default group
- have /usr/bin/git-shell as shell
- copy the remote ssh pubkey to ~/.ssh/authorized_keys.

## Build the docker image
1. adapt conf.sh
2. run build.sh: 

## Usage
create git accounts and bare repo: 
    
    run.sh -ir bash
    vi /tmp/be_id.pub  # paste the public key of the backend user into the file
    /mk_git_account.sh backend /tmp/be_id.pub
    vi /tmp/ul_id.pub  # paste the public key of the upload user into the file
    /mk_git_account.sh upload /tmp/ul_id.pub

        
    create bare repo
