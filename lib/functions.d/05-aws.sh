#!/usr/bin/env bash
# A simple set of functions to load and export the AWS credentials from a given
# file. We expect the credentials to be in standard AWS-Conf format;
#
#   aws_access_key_id=ASDFGHJKDFGHJGH
#   aws_secret_access_key=DFGBNM&UYJFGHJ&UJ&*(*I%TG)
#
#   ..which we will export into two environment variables AWS_ACCESS_KEY_ID
#   and AWS_SECRET_ACCESS_KEY
#


# Default MFA token duration in seconds
DEFAULT_TOKEN_DURATION=3600


# A boolean helper to provide a means of checking if credentials are active
# before attempting other commands that require the user to be logged in
function _aws_is_authenticated {

    if [[ -z ${AWS_ACCESS_KEY_ID} ]] || [[ -z ${AWS_SECRET_ACCESS_KEY} ]]; then
        return 1
    fi
    return 0

}


# Helper function to load simple API keys
function _aws_load_basic_credentials {

    # Load the INI config and make it available for use
    _config_ini_parser "${1}"
    cfg.section.default

    AWS_DEFAULT_REGION="${region}"
    AWS_ACCESS_KEY_ID="${aws_access_key_id}"
    AWS_SECRET_ACCESS_KEY="${aws_secret_access_key}"

    export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION

}


