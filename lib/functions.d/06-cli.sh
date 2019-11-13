#!/usr/bin/env bash

# We will attempt to create a PS1 that displays AWS identity when active

_AWSH_OLDPROMPT=
_AWSH_OLDPS1=

_SEPARATOR_LEFT_BOLD=
_SEPARATOR_LEFT_THIN=
_SEPARATOR_RIGHT_BOLD=
_SEPARATOR_RIGHT_THIN=

function _patched_font_in_use {
    if [ -z "$PATCHED_FONT_IN_USE" ]; then
      return 1
    fi
    return 0
}


if _patched_font_in_use; then
	_SEPARATOR_LEFT_BOLD=""
	_SEPARATOR_LEFT_THIN=""
	_SEPARATOR_RIGHT_BOLD=""
	_SEPARATOR_RIGHT_THIN=""
else
	_SEPARATOR_LEFT_BOLD="◀"
	_SEPARATOR_LEFT_THIN="❮"
	_SEPARATOR_RIGHT_BOLD="▶"
	_SEPARATOR_RIGHT_THIN="❯"
fi

# Segment colors
__awsh_segment="$(_screen_encode_color ${__awsh_brand_bg} ${__awsh_brand_fg})"
__awsh_next_sep="$(_screen_encode_color ${__awsh_datetime_bg} ${__awsh_brand_bg})"

__date_segment="$(_screen_encode_color ${__awsh_datetime_bg} ${__awsh_datetime_fg})"
__date_next_sep="$(_screen_encode_color ${__awsh_account_bg} ${__awsh_datetime_bg})"

__awsid_segment="$(_screen_encode_color ${__awsh_account_bg} ${__awsh_account_fg})"
__awsid_next_sep="$(_screen_encode_color ${__awsh_region_bg} ${__awsh_account_bg})"

__awsregion_segment="$(_screen_encode_color ${__awsh_region_bg} ${__awsh_region_fg})"
__awsregion_next_sep="$(_screen_encode_color ${__awsh_brand_bg} ${__awsh_region_bg})"

__awstoken_valid_segment="$(_screen_encode_color ${__dark_green} ${__awsh_brand_fg})"
__awstoken_valid_next_sep="$(_screen_encode_color ${__dark_green} ${__awsh_region_bg})"

__awstoken_expired_segment="$(_screen_encode_color ${__red} ${__awsh_brand_fg})"
__awstoken_expired_next_sep="$(_screen_encode_color ${__red} ${__awsh_region_bg})"

__awstoken_lowtime_segment="$(_screen_encode_color ${__yellow} ${__awsh_brand_fg})"
__awstoken_lowtime_next_sep="$(_screen_encode_color ${__yellow} ${__awsh_region_bg})"



# Attempts to retrieve the current AWS identity name
function _cli_get_segment_aws_id_name {
    if _patched_font_in_use; then
        local segment_icon="$(echo -e "\uf007")"
    fi
    local segment_value="$(echo ${AWS_ID_NAME})"
    if [[ ! -z $segment_value ]]; then
        echo "${__date_next_sep}${_SEPARATOR_RIGHT_BOLD}${__awsid_segment} ${segment_icon} ${segment_value} "
    fi
}


# Attempts to retrieve the current AWS region
function _cli_get_segment_aws_region {
    if _patched_font_in_use; then
        local segment_icon="$(echo -e "\uf0c2")"
    fi
    local segment_value="$(echo ${AWS_DEFAULT_REGION})"
    if [ ! -z $segment_value ]; then
        echo "${__awsid_next_sep}${_SEPARATOR_RIGHT_BOLD}${__awsregion_segment} ${segment_icon} ${segment_value} "
    fi
}


