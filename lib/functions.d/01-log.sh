#!/usr/bin/env bash
# A logging function which can be used as follows
# _log "$LINENO" "Example test message"
function _log {

    local p_line_number="$1"
    local p_message="$2"
    : "${p_line_number:=0}"
    : "${DEFAULT_OUT:=/dev/stderr}"

    timestamp="$(date +'%Y-%m-%dT%H:%M:%S%z')"
    log_file_msg=$(printf "[%s]: %-s:%04d : %s" "$timestamp" "$CONST_SCRIPT_NAME" "$p_line_number" "${p_message}")
    log_tty_msg=$(printf "[%s]: %03d : INFO  %s" "$timestamp" "$p_line_number" "$p_message")

    # Output to TTY if enabled
    [[ $TTY_OUTPUT_ENABLED -eq $TRUE ]] && echo -e "${log_tty_msg}" >&2
    # Output to the DEFAULT_OUT file if enabled
    [[ $LOG_OUTPUT_ENABLED -eq $TRUE ]] && echo -e "${log_file_msg}" >> "$DEFAULT_OUT"
    # Output to the syslog if the logger command is found
    _dummy=$(command -v logger > /dev/null 2>&1)
    has_syslogger=$?
    [[ $SYSLOG_OUTPUT_ENABLED -eq $TRUE ]] && [[ "$has_syslogger" -eq $TRUE ]] && logger -t "$CONST_SCRIPT_NAME[$$]" -p user.info "${log_tty_msg}"

}

# A logging function which can be used as follows
# _log_event "$LINENO" "<Severity>" "Example test message"
# _log_event "$LINENO" "INFO" "Example test message"
# _log_event "$LINENO" "ERROR" "Example test message"
# _log_event "$LINENO" "WARNING" "Example test message"
function _log_event {

    local p_line_number="$1"
    local p_severity="$2"
    local p_message="$3"
    : "${p_line_number:=0}"
    : "${p_severity:='INFO'}"
    : "${EVENT_LOG:=/dev/stderr}"

    timestamp="$(date +'%Y-%m-%dT%H:%M:%S%z')"
    log_file_msg=$(printf "[%s]: %03d : %-7.7s : %s" "$timestamp" "$p_line_number" "${p_severity}" "${p_message}")
    log_tty_msg=$(printf "[%s]: %03d : %-7.7s : %s" "$timestamp" "$p_line_number" "${p_severity}" "${p_message}")

    # Output to the EVENT_LOG file if enabled
    [[ $EVENT_OUTPUT_ENABLED -eq $TRUE ]] && echo -e "${log_file_msg}" >> "$EVENT_LOG"
    # Also output to the syslog if the logger command is found
    _dummy=$(command -v logger > /dev/null 2>&1)
    has_syslogger=$?
    [[ $SYSLOG_OUTPUT_ENABLED -eq $TRUE ]] && [[ $has_syslogger -eq $TRUE ]] && logger -t "$CONST_SCRIPT_NAME[$$]" -p user.info "${log_tty_msg}"

}


# A helper function that can be used to print timestamps to strings printed to
# output streams aimed at mimicking the 'ts' utility if it's not present
function _log_ts {
    cat | while IFS= read -r line; do printf '%s %s %s\n' "$(date +'%Y-%m-%dT%H:%M:%S%z')" "$line" "$(echo -e ${__no_color})"; done
}



# A logging function which can be used as follows to exit the run with a specific error message
# _log_exit_with_error "$LINENO" "Example test message"
function _log_exit_with_error {

  # ANSI escape code for red text
  local red='\033[0;31m'
  # ANSI escape code to reset text color
  local reset='\033[0m'

  local p_line_number="$1"
  local p_message="$2"
  : "${p_line_number:=0}"
  : "${DEFAULT_OUT:=/dev/stderr}"

  timestamp="$(date +'%Y-%m-%dT%H:%M:%S%z')"
  log_file_msg=$(printf "[%s]: %-s:%04d : %s" "$timestamp" "$CONST_SCRIPT_NAME" "$p_line_number" "${p_message}")
  log_tty_msg=$(printf "[%s]: %03d : %s" "$timestamp" "$p_line_number" "${red}ERROR ${p_message}${reset}")

  # Output to TTY if enabled
  [[ $TTY_OUTPUT_ENABLED -eq $TRUE ]] && echo -e "${log_tty_msg}" >&2
  # Output to the DEFAULT_OUT file if enabled
  [[ $LOG_OUTPUT_ENABLED -eq $TRUE ]] && echo -e "${log_file_msg}" >> "$DEFAULT_OUT"
  # Output to the syslog if the logger command is found
  _dummy=$(command -v logger > /dev/null 2>&1)
  has_syslogger=$?
  [[ $SYSLOG_OUTPUT_ENABLED -eq $TRUE ]] && [[ "$has_syslogger" -eq $TRUE ]] && logger -t "$CONST_SCRIPT_NAME[$$]" -p user.info "${log_tty_msg}"

  exit 1

}