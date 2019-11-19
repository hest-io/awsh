#!/usr/bin/env bash

# Simple function to send metrics to Graphite based on the awesome example from
# https://github.com/etsy/statsd/blob/master/examples/statsd-client.sh

# Usage _graphite_send_raw 'my_metric 100 [timestamp]'
# Optionally set GRAPHITE_HOST and GRAPHITE_PORT variables
function _graphite_send_raw {

    _system_ensure_is_bash

    local current_timestamp="$(date +%s)"
    local metric_timestamp="${3:-$current_timestamp}"
    local host="${GRAPHITE_HOST:-127.0.0.1}"
    local port="${GRAPHITE_PORT:-2003}"
    if [ $# -lt 2 ]; then
        exit 1
    fi

    # _log "$LINENO" "Testing for connectivity to Graphite @ ${host}:${port}"
    timeout 2 bash -c "exec 4<> /dev/tcp/$host/$port"

    if [ $? -eq 0 ]; then

        _log "$LINENO" "Sending metric ${1}=${2} [${metric_timestamp}] to Graphite @ ${host}:${port}"
        # Set up TCP socket with statsd server
        exec 4<> /dev/tcp/$host/$port
        # Send data
        echo "${1} ${2} ${metric_timestamp}" >&4
        # Close TCP socket
        exec 4<&-
        exec 4>&-

    else

        _log "$LINENO" "Unable to connect to Graphite @ ${host}:${port}"

    fi

}


# Usage _graphite_pipe_raw '<filename>' or cat <filename> | _graphite_pipe_raw
# Optionally set GRAPHITE_HOST and GRAPHITE_PORT variables
function _graphite_pipe_raw {

    _system_ensure_is_bash

    local host="${GRAPHITE_HOST:-127.0.0.1}"
    local port="${GRAPHITE_PORT:-2003}"

    # _log "$LINENO" "Testing for connectivity to Graphite @ ${host}:${port}"
    timeout 2 bash -c "exec 4<> /dev/tcp/$host/$port"

    if [ $? -eq 0 ]; then

        # If no input file was passed as an argument then assume that we're part
        # of a pipeline and read from STDIN
        _log "$LINENO" "Sending raw input to Graphite @ ${host}:${port}"

        # Set up TCP socket with statsd server
        exec 4<> /dev/tcp/$host/$port
        # Send data from file if we have one of STDIN if not
        if [ -z $1 ]; then
            cat >&4
            result=$?
        else
            cat "$1" >&4
            result=$?
        fi

        # Close TCP socket
        exec 4<&-
        exec 4>&-

        _log "$LINENO" "Graphite pipeline completed. RC ${result}"

    else
        _log "$LINENO" "Unable to connect to Graphite @ ${host}:${port}"
    fi

}