# Attempts to retrieve the current AWS identity name
function _cli_get_segment_aws_token_expiry {
    if _patched_font_in_use; then
        local segment_icon="$(echo -e "\uf017")"
    fi
    if [[ ! -z ${AWS_TOKEN_EXPIRY} ]]; then
        local dt_now="$(date)"
        local dt_expiry="$(date --date "@${AWS_TOKEN_EXPIRY}")"
        local delta=$(( $(date -d "$dt_expiry" +%s) - $(date -d "$dt_now" +%s) ))
        if [[ ${delta} -gt 300 ]]; then
            local segment_value="$(date -d @$(( $(date -d "$dt_expiry" +%s) - $(date -d "$dt_now" +%s) )) -u +'%H:%M:%S')"
            local segment_style="${__awstoken_valid_next_sep}${_SEPARATOR_RIGHT_BOLD}${__awstoken_valid_segment}"
        elif [[ ${delta} -gt 0 ]]; then
            local segment_value="$(date -d @$(( $(date -d "$dt_expiry" +%s) - $(date -d "$dt_now" +%s) )) -u +'%H:%M:%S')"
            local segment_style="${__awstoken_lowtime_segment}${_SEPARATOR_RIGHT_BOLD}${__awstoken_valid_segment}"
        else
            local segment_value="EXPIRED"
            local segment_style="${__awstoken_expired_next_sep}${_SEPARATOR_RIGHT_BOLD}${__awstoken_expired_segment}"
        fi
        if [[ ! -z $segment_value ]]; then
            echo "${segment_style} ${segment_icon} ${segment_value} "
        fi
    fi
}


function _cli_get_segment_awsh {
    echo "${__awsh_segment} AWSH "
}


function _cli_get_segment_datetime {
    echo "${__awsh_next_sep}${_SEPARATOR_RIGHT_BOLD}${__date_segment}"' \d \t '
}


function _cli_update_awsh_ps1 {
    PS1="\n$(_cli_get_segment_awsh)"
    PS1="${PS1}$(_cli_get_segment_datetime)"
    PS1="${PS1}$(_cli_get_segment_aws_id_name)"
    PS1="${PS1}$(_cli_get_segment_aws_region)"
    PS1="${PS1}$(_cli_get_segment_aws_token_expiry)"
    PS1="${PS1}${__reset}"' \w\n\\$ '
    export PS1
}


function _cli_save_prompt {
    if [[ ! -z ${PROMPT} ]]; then
        export _AWSH_OLDPROMPT="${PROMPT}"
    else
        export _AWSH_OLDPROMPT="${PROMPT_COMMAND}"
    fi
    export _AWSH_OLDPS1="${PS1}"
}

function _cli_restore_prompt {
    unset PROMPT_COMMAND PROMPT PS1
    export PROMPT_COMMAND="${_AWSH_OLDPROMPT}"
    export PROMPT="${_AWSH_OLDPROMPT}"
    export PS1="${_AWSH_OLDPS1}"
}


function _cli_awsh_prompt {
    unset PROMPT_COMMAND PROMPT
    export PROMPT_COMMAND="_cli_update_awsh_ps1; $PROMPT_COMMAND"
    export PROMPT="_cli_update_awsh_ps1; $PROMPT"
}


function _cli_startup {
    if [[ ! -z "$BASH_VERSION" ]]; then
        echo ""
        echo "Getting Started:"
        echo ""
        echo "  'awsh identity-create'    Create a simple AWS Credentials identity"
        echo "  'awsh login'              Login to AWS using a configured identity"
        echo "  'awsh region'             Change the default AWS region"
        echo "  'awsh logout'             Logout of an active session"
        echo "  'awsh save'               Save an active AWS session"
        echo "  'awsh load'               Resume a previous saved AWS session"
        echo "  'awsh help'               Show help and usage"
        echo "  'awsh prompt'             Enable the AWSH custom PS1 prompt"
        echo "  'awsh oldprompt'          Restore the previous PS1 prompt"
        echo ""
        echo "If you do not wish to see these tips then 'touch ~/.awsh/config.d/.notips'"
        echo ""
    fi
}


# Activate promt only if we're a terminal and it was the starting shell
if [[ -t 1 ]] && [[ "bash" == "${0##*/}" ]]; then
    if [[ ! -z "$BASH_VERSION" ]]; then
        _cli_save_prompt
        # Info helper for first run if no marker file are found
        if [[ ! -f ~/.awsh/config.d/.notips ]]; then
            _cli_startup
        fi
        _cli_awsh_prompt
    fi
fi
