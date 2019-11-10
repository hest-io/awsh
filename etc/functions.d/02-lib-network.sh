#!/usr/bin/env bash

# Simple function to get a list of the local IP addresses
function _network_get_local_ip {
    echo "$(ifconfig | grep 'inet addr' | cut -d: -f2 | cut -d' ' -f1 | grep -v '127.0.0.1')"
}


# Simple function to test if the variable is a valid IP address. Additionally
# it will echo to stdout the list of matching valid IP addresses so that it can
# be used as a filter
function _network_is_valid_ip4_address {

    echo "$1" | grep -Eoaq "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"
    return $?

}


# Simple function to test if remote destination is reachable. Defaults to port
# 80. Only valid for TCP targets and returns 0 (open) or 1
# Use with _network_can_reach google.com 80
function _network_can_reach {
    local tgt_host="${1:-127.0.0.1}"
    local tgt_port="${2:-80}"
    timeout 1 bash -c ">/dev/tcp/${tgt_host}/${tgt_port}" && result=0 || result=1
    return $result
}


# Simple function to read from a remote TCP network target. A poor man's
# CURL/WGET. Remember to use a valid protocol request
# (eg Add 'GET <url>\n' if HTTP)
# Usage:
#   Read    : _network_read_from google.com 80 'GET /api/data\n'
#   Download: _network_read_from www.freeipa.org 80 "GET /images/freeipa/freeipa-logo-small.png\n" > /tmp/file
function _network_read_from {
    local tgt_host="${1:-127.0.0.1}"
    local tgt_port="${2:-80}"
    local tgt_request="${3:-GET / HTTP/1.0\n\n}"
    exec 5<>/dev/tcp/${tgt_host}/${tgt_port}
    echo -e "$tgt_request" >&5
    cat <&5
}


# Helper alias to read from target after making an HTTP 1.0 request
function _network_http_1_0_read_from_url {
    local tgt_host="${1:-127.0.0.1}"
    local tgt_port="${2:-80}"
    local tgt_request="${3:-/}"
    _network_read_from "$tgt_host" "$tgt_port" "GET ${tgt_request} HTTP/1.0\n\n"
}


# Helper alias to read from target after making an HTTP 1.1 request
function _network_http_1_1_read_from_url {
    local tgt_host="${1:-127.0.0.1}"
    local tgt_port="${2:-80}"
    local tgt_request="${3:-/}"
    _network_read_from "$tgt_host" "$tgt_port" "GET ${tgt_request} HTTP/1.1\nHost:${tgt_host}\nConnection: close\n\n"
}


# Simply utility function to act as poor man's nmap command
# Use with _network_nmap hostname.
function _network_nmap {
    local tgt_host="${1:-127.0.0.1}"
    for tgt_port in {1..1023}; do
        (_network_can_reach "${tgt_host}" "${tgt_port}") >/dev/null 2>&1 && echo "$tgt_port open" || echo "$tgt_port closed"
    done
}
