# Job management to assist with parallel processing. Use by backgrounding the
# previous command and then invoking the job manager to manage the queue
# Defaults to 2 jobs limit
#
# eg.
#   while true
#   do
#       _job_queue 4                       # limit of 4
#       do_something "arg1" "arg2" &
#   done
#
_job_queue() {

    local p_max_jobs="$1"
    : ${p_max_jobs:=4}

    jobs_count="$(jobs -p | wc -l)"
    while [ ${jobs_count} -gt ${p_max_jobs} ]; do
        sleep 1
        jobs_count="$(jobs -p | wc -l)"
    done
}
