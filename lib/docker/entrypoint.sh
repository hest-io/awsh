#!/usr/bin/env bash

# UID/GID (may) map to unknown user/group, $HOME=/ (the default when no home directory is defined)
eval $( fixuid -q )
# UID/GID now match user/group, $HOME has been set to user's home directory

# Starship setup
[ -d "${HOME}/.config" ] || mkdir -p "${HOME}/.config"
[ -f "${HOME}/.config/starship.toml" ] || ln -s /opt/awsh/lib/starship/starship.toml "${HOME}/.config/starship.toml"

# On with the show
exec "$@"
