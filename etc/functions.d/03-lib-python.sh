# Activate the local instance of Python or correct the PYTHONPATH env variable
# depending on the OS detected.
# TODO(kxseven: Better solution needed on OSX for forked shells from within Python
if [[ "$(uname)" == "Darwin" ]]; then
   export PYTHONPATH="${AWSH_ROOT}/local/python/lib/python2.7/site-packages:${AWSH_ROOT}/lib:${AWSH_ROOT}/bin/tools:${AWSH_ROOT}/bin/subcommands"
elif [[ "${AWSH_CONTAINER}" == "docker" ]]; then
       PYTHONPATH=$PYTHONPATH:${AWSH_ROOT}/lib/python:${AWSH_ROOT}/bin/tools:${AWSH_ROOT}/bin/subcommands
       export PYTHONPATH
else
    if [ -e "${AWSH_ROOT}/local/python/bin/activate" ]; then
       source ${AWSH_ROOT}/local/python/bin/activate
       PYTHONPATH=$PYTHONPATH:${AWSH_ROOT}/lib/python:${AWSH_ROOT}/bin/tools:${AWSH_ROOT}/bin/subcommands
       export PYTHONPATH
    else
        _log "$LINENO" "The Python VirtualEnv does not appear to be present where I expect it to be: ${AWSH_ROOT}/local/python"
    fi
fi
