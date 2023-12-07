#!/usr/bin/env bash

# Simple function to convert an epoch timestamp to a date string using the
# FV_TIMESTAMP format
function _time_from_epoch {

  : "${FV_TIMESTAMP_FORMAT:='%Y-%m-%d %H:%M:%S'}"

  local ts_epoch="${1:--1}"
  local ts_epoch_scale="${2:-1}"
  local ts_epoch_length=${#ts_epoch}
  local re_number='^-?[0-9]+([.][0-9]+)?$'

  if ! [[ $ts_epoch =~ $re_number ]]; then
    # _log "$LINENO" "Provided variable $ts_epoch was not a number. Returning default"
    # shellcheck disable=SC2005
    echo "$(date +"${FV_TIMESTAMP_FORMAT}" -d@0)"
    return 2
  fi

  # If no input was passed then return the current date
  local ts_date
  if [ $ts_epoch -ge 0 ]; then

    # If the epoch is longer than the normal length we will assume the value
    # is in milliseconds
    if [ $ts_epoch_length -gt 10 ]; then
      ts_epoch_scale=1000
    fi
    ts_date=$(date +"${FV_TIMESTAMP_FORMAT}" -d @$((ts_epoch / ts_epoch_scale)))
  else
    ts_date=$(date +"${FV_TIMESTAMP_FORMAT}")
  fi
  # _log "$LINENO" "Converted ${ts_epoch} to ${ts_date} at scale ${ts_epoch_scale}"

  echo "${ts_date}"
  return 0

}

# Simple function to convert to epoch timestamp from a date string
function _time_to_epoch {

  local ts_time="${1:-now}"
  # Perform basic cleanup
  # shellcheck disable=SC2001
  local ts_date="$(echo "$ts_time" | sed -e "s/_/\ /g")"
  # shellcheck disable=SC2005
  echo "$(date +%s -d"${ts_date}")"
  return 0

}

# Simple function to return the current date and time in ISO-8601
# format. Defaults to UTC timezone. Takes optional arg of valid timezone
function _time_get_iso8601_date {

  local ts_tz="${1:-UTC}"
  # shellcheck disable=SC2005
  echo "$(TZ=${ts_tz} date "+%Y%m%dT%H%M%S")"
  return 0

}

# Attempts to convert the value into a valid date with format. The argument
# may be a numeric value representing a UNIX epoch or a string in a format
# similar to "2023-11-29T12:28:00Z"
function _time_convert_to_date {

  local possible_date="${1:-now}"
  local ts_date

  if [[ $possible_date =~ ^[0-9]+$ ]]; then
    # Input is a numeric value representing UNIX epoch
    ts_date=$(_time_from_epoch "${possible_date}")
  else
    # Input is a string
    ts_date=$(date +"${FV_TIMESTAMP_FORMAT}" -d "${possible_date}")
  fi

  echo "$ts_date"
  return 0

}
