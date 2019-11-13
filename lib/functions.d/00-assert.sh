#!/usr/bin/env bash

function _assert_is_authenticated {
    if ! _aws_is_authenticated ; then
        _screen_error 'This command requires an active AWS session. Login first please!'
        exit 1
    fi
}

