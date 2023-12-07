#!/usr/bin/env bash

function show_help {
    cat <<EOF
usage: awsh [--help] <command> [<args>]

available commands:

EOF
    _awsh_list_subcommands
}


function _awsh_show_completions {

    # Variable setup
    local DEFAULT_OUT="${HOME}/.awsh/log/awsh-cli.log"
    local SUBCOMMAND_ROOT="${AWSH_ROOT}/bin/subcommands"
    local SUBCOMMANDS="$(find ${SUBCOMMAND_ROOT} -type f -name 'awsh-*' -exec basename {} \; 2> /dev/null | sed -e 's/awsh-//g')"
    local VS_SUBCOMMANDS=( 'login' 'logout' 'region' 'session-save' 'session-load' 'session-purge' 'creds')
    local CLOUDBUILDER_ROOT="~/.cloudbuilder"

    # Add all of our discovered sub-commands
    VS_SUBCOMMANDS+=( $SUBCOMMANDS )

    saveIFS=$IFS
    IFS=$'\n'
    echo "${VS_SUBCOMMANDS[*]} ${INTERNALCOMMANDS}" | sort
    IFS=$saveIFS

}


function _awsh_show_usage {
    cat <<EOF
usage: awsh [version] [--help] <command> [<args>]

The most commonly used commands are:
  whoami            Lists information about the current API user
  list              Lists many AWS resource types using JQ based filters
  vpc-viz           Creates diagrams and graphs of your VPC resources
  scp               Wrapper for SCP configured to use loaded AWS identity
  ssh               Wrapper for SSH configured to use loaded AWS identity

'awsh -h' lists available subcommands
EOF
}


function _awsh_version {
    # Default for AWSH_VERSION if unset
    : "${AWSH_ROOT:='unknown'}"
    echo "awsh version $AWSH_VERSION"
}


function cleanup {
    echo "Exiting."
    exit 1
}


function _awsh_list_subcommands {

    _awsh_show_completions | sort | column -c 80

}


function awsh {

    # Variable setup
    local DEFAULT_OUT="${HOME}/.awsh/log/awsh-cli.log"
    local SUBCOMMAND_ROOT="${AWSH_ROOT}/bin/subcommands"
    local SUBCOMMANDS="$(find $SUBCOMMAND_ROOT -type f -name 'awsh-*' -exec basename {} \; 2> /dev/null | sed -e 's/awsh-//g')"

    # Show most common commands if no args are given
    if { [ -z "$1" ] && [ -t 0 ] ; }; then
        _awsh_show_usage
        return 0
    fi

    # show help for no arguments if stdin is a terminal
    if [ "$1" == '-h' ] || [ "$1" == '--help' ] || [ "$1" == 'help' ]; then
        show_help
        return 0
    fi

    # show lst of commands
    if [ "$1" == '-c' ] || [ "$1" == '--commands' ] || [ "$1" == 'commands' ]; then
        _awsh_show_completions
        return 0
    fi


    # Pop the first arg as a potential command and attempt to process
    _sub_command=$1
    shift

    case ${_sub_command} in

        oldprompt)
            _cli_restore_prompt
        ;;

        prompt)
            _cli_awsh_prompt
        ;;

        login)
            if [[ -n "$AWS_CONTAINER_CREDENTIALS_FULL_URI" ]] && [[ -n "$AWS_CONTAINER_AUTHORIZATION_TOKEN" ]]; then
                _screen_info "CloudShell detected. Attempting to load existing credentials"
                _aws_load_credentials_from_cloudshell
            elif [[ "$1" == "instance" ]]; then
                _screen_info "Attempting to aquire credentials from Instance"
                _aws_load_credentials_from_instance
            else
                _aws_login "${@}"
            fi
        ;;

        assume|sudo)
            _aws_assume_role_and_load_credentials "${@}"
        ;;

        logout|session-purge)
            _aws_logout
        ;;

        credentials|creds)
            if [[ "$1" == "load" ]]; then
                _aws_load_sso_credentials
            else
                _aws_show_credentials
            fi

        ;;

        session-save)
            _aws_session_save
        ;;

        session-load)
            _aws_session_load
        ;;

        region)
            _aws_region "${@}"
        ;;

        version)
            _awsh_version
        ;;

        reload)
            . "${AWSH_ROOT}/etc/awshrc"
        ;;

        *)
            # Ensure that the command we will try to execute actually exists in the
            # subcommand dir
            if [ ! -x "${SUBCOMMAND_ROOT}/awsh-${_sub_command}" ]; then
                _screen_error "'${_sub_command}' is not a valid awsh command. See 'awsh --help' for more info."
                return 1
            fi

            # Now attempt to execute the subcommand
            "${SUBCOMMAND_ROOT}/awsh-${_sub_command}" "${@}"
        ;;

    esac

}

export -f awsh
