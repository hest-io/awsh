# Load the global AWSH rc
. /opt/awsh/etc/awshrc

# Load FZF completion support
. /usr/share/fzf/key-bindings.bash

# Load the optional user rc
[ -f ${HOME}/.bashrc_local ] && . ${HOME}/.bashrc_local