function _aws_load_credentials_from_json {

    AWS_CONFIG_FILE=$(mktemp /tmp/awsmfaXXXX)

    jq '.Credentials | {
        AWS_ACCESS_KEY_ID: (.AccessKeyId),
        AWS_SECRET_ACCESS_KEY: (.SecretAccessKey),
        AWS_SESSION_TOKEN: ((.SessionToken) // ""),
        AWS_SECURITY_TOKEN: ((.SessionToken) // ""),
        AWS_EXPIRY: ((.Expiration) // "")
        }' "${1}" \
        | awsh-json2properties > "${AWS_CONFIG_FILE}"

    source "${AWS_CONFIG_FILE}"

    # Now set the token expiry time so that it can be used for the PS1 prompt
    let AWS_TOKEN_EXPIRY=$(date +"%s" --date "${AWS_EXPIRY}")
    local expiry_time=$(date +"%Y-%m-%d %H:%M:%S" --date ${AWS_TOKEN_EXPIRY})
    _screen_note "AWS_TOKEN_EXPIRES...... $expiry_time"

    export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION
    export AWS_SECURITY_TOKEN AWS_TOKEN_EXPIRY AWS_SESSION_TOKEN

}


# Helper function to get API keys using MFA token
function _aws_load_mfaauth_credentials {

    # Load the INI config and make it available for use
    _config_ini_parser "${1}"
    cfg.section.default

    AWS_DEFAULT_REGION="${region}"
    AWS_ACCESS_KEY_ID="${aws_access_key_id}"
    AWS_SECRET_ACCESS_KEY="${aws_secret_access_key}"
    AWS_MFA_ID="${aws_mfa_id}"
    REQUESTED_TOKEN_DURATION="${token_duration:-$DEFAULT_TOKEN_DURATION}"

    AWS_CONFIG_FILE=$(mktemp /tmp/awsmfaXXXX)

    echo -e -n "INFO : ${__fg_red}MFA Account Detected... ${__no_color}"
    read -p "Please specify the MFA PIN Now: " response
    _screen_note  "Requesting Token for... ${REQUESTED_TOKEN_DURATION}s"
    ${AWSH_ROOT}/bin/subcommands/awsh-token-mfaauth-create \
        "$aws_access_key_id" \
        "$aws_secret_access_key" \
        "$AWS_MFA_ID" \
        "$response" \
        "${REQUESTED_TOKEN_DURATION}" \
        > $AWS_CONFIG_FILE

    AWS_ACCESS_KEY_ID="$(grep -h aws_access_key_id "$AWS_CONFIG_FILE" | awk '{print $2}')"
    AWS_SECRET_ACCESS_KEY="$(grep -h aws_secret_access_key "$AWS_CONFIG_FILE" | awk '{print $2}')"
    AWS_SECURITY_TOKEN="$(grep -h -i aws_security_token "$AWS_CONFIG_FILE" | awk '{print $2}')"
    AWS_SESSION_TOKEN="$(grep -h -i aws_security_token "$AWS_CONFIG_FILE" | awk '{print $2}')"
    AWS_TOKEN_EXPIRY_DATETIME="$(grep -h -i aws_token_expiry "$AWS_CONFIG_FILE" | awk '{print $2}')"

    _screen_note "AWS_MFA_ID............. $AWS_MFA_ID"

    # Now set the token expiry time so that it can be used for the PS1 prompt
    let AWS_TOKEN_EXPIRY=$(date +"%s" --date "${AWS_TOKEN_EXPIRY_DATETIME}")
    local expiry_time=$(date +"%Y-%m-%d %H:%M:%S" --date "${AWS_TOKEN_EXPIRY_DATETIME}")
    _screen_note "AWS_TOKEN_EXPIRES...... $expiry_time"

    export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION
    export AWS_MFA_ID AWS_SECURITY_TOKEN AWS_TOKEN_EXPIRY AWS_SESSION_TOKEN

}


# Helper function to get API keys using ADFS based SAML2 authentication to AWS
# after IDP form based login
function _aws_load_krb5formauth_credentials {

    # Load the INI config and make it available for use
    _config_ini_parser "${1}"
    local aws_role_idx=${2}
    : "${aws_role_idx:=-1}"
    cfg.section.default

    AWS_DEFAULT_REGION="${region}"
    AWS_ACCESS_KEY_ID="${aws_access_key_id}"
    AWS_SECRET_ACCESS_KEY="${aws_secret_access_key}"
    REQUESTED_TOKEN_DURATION="${token_duration:-$DEFAULT_TOKEN_DURATION}"

    AWS_CONFIG_FILE=$(mktemp /tmp/awsmfaXXXX)

    # Only attempt Kerberos based token generation if we have a valid kerberos
    # token at present
    active_tokens="$(klist 2>/dev/null)"
    [ $? -eq 0 ] || { _screen_error "No AD/Kerberos token found. Start with kinit to authenticate against your directory first" && return 1;}

    _screen_note  "Kerberos IDP Account Detected..."
    _screen_note  "Requesting Token for............ ${REQUESTED_TOKEN_DURATION}s"
        
    ${AWSH_ROOT}/bin/subcommands/awsh-token-krb5formauth-create \
        --region "${region}" \
        --idp_url "${aws_idp_url}" \
        --params "${identity_path}/idp_params.json" \
        --principal "${aws_idp_principal}" \
        --creds_cache "${AWS_CONFIG_FILE}" \
        --token_duration "${REQUESTED_TOKEN_DURATION}" \
        --role_index ${aws_role_idx}

    [ $? -eq 0 ] || { _screen_error "IDP Token generation failed. Check that both the IDP and the AWS Provider are configured" && return 1 ;}

    AWS_ACCESS_KEY_ID="$(grep -h aws_access_key_id "$AWS_CONFIG_FILE" | awk '{print $2}')"
    AWS_SECRET_ACCESS_KEY="$(grep -h aws_secret_access_key "$AWS_CONFIG_FILE" | awk '{print $2}')"
    AWS_SECURITY_TOKEN="$(grep -h -i aws_session_token "$AWS_CONFIG_FILE" | awk '{print $2}')"
    AWS_SESSION_TOKEN="$(grep -h -i aws_session_token "$AWS_CONFIG_FILE" | awk '{print $2}')"
    AWS_TOKEN_EXPIRY_DATETIME="$(grep -h -i aws_token_expiry "$AWS_CONFIG_FILE" | awk '{print $2}')"

    # Now set the token expiry time so that it can be used for the PS1 prompt
    let AWS_TOKEN_EXPIRY=$(date +"%s" --date "${AWS_TOKEN_EXPIRY_DATETIME}")
    local expiry_time=$(date +"%Y-%m-%d %H:%M:%S" --date "${AWS_TOKEN_EXPIRY_DATETIME}")
    _screen_note "AWS_TOKEN_EXPIRES...... $expiry_time"

    export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION
    export AWS_SECURITY_TOKEN AWS_SESSION_TOKEN AWS_TOKEN_EXPIRY

}


function _aws_login {

    local aws_id_name="$1"
    local aws_role_idx="$2"

    # Unset any AWS_ env variables
    local aws_vars="$(env | grep '^AWS_')"
    for item in $aws_vars; do
        var_name="$(echo "${item}" | awk -F'=' '{print $1}')"
        unset $var_name
    done

    unset region
    unset aws_mfa
    unset aws_session_token
    unset aws_security_token
    unset aws_secret_access_key
    unset aws_idp_url
    unset aws_idp_principal
    unset token_duration

    # Clear function definitions
    funcs="$(declare -F | grep 'cfg\.')"
    funcs="${funcs//declare -f/}"
    for f in $funcs; do
        unset -f "$f"
    done

    if [ -z $aws_id_name ]; then

        # Create a list of identities as well as a corresponding list of identity names
        local personal_id_names="$(find -L ~/.awsh/identities/* -maxdepth 1 -type d -print 2> /dev/null | _system_xargs basename)"
        local project_id_names="$(find -L ~/.cloudbuilder/identities/* -maxdepth 1 -type d -print 2> /dev/null | _system_xargs basename)"
        local vs_id_names="${personal_id_names} ${project_id_names}"
        local vs_ids="$(find -L ~/.awsh/identities/* -maxdepth 1 -type d -print 2> /dev/null) $(find ~/.cloudbuilder/identities/* -maxdepth 1 -type d -print 2> /dev/null)"
        local options=( $vs_id_names )
        local real_paths=( $vs_ids )

        # Ensure we have at least one identity to offer before proceeding
        if [ ! ${#options[@]} -ge 1 ]; then
            _log "$LINENO" "No identities currently configured. RTFM."
            return 1
        fi

        _screen_print_header_l1 "Available Identities"

        profile_idx=1
        local VS_BADGES=()
        # Build Personal Identities
        for next_id in $personal_id_names; do
            VS_BADGES+=("$(printf '%b%3.3s%b : %s' "${__fg_yellow}" "${profile_idx}" "${__no_color}" "${next_id}")")
            let profile_idx=profile_idx+1
        done
        # Build Project Identities
        for next_id in $project_id_names; do
            VS_BADGES+=("$(printf '%b%3.3s%b : %s' "${__fg_cyan}" "${profile_idx}" "${__no_color}" "${next_id}")")
            let profile_idx=profile_idx+1
        done

        # Find the length of the longest entry
        col_width=$(printf '%s\n' "${VS_BADGES[@]}" | awk '{ print length(), $0 | "sort -n" }' | tail -1 | awk '{print $1}')
        badge_template="%-${col_width}.${col_width}s\\n"
        printf $badge_template "${VS_BADGES[@]}" | column

        echo
        read -p "Please select an identity: " REPLY

        let idx=$REPLY-1
        local identity_path="${real_paths[idx]}"
        local identity="$(basename $identity_path)"

        identity_path="$(_string_chomp "$identity_path")"

    else

        # A specific ID was provided
        identity_path="${HOME}/.awsh/identities/${aws_id_name}"

    fi

    AWS_SSH_KEY="${identity_path}/ssh_id.pem"
    AWS_CONFIG_FILE="${identity_path}/aws.conf"
    AWS_ID_NAME="${identity}"

    # Ensure the files we need actually exist
    [ ! -f $AWS_SSH_KEY ] && _screen_error "No PrivateKey file found $AWS_SSH_KEY" && return 1
    [ ! -f $AWS_CONFIG_FILE ] && _screen_error "No credentials file found $AWS_CONFIG_FILE" && return 1

    if grep -q "aws_mfa" "$AWS_CONFIG_FILE"; then
        # Check if we have MFA to process
        _aws_load_mfaauth_credentials "${AWS_CONFIG_FILE}"
    elif grep -q "aws_idp" "$AWS_CONFIG_FILE"; then
        # Check if we have IDP to process
        _aws_load_krb5formauth_credentials "${AWS_CONFIG_FILE}" "${aws_role_idx}"
    else
        # If we haven't matched one of the earlier patterns
        _aws_load_basic_credentials "${AWS_CONFIG_FILE}"
    fi

    # Check to determine if we have a valid set of credentials for use
    if _aws_is_authenticated ; then
        _screen_note "AWS_CONFIG_FILE........ $AWS_CONFIG_FILE"
        _screen_note "AWS_SSH_KEY............ $AWS_SSH_KEY"
        _screen_note "AWS_DEFAULT_REGION..... $AWS_DEFAULT_REGION"
        _screen_note "AWS_ACCESS_KEY_ID...... $AWS_ACCESS_KEY_ID"
        _screen_note "AWS_SECRET_ACCESS_KEY.. $AWS_SECRET_ACCESS_KEY"

        _aws_load_account_metadata
        if [[ ! -z ${AWS_ACCOUNT_ALIAS} ]]; then
            AWS_ID_NAME="${AWS_ACCOUNT_ALIAS}"
        fi

        export AWS_SSH_KEY AWS_ID_NAME
        export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION
        export AWS_SECURITY_TOKEN AWS_SESSION_TOKEN AWS_TOKEN_EXPIRY

        # We now need to unset AWS_CONFIG_FILE to ensure that it's the AWS API
        # variables that are detected and used
        unset AWS_CONFIG_FILE
        return 0
    fi
    return 1
}


function _aws_region {
    local new_aws_region="$1"
    if _aws_is_authenticated ; then
        if [ -z $new_aws_region ]; then
            echo ""
            echo "You must specify a valid region for this account. Valid entries are:"
            region_list="$(aws ec2 describe-regions --output=text | awk '{printf "%s ", $3}')"
            echo "${region_list}" | fold -w 80 -s | column -t
            echo ""
            echo "Switch region with 'awsh region <name>'"
        else
            AWS_DEFAULT_REGION="${new_aws_region}"
            export AWS_DEFAULT_REGION

            _screen_info "AWS_DEFAULT_REGION now ${AWS_DEFAULT_REGION}"
        fi
    else
        _screen_error 'This command requires an active AWS session. Login first please!'
    fi
}


function _aws_save_account_metadata {

    if _aws_is_authenticated ; then

        AWS_ACCOUNT_NUMBER="$(aws sts get-caller-identity | jq -r '.Account')"
        # Create the metadata file if we don't already have one
        if [[ ! -f "${HOME}/.awsh/config.d/${AWS_ACCOUNT_NUMBER}.awsh" ]]; then
            AWS_ACCOUNT_ALIAS="$(aws iam list-account-aliases | jq -r '.AccountAliases[0]')"

            cat > "${HOME}/.awsh/config.d/${AWS_ACCOUNT_NUMBER}.awsh" <<-EOF
AWS_ACCOUNT_NUMBER=${AWS_ACCOUNT_NUMBER}
AWS_ACCOUNT_ALIAS=${AWS_ACCOUNT_ALIAS}
EOF

        fi

        export AWS_ACCOUNT_NUMBER AWS_ACCOUNT_ALIAS
    fi

}


function _aws_load_account_metadata {

    if _aws_is_authenticated ; then

        AWS_ACCOUNT_NUMBER="$(aws sts get-caller-identity | jq -r '.Account')"
        # Create the metadata file if we don't already have one
        if [[ -f "${HOME}/.awsh/config.d/${AWS_ACCOUNT_NUMBER}.awsh" ]]; then
            source "${HOME}/.awsh/config.d/${AWS_ACCOUNT_NUMBER}.awsh"
            export AWS_ACCOUNT_NUMBER AWS_ACCOUNT_ALIAS
        else
            _aws_save_account_metadata
        fi
    fi

}


function _aws_show_credentials {
    if _aws_is_authenticated ; then
        echo "--snip--"
        env | grep -E "^AWS_SECRET_ACCESS_KEY|^AWS_DEFAULT_REGION|^AWS_SESSION_TOKEN|^AWS_ACCESS_KEY_ID|^AWS_SECURITY_TOKEN"
        echo "--snip--"
    else
        _screen_error 'This command requires an active AWS session. Login first please!'
    fi
}


function _aws_logout {
    env \
        | grep '^AWS_' \
        | awk -F'=' '{print $1}' \
        | xargs -i echo 'unset {}' > /tmp/aws-session-purge
    source /tmp/aws-session-purge
}


function _aws_session_save {
    local -r CREDENTIALS_CACHE='/tmp/aws-session-credentials'
    env \
        | grep '^AWS_' \
        | xargs -i echo "export {}" \
        | sed -e 's/=/=\"/' \
        | sed -e 's/$/\"/' > "${CREDENTIALS_CACHE}"
}


function _aws_session_load {
    local -r CREDENTIALS_CACHE='/tmp/aws-session-credentials'
    if [[ -f "${CREDENTIALS_CACHE}" ]]; then
        source "${CREDENTIALS_CACHE}"
    else
        _
    fi
}


# Export our helper functions
export -f _aws_login
export -f _aws_logout
export -f _aws_region
export -f _aws_session_save
export -f _aws_session_load
