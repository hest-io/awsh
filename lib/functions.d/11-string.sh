#!/usr/bin/env bash

# Reproduces the behaviour of the Python aray.join() function. Copied from the
# awesome example on https://stackoverflow.com/a/17841619
function _string_join {
    local IFS="$1";
    shift;
    echo "$*";
}


# Reproduces the behaviour of the chomp command/utility
function _string_chomp {
    local s="$(echo "${@}" | sed -e 's/^ *//g;s/ *$//g')"
    echo "${s}"
}
