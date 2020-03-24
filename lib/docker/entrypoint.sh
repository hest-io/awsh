#!/bin/bash

# UID/GID (may) map to unknown user/group, $HOME=/ (the default when no home directory is defined)
eval $( fixuid -q )
# UID/GID now match user/group, $HOME has been set to user's home directory

# On with the show
exec "$@"
