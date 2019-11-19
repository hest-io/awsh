#!/usr/bin/env bash
# Intended to perform all tasks that need to be executed on a first run of the
# tools

function _firstrun {

    echo ""
    echo "AWSH: Welcome!"
    echo ""
    echo "  Documentation   : https://www.hest.io/awsh/docs/"
    echo "  Found an issue? : https://github.com/hest-io/awsh/issues"

    mkdir -p ~/.awsh/config.d/
    touch ~/.awsh/config.d/.firstrun

}

# Create a tmp dir if none exists
if [[ ! -d "${AWSH_ROOT}/tmp" ]]; then
    mkdir -p "${AWSH_ROOT}/tmp"
fi

# Create a log dir if none exists
if [[ ! -d "${AWSH_ROOT}/log" ]]; then
    mkdir -p "${AWSH_ROOT}/log"
fi

# Create an user identities dir if none exists
if [[ ! -d ~/.awsh/identities ]]; then
    mkdir -p ~/.awsh/identities
fi

# First Run helper if no config file is found
if [[ ! -f ~/.awsh/config.d/.firstrun ]]; then
    _firstrun
fi

