# Intended to perform all tasks that need to be executed on a first run of the
# tools

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

# Info helper for first run if no credentials are found
if [[ ! -f ~/.awsh/.notips ]]; then
    # Activate promt only if we're a terminal and it was the starting shell
    if [[ -t 1 ]] && [[ "bash" == "${0##*/}" ]]; then
        if [[ ! -z "$BASH_VERSION" ]]; then
            echo ""
            echo "AWS Getting Started:"
            echo ""
            echo "  'awsh identity-create'    Create a simple AWS Credentials identity"
            echo "  'awsh login'              Login to AWS using a configured identity"
            echo "  'awsh region'             Change the default AWS region"
            echo "  'awsh logout'             Logout of an active session"
            echo "  'awsh save'               Save an active AWS session"
            echo "  'awsh load'               Resume a previous saved AWS session"
            echo "  'awsh help'               Show help and usage"
            echo ""
            echo "If you do not wish to see these tips then 'touch ~/.awsh/.notips'"
            echo ""
        fi
    fi
fi
