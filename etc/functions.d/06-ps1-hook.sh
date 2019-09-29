# We will attempt to create a PS1 that displays AWS identity when active

_AWSH_OLDPROMPT=
_AWSH_OLDPS1=

_SEPARATOR_LEFT_BOLD=
_SEPARATOR_LEFT_THIN=
_SEPARATOR_RIGHT_BOLD=
_SEPARATOR_RIGHT_THIN=

_patched_font_in_use() {
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
__awsh_segment="$(__get_color_escape ${__awsh_brand_bg} ${__awsh_brand_fg})"
__awsh_next_sep="$(__get_color_escape ${__awsh_datetime_bg} ${__awsh_brand_bg})"

__date_segment="$(__get_color_escape ${__awsh_datetime_bg} ${__awsh_datetime_fg})"
__date_next_sep="$(__get_color_escape ${__awsh_account_bg} ${__awsh_datetime_bg})"

__awsid_segment="$(__get_color_escape ${__awsh_account_bg} ${__awsh_account_fg})"
__awsid_next_sep="$(__get_color_escape ${__awsh_region_bg} ${__awsh_account_bg})"

__awsregion_segment="$(__get_color_escape ${__awsh_region_bg} ${__awsh_region_fg})"
__awsregion_next_sep="$(__get_color_escape ${__awsh_brand_bg} ${__awsh_region_bg})"

__awstoken_valid_segment="$(__get_color_escape ${__dark_green} ${__awsh_brand_fg})"
__awstoken_valid_next_sep="$(__get_color_escape ${__dark_green} ${__awsh_region_bg})"

__awstoken_expired_segment="$(__get_color_escape ${__red} ${__awsh_brand_fg})"
__awstoken_expired_next_sep="$(__get_color_escape ${__red} ${__awsh_region_bg})"

__awstoken_lowtime_segment="$(__get_color_escape ${__yellow} ${__awsh_brand_fg})"
__awstoken_lowtime_next_sep="$(__get_color_escape ${__yellow} ${__awsh_region_bg})"



# Attempts to retrieve the current AWS identity name
_get_segment_aws_id_name() {
    if _patched_font_in_use; then
        local segment_icon="$(echo -e "\uf007")"
    fi
    local segment_value="$(echo ${AWS_ID_NAME})"
    if [ ! -z $segment_value ]; then
        echo "${__date_next_sep}${_SEPARATOR_RIGHT_BOLD}${__awsid_segment} ${segment_icon} ${segment_value} "
    fi
}


# Attempts to retrieve the current AWS region
_get_segment_aws_region() {
    if _patched_font_in_use; then
        local segment_icon="$(echo -e "\uf0c2")"
    fi
    local segment_value="$(echo ${AWS_DEFAULT_REGION})"
    if [ ! -z $segment_value ]; then
        echo "${__awsid_next_sep}${_SEPARATOR_RIGHT_BOLD}${__awsregion_segment} ${segment_icon} ${segment_value} "
    fi
}


# Attempts to retrieve the current AWS identity name
_get_segment_aws_token_expiry() {
    if _patched_font_in_use; then
        local segment_icon="$(echo -e "\uf017")"
    fi
    if [ ! -z ${AWS_TOKEN_EXPIRY} ]; then
        local dt_now="$(date)"
        local dt_expiry="$(date --date "@${AWS_TOKEN_EXPIRY}")"
        local delta=$(( $(date -d "$dt_expiry" +%s) - $(date -d "$dt_now" +%s) ))
        if [ ${delta} -gt 300 ]; then
            local segment_value="$(date -d @$(( $(date -d "$dt_expiry" +%s) - $(date -d "$dt_now" +%s) )) -u +'%H:%M:%S')"
            local segment_style="${__awstoken_valid_next_sep}${_SEPARATOR_RIGHT_BOLD}${__awstoken_valid_segment}"
        elif [ ${delta} -gt 0 ]; then
            local segment_value="$(date -d @$(( $(date -d "$dt_expiry" +%s) - $(date -d "$dt_now" +%s) )) -u +'%H:%M:%S')"
            local segment_style="${__awstoken_lowtime_segment}${_SEPARATOR_RIGHT_BOLD}${__awstoken_valid_segment}"
        else
            local segment_value="EXPIRED"
            local segment_style="${__awstoken_expired_next_sep}${_SEPARATOR_RIGHT_BOLD}${__awstoken_expired_segment}"
        fi
        if [ ! -z $segment_value ]; then
            echo "${segment_style} ${segment_icon} ${segment_value} "
        fi
    fi
}


_get_segment_awsh() {
    echo "${__awsh_segment} AWSH "
}


_get_segment_datetime() {
    echo "${__awsh_next_sep}${_SEPARATOR_RIGHT_BOLD}${__date_segment}"' \d \t '
}


_update_awsh_ps1() {
    PS1="\n$(_get_segment_awsh)"
    PS1="${PS1}$(_get_segment_datetime)"
    PS1="${PS1}$(_get_segment_aws_id_name)"
    PS1="${PS1}$(_get_segment_aws_region)"
    PS1="${PS1}$(_get_segment_aws_token_expiry)"
    PS1="${PS1}${__reset}"' \w\n\\$ '
    export PS1
}


_save_prompt() {
    if [ ! -z ${PROMPT} ]; then
        export _AWSH_OLDPROMPT="${PROMPT}"
    else
        export _AWSH_OLDPROMPT="${PROMPT_COMMAND}"
    fi
    export _AWSH_OLDPS1="${PS1}"
}

restore_prompt() {
    unset PROMPT_COMMAND PROMPT PS1
    export PROMPT_COMMAND="${_AWSH_OLDPROMPT}"
    export PROMPT="${_AWSH_OLDPROMPT}"
    export PS1="${_AWSH_OLDPS1}"
}


awsh_prompt() {
    unset PROMPT_COMMAND PROMPT
    export PROMPT_COMMAND="_update_awsh_ps1; $PROMPT_COMMAND"
    export PROMPT="_update_awsh_ps1; $PROMPT"
}


# Activate promt only if we're a terminal and it was the starting shell
if [[ -t 1 ]] && [[ "bash" == "${0##*/}" ]]; then
    if [ ! -z "$BASH_VERSION" ]; then
        _save_prompt
        if [ ! -f ~/.awsh/.notips ]; then
            echo "You can restore the previous prompt with 'restore_prompt' if you"
            echo "prefer or do not have patched fonts available and re-enable the "
            echo "custom prompt with 'awsh_prompt'"
        fi
        awsh_prompt
    fi
fi
