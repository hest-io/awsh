#!/usr/bin/env bash

# Simple function to send metrics to StatsD based on the awesome example from
# https://github.com/etsy/statsd/blob/master/examples/statsd-client.sh

# Usage _statsd_send_raw 'my_metric:100|g'
# Optionally set STATSD_HOST and STATSD_PORT variables
function _statsd_send_raw {

    _system_ensure_is_bash

    local host="${STATSD_HOST:-127.0.0.1}"
    local port="${STATSD_PORT:-8125}"
    if [ $# -ne 1 ]; then
        exit 1
    fi
    _log "$LINENO" "Sending metric ${1} to StatsD @ ${host}:${port}"
    # Set up UDP socket with statsd server
    exec 3<> /dev/udp/$host/$port
    # Send data
    echo "$1" >&3
    # Close UDP socket
    exec 3<&-
    exec 3>&-

}


# Usage _statsd_send_count 'my_metric:100'
function _statsd_send_count {
    _statsd_send_raw "${1}|c"
}


# Usage _statsd_send_gauge 'my_metric:100'
function _statsd_send_gauge {
    _statsd_send_raw "${1}|g"
}


# Usage _statsd_send_set 'my_metric:100'
function _statsd_send_set {
    _statsd_send_raw "${1}|s"
}


# Usage _statsd_send_ms 'my_metric:100'
function _statsd_send_ms {
    _statsd_send_raw "${1}|ms"
}
