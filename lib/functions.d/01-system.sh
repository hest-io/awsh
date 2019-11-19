#!/usr/bin/env bash
# An alias for xargs to ensure that the expected behaviour in scripts is as
# intended for those on OS X
function _system_xargs {
    if [ "$(uname)" == "Darwin" ]; then
       xargs -L 1 $@
    else
       xargs -i $@ {}
    fi
}


# Dummy function for cleanup
function _system_cleanup {
    local p_exit_code="$1"
    : "${p_exit_code:=1}"
    echo 'ERROR: Interrupted! Please check your app/script'
    exit $p_exit_code
}


# This ain't Burger King.
function _system_ensure_is_bash {

    if [[ -z "$BASH_VERSION" ]]; then
        echo ''
        echo 'You did not use a BASH shell and tried to use something that needs it.'
        echo 'https://www.youtube.com/watch?feature=player_detailpage&v=bWXazVhlyxQ#t=89'
        echo ''
    fi

}


# Job management to assist with parallel processing. Use by backgrounding the
# previous command and then invoking the job manager to manage the queue
# Defaults to 2 jobs limit
#
# eg.
#   while true
#   do
#       _system_job_queue 4                       # limit of 4
#       do_something "arg1" "arg2" &
#   done
#
function _system_job_queue {

    local p_max_jobs="$1"
    : "${p_max_jobs:=4}"

    jobs_count="$(jobs -p | wc -l)"
    while [[ ${jobs_count} -gt ${p_max_jobs} ]]; do
        sleep 1
        jobs_count="$(jobs -p | wc -l)"
    done
}
