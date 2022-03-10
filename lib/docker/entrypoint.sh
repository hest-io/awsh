#!/bin/bash

# Create shared bash history file if it doesn't exist
[[ ! -f /home/awsh/.awsh/.bash_history ]] && umask 066 && touch /home/awsh/.awsh/.bash_history

# Link shared history to user bash

ln -s /home/awsh/.awsh/.bash_history /home/awsh/.bash_history

# UID/GID (may) map to unknown user/group, $HOME=/ (the default when no home directory is defined)
eval $( fixuid -q )
# UID/GID now match user/group, $HOME has been set to user's home directory

# On with the show
exec "$@"
