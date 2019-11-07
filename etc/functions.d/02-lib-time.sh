# Simple function to convert an epoch timestamp to a date string using the
# FV_TIMESTAMP format
_time_from_epoch() {

    local ts_epoch="${1:--1}"
    local re_number='^-?[0-9]+([.][0-9]+)?$'

    if ! [[ $ts_epoch =~ $re_number ]]; then
        _log "$LINENO" "Provided variable $ts_epoch was not a number. Returning default"
        echo "$(date +"${FV_TIMESTAMP_FORMAT}" -d@0)"
        return 2
    fi

    # If no input was passed then return the current date
    local ts_date
    if [ $ts_epoch -ge 0 ]; then
        ts_date=$(date +"${FV_TIMESTAMP_FORMAT}" -d @${ts_epoch})
    else
        ts_date=$(date +"${FV_TIMESTAMP_FORMAT}")
    fi
    _log "$LINENO" "Converted ${ts_epoch} to ${ts_date}"

    echo "${ts_date}"
    return 0

}


# Simple function to convert to epoch timestamp from a date strin
_time_to_epoch() {

    local ts_time="${1:-now}"
    # Perform basic cleanup
    local ts_date="$(echo "$ts_time" | sed -e "s/_/\ /g")"
    echo "$(date +%s -d"${ts_date}")"
    return 0

}


# Simple function to return the current date and time in ISO-8601
# format. Defaults to UTC timezone. Takes optional arg of valid timezone
_time_get_iso8601_date() {
    local ts_tz="${1:-UTC}"
    echo "$(TZ=${ts_tz} date "+%Y%m%dT%H%M%S")"
}

