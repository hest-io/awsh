# An alias for xargs to ensure that the expected behaviour in scripts is as
# intended for those on OS X
_xargs() {
    if [ "$(uname)" == "Darwin" ]; then
       xargs -L 1 $@
    else
       xargs -i $@ {}
    fi
}


# Dummy function for cleanup
_cleanup() {
    local p_exit_code="$1"
    : ${p_exit_code:=1}
    echo 'ERROR: Interrupted! Please check your app/script'
    exit $p_exit_code
}


# This ain't Burger King.
_ensure_is_bash() {

    if [ ! -n "$BASH_VERSION" ]; then
        echo ''
        echo 'You did not use a BASH shell and tried to use something that needs it.'
        echo 'https://www.youtube.com/watch?feature=player_detailpage&v=bWXazVhlyxQ#t=89'
        echo ''
    fi

}